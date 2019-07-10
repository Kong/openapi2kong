local paths = require "openapi2kong.paths"

describe("[paths]", function()

  it("requires a table parameter", function()
    local ok, err = paths("lalala", nil, {})
    assert.equal("a paths object expects a table, but got string", err)
    assert.falsy(ok)
  end)

  it("accepts an empty table", function()
    local result, err = paths({}, nil, {})
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("paths", result.type)
    assert.equal(0, #result)
  end)

  it("accepts proper paths", function()
    local result, err = paths({ ["/1"] = {}, ["/2"] = {} }, nil, {})
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("paths", result.type)
    assert.equal(2, #result)
  end)

end)
