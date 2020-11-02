-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

_G._TEST = true
local encoding = require "openapi2kong.encoding"

assert:set_parameter("TableFormatLevel", 5)

describe("[encoding]", function()

  it("requires a table parameter as spec", function()
    local ok, err = encoding("myProperty", "lalala", nil, {})
    assert.equal("a encoding object expects a table as spec, but got string (origin: PARENT:encoding[myProperty])", err)
    assert.falsy(ok)
  end)

  it("requires a string parameter as property_name", function()
    local ok, err = encoding(123, {}, nil, {})
    assert.equal("a encoding object expects a string as property_name, but got number (origin: PARENT:encoding[123])", err)
    assert.falsy(ok)
  end)

  it("succeeds with a proper headers table", function()
    local result, err = encoding("myProperty", {
        headers = {
          ["X-Rate-Limit-Limit"] = {
            schema = {},
          },
        },
      }, nil, {})
    assert.is_nil(err)
    assert.equal("headers", result.headers.type)
  end)

  it("fails with a bad headers table", function()
    local result, err = encoding("myProperty", {
        headers = "lalala",
      }, nil, {})
    assert.equal("a headers object expects a table, but got string (origin: PARENT:encoding[myProperty]:headers)", err)
    assert.is_nil(result)
  end)

end)


