_G._TEST = true
local securityScheme = require "openapi2kong.securityScheme"

assert:set_parameter("TableFormatLevel", 5)

describe("[securityScheme]", function()

  it("requires a table parameter as spec", function()
    local ok, err = securityScheme("petstoreAuth", {}, "lalala", nil, {})
    assert.equal("a securityScheme object expects a table as spec, but got string (origin: PARENT:securityScheme[petstoreAuth])", err)
    assert.falsy(ok)
  end)

  it("requires a string parameter as scheme_name", function()
    local ok, err = securityScheme(123, {}, {}, nil, {})
    assert.equal("a securityScheme object expects a string as scheme_name, but got number (origin: PARENT:securityScheme[123])", err)
    assert.falsy(ok)
  end)

  it("requires a table parameter as scopes", function()
    local ok, err = securityScheme("petstoreAuth", "lalala", {}, nil, {})
    assert.equal("a securityScheme object expects a table as scopes, but got string (origin: PARENT:securityScheme[petstoreAuth])", err)
    assert.falsy(ok)
  end)



  describe("type apiKey:", function()

    it("name must be string", function()
      local ok, err = securityScheme("petstoreAuth", {}, {
          type = "apiKey",
          name = 123,
          ["in"] = "header",
        }, nil, {})
      assert.equal("a securityScheme object of type apiKey expects a string as name property, but got number (origin: PARENT:securityScheme[petstoreAuth])", err)
      assert.falsy(ok)
    end)

    it("in must be valid", function()
      local ok, err = securityScheme("petstoreAuth", {}, {
          type = "apiKey",
          name = "x-my-auth",
          ["in"] = "invalid",
        }, nil, {})
      assert.equal("a securityScheme object of type apiKey expects a proper in property, but got invalid (origin: PARENT:securityScheme[petstoreAuth])", err)
      assert.falsy(ok)
    end)

    it("accepted if valid", function()
      local result, err = securityScheme("petstoreAuth", {}, {
          type = "apiKey",
          name = "x-my-auth",
          ["in"] = "cookie",
        }, nil, {})
      assert.is_nil(err)
      assert.equal("securityScheme", result.type)
    end)

  end)



  describe("type http:", function()

    it("scheme must be string", function()
      local ok, err = securityScheme("petstoreAuth", {}, {
          type = "http",
          scheme = 123,
        }, nil, {})
      assert.equal("a securityScheme object of type http expects a string as scheme property, but got number (origin: PARENT:securityScheme[petstoreAuth])", err)
      assert.falsy(ok)
    end)

    it("accepted if valid", function()
      local result, err = securityScheme("petstoreAuth", {}, {
          type = "http",
          scheme = "basic",
        }, nil, {})
      assert.is_nil(err)
      assert.equal("securityScheme", result.type)
    end)

  end)



  describe("type oauth2:", function()

    it("flows must be table", function()
      local ok, err = securityScheme("petstoreAuth", {}, {
          type = "oauth2",
          flows = 123,
        }, nil, {})
      assert.equal("a securityScheme object of type oauth2 expects a table as flows property, but got number (origin: PARENT:securityScheme[petstoreAuth])", err)
      assert.falsy(ok)
    end)

    it("flows must not be empty", function()
      local ok, err = securityScheme("petstoreAuth", {}, {
          type = "oauth2",
          flows = {},
        }, nil, {})
      assert.equal("a securityScheme object of type oauth2 expects at least 1 entry in the flows property (origin: PARENT:securityScheme[petstoreAuth])", err)
      assert.falsy(ok)
    end)

    it("accepted if valid", function()
      local result, err = securityScheme("petstoreAuth", {}, {
          type = "oauth2",
          flows = {
            implicit = {
              scopes = {},
              authorizationUrl = "",
            },
          },
        }, nil, {})
      assert.is_nil(err)
      assert.equal("securityScheme", result.type)
      assert.equal("oauthFlow", result.flows[1].type)
      assert.equal("implicit", result.flows[1].flow_type)
    end)

  end)



  describe("type openIdConnect:", function()

    it("openIdConnectUrl must be string", function()
      local ok, err = securityScheme("petstoreAuth", {}, {
          type = "openIdConnect",
          openIdConnectUrl = 123,
        }, nil, {})
      assert.equal("a securityScheme object of type openIdConnect expects a string as openIdConnectUrl property, but got number (origin: PARENT:securityScheme[petstoreAuth])", err)
      assert.falsy(ok)
    end)

    it("accepted if valid", function()
      local result, err = securityScheme("petstoreAuth", {}, {
          type = "openIdConnect",
          openIdConnectUrl = "https://discover.company.com/openid",
        }, nil, {})
      assert.is_nil(err)
      assert.equal("securityScheme", result.type)
    end)

  end)



end)


