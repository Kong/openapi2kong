local parameters = require "openapi2kong.parameters"

assert:set_parameter("TableFormatLevel", 5)

describe("[parameters]", function()

  it("requires a table parameter as spec", function()
    local ok, err = parameters("lalala", nil, {})
    assert.equal("a parameters object expects a table as spec, but got string", err)
    assert.falsy(ok)
  end)


  it("accepts a proper parameter", function()
    local result, err = parameters({
        {
          ["in"] = "query",
          ["name"] = "param",
          ["schema"] = {},
        }, {
          ["in"] = "header",
          ["name"] = "just-a-header",
          ["schema"] = {},
        },
      }, nil, {})
    assert.is_nil(err)
    assert.equal("parameters", result.type)
    assert.equal("parameter", result[1].type)
    assert.equal(2, #result)
  end)


  it("rejects a bad parameter", function()
    local ok, err = parameters({ [1] = 123 }, nil, {})
    assert.equal("a parameter object expects a table as spec, but got number", err)
    assert.falsy(ok)
  end)


  it("ignores a parameter", function()
    local result, err = parameters({
        {
          ["in"] = "header",     -- "Accept" header should be ignored, per OAS spec
          ["name"] = "aCcEpT",   --> should be case insensitive
          ["schema"] = {},
        }, {
          ["in"] = "header",
          ["name"] = "just-a-header",
          ["schema"] = {},
        },
      }, nil, {})
    assert.is_nil(err)
    assert.equal("parameters", result.type)
    assert.equal(1, #result)
    assert.equal("parameter", result[1].type)
    assert.equal("just-a-header", result[1].spec.name)
  end)

end)


