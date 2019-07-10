local encodings = require "openapi2kong.encodings"

describe("[encodings]", function()

  it("requires a table parameter", function()
    local ok, err = encodings("lalala", nil, {})
    assert.equal("a encodings object expects a table, but got string", err)
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
