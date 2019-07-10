local singletons = require "kong.singletons"
local utils      = require "kong.tools.utils"
local lyaml      = require "lyaml"
local cjson      = require "cjson.safe"
--local pl_stringx = require "pl.stringx"
local pl_tablex  = require "pl.tablex"
local socket_url = require "socket.url"
--local workspaces = require "kong.workspaces"

--local sub          = string.sub
local gsub         = string.gsub
local to_lower     = string.lower
local to_upper     = string.upper
local match        = string.match
local insert       = table.insert
--local pl_split     = pl_stringx.split
local pl_pairmap   = pl_tablex.pairmap
local tonumber     = tonumber

--local uuid         = require("kong.tools.utils").uuid


local _M = {}

-- returns true if the value is a string with more than just whitespace
local function non_empty_string(str)
  return type(str) == "string" and utils.strip(str) ~= ""
end


local function create_services(service_configs)
  local services = {}

  for _, service_config in ipairs(service_configs) do
    local service, _, err_t = singletons.db.services:insert(service_config)
    if err_t then
      return nil, err_t
    end

    insert(services, service)
  end

  return services
end


local function create_routes(spec, services)
  local routes = {}

  for path, methods in pairs(spec.paths) do
    -- TODO: adjust the regex created here. OAS 3 does not support multiple segment capture
    -- see https://github.com/OAI/OpenAPI-Specification/issues/291#issuecomment-316593913
    -- So the regex should match non-empty, no /, no ?, no #
    local formatted_path = gsub(path, "{(.-)}", "(?<%1>\\S+)")

    for _, service in ipairs(services) do
      local route_conf = {
        params = {
          -- TODO: routes have names, so construct one here
          service = { id = service.id },
          paths = { formatted_path },
          protocols = { service.protocol },
          strip_path = false,
          methods = pl_pairmap(function(key) -- returns array of uppercase method names
            return to_upper(key)
          end, methods),
        },
      }

--      if workspaces.is_route_colliding(route_conf, singletons.router) then
--        return nil, {
--          message = "API route collides with an existing API",
--          code = 409,
--        }
--      end

--      local route, _, err_t = singletons.db.routes:insert(route_conf.params)
--      if err_t then
--        return nil, err_t
--      end

      insert(routes, route)
    end
  end

  return routes
end


-- Loads a string value as either json or yaml.
-- @param spec_str (string) string holding valid json or yaml
-- @return Lua table with the parsed contents, or nil+err
local function load_spec(spec_str)
  if non_empty_string(spec_str) then
    return nil, "Spec is required and cannot be empty"
  end

  -- first try to parse as JSON
  local result, cjson_err = cjson.decode(spec_str)
  if type(result) ~= "table" then
    -- if fail, try as YAML
    local ok, result = pcall(lyaml.load, spec_str)
    if not ok or type(result) ~= "table" then
      return nil, ("Spec is neither valid json ('%s') nor valid yaml ('%s')"):
                  format(tostring(cjson_err), tostring(result))
    end
  end

  if not result.openapi then
    return nil, "missing openapi version"
  end

  local major_version = match(result.openapi, "^(%d+)%.%d")
  if major_version ~= "3" then
    return nil, "unsupported major version: " .. major_version .. ". OAS major version v3 supported"
  end

  return result
end


local function get_name(spec_info, protocol, index)
  spec_info = spec_info or {}

  local name = spec_info.title
  if not name or name == "" then
    return nil, "info.title is required for service name"
  end

  -- convert to lowercase and replace spaces with dashes
  -- add protocol and index suffixes
  local suffix = "-" .. index .. (protocol == "https" and "-secure" or "")
  return gsub(to_lower(name), "%s+", "-") .. suffix
end

-- return port number.
-- Port number if provided, or default port based on protocol
local function get_port(port, scheme)
  return tonumber(port) or port or
         (scheme == "http" and 80) or
         (scheme == "https" and 443) or nil
end


local function parse_url(url)
  if not url or url == "" then
    return nil, "url is required"
  end

  local parsed_url = socket_url.parse(url)

  return {
    protocol = parsed_url.scheme,
    host = parsed_url.host,
    port = get_port(parsed_url.port, parsed_url.scheme),
    path = parsed_url.path,
  }
end


-- Get a Service definition from a 'server' entry.
-- @param server An entry from the spec.servers table
-- @param spec The spec table
-- @param counters Table with counters per protocol/scheme
-- @return a table or nil+err. Table looks like this:
-- {
--   protocol = "https",               -- https => "-secure" appendix below
--   host = "myhost.com",
--   port = 443,
--   path = "/some/path",
--   name = "my-api-title-23-secure",  -- constructed from spec title
-- }
local function server_to_service(server, spec, counters)

--[[
  TODO: Handle variable replacement in urls.
  This will change the return signature, this
  method will then return an array of configs
  Thijs: replace entries with the 'default' values???
  Thijs: url-parser suppoprt {} in elements for substitution

  Thijs: what if we provide a table with variable values with the spec. This
  table could hold separate values for different environments (qa/dev/prod)
  that would facilitate migrating env's through the lifecycle

  eg. (see example at "Servers" in OAS3 spec)
  servers = {
    [1] = {
      username = "aladdin",
      port = nil,            -- not provided, fall back on "default"
      basePath = nil,        -- not provided fallback on upper level
      },
    [2] = {},
    basePath = "v4",          -- upper level as fallback


  Thijs: seems we're attaching all routes/paths to every server/service??
  That's a lot of duplication. Ideally we have 1 server/service. So can we reduce
  multiple servers to 1 loadbalancer? only if they have identical paths...
]]

  -- parse the url, setting default port if required
  local config, err = parse_url(server.url)
  if err then
    return nil, err
  end

  -- increment counters (used in naming the services)
  counters[config.protocol] = counters[config.protocol] + 1

  local name
  name, err = get_name(spec.info, config.protocol, counters[config.protocol])
  -- spec title "my api title" --> "my-api-title-23-secure"
  -- 23 is a counter, "-secure" is a https-only postfix
  if err then
    return nil, err
  end

  config.name = name

  return config
end


-- Create a Service for each server in the spec.
-- @param spec the OAS spec table
-- @return array with services, or nil+err
local function get_services(spec)
  if not next(spec.servers or {}) then
    return nil, "OAS v3 - servers required"
  end

  -- counter table to help with naming of services
  -- TODO: why do we need to count by protocol???
  local counters = {
    http = 0,
    https = 0
  }

  local err
  local services = {}
  for i, server in ipairs(spec.servers) do
    services[i], err = server_to_service(server, spec, counters)
    if err then
      return nil, "OAS v3 - " .. err
    end
  end

  return services
end


-- ====================================================================
-- 1. this is where we start
-- ====================================================================
function _M.generate_config(spec_str)
  -- convert from str to lua table
  local spec, err = load_spec(spec_str)
  if err then
    return nil, err
  end

  -- populate service tables
  local service_configs
  service_configs, err = get_services(spec)
  if err then
    return nil, { code = 400, message = err }
  end

  -- create services
  local services
  services, err = create_services(service_configs)
  if err then
    return nil, err
  end

  -- create routes
  local routes
  routes, err = create_routes(spec, services)
  if err then
    return nil, err
  end

  return {
    services = services,
    routes = routes,
  }
end


return _M
