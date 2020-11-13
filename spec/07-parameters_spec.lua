-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

_G._TEST = true
local parameters = require "openapi2kong.parameters"

assert:set_parameter("TableFormatLevel", 5)

describe("[parameters]", function()

  it("requires a table parameter as spec", function()
    local ok, err = parameters("lalala", nil, {})
    assert.equal("a parameters object expects a table as spec, but got string (origin: PARENT:parameters)", err)
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
    assert.equal("a parameter object expects a table as spec, but got number (origin: PARENT:parameters:parameter[<bad spec: number>])", err)
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


  it("iterates parameter", function()
    local path = { type = "path" }
    local path_params = assert(parameters({
        {
          ["in"] = "path",
          ["name"] = "user",
          ["schema"] = { schema = 1 },
          ["required"] = true,
        }, {
          ["in"] = "header",
          ["name"] = "just-a-header",
          ["schema"] = { schema = 2 },
        },
      }, nil, path))
    path.parameters = path_params

    local operation_params = assert(parameters({
        {
          ["in"] = "path",     -- "Accept" header should be ignored, per OAS spec
          ["name"] = "user",   --> should be case insensitive
          ["schema"] = { schema = 3 },
          ["required"] = true,
        }, {
          ["in"] = "cookie",
          ["name"] = "user",
          ["schema"] = { schema = 5 },
        },
      }, nil, { type = "operation", parent = path }))
      operation_params.parent.parameters = operation_params


      -- validate the returned params on the "path" object
      local list = {}
      for param in path_params:iterate() do
        list[#list+1] = param.spec.schema.schema
      end
      assert.same({ 1, 2 }, list)

      -- validate the returned params on the "operation" object
      list = {}
      for param in operation_params:iterate() do
        list[#list+1] = param.spec.schema.schema
      end
      assert.same({
          3,   -- operation level parameter overrules path level
          5,   -- new on operation level
          2,   -- inherited from path level
        }, list)

  end)

end)


