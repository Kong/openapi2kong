-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

_G._TEST = true
local server = require "openapi2kong.server"

describe("[server]", function()

  it("requires a table parameter", function()
    local ok, err = server(123, nil, {})
    assert.equal("a server object expects a table, but got number (origin: PARENT:server[<bad spec: number>])", err)
    assert.falsy(ok)
  end)

  it("accepts a proper url", function()
    local result

    result = assert(server({url="http://server.com:80/path"}, nil, {}))
    assert.same({
        host = 'server.com',
        path = '/path',
        port = '80',
        scheme = 'http',
      }, result.parsed_url)
    assert.equal("server", result.type)
  end)

  it("sets default ports", function()
    local result

    result = assert(server({url="http://server.com:1/path"}, nil, {}))
    assert.same({
        host = 'server.com',
        path = '/path',
        port = '1',
        scheme = 'http',
      }, result.parsed_url)

    result = assert(server({url="https://server.com:1/path"}, nil, {}))
    assert.same({
        host = 'server.com',
        path = '/path',
        port = '1',
        scheme = 'https',
      }, result.parsed_url)

    result = assert(server({url="http://server.com/path"}, nil, {}))
    assert.same({
        host = 'server.com',
        path = '/path',
        port = '80',
        scheme = 'http',
      }, result.parsed_url)

    result = assert(server({url="https://server.com/path"}, nil, {}))
    assert.same({
        host = 'server.com',
        path = '/path',
        port = '443',
        scheme = 'https',
      }, result.parsed_url)

    result = assert(server({url="tcp://server.com/path"}, nil, {}))
    assert.same({
        host = 'server.com',
        path = '/path',
        scheme = 'tcp',
      }, result.parsed_url)
  end)

  it("substitutes server variables", function()
    local result, err = server({
        url="https://server.com/{var}/path",
        variables = {
          var = {
            default = "segment",
          },
        },
      }, nil, {})
    assert.is_nil(err)
    assert.same({
        host = 'server.com',
        path = '/segment/path',
        scheme = 'https',
        port = '443',
      }, result.parsed_url)
  end)

end)
