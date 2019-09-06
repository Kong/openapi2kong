_G._TEST = true
local headers = require "openapi2kong.headers"

describe("[headers]", function()

  it("requires a table parameter", function()
    local ok, err = headers("lalala", nil, {})
    assert.equal("a headers object expects a table, but got string (origin: PARENT:headers)", err)
    assert.falsy(ok)
  end)

  it("accepts an empty table", function()
    local result, err = headers({}, nil, {})
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("headers", result.type)
    assert.equal(0, #result)
  end)

  it("accepts proper encodings", function()
    local result, err = headers({
        ["X-Rate-Limit-Limit"] = {
          schema = {},
        },
        ["X-client-type"] = {
          schema = {},
        },
      }, nil, {})
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("headers", result.type)
    assert.equal(2, #result.headers)
  end)

  it("ignores specific headers", function()
    local result, err = headers({
        ["aCcEpT"] = {    -- "Accept" header should be ignored, per OAS spec (parameter object)
          ["schema"] = {},
        },
        ["just-a-header"] = {
          ["schema"] = {},
        },
      }, nil, {})
    assert.is_nil(err)
    assert.equal("headers", result.type)
    assert.equal(1, #result.headers)
    assert.equal("header", result.headers[1].type)
    assert.equal("just-a-header", result.headers[1].name)
  end)

end)
