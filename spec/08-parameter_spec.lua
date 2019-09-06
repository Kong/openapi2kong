_G._TEST = true
local parameter = require "openapi2kong.parameter"

assert:set_parameter("TableFormatLevel", 5)

describe("[parameter]", function()

  it("requires a table parameter as spec", function()
    local ok, err = parameter("lalala", nil, {})
    assert.equal("a parameter object expects a table as spec, but got string (origin: PARENT:parameter[<bad spec: string>])", err)
    assert.falsy(ok)
  end)


  it("accepts proper 'in' values and sets them properly", function()
    for _, where in ipairs {"path", "query", "header", "cookie"} do
      local result, err = parameter({
          ["in"] = where,
          required = true,
          name = "Param_Name",
          schema = {},
        }, nil, {})
      assert.is_nil(err)
      assert.is_table(result)
      assert.equal(where, result["in"])
      if where == "header" then
        assert.equal("param_name", result.name)
      else
        assert.equal("Param_Name", result.name)
      end
      assert.equal("parameter", result.type)
    end
  end)


  it("get_id() creates proper ids", function()
    for _, where in ipairs {"path", "query", "header", "cookie"} do
      local result, err = parameter({
          ["in"] = where,
          required = true,
          name = "Param_Name",
          schema = {},
        }, nil, {})
      assert.is_nil(err)
      assert.is_table(result)
      assert.equal(where, result["in"])
      assert.equal("parameter", result.type)
      assert.equal(({
          path = "path/Param_Name",
          query = "query/Param_Name",
          header = "header/param_name",  -- lower case
          cookie = "cookie/Param_Name",
        })[where], result:get_id())
    end
  end)


  it("rejects bad 'in' values", function()
    local result, err = parameter({
        ["in"] = "this is a bad one",
        required = true,
        name = "param_name",
        schema = {},
      }, nil, {})
    assert.equal("parameter.in cannot have value 'this is a bad one' (origin: PARENT:parameter[param_name])", err)
    assert.is_nil(result)
  end)


  it("required must be true for path variables", function()
    local result, err = parameter({
        ["in"] = "path",
        required = false,
        name = "param_name",
        schema = {},
      }, nil, {})
    assert.equal("parameter.required must be true, if parameter.in == 'path' (origin: PARENT:parameter[param_name])", err)
    assert.is_nil(result)
  end)

  describe("schema and content:", function()

    it("both fails", function()
      local result, err = parameter({
          ["in"] = "path",
          required = true,
          name = "param_name",
          schema = {},
          content = {},
        }, nil, {})
      assert.equal("parameter cannot have both schema and content properties (origin: PARENT:parameter[param_name])", err)
      assert.is_nil(result)
    end)

    it("none fails", function()
      local result, err = parameter({
          ["in"] = "path",
          required = true,
          name = "param_name",
          --schema = {},
          --content = {},
        }, nil, {})
      assert.equal("parameter must have either schema or content property (origin: PARENT:parameter[param_name])", err)
      assert.is_nil(result)
    end)

    it("only schema succeeds", function()
      local result, err = parameter({
          ["in"] = "path",
          required = true,
          name = "param_name",
          schema = {},
          --content = {},
        }, nil, {})
      assert.is_nil(err)
      assert.is_table(result)
      assert.equal("parameter", result.type)
    end)

    it("only content succeeds", function()
      local result, err = parameter({
          ["in"] = "path",
          required = true,
          name = "param_name",
          --schema = {},
          content = { user_id = {} },
        }, nil, {})
      assert.is_nil(err)
      assert.is_table(result)
      assert.equal("parameter", result.type)
    end)

  end)


  it("default for required", function()
    local cases = {
      { input = true,  output = true },
      { input = false, output = false },
      { input = nil,   output = false },
    }
    for _, case in ipairs(cases) do

      local result, err = parameter({
          ["in"] = "query",
          required = case.input,
          name = "param_name",
          schema = {},
        }, nil, {})
      assert.is_nil(err)
      assert.equal(case.output, result.required)
    end
  end)


  it("default for allowEmptyValue", function()
    local cases = {
      { where = "query", input = true,  output = true },
      { where = "query", input = false, output = false },
      { where = "query", input = nil,   output = false },
      { where = "cookie",  input = true,  output = nil },
      { where = "cookie",  input = false, output = nil },
      { where = "cookie",  input = nil,   output = nil },
    }
    for _, case in ipairs(cases) do

      local result, err = parameter({
          ["in"] = case.where,
          allowEmptyValue = case.input,
          name = "param_name",
          schema = {},
        }, nil, {})
      assert.is_nil(err)
      assert.equal(case.output, result.allowEmptyValue)
    end
  end)


  it("default for allowReserved", function()
    local cases = {
      { where = "query", input = true,  output = true },
      { where = "query", input = false, output = false },
      { where = "query", input = nil,   output = false },
      { where = "cookie",  input = true,  output = nil },
      { where = "cookie",  input = false, output = nil },
      { where = "cookie",  input = nil,   output = nil },
    }
    for _, case in ipairs(cases) do

      local result, err = parameter({
          ["in"] = case.where,
          allowReserved = case.input,
          name = "param_name",
          schema = {},
        }, nil, {})
      assert.is_nil(err)
      assert.equal(case.output, result.allowReserved)
    end
  end)


  it("default for style", function()
    local cases = {
      { where = "query",  output = "form" },
      { where = "path",   output = "simple" },
      { where = "header", output = "simple" },
      { where = "cookie", output = "form" },
    }
    for _, case in ipairs(cases) do

      local result, err = parameter({
          ["in"] = case.where,
          required = true,
          name = "param_name",
          schema = {},
        }, nil, {})
      assert.is_nil(err)
      assert.equal(case.output, result.style)
    end
  end)


  it("default for explode", function()
    local cases = {
      { style = "spaceDelimited", explode = true,  output = true },
      { style = "spaceDelimited", explode = false, output = false },
      { style = "spaceDelimited", explode = nil,   output = false },
      { style = "form", explode = true,  output = true },
      { style = "form", explode = false, output = false },
      { style = "form", explode = nil,   output = true },
    }
    for _, case in ipairs(cases) do

      local result, err = parameter({
          ["in"] = "query",
          name = "param_name",
          schema = {},
          style = case.style,
          explode = case.explode,
        }, nil, {})
      -- print(case.style, case.explode, case.output)
      assert.is_nil(err)
      assert.equal(case.output, result.explode)
    end
  end)


  it("accepts a proper schema object", function()
    local result, err = parameter({
        ["in"] = "query",
        name = "param_name",
        schema = {},
      }, nil, {})
    assert.is_nil(err)
    local schema = assert(result.schema)
    assert.is_table(schema)
    assert.equal("schema", schema.type)
  end)


  it("fails on a bad schema object", function()
    local result, err = parameter({
        ["in"] = "query",
        name = "param_name",
        schema = "should have been a table!",
      }, nil, {})
    assert.equal("a schema object expects a table as spec, but got string (origin: PARENT:parameter[param_name]:schema)", err)
    assert.is_nil(result)
  end)


  it("accepts a proper mediaType object", function()
    local result, err = parameter({
        ["in"] = "query",
        name = "param_name",
        content = { ["application/json"] = {} },
      }, nil, {})
    assert.is_nil(err)
    local content = assert(result.content)
    assert.is_table(content)
    assert.equal("mediaType", content[1].type)
  end)


  it("fails on a bad mediaType object", function()
    local result, err = parameter({
        ["in"] = "query",
        name = "param_name",
        content = { ["application/json"] = "should have been a table!" },
      }, nil, {})
    assert.equal("a mediaType object expects a table as spec, but got string (origin: PARENT:parameter[param_name]:mediaType[application/json])", err)
    assert.is_nil(result)
  end)


end)


