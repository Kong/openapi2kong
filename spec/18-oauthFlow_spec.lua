local oauthFlow = require "openapi2kong.oauthFlow"

assert:set_parameter("TableFormatLevel", 5)

describe("[oauthFlow]", function()

  it("requires a table parameter as spec", function()
    local ok, err = oauthFlow("implicit", "lalala", nil, {})
    assert.equal("a oauthFlow object expects a table as spec, but got string", err)
    assert.falsy(ok)
  end)

  it("requires a string parameter as flow_type", function()
    local ok, err = oauthFlow(123, {}, nil, {})
    assert.equal("a oauthFlow object expects a proper flow_type, but got 123", err)
    assert.falsy(ok)
  end)



  describe("type implicit:", function()

    it("authorizationUrl must be string", function()
      local ok, err = oauthFlow("implicit", {
          authorizationUrl = 123,
          scopes = {},
        }, nil, {})
      assert.equal("a oauthFlow object expects a string as authorizationUrl, but got number", err)
      assert.falsy(ok)
    end)

    it("scopes must be string", function()
      local ok, err = oauthFlow("implicit", {
          authorizationUrl = "https://auth.mycompany.com",
          scopes = 123,
        }, nil, {})
      assert.equal("a oauthFlow object expects a table as scopes, but got number", err)
      assert.falsy(ok)
    end)

  end)

end)


