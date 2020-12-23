-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local kong = require "openapi2kong"
local utils = require "pl.utils"
local cjson = require "cjson.safe"
local lyaml = require "lyaml"



-- Set this to 'true' to write the expected files, instead of validating them.
-- Set to true, run the tests, and check the `git diff` for the expected changes
local WRITE_FILES = false



describe("[Kong conversion]", function()

  local files = {
    "spec/testfiles/api-with-examples.yaml",
    "spec/testfiles/callback-example.yaml",
    "spec/testfiles/link-example.yaml",
    "spec/testfiles/petstore-expanded.yaml",
    "spec/testfiles/uspto.yaml",
    "spec/testfiles/httpbin.yaml",
    "spec/testfiles/petstore.yaml",
    "spec/testfiles/security.yaml",
    "spec/testfiles/no-servers-block.yaml",
  }

  if WRITE_FILES then
    pending("WARNING: these tests have been disabled!!!", function() end)
    -- set WRITE_FILES above to false to enable the tests
  end

  it("parses all-files-in-one", function()
    local kong_spec = assert(kong.convert_files(files))
    if not WRITE_FILES then
      local expected = assert(utils.readfile("spec/testfiles/all-files-in-one.expected.yaml"))
      expected = assert(lyaml.load(expected))
      assert.same(expected, kong_spec)
    else
      assert(utils.writefile("spec/testfiles/all-files-in-one.expected.yaml", assert(lyaml.dump({ kong_spec }))))
    end
  end)


  for _, filename in ipairs(files) do
    it("parses " .. filename, function()
      local kong_spec = assert(kong.convert_files(filename))
      if not WRITE_FILES then
        local expected = assert(utils.readfile(filename:match("^(.+)%.yaml$") .. ".expected.yaml"))
        expected = assert(lyaml.load(expected))
        assert.same(expected, kong_spec)
      else
        assert(utils.writefile(filename:match("^(.+)%.yaml$") .. ".expected.yaml", assert(lyaml.dump({ kong_spec }))))
      end
    end)
  end

end)
