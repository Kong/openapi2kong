-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

_G._TEST = true
local servers = require "openapi2kong.servers"

describe("[servers]", function()

  it("requires a table parameter", function()
    local ok, err = servers("lalala", nil, {})
    assert.equal("a servers object expects a table, but got string (origin: PARENT:servers)", err)
    assert.falsy(ok)
  end)

  it("accepts an empty table", function()
    local result, err = servers({}, nil, {})
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("servers", result.type)
    assert.equal(0, #result)
  end)

  it("accepts a proper url", function()
    local result, err = servers({
      {
        url = "http://server.com/path",
      },
    }, nil, {})
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("servers", result.type)
    assert.equal(1, #result)
  end)

  it("accepts multiple proper urls", function()
    local result, err = servers({
      {
        url = "http://server1.com/path",
      }, {
        url = "http://server2.com/path",
      },
    }, nil, {})
    assert.is_nil(err)
    assert.is_table(result)
    assert.equal("servers", result.type)
    assert.equal(2, #result)
  end)

  it("fails if servers differ other than hostname+port", function()
    local ok, err = servers({
      {
        url = "http://server1.com/path1",
      }, {
        url = "http://server2.com/path2",
      },
    }, nil, {})
    assert.equal("server urls should not differ other than host or port (origin: PARENT:servers)", err)
    assert.is_nil(ok)
  end)

end)
