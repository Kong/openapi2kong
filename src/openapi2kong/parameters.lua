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

-- this object contains an array part that holds the parameter objects
local function parse(spec, options, parent)

  local self = setmetatable({
    spec = assert(spec, "spec argument is required"),
    parent = assert(parent, "parent argument is required"),
    options = options,
  }, mt)

  local ok, err = self:validate()
  if not ok then
    return ok, err
  end

  local new_parameter = require "openapi2kong.parameter"
  for _, param_spec in ipairs(self.spec) do
--print(require("pl.pretty").write(param_spec))
    local param_obj, err = new_parameter(param_spec, options, self)
    if not param_obj then
      if err ~= "ignore" then
        return nil, err
      end
    else
      self[#self+1] = param_obj
    end
  end

  ok, err = self:post_validate()
  if not ok then
    return ok, err
  end

  return self
end

return parse