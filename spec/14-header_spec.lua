local header = require "openapi2kong.header"

assert:set_parameter("TableFormatLevel", 5)

describe("[header]", function()

  it("requires a table parameter as spec", function()
    local ok, err = header("X-client-type", "lalala", nil, {})
    assert.equal("a header object expects a table as spec, but got string", err)
    assert.falsy(ok)
  end)

  it("requires a string parameter as header_name", function()
    local ok, err = header(123, {}, nil, {})
    assert.equal("a header object expects a string as name, but got number", err)
    assert.falsy(ok)
  end)

  it("lowercases header_name", function()
    local result, err = header("X-client-type", {
        schema = {},
      }, nil, {})
    assert.is_nil(err)
    assert.equal("header", result.type)
    assert.equal("x-client-type", result.name)
  end)


  describe("special case parameter object:", function()

    it("original spec table is set", function()
      local spec = {
          schema = {},
        }
      local result, err = header("X-client-type", spec, nil, {})
      assert.is_nil(err)
      assert.equal("header", result.type)
      assert.equal(spec, result.spec)
    end)

    it("properties name+in are properly set", function()
      local spec = {
          schema = {},
        }
      local result, err = header("X-client-type", spec, nil, {})
      assert.is_nil(err)
      assert.equal("header", result.type)
      assert.is_nil(spec.name)
      assert.is_nil(spec["in"])
      assert.equal("x-client-type", result.name)
      assert.equal("header", result["in"])
    end)

    it("dereference a header that has no 'name' and 'in' set", function()
      local openapi = {
        type = "openapi",
        spec = {
          components = {
            headers = {
              myHeader = {
                schema = { "hello world" },
              },
            },
          },
        },
      }

      local header_spec = {
        ["$ref"] = "#/components/headers/myHeader",
      }

      local headers_spec = {
        ["X-My-Header"] = header_spec,
      }

      local new_headers = require "openapi2kong.headers"
      local headers = assert(new_headers(headers_spec, nil, openapi))
      assert.equal("headers", headers.type)

      local header = assert(headers.headers[1])
      assert.equal("header", header.type)

      assert.equal(openapi.spec.components.headers.myHeader, header.spec)
      assert.equal(header_spec, header.spec_ref)
      assert.equal("header", header["in"])
      assert.equal("x-my-header", header.name)
    end)

    it("proper parent is set", function()
      local parent = {}
      local result, err = header("X-client-type", {
          schema = {},
        }, nil, parent)
      assert.is_nil(err)
      assert.equal(parent, result.parent)
    end)

  end)


end)


