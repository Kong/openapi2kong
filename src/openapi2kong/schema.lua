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

  return true
end


function mt:post_validate()

  -- do validation after creation

  return true
end


local function parse(spec, options, parent)

  local self = setmetatable({
    spec = assert(spec, "spec argument is required"),
    parent = assert(parent, "parent argument is required"),
    options = options,
  }, mt)

  do
    local ok, err = self:dereference()
    if not ok then
      return ok, self:log_message(err)
    end
    -- prevent accidental access to non-dereferenced spec table
    spec = nil -- luacheck: ignore
  end

  local ok, err = self:validate()
  if not ok then
    return ok, self:log_message(err)
  end

  ok, err = self:post_validate()
  if not ok then
    return ok, self:log_message(err)
  end

  return self
end

return parse
