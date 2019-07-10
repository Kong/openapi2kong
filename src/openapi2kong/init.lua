local parse_openapi = require "openapi2kong.openapi"
local lyaml = require "lyaml"
local cjson = require "cjson.safe"
local utils = require "pl.utils"
local gsub = string.gsub
local tablex = require "pl.tablex"
local table_deepcopy = tablex.deepcopy
local path = require "pl.path"

local pack = function(...)  -- nil safe version of pack
  return { n = select("#", ...), ...}
end


local SERVERS_TYPES = {  -- types having a `servers` array
  openapi = true,
  path = true,
  operation = true,
}


--- Loads a spec string.
-- Tries to first read it as json, and if failed as yaml.
-- @param spec_str (string) the string to load
-- @return table or nil+err
local function load_spec(spec_str)

  -- first try to parse as JSON
  local result, cjson_err = cjson.decode(spec_str)
  if type(result) ~= "table" then
    -- if fail, try as YAML
    local ok
    ok, result = pcall(lyaml.load, spec_str)
    if not ok or type(result) ~= "table" then
      return nil, ("Spec is neither valid json ('%s') nor valid yaml ('%s')"):
                  format(tostring(cjson_err), tostring(result))
    end
  end

  return result
end



-- removes all non-allowed characters from a tag name
local function clean_tag(tag)
  return tag:gsub("[^%w%_%-%.%~]", "_")
end


-- return a NEW table, with all tags combined, without duplication.
-- Each parameter should be a list of tags
local function get_tags(...)
  local params = pack(...)
  local tags = {}
  local check = {}

  for i = 1, params.n do
    for _,v in ipairs(params[i] or {}) do
      v = clean_tag(v)
      if not check[v] then
        tags[#tags+1] = v
        check[v] = true
      end
    end
  end

  return tags
end


local registry_add, registry_get
do
  local registry = setmetatable({}, { __mode = "kv" })

  --- Add an entry to the generation registry.
  -- The registry keeps track of what Kong entities were generated from OpenAPI
  -- objects. The key is an OpenAPI object (eg. "path", or "servers"), and the
  -- values attached to it the will be the Kong entities.
  function registry_add(key, value1, value2)
    assert(type(key) == "table", "expected key to be an OpenApi parsed object")
    assert(not registry[key], "this key was already registered")
    local type_obj = key.type
    assert(type_obj, "expected key to be an OpenApi parsed object")

    if type_obj == "servers" then
      registry[key] = {
        upstream = assert(value1.targets and value1, "expected first value to be an Upstream"),
        service = assert(value2.path and value2, "expected second value to be a Service"),
      }

    elseif type_obj == "operation" then
      registry[key] = assert(value1.strip_path ~= nil, "expected first value to be a Route")
      assert(value2 == nil, "did not expect a second value for 'operation'")

    else
      error("cannot add object (key) of type: " .. type_obj, 2)
    end
  end

  --- Gets an entry from the generation registry.
  function registry_get(key)
    assert(type(key) == "table", "expected key to be an OpenApi parsed object")
    assert(key.type, "expected key to be an OpenApi parsed object")
    return registry[key]
  end
end


-- finds the next "x-kong-xxxx" custom extension.
-- returns a copy of the default table, or an empty table if not found
local function get_kong_defaults(obj, custom_directive, types)
  local default, err = obj:get_inherited_property(custom_directive, types)
  if err and err ~= "not found" then
    return nil, err
  end
  default = default or {}
  return table_deepcopy(default)
end

-- finds the next "x-kong-upstream-defaults" custom extension
local function get_upstream_defaults(obj)
  return get_kong_defaults(obj, "x-kong-upstream-defaults", SERVERS_TYPES)
end

-- finds the next "x-kong-service-defaults" custom extension
local function get_service_defaults(obj)
  return get_kong_defaults(obj, "x-kong-service-defaults", SERVERS_TYPES)
end

-- finds the next "x-kong-route-defaults" custom extension
local function get_route_defaults(obj)
  return get_kong_defaults(obj, "x-kong-route-defaults", SERVERS_TYPES)
end


--- returns all "servers" objects from the openapi spec.
local function  get_all_servers(openapi)
  local servers_arr = { openapi.servers }

  for _, path_obj in ipairs(openapi.paths) do
    servers_arr[#servers_arr+1] = path_obj.servers
  end

  return servers_arr
end

--- Converts "servers" object to "upstreams", "targets", and "services".
-- @param openapi (table) openapi object as parsed from the spec.
-- @param options table with conversion options
-- @return kong table (options.kong, updated) or nil+err.
local function convert_servers(openapi, options)
  local servers_arr = get_all_servers(openapi)
  local kong = options.kong
  local upstreams = kong.upstreams
  local services = kong.services

  for _, servers in ipairs(servers_arr) do
    -- upstream
    local targets = {}

    -- add targets
    for _, server in ipairs(servers) do
      targets[#targets+1] = {
        target = server.parsed_url.host .. ":" .. server.parsed_url.port,
      }
    end

    local upstream = get_upstream_defaults(servers)
    upstream.name = servers:get_name(options)
    upstream.targets = targets
    upstream.tags = get_tags(options.tags, upstream.tags)

    upstreams[#upstreams+1] = upstream

    -- service
    local url = servers[1].parsed_url

    local service = get_service_defaults(servers)
    service.name = servers:get_name(options)
    service.protocol = url.scheme
    service.port = tonumber(url.port)
    service.host = servers:get_name(options)
    service.path = "/"
    service.tags = get_tags(options.tags, service.tags)

    services[#services+1] = service

    -- register entities
    registry_add(servers, upstream, service)
  end

  return kong
end


--- Converts "paths" object to "routes", and "plugins".
-- @param openapi (table) openapi object as parsed from the spec.
-- @param options table with conversion options
-- @return kong table (options.kong, updated) or nil+err.
local function convert_paths(openapi, options)
  local kong = options.kong

  for _, path_obj in ipairs(openapi.paths) do

    local path = path_obj:get_servers()[1].parsed_url.path or "/"
    if path:sub(-1,-1) == "/" and
       path_obj.path:sub(1,1) == "/" then
      -- double slashes, drop one
      path = path .. path_obj.path:sub(2,-1)
    else
      path = path .. path_obj.path
    end

    -- convert path into a regex
    -- 1) add template parameters
    -- TODO: adjust the regex created here. OAS 3 does not support multiple segment capture
    -- see https://github.com/OAI/OpenAPI-Specification/issues/291#issuecomment-316593913
    -- So the regex should match non-empty, no /, no ?, no #
    path = gsub(path, "{(.-)}", "(?<%1>\\S+)")

    -- 2) anchor the match, because we're matching in full, not just prefixes
    path = path .. "$"

    local service = registry_get(path_obj:get_servers()).service
    service.routes = service.routes or {}

    for _, operation_obj in ipairs(path_obj.operations) do

      local route = get_route_defaults(operation_obj)
      route.name = operation_obj:get_name()
      route.paths = { path }
      route.methods = { operation_obj.method:upper() }
      route.strip_path = false
      route.tags = get_tags(options.tags, route.tags)
      --TODO: set regex_priority property to match in proper order??

      -- store the final route on the service
      service.routes[#service.routes+1] = route

      -- register entities
      registry_add(operation_obj, route)
    end

  end

  return kong
end


-- returns a basic Kong spec
local function new_kong()
  return {
    _format_version = "1.1",
  }
end


--- Convert an OpenAPI spec table and convert it to a Kong table.
-- @param openapi (table) openapi object as parsed from the spec.
-- @param options table with conversion options;
--  - `kong` (optional) an existing kong spec to add to
-- @return table or nil+err
local function to_kong(openapi, options)
  options = options or {}
  options.kong = options.kong or new_kong()
  options.kong.upstreams = options.kong.upstreams or {}
  options.kong.services = options.kong.services or {}


  local ok, err = convert_servers(openapi, options)
  if not ok then
    return nil, "Failed to convert servers: " .. tostring(err)
  end

  ok, err = convert_paths(openapi, options)
  if not ok then
    return nil, "Failed to convert paths: " .. tostring(err)
  end

  return options.kong
end


--- Takes an OpenAPI spec and returns it as a Kong config.
-- @param spec_input the OpenAPI spec to convert. Can be a either a table, a json-string, or a yaml-string.
-- @param options table with conversion options
-- @return table with kong spec, or nil+err
local function convert_spec(spec_input, options)
  if type(spec_input) == "string" then
    local err
    spec_input, err = load_spec(spec_input)
    if not spec_input then
      return nil, err
    end
  end

  local openapi_obj, err = parse_openapi(spec_input, options)
  if not openapi_obj then
    return nil, err
  end

  local kong_obj
  kong_obj, err = to_kong(openapi_obj, options)
  if not kong_obj then
    return nil, err
  end

  return kong_obj
end

-- @param filenames either a filename (string) or list of filenames (table)
-- @param options table with conversion options
-- @return table with kong spec, or nil+err
local function convert_files(filenames, options)
  if type(filenames) == "string" then
    filenames = { filenames }
  end

  options = options or {}
  options.tags = options.tags or {}
  options.tags[#options.tags + 1] = "OAS3_import"

  local kong = options.kong or new_kong()

  local file_tag_id = #options.tags + 1

  for _, filename in ipairs(filenames) do

    local file_content, err = utils.readfile(filename)
    if not file_content then
      return nil, ("Failed reading '%s': %s"):format(tostring(filename), tostring(err))
    end

    options.import_filename = path.basename(filename)
    options.tags[file_tag_id] = "OAS3file_" .. options.import_filename

    options.kong = kong
    kong, err = convert_spec(file_content, options)
    if not kong then
      return nil, ("Failed converting '%s': %s"):format(tostring(filename), tostring(err))
    end
  end

  return kong
end


return {
  convert_files = convert_files,
  convert_spec = convert_spec,
}
