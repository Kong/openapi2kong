local openapi = require "openapi2kong.openapi"

assert:set_parameter("TableFormatLevel", 5)

describe("[openapi]", function()

  it("requires a table parameter", function()
    local ok, err = openapi("lalala")
    assert.equal("a openapi object expects a table, but got string", err)
    assert.falsy(ok)
  end)

  it("requires an openapi version", function()
    local ok, err = openapi({})
    assert.equal("missing openapi version", err)
    assert.falsy(ok)
  end)

  it("requires a supported openapi version", function()
    local ok, err = openapi({
      openapi = "2.0"
    })
    assert.equal("unsupported major version: 2. OAS major version v3 supported", err)
    assert.falsy(ok)

    local result, err = openapi({
      openapi = "3.0",
      servers = { { url = "http://server.com/path" } },
      paths = { ["/"] = {} },
    })
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("openapi", result.type)
  end)

  it("accepts a missing servers property", function()
    local result, err = openapi({
      openapi = "3.0",
      --servers = { "http://server.com/path" },
      paths = { ["/"] = {} },
    })
    assert.is_nil(err)
    assert.equal("openapi", result.type)
  end)

  it("accepts an empty servers property", function()
    local result, err = openapi({
      openapi = "3.0",
      servers = {}, --{ "http://server.com/path" },
      paths = { ["/"] = {} },
    })
    assert.is_nil(err)
    assert.equal("openapi", result.type)
  end)

  it("requires a table security property", function()
    local ok, err = openapi({
      openapi = "3.0",
      servers = { "http://server.com/path" },
      paths = { ["/"] = {} },
      security = "lalala",
    })
    assert.equal("a openapi object expects a table as security property, but got string", err)
    assert.falsy(ok)
  end)

  it("requires a paths property", function()
    local ok, err = openapi({
      openapi = "3.0",
      servers = { "http://server.com/path" },
      --paths = { ["/"] = {} },
    })
    assert.equal("missing paths property", err)
    assert.falsy(ok)
  end)

  it("requires a non-empty paths property", function()
    local ok, err = openapi({
      openapi = "3.0",
      servers = { "http://server.com/path" },
      paths = {},
    })
    assert.equal("paths needs at least 1 path entry", err)
    assert.falsy(ok)
  end)

  it("does not allow unsupported x-kong-xxx directives", function()
    local result, err = openapi({
      openapi = "3.0",
      servers = { { url = "http://server.com/path" } },
      paths = { ["/"] = {} },
      ["x-kong-unsupported-one"] = { "this should fail" }
    })
    assert.equal("Not a valid Kong extension: x-kong-unsupported-one", err)
    assert.is_nil(result)
  end)

  it("allows supported x-kong-xxx directives", function()
    local result, err = openapi({
      openapi = "3.0",
      servers = { { url = "http://server.com/path" } },
      paths = { ["/"] = {} },
      ["x-kong-upstream-defaults"] = { "this works" }
    })
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("openapi", result.type)
  end)

  it("only allows supported x-kong-xxx directives in the proper locations", function()
    local result, err = openapi({
      openapi = "3.0",
      servers = {
        {
          url = "http://server.com/path",
          ["x-kong-upstream-defaults"] = { "this is in the wrong location" },
        },
      },
      paths = { ["/"] = {} },
    })
    assert.equal("Kong extension 'x-kong-upstream-defaults' cannot be used on type 'server'", err)
    assert.is_nil(result)
  end)


end)
