-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local TYPE_NAME = ({...})[1]:match("openapi2kong%.([^%.]+)$")  -- grab type-name from filename

local mt = require("openapi2kong.common").create_mt(TYPE_NAME)


function mt:get_trace()
  return ""
end


function mt:validate()

  if type(self.spec) ~= "table" then
    return nil, ("a %s object expects a table as spec, but got %s"):format(TYPE_NAME, type(self.spec))
  end

  if not next(self.spec) then
    return nil, ("a %s requires at least 1 securityScheme"):format(TYPE_NAME)
  end

  return true
end


function mt:post_validate()

  -- do validation after creation

  return true
end

-- the security requirements will be listed in the array part of the object
-- the 'scheme_name' will be set on the generated securityScheme objects
local function parse(spec, options, parent)

  local self = setmetatable({
    spec = assert(spec, "spec argument is required"),
    parent = assert(parent, "parent argument is required"),
    options = options,
  }, mt)

  local ok, err = self:validate()
  if not ok then
    return ok, self:log_message(err)
  end

  local new_securityScheme = require("openapi2kong.securityScheme")

  for scheme_name, scopes_spec in pairs(self.spec) do
    local scheme_spec = ((self:get_openapi().spec.components or {}).securitySchemes or {})[scheme_name]
    if not scheme_spec then
      return nil, self:log_message("securityScheme not found: #/components/securitySchemes/" .. scheme_name)
    end

    local scheme_obj, err = new_securityScheme(scheme_name, scopes_spec, scheme_spec, options, self)
    if not scheme_obj then
      return nil, err
    end

    self[#self+1] = scheme_obj
  end

  ok, err = self:post_validate()
  if not ok then
    return ok, self:log_message(err)
  end

  return self
end

return parse
