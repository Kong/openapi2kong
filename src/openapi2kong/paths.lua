local new_path = require("openapi2kong.path")

local TYPE_NAME = ({...})[1]:match("openapi2kong%.([^%.]+)$")  -- grab type-name from filename


local mt = require("openapi2kong.common").create_mt(TYPE_NAME)


function mt:validate()

  if type(self.spec) ~= "table" then
    return nil, ("a %s object expects a table, but got %s"):format(TYPE_NAME, type(self.spec))
  end

  return true
end


function mt:post_validate()

  -- do validation after creation

  return true
end


-- returns an array with path entries
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

  --self.paths = {}
  for path, path_spec in pairs(spec) do
    local path_obj, err = new_path(path, path_spec, options, self)
    if not path_obj then
      return nil, err
    end
    self[#self+1] = path_obj
    --self.paths[#self.paths+1] = path_obj
  end

  ok, err = self:post_validate()
  if not ok then
    return ok, err
  end

  return self
end

return parse
