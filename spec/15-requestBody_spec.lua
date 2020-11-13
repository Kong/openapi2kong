-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

_G._TEST = true
local requestBody = require "openapi2kong.requestBody"

assert:set_parameter("TableFormatLevel", 5)

describe("[requestBody]", function()

  it("requires a table parameter as spec", function()
    local ok, err = requestBody("lalala", nil, {})
    assert.equal("a requestBody object expects a table as spec, but got string (origin: PARENT:requestBody)", err)
    assert.falsy(ok)
  end)


  it("accepts a proper media type", function()
    local result, err = requestBody({
        content = {
          ["application/json"] = { schema = {} },
          ["text/plain"] = { schema = {} },
        }
      }, nil, {})
    assert.is_nil(err)
    assert.equal("requestBody", result.type)
    assert.equal("mediaType", result.content[1].type)
    assert.equal(2, #result.content)
  end)


  it("rejects a bad parameter", function()
    local result, err = requestBody({
        content = {
          ["application/json"] = "lalala",
          ["text/plain"] = { schema = {} },
        }
      }, nil, {})
    assert.equal("a mediaType object expects a table as spec, but got string (origin: PARENT:requestBody:mediaType[application/json])", err)
    assert.falsy(result)
  end)


end)


