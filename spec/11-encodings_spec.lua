-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

_G._TEST = true
local encodings = require "openapi2kong.encodings"

describe("[encodings]", function()

  it("requires a table parameter", function()
    local ok, err = encodings("lalala", nil, {})
    assert.equal("a encodings object expects a table, but got string (origin: PARENT:encodings)", err)
    assert.falsy(ok)
  end)

  it("accepts an empty table", function()
    local result, err = encodings({}, nil, {})
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("encodings", result.type)
    assert.equal(0, #result)
  end)

  it("accepts proper encodings", function()
    local result, err = encodings({ myProperty = {}, yourProperty = {} }, nil, {})
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("encodings", result.type)
    assert.equal(2, #result.encodings)
  end)

end)
