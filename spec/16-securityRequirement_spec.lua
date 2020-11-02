-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

_G._TEST = true
local common = require "openapi2kong.common"
local securityRequirement = require "openapi2kong.securityRequirement"

assert:set_parameter("TableFormatLevel", 5)

describe("[securityRequirement]", function()

  it("requires a table parameter as spec", function()
    local ok, err = securityRequirement("lalala", nil, {})
    assert.equal("a securityRequirement object expects a table as spec, but got string (origin: PARENT:securityRequirement)", err)
    assert.falsy(ok)
  end)

  it("fails without at leat 1 securityScheme", function()
    local ok, err = securityRequirement({}, nil, {})
    assert.equal("a securityRequirement requires at least 1 securityScheme (origin: PARENT:securityRequirement)", err)
    assert.falsy(ok)
  end)

  it("works with proper securitySchemes", function()
    local scheme_spec = {
      type = "http",
      scheme = "basic",
    }
    local openapi = setmetatable({
      spec = {
        components = {
          securitySchemes = {
            petstoreAuth = scheme_spec,
          },
        },
      }
    }, common.create_mt("openapi"))
    local requirements_spec = { petstoreAuth = {} }

    local result = assert(securityRequirement(requirements_spec, nil, openapi))
    assert.equal("securityRequirement", result.type)
    local scheme = assert(result[1], "expected scheme element")
    assert.equal("securityScheme", scheme.type)
    assert.equal(scheme_spec, scheme.spec)
    assert.equal("petstoreAuth", scheme.scheme_name)
    assert.equal(requirements_spec.petstoreAuth, scheme.scopes)
  end)

  it("fails with non-existing securitySchemes", function()
    local scheme_spec = {}
    local openapi = setmetatable({
      spec = {
        components = {
          securitySchemes = {
            petstoreAuth = scheme_spec,
          },
        },
      }
    }, common.create_mt("openapi"))
    openapi.get_trace = function() return "" end
    local requirements_spec = { nonexistingAuth = {} }

    local result, err = securityRequirement(requirements_spec, nil, openapi)
    assert.equal("securityScheme not found: #/components/securitySchemes/nonexistingAuth (origin: openapi:securityRequirement)", err)
    assert.is_nil(result)
  end)

  it("fails with bad securitySchemes", function()
    local scheme_spec = "lalala"
    local openapi = setmetatable({
      spec = {
        components = {
          securitySchemes = {
            petstoreAuth = scheme_spec,
          },
        },
      }
    }, common.create_mt("openapi"))
    openapi.get_trace = function() return "" end
    local requirements_spec = { petstoreAuth = {} }

    local result, err = securityRequirement(requirements_spec, nil, openapi)
    assert.equal("a securityScheme object expects a table as spec, but got string (origin: openapi:securityRequirement:securityScheme[petstoreAuth])", err)
    assert.is_nil(result)
  end)

end)


