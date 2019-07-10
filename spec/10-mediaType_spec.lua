local mediaType = require "openapi2kong.mediaType"

assert:set_parameter("TableFormatLevel", 5)

describe("[mediaType]", function()

  it("requires a table parameter as spec", function()
    local ok, err = mediaType("application/json", "lalala", nil, {})
    assert.equal("a mediaType object expects a table as spec, but got string", err)
    assert.falsy(ok)
  end)

  it("requires a string parameter as mediatype", function()
    local ok, err = mediaType(123, {}, nil, {})
    assert.equal("a mediaType object expects a string as mediatype, but got number", err)
    assert.falsy(ok)
  end)

  it("succeeds with a proper schema and encoding table", function()
    local result, err = mediaType("application/json", {
        schema = {
          type = "object",
          properties = {
            myProperty = {
              type = "string",
              format = "uuid",
            },
          },
        },
        encoding = {
          myProperty = {
            contentType = "application/xml; charset=utf-8",
          },
        },
      }, nil, {})
    assert.is_nil(err)
    assert.equal("schema", result.schema.type)
    assert.equal("encodings", result.encoding.type)
  end)

  it("fails with a bad schema", function()
    local result, err = mediaType("application/json", {
        schema = "lalala",
        encoding = {
          myProperty = {
            contentType = "application/xml; charset=utf-8",
          },
        },
      }, nil, {})
    assert.equal("a schema object expects a table as spec, but got string", err)
    assert.is_nil(result)
  end)

  it("fails with a bad encodings table", function()
    local result, err = mediaType("application/json", {
        schema = {
          type = "object",
          properties = {
            myProperty = {
              type = "string",
              format = "uuid",
            },
          },
        },
        encoding = "lalala",
      }, nil, {})
    assert.equal("a encodings object expects a table, but got string", err)
    assert.is_nil(result)
  end)

end)


