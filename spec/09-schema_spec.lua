_G._TEST = true
local openapi = require "openapi2kong.openapi"
local schema = require "openapi2kong.schema"
local deepcopy = require("pl.tablex").deepcopy

assert:set_parameter("TableFormatLevel", 5)

describe("[schema]", function()

  it("requires a table parameter as spec", function()
    local ok, err = schema("lalala", nil, {})
    assert.equal("a schema object expects a table as spec, but got string (origin: PARENT:schema)", err)
    assert.falsy(ok)
  end)

  it("dereference the (nested) schema", function()
    local spec = {
      openapi = "3.0",
      paths = {
        ["/"] = {
          post = {
            requestBody = {
              content = {
                ["application/json"] = {
                  schema = {
                    type = "array",
                    items = {
                      ["$ref"] = "#/components/schemas/LearningCenterVideo"
                    },
                  },
                },
              },
            },
          },
        },
      },
      components = {
        schemas = {
          LearningCenterVideo = {
            type = "object",
            properties = {
              id = {
                description = "Id of a learning center video",
                type = "string"
              },
              title = {
                type = "string"
              },
              abbreviation = {
                type = "string"
              },
              trackId = {
                ["$ref"] = "#/components/schemas/TrackId"
              },
            },
          },
          TrackId = {
            description = "Id of a learning center track",
            type = "string",
            minLength = 1,
            maxLength = 5,
          },
        },
      },
    }
    local result = assert(openapi(deepcopy(spec)))

    local expected = deepcopy(spec.paths["/"].post.requestBody.content["application/json"].schema)
    expected.items = deepcopy(spec.components.schemas.LearningCenterVideo)
    expected.items.properties.trackId = deepcopy(spec.components.schemas.TrackId)

    local schema_obj = result.paths[1].operations[1].requestBody.content[1].schema
    assert.equal("schema", schema_obj.type)

    assert.same(expected, assert(schema_obj:get_dereferenced_schema()))
  end)


  it("dereference fails on non-local reference", function()
    local spec = {
      openapi = "3.0",
      paths = {
        ["/"] = {
          post = {
            requestBody = {
              content = {
                ["application/json"] = {
                  schema = {
                    type = "array",
                    items = {
                      ["$ref"] = "#/components/schemas/LearningCenterVideo"
                    },
                  },
                },
              },
            },
          },
        },
      },
      components = {
        schemas = {
          LearningCenterVideo = {
            type = "object",
            properties = {
              id = {
                description = "Id of a learning center video",
                type = "string"
              },
              title = {
                type = "string"
              },
              abbreviation = {
                type = "string"
              },
              trackId = {
                ["$ref"] = "somefile#/components/schemas/TrackId"
              },
            },
          },
        },
      },
    }
    local result = assert(openapi(deepcopy(spec)))
    local schema_obj = result.paths[1].operations[1].requestBody.content[1].schema
    assert.equal("schema", schema_obj.type)

    local ok, err = schema_obj:get_dereferenced_schema()
    assert.equal("only local references are supported, not somefile#/components/schemas/TrackId", err)
    assert.is_nil(ok)
  end)


  it("dereference dereference fails on relative paths", function()
    local spec = {
      openapi = "3.0",
      paths = {
        ["/"] = {
          post = {
            requestBody = {
              content = {
                ["application/json"] = {
                  schema = {
                    type = "array",
                    items = {
                      ["$ref"] = "#components/schemas/LearningCenterVideo"
                    },
                  },
                },
              },
            },
          },
        },
      },
    }
    local result = assert(openapi(deepcopy(spec)))
    local schema_obj = result.paths[1].operations[1].requestBody.content[1].schema
    assert.equal("schema", schema_obj.type)

    local ok, err = schema_obj:get_dereferenced_schema()
    assert.equal("failed dereferencing schema: only absolute references are supported, not components/schemas/LearningCenterVideo", err)
    assert.is_nil(ok)
  end)


  it("dereference recursive loop fails", function()
    local spec = {
      openapi = "3.0",
      paths = {
        ["/"] = {
          post = {
            requestBody = {
              content = {
                ["application/json"] = {
                  schema = {
                    type = "array",
                    items = {
                      ["$ref"] = "#/components/schemas/LearningCenterVideo"
                    },
                  },
                },
              },
            },
          },
        },
      },
      components = {
        schemas = {
          LearningCenterVideo = {
            type = "object",
            properties = {
              id = {
                description = "Id of a learning center video",
                type = "string"
              },
              title = {
                type = "string"
              },
              abbreviation = {
                type = "string"
              },
              trackId = {
                ["$ref"] = "#/components/schemas/TrackId"
              },
            },
          },
          TrackId = {
            ["$ref"] = "#/components/schemas/LearningCenterVideo"
          },
        },
      },
    }
    local result = assert(openapi(deepcopy(spec)))
    local schema_obj = result.paths[1].operations[1].requestBody.content[1].schema
    assert.equal("schema", schema_obj.type)

    local ok, err = schema_obj:get_dereferenced_schema()
    assert.equal("recursion detected in schema dereferencing", err)
    assert.is_nil(ok)
  end)


end)


