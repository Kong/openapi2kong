local path = require "openapi2kong.path"

assert:set_parameter("TableFormatLevel", 5)

describe("[path]", function()

  it("requires a table parameter as spec", function()
    local ok, err = path("/", "lalala", nil, {})
    assert.equal("a path object expects a table as spec, but got string", err)
    assert.falsy(ok)
  end)



  describe("'path' property", function()

    it("requires a string parameter", function()
      local ok, err = path(12, {}, nil, {})
      assert.equal("a path object expects a string as path, but got number", err)
      assert.falsy(ok)
    end)


    it("accepts a path", function()
      local result, err = path("/", {}, nil, {})
      assert.is_nil(err)
      assert.equal("/", result.path)
    end)

  end)



  describe("'operations' property", function()

    it("skips unknown methods", function()
      local result, err = path("/",  { donotget_method = {} }, nil, {})
      assert.is_nil(err)
      assert.same({}, result.operations)
    end)


    it("adds known methods", function()
      local result, err = path("/",  { get = {} }, nil, {})
      assert.is_nil(err)
      assert.equal("path", result.type)
      local op_array = assert(result.operations)
      local operation = assert(op_array[1])
      assert.equal("operation", operation.type)
      assert.equal("get", operation.method)
    end)

  end)



  describe("'servers' property", function()

    it("does not create a 'servers' property if it's nil", function()
      local result, err = path("/", { servers = nil }, nil, {})
      assert.is_nil(err)
      assert.is_nil(result.servers)
    end)


    it("does create a 'servers' property if it has valid entries", function()
      local result, err = path("/", { servers = {{url="https://server.com/path"}} }, nil, {})
      assert.is_nil(err)
      assert.equal("servers", result.servers.type)
      assert.equal(1, #result.servers)
    end)

  end)

end)
