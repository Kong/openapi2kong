local schema = require "openapi2kong.schema"

assert:set_parameter("TableFormatLevel", 5)

describe("[schema]", function()

  it("requires a table parameter as spec", function()
    local ok, err = schema("lalala", nil, {})
    assert.equal("a schema object expects a table as spec, but got string", err)
    assert.falsy(ok)
  end)

  pending("dereference the schema", function()
    -- TODO: dereference the JSON schema, since it references higher level
    -- elements in #/components that will not be available when running snippets.
    -- Can also be done in the render phase?
  end)

end)


