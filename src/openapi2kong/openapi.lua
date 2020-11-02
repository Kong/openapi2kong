-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local TYPE_NAME = ({...})[1]:match("openapi2kong%.([^%.]+)$")  -- grab type-name from filename

local mt = require("openapi2kong.common").create_mt(TYPE_NAME)


function mt:get_trace()
  return (self.spec.info or {}).title or ""
end


function mt:validate()

  if type(self.spec) ~= "table" then
    return nil, ("a %s object expects a table, but got %s"):format(TYPE_NAME, type(self.spec))
  end

  if not self.spec.openapi then
    return nil, "missing openapi version"
  end

  local major_version = string.match(self.spec.openapi, "^(%d+)%.%d")
  if major_version ~= "3" then
    return nil, "unsupported major version: " .. major_version .. ". OAS major version v3 supported"
  end

  if not self.spec.paths then
    return nil, "missing paths property"
  end

  if not next(self.spec.paths) then
    return nil, "paths needs at least 1 path entry"
  end

  if type(self.spec.security) ~= "table" and
     type(self.spec.security) ~= "nil" then
    return nil, ("a %s object expects a table as security property, but got %s"):format(TYPE_NAME, type(self.spec.security))
  end

  return true
end


function mt:post_validate()

  -- all known directives, and a list of object types on which they are supported
  local valid_kong_directives = {
    ["x-kong-name"] = { "openapi", "path" },
    ["x-kong-upstream-defaults"] = { "openapi", "path", "operation" },
    ["x-kong-service-defaults"] = { "openapi", "path", "operation" },
    ["x-kong-route-defaults"] = { "openapi", "path", "operation" },
  }
  local valid_kong_directives_patterns = {
    ["^x%-kong%-plugin%-"] = { "openapi", "operation" },
    ["^x%-kong%-security%-"] = { "openapi", "operation" },
  }

  local recursion_tracker = {}

  local function check(obj)
    -- check for recursion
    if recursion_tracker[obj] then return true end
    recursion_tracker[obj] = true

    -- check myself first
    if type(obj.spec) == "table" then

      for key, value in pairs(obj.spec) do

        if type(key) == "string" and key:sub(1,6) == "x-kong" then
          -- found a Kong directive
          local valid_types = valid_kong_directives[key]
          if not valid_types then
            for patt, types in pairs(valid_kong_directives_patterns) do
              if key:find(patt) then
                valid_types = types
                break
              end
            end
            if not valid_types then
              return nil, "Not a valid Kong extension: " .. tostring(key)
            end
          end

          local valid = false
          for _, allowed_type in ipairs(valid_types) do
            if obj.type == allowed_type then
              valid = true
              break
            end
          end
          if not valid then
            return nil, ("Kong extension '%s' cannot be used on type '%s'"):format(tostring(key), obj.type)
          end
        end
      end
    end

    -- check siblings
    for key, value in pairs(obj) do
      if type(value) == "table" and (getmetatable(value) or {}).type then
        -- we have a sub-object
        local ok, err = check(value)
        if not ok then
          return nil, err
        end
      end
    end

    -- we're good
    return true
  end

  return check(self)
end


local function parse(spec, options, parent)

  local self = setmetatable({
    spec = assert(spec, "spec argument is required"),
    parent = parent, -- Note: openapi is the only object with an OPTIONAL parent
    options = options,
  }, mt)

  local ok, err = self:validate()
  if not ok then
    return ok, self:log_message(err)
  end

  for _, property in ipairs { "servers", "paths" } do
    local create_type = require("openapi2kong." .. property)
    local sub_spec = self.spec[property]
    if sub_spec then
      local new_obj, err = create_type(sub_spec, options, self)
      if not new_obj then
        return nil, err
      end

      self[property] = new_obj
    end
  end

  if self.spec.security then
    local new_securityRequirements = require("openapi2kong.securityRequirements")
    self.security, err = new_securityRequirements(self.spec.security, options, self)
    if not self.security then
      return nil, err
    end
  end


  ok, err = self:post_validate()
  if not ok then
    return ok, self:log_message(err)
  end

  return self
end

return parse