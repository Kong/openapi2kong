local kong = require "openapi2kong"
local utils = require "pl.utils"
local cjson = require "cjson.safe"

describe("[Kong conversion]", function()

  local files = {
    "spec/testfiles/api-with-examples.yaml",
    "spec/testfiles/callback-example.yaml",
    "spec/testfiles/link-example.yaml",
    "spec/testfiles/petstore-expanded.yaml",
    "spec/testfiles/uspto.yaml",
    "spec/testfiles/httpbin.yaml",
    "spec/testfiles/petstore.yaml",
  }

  for _, filename in ipairs(files) do
    it("parses " .. filename, function()
      local kong_spec = assert(kong.convert_files(filename))
--      local expected = assert(utils.readfile(filename .. ".expected"))
--      expected = assert(cjson.decode(expected))
--      assert.same(expected, kong_spec)
      assert(utils.writefile(filename .. ".expected", cjson.encode(kong_spec)))
    end)
  end

  it("parses all-files-in-one", function()
    local kong_spec = assert(kong.convert_files(files))
--    local expected = assert(utils.readfile("spec/testfiles/all-files-in-one.expected"))
--    expected = assert(cjson.decode(expected))
--    assert.same(expected, kong_spec)
    assert(utils.writefile("spec/testfiles/all-files-in-one.expected", cjson.encode(kong_spec)))
  end)

end)
