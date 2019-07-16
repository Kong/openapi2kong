local split = require("pl.utils").split

local M = {}
local methods = {}

local MAX_RECUR = 1000

-- return the toplevel openapi object
function methods:get_openapi()
  local parent = self
  local count = MAX_RECUR  -- poor man's recursion detection
  while true do
    if parent.type == "openapi" then
      return parent -- we've got the top level openapi object
    end

    parent = parent.parent
    if type(parent) ~= "table" then
      return nil, "parent lookup links broken, expected table, got " .. type(parent)
    end

    count = count - 1
    if count == 0 then
      return nil, "recursion detected while traversing to top openapi element"
    end
  end
  -- unreachable
end


do
  -- register per top-level OpenApi object, each register indexed by object with
  -- as value the name.
  local registers = setmetatable({}, { __mode = "k" })

  -- returns a unique generated name for an object
  function methods:get_name()

    local register
    do  -- get the register for this OpenAPI object
      local openapi = self:get_openapi()
      register = registers[openapi]
      if not register then
        register = {}
        registers[openapi] = register
      end
    end

    -- if we already have a name, exit early
    local name = register[self]
    if name then return name end

    -- create a name based on object type
    if self.type == "openapi" then
      name = self.spec["x-kong-name"] or (self.spec.info or {}).title or "openapi"

    elseif self.type == "path" then
      name = self.spec["x-kong-name"] or self.spec.summary or "path"
      name = self.parent.parent:get_name() .. "-" .. name

    elseif self.type == "operation" then
      name = self.parent:get_name() .. "-" .. self.method

    elseif self.type == "servers" then
      return self.parent:get_name()

    else
      error("don't know how to get 'name' of an '" .. tostring(self.type) .. "' object", 2)
    end

    -- cleanup name; must be valid hostname for 'upstream'
    name = name:gsub("[^%w%_%-%.%~]", "_")

    -- go and check for (case insensitive) duplicates, number towards
    -- uniqueness if needed
    local count = 0
    local check_name = name
    while true do
      local duplicate = false
      for obj, obj_name in pairs(register) do
        if obj.type == self.type and check_name:lower() == obj_name:lower() then
          duplicate = true
          count = count + 1
          check_name = name .."_" .. count
          break
        end
      end
      if not duplicate then
        name = check_name
        break
      end
    end

    register[self] = name

    return name
  end
end

-- returns the first named property in the chain up to toplevel openapi
-- object.
-- @param name the property name to look for
-- @param types (optional) a set with the types we're looking for, types not listed
-- will be skipped. Default: allow all types
function methods:get_inherited_property(name, types)
  local obj = self
  local count = MAX_RECUR  -- poor man's recursion detection
  if types == nil then
    -- this will make every lookup succesful
    types = setmetatable({}, {__index = function() return true end})
  end

  local is_x_kong = name:find("^x%-kong%-")

  while true do
    if types[obj.type] then
      local value
      if is_x_kong then
        value = obj.spec[name]
      else
        value = obj[name]
      end
      if value ~= nil then
        return value
      end
    end

    if obj.type == "openapi" then
      return nil, "not found" -- we're at top level, but there is no named property
    end

    if type(obj.parent) ~= "table" then
      return nil, "parent lookup links broken, expected table, got " .. type(obj.parent)
    end

    obj = obj.parent
    count = count - 1
    if count == 0 then
      return nil, "recursion detected while traversing to top openapi element"
    end
  end
  -- unreachable
end


do
  local servers_types = {  -- types having a `servers` array
    openapi = true,
    path = true,
    operation = true,
  }

  function methods:get_servers()
    return self:get_inherited_property("servers", servers_types)
  end
end


do
  local security_types = {  -- types having a `security` array
    openapi = true,
    operation = true,
  }

  -- returns the security property as applicable to the 'self' object
  -- or nil+"not found" if there is none
  function methods:get_security()
    return self:get_inherited_property("security", security_types)
  end
end


do
  local function walk_tree(path, tree)
    assert(type(path) == "string", "path must be a string")
    assert(type(tree) == "table", "tree must be a table")

    local segments = split(path, "%/")
    if path == "/" then
      -- top level reference, to full document
      return tree

    elseif segments[1] == "" then
      -- starts with a '/', so remove first empty segment
      table.remove(segments, 1)

    else
      -- first segment is not empty, so we had a relative path
      return nil, "only absolute references are supported, not " .. path
    end

    local position = tree
    for i = 1, #segments do
      position = position[segments[i]]
      if position == nil then
        return nil, "not found"
      end
      if i < #segments and type(position) ~= "table" then
        return nil, "next level cannot be dereferenced, expected table, got " .. type(position)
      end
    end
    return position
  end -- walk_tree


  local reference_types = {
    schema = true,
    parameter = true,
    requestBody = true,
    header = true,
    securityScheme = true,
    path = true,
  }


  -- dereferences 'self' in place, original 'spec' is moved
  -- to 'spec_ref' and replaced by the referenced spec
  function methods:dereference()
    if not reference_types[self.type] then
      return nil, "cannot dereference this type: " .. self.type
    end

    if type(self.spec) ~= "table" or not self.spec["$ref"] then
      return true -- nothing to dereference
    end

    local openapi_spec
    do
      local openapi, err = self:get_openapi()
      if not openapi then
        return nil, err
      end
      openapi_spec = openapi.spec
    end

    -- store the original spec in a new property
    self.spec_ref = self.spec

    local loop_tracker = {}
    while true do
      if type(self.spec) ~= "table" or not self.spec["$ref"] then
        return true -- nothing to dereference anymore, we're done
      end

      local reference = self.spec["$ref"]
      local file, path = reference:match("^(.-)#(.-)$")
      if not file then
        return nil, "bad reference: " .. reference
      elseif file ~= "" then
        return nil, "only local references are supported, not " .. reference
      end

      local spec, err = walk_tree(path, openapi_spec)
      if not spec then
        return nil, err
      end

      if loop_tracker[spec] then
        return nil, "recursive reference loop detected: " .. self.spec_ref["$ref"]
      end
      loop_tracker[spec] = true

      self.spec = spec
    end
    -- unreachable

  end  -- methods:dereference
end



-- create a metatable for a type, including common methods and a type name
function M.create_mt(type_name)
  assert(type(type_name) == "string", "expected string, got " .. type(type_name))
  local mt = {
    type = type_name,
  }
  mt.__index = mt

  for name, method in pairs(methods) do
    mt[name] = method
  end

  return mt
end


return M
