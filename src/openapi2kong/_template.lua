local TYPE_NAME = ({...})[1]:match("openapi2kong%.([^%.]+)$")  -- grab type-name from filename

local mt = require("openapi2kong.common").create_mt(TYPE_NAME)


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
print("TODO: implement ", TYPE_NAME)

  local self = setmetatable({
    spec = assert(spec, "spec argument is required"),
    parent = assert(parent, "parent argument is required"),
    options = options,
  }, mt)

  do
    local ok, err = self:dereference()
    if not ok then
      return ok, err
    end
    -- prevent accidental access to non-dereferenced spec table
    spec = nil -- luacheck: ignore
  end

  local ok, err = self:validate()
  if not ok then
    return ok, err
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

  ok, err = self:post_validate()
  if not ok then
    return ok, err
  end

  return self
end

return parse
