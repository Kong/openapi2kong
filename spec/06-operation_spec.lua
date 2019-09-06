_G._TEST = true
local common = require "openapi2kong.common"
local operation = require "openapi2kong.operation"

assert:set_parameter("TableFormatLevel", 5)

describe("[operation]", function()

  it("requires a table parameter as spec", function()
    local ok, err = operation("get", "lalala", nil, {})
    assert.equal("a operation object expects a table as spec, but got string (origin: PARENT:operation[get])", err)
    assert.falsy(ok)
  end)



  describe("'method' property", function()

    it("requires a string parameter", function()
      local ok, err = operation(12, {}, nil, {})
      assert.equal("a operation object expects a string as method, but got number (origin: PARENT:operation[12])", err)
      assert.falsy(ok)
    end)


    it("accepts a method", function()
      local result, err = operation("get", {}, nil, {})
      assert.is_nil(err)
      assert.equal("get", result.method)
    end)

  end)


  describe("'parameters' property", function()

    it("fails on bad parameters", function()
      local ok, err = operation("get", { parameters = "" }, nil, {})
      assert.equal("a parameters object expects a table as spec, but got string (origin: PARENT:operation[get]:parameters)", err)
      assert.falsy(ok)
    end)


    it("accepts a proper parameters object", function()
      local result, err = operation("get", { parameters = {} }, nil, {})
      assert.is_nil(err)
      assert.equal("parameters", result.parameters.type)
    end)

  end)


  describe("'requestBody' property", function()

    it("fails on bad parameters", function()
      local ok, err = operation("get", { requestBody = "" }, nil, {})
      assert.equal("a requestBody object expects a table as spec, but got string (origin: PARENT:operation[get]:requestBody)", err)
      assert.falsy(ok)
    end)


    it("accepts a proper requestBody object", function()
      local result, err = operation("get", { requestBody = {} }, nil, {})
      assert.is_nil(err)
      assert.equal("requestBody", result.requestBody.type)
    end)

  end)


  describe("'security' property", function()

    it("fails on bad parameters", function()
      local ok, err = operation("get", { security = "" }, nil, {})
      assert.equal("a operation object expects a table as security property, but got string (origin: PARENT:operation[get])", err)
      assert.falsy(ok)
    end)


    it("accepts a proper security object", function()
      local openapi = setmetatable({
        spec = {
          components = {
            securitySchemes = {
              petstoreAuth = {
                type = "http",
                scheme = "basic",
              },
              anotherAuth = {
                type = "http",
                scheme = "basic",
              },
            },
          },
        }
      }, common.create_mt("openapi"))
      local result, err = operation("get", {
          security = {   -- list of securityRequirements
            {  -- 1st securityRequirement, with 2 schemes
              petstoreAuth = {},
              anotherAuth = {},
            },
            { -- 2nd securityRequirement, with 1 scheme
              anotherAuth = {},
            },
          }
        }, nil, openapi)
      assert.is_nil(err)
      assert.equal(2, #result.security)
      assert.equal("securityRequirement", result.security[1].type)
      assert.equal("securityRequirement", result.security[2].type)
    end)

  end)


  describe("'servers' property", function()

    it("fails on bad parameters", function()
      local ok, err = operation("get", { servers = "" }, nil, {})
      assert.equal("a servers object expects a table, but got string (origin: PARENT:operation[get]:servers)", err)
      assert.falsy(ok)
    end)


    it("accepts a proper servers object", function()
      local result, err = operation("get", { servers = {} }, nil, {})
      assert.is_nil(err)
      assert.equal("servers", result.servers.type)
    end)

  end)

end)