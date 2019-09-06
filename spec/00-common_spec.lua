_G._TEST = true
local common = require "openapi2kong.common"
local openapi = require "openapi2kong.openapi"

describe("[common]", function()


  describe("'get_openapi' method", function()

    it("fails on recursion", function()
      local t1 = setmetatable({}, common.create_mt("a-name"))
      local t2 = setmetatable({}, common.create_mt("b-name"))
      t1.parent = t2
      t2.parent = t1

      local ok, err = t1:get_openapi()
      assert.equal("recursion detected while traversing to top openapi element", err)
      assert.falsy(ok)
    end)


    it("fails on broken-links", function()
      local t1 = setmetatable({}, common.create_mt("a-name"))
      local t2 = setmetatable({}, common.create_mt("b-name"))
      t2.parent = t1
      t1.parent = nil

      local ok, err = t2:get_openapi()
      assert.equal("parent lookup links broken, expected table, got nil", err)
      assert.falsy(ok)
    end)


    it("finds top-level openapi", function()
      local t0 = setmetatable({}, common.create_mt("openapi"))
      local t1 = setmetatable({}, common.create_mt("a-name"))
      local t2 = setmetatable({}, common.create_mt("b-name"))
      t2.parent = t1
      t1.parent = t0

      local result, err = t2:get_openapi()
      assert.is_nil(err)
      assert.equal(t0, result)
    end)

  end)



  describe("'get_servers' method", function()

    local oas_spec

    before_each(function()
      oas_spec = {
        openapi = "3.0",
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            servers = {{url="https://server2.com/path"}},
          },
        },
      }
    end)

    it("returns own servers if available", function()
      local result = assert(openapi(oas_spec))

      local paths_obj = assert(result.paths)
      local path = assert(paths_obj[1])
      local servers = assert(path:get_servers())
      assert.equal("server2.com", servers[1].parsed_url.host)
    end)

    it("returns openapi servers if own servers unavailable", function()
      oas_spec.paths["/"].servers = nil  -- remove own servers
      local result = assert(openapi(oas_spec))

      local paths_obj = assert(result.paths)
      local path = assert(paths_obj[1])
      local servers = assert(path:get_servers())
      assert.equal("server1.com", servers[1].parsed_url.host)
    end)


    it("fails on recursion", function()
      local t1 = setmetatable({}, common.create_mt("a-name"))
      local t2 = setmetatable({}, common.create_mt("b-name"))
      t1.parent = t2
      t2.parent = t1

      local ok, err = t1:get_servers()
      assert.equal("recursion detected while traversing to top openapi element", err)
      assert.falsy(ok)
    end)


    it("fails on broken-links", function()
      local t1 = setmetatable({}, common.create_mt("a-name"))
      local t2 = setmetatable({}, common.create_mt("b-name"))
      t2.parent = t1
      t1.parent = nil

      local ok, err = t2:get_servers()
      assert.equal("parent lookup links broken, expected table, got nil", err)
      assert.falsy(ok)
    end)

  end)



  describe("'get_security' method", function()

    local oas_spec

    before_each(function()
      oas_spec = {
        openapi = "3.0",
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            post = {
              security = {
                {
                  petstoreAuth = {}
                },
              },
            },
          },
        },
        security = {
          {
            anotherAuth = {}
          },
        },
        components = {
          securitySchemes = {
            petstoreAuth = {
              type = "http",
              scheme = "basic",
            },
            anotherAuth = {
              type = "http",
              scheme = "basic",
            }
          },
        },
      }
    end)


    it("returns own security property if available", function()
      local openapi_obj = assert(openapi(oas_spec))

      local paths_obj = assert(openapi_obj.paths)
      local path = assert(paths_obj[1])
      local operation = assert(path.operations[1])

      -- on "path" it should return top-level property
      local security, err = path:get_security()
      assert.is_nil(err)
      assert.equal(1, #security)
      local securityRequirement = security[1]
      assert.equal("anotherAuth", securityRequirement[1].scheme_name)

      -- on "operation" it should return own property
      security, err = operation:get_security()
      assert.is_nil(err)
      assert.equal(1, #security)
      securityRequirement = security[1]
      assert.equal("petstoreAuth", securityRequirement[1].scheme_name)
    end)


    it("returns openapi security property if own security property unavailable", function()

      oas_spec.paths["/"].post.security = nil  -- remove own security property
      local openapi_obj = assert(openapi(oas_spec))

      local paths_obj = assert(openapi_obj.paths)
      local path = assert(paths_obj[1])
      local operation = assert(path.operations[1])

      -- on "operation" it should return own property
      local security, err = operation:get_security()
      assert.is_nil(err)
      assert.equal(1, #security)
      local securityRequirement = security[1]
      assert.equal("anotherAuth", securityRequirement[1].scheme_name)
    end)


    it("returns nil+err if not found", function()

      oas_spec.paths["/"].post.security = nil  -- remove own security property
      oas_spec.security = nil -- remove top-level security property
      local openapi_obj = assert(openapi(oas_spec))

      local paths_obj = assert(openapi_obj.paths)
      local path = assert(paths_obj[1])
      local operation = assert(path.operations[1])

      local security, err = operation:get_security()
      assert.equal("not found", err)
      assert.is_nil(security)
    end)


    it("fails on recursion", function()
      local t1 = setmetatable({}, common.create_mt("a-name"))
      local t2 = setmetatable({}, common.create_mt("b-name"))
      t1.parent = t2
      t2.parent = t1

      local ok, err = t1:get_security()
      assert.equal("recursion detected while traversing to top openapi element", err)
      assert.falsy(ok)
    end)


    it("fails on broken-links", function()
      local t1 = setmetatable({}, common.create_mt("a-name"))
      local t2 = setmetatable({}, common.create_mt("b-name"))
      t2.parent = t1
      t1.parent = nil

      local ok, err = t2:get_security()
      assert.equal("parent lookup links broken, expected table, got nil", err)
      assert.falsy(ok)
    end)

  end)



  describe("'dereference' method", function()

    it("fails on ivalid references", function()
      local t0 = setmetatable({
        spec = {
          components = {
            schemas = {
              Pet = "a pet reference"
            },
          },
        }
      }, common.create_mt("openapi"))

      local t1 = setmetatable({
        parent = t0,
        spec = {
          ["$ref"] = "lalala",
        }
      }, common.create_mt("path"))

      local ok, err = t1:dereference()
      assert.equal("bad reference: lalala", err)
      assert.is_nil(ok)
    end)


    it("fails on non-local references", function()
      local t0 = setmetatable({
        spec = {
          components = {
            schemas = {
              Pet = "a pet reference"
            },
          },
        }
      }, common.create_mt("openapi"))

      local t1 = setmetatable({
        parent = t0,
        spec = {
          ["$ref"] = "definitions.json#/Pet",
        }
      }, common.create_mt("path"))

      local ok, err = t1:dereference()
      assert.equal("only local references are supported, not definitions.json#/Pet", err)
      assert.is_nil(ok)
    end)


    it("fails on relative references", function()
      local t0 = setmetatable({
        spec = {
          components = {
            schemas = {
              Pet = "a pet reference"
            },
          },
        }
      }, common.create_mt("openapi"))

      local t1 = setmetatable({
        parent = t0,
        spec = {
          ["$ref"] = "#Pet",
        }
      }, common.create_mt("path"))

      local ok, err = t1:dereference()
      assert.equal("only absolute references are supported, not Pet", err)
      assert.is_nil(ok)
    end)


    it("succeeds on proper references", function()
      local t0 = setmetatable({
        spec = {
          components = {
            schemas = {
              Pet = "a pet reference"
            },
          },
        }
      }, common.create_mt("openapi"))

      local t1 = setmetatable({
        parent = t0,
        spec = {
          ["$ref"] = "#/components/schemas/Pet",
        }
      }, common.create_mt("path"))

      local ok, err = t1:dereference()
      assert.is_nil(err)
      assert.truthy(ok)
      assert.equal("#/components/schemas/Pet", t1.spec_ref["$ref"])
      assert.equal("a pet reference", t1.spec)
    end)


    it("succeeds on empty path / top-level reference", function()
      local t0 = setmetatable({
        spec = {
          components = {
            schemas = {
              Pet = "a pet reference"
            },
          },
        }
      }, common.create_mt("openapi"))

      local t1 = setmetatable({
        parent = t0,
        spec = {
          ["$ref"] = "#/",
        }
      }, common.create_mt("path"))

      local ok, err = t1:dereference()
      assert.is_nil(err)
      assert.truthy(ok)
      assert.equal("#/", t1.spec_ref["$ref"])
      assert.equal(t0.spec, t1.spec)
    end)


    it("fails if reference not found", function()
      local t0 = setmetatable({
        spec = {
          components = {
            schemas = {
              Pet = "a pet reference"
            },
          },
        }
      }, common.create_mt("openapi"))

      local t1 = setmetatable({
        parent = t0,
        spec = {
          ["$ref"] = "#/components/schemas/Car",
        }
      }, common.create_mt("path"))

      local ok, err = t1:dereference()
      assert.equal("not found", err)
      assert.falsy(ok)
    end)


    it("fails if reference bad type", function()
      local t0 = setmetatable({
        spec = {
          components = {
            schemas = {
              Pet = "a pet reference"
            },
          },
        }
      }, common.create_mt("openapi"))

      local t1 = setmetatable({
        parent = t0,
        spec = {
          ["$ref"] = "#/components/schemas/Pet/dog",
        }
      }, common.create_mt("path"))

      local ok, err = t1:dereference()
      assert.equal("next level cannot be dereferenced, expected table, got string", err)
      assert.falsy(ok)
    end)

    it("succeeds with recursive references", function()
      local t0 = setmetatable({
        spec = {
          components = {
            schemas = {
              pet = {
                Dog = { ["$ref"] = "#/components/schemas/pet/Cat" },
                Cat = "a cat reference",
              },
            },
          },
        }
      }, common.create_mt("openapi"))

      local t1 = setmetatable({
        parent = t0,
        spec = {
          ["$ref"] = "#/components/schemas/pet/Dog",
        }
      }, common.create_mt("path"))

      local ok, err = t1:dereference()
      assert.is_nil(err)
      assert.truthy(ok)
      assert.equal("#/components/schemas/pet/Dog", t1.spec_ref["$ref"])
      assert.equal("a cat reference", t1.spec)
    end)

    it("fails on looping references", function()
      local t0 = setmetatable({
        spec = {
          components = {
            schemas = {
              pet = {
                Dog = { ["$ref"] = "#/components/schemas/pet/Cat" },
                Cat = { ["$ref"] = "#/components/schemas/pet/Dog" },
              },
            },
          },
        }
      }, common.create_mt("openapi"))

      local t1 = setmetatable({
        parent = t0,
        spec = {
          ["$ref"] = "#/components/schemas/pet/Dog",
        }
      }, common.create_mt("path"))

      local ok, err = t1:dereference()
      assert.equal("recursive reference loop detected: #/components/schemas/pet/Dog", err)
      assert.is_nil(ok)
    end)

  end)



  describe("'get_name' method", function()

    it("openapi object with x-kong-name", function()
      local oas_spec = {
        openapi = "3.0",
        info = {
          title = "awesome spec",
        },
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            post = {
            },
          },
        },
        ["x-kong-name"] = "myName",
      }
      local result = assert(openapi(oas_spec))
      assert.equal("openapi", result.type)
      assert.equal("myName", result:get_name())
    end)

    it("openapi object, call twice returns the same name", function()
      local oas_spec = {
        openapi = "3.0",
        info = {
          title = "awesome spec",
        },
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            post = {
            },
          },
        },
        ["x-kong-name"] = "myName",
      }
      local result = assert(openapi(oas_spec))
      assert.equal("openapi", result.type)
      assert.equal("myName", result:get_name())

      -- do it again, we should NOT get a numbered version because the two
      -- calls are independent OpenAPI objects
      result = assert(openapi(oas_spec))
      assert.equal("openapi", result.type)
      assert.equal("myName", result:get_name())
    end)

    it("openapi object with title, without x-kong-name", function()
      local oas_spec = {
        openapi = "3.0",
        info = {
          title = "awesome spec",
        },
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            post = {
            },
          },
        },
        --["x-kong-name"] = "myName",
      }
      local result = assert(openapi(oas_spec))
      assert.equal("openapi", result.type)
      assert.equal("awesome_spec", result:get_name())
    end)

    it("openapi object without both x-kong-name and title", function()
      local oas_spec = {
        openapi = "3.0",
        info = {
          --title = "awesome spec",
        },
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            post = {
            },
          },
        },
        --["x-kong-name"] = "myName",
      }
      local result = assert(openapi(oas_spec))
      assert.equal("openapi", result.type)
      assert.equal("openapi", result:get_name())
    end)

    it("path object with x-kong-name", function()
      local oas_spec = {
        openapi = "3.0",
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            summary = "path summary",
            ["x-kong-name"] = "myName",
            post = {
            },
          },
        },
        ["x-kong-name"] = "TopName",
      }
      local result = assert(openapi(oas_spec))
      local path = result.paths[1]
      assert.equal("path", path.type)
      assert.equal("TopName-myName", path:get_name())
    end)

    it("path object with x-kong-name, duplicate", function()
      local oas_spec = {
        openapi = "3.0",
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/one"] = {
            summary = "path summary",
            ["x-kong-name"] = "myName",
            post = {
            },
          },
          ["/two"] = {
            summary = "path summary",
            ["x-kong-name"] = "myName",
            post = {
            },
          },
        },
        ["x-kong-name"] = "TopName",
      }
      local result = assert(openapi(oas_spec))
      local path = result.paths[1]
      assert.equal("path", path.type)
      assert.equal("TopName-myName", path:get_name())

      path = result.paths[2]
      assert.equal("path", path.type)
      assert.equal("TopName-myName_1", path:get_name())
    end)

    it("path object with summary", function()
      local oas_spec = {
        openapi = "3.0",
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            summary = "path summary",
            --["x-kong-name"] = "myName",
            post = {
            },
          },
        },
        ["x-kong-name"] = "TopName",
      }
      local result = assert(openapi(oas_spec))
      local path = result.paths[1]
      assert.equal("path", path.type)
      assert.equal("TopName-path_summary", path:get_name())
    end)

    it("path object without summary", function()
      local oas_spec = {
        openapi = "3.0",
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            --summary = "path summary",
            --["x-kong-name"] = "myName",
            post = {
            },
          },
        },
        ["x-kong-name"] = "TopName",
      }
      local result = assert(openapi(oas_spec))
      local path = result.paths[1]
      assert.equal("path", path.type)
      assert.equal("TopName-path", path:get_name())
    end)

    it("operation object", function()
      local oas_spec = {
        openapi = "3.0",
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            ["x-kong-name"] = "pathName",
            post = {
            },
          },
        },
        ["x-kong-name"] = "TopName",
      }
      local result = assert(openapi(oas_spec))
      local operation = result.paths[1].operations[1]
      assert.equal("operation", operation.type)
      assert.equal("TopName-pathName-post", operation:get_name())
    end)

    it("servers object returns name of the parent object", function()
      local oas_spec = {
        openapi = "3.0",
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            --summary = "path summary",
            ["x-kong-name"] = "myName",
            servers = {{url="https://server2.com/path"}},
            post = {
            },
          },
        },
        ["x-kong-name"] = "TopName",
      }
      local result = assert(openapi(oas_spec))
      local servers = result.servers
      assert.equal("openapi", result.type)
      assert.equal("servers", servers.type)
      assert.equal(result:get_name(), servers:get_name())

      local path = result.paths[1]
      servers = path.servers
      assert.equal("path", path.type)
      assert.equal("servers", servers.type)
      assert.equal(path:get_name(), servers:get_name())
    end)

    it("fails with unsupported object", function()
      local oas_spec = {
        openapi = "3.0",
        servers = {{url="https://server1.com/path"}},
        paths = {
          ["/"] = {
            --summary = "path summary",
            ["x-kong-name"] = "myName",
            servers = {{url="https://server2.com/path"}},
            post = {
            },
          },
        },
        ["x-kong-name"] = "TopName",
      }
      local result = assert(openapi(oas_spec))
      assert.equal("openapi", result.type)
      local paths = result.paths
      assert.equal("paths", paths.type)
      assert.has.error(function() paths:get_name() end,
        "don't know how to get 'name' of an 'paths' object")
    end)

  end)



  describe("'get_plugins' method", function()

    it("returns plugins", function()
      local openapi_obj = assert(openapi({
        openapi = "3.0",
        components = {
          plugins = {}
        },
        paths = {
          ["/"] = {
            get = {
              ["x-kong-plugin-request-termination"] = {  -- overrides global one
                value = 1,
              },
            },
            post = {
              ["x-kong-plugin-request-transformer"] = {  -- only on this level
                value = 3,
              },
            },
          },
        },
        ["x-kong-plugin-request-termination"] = {
          value = 2,
        },
        ["x-kong-plugin-response-transformer"] = {  -- only global, so in all lists
          value = 4,
        },
      }))

      local get_op = assert(openapi_obj.paths[1].operations[1])
      local post_op = assert(openapi_obj.paths[1].operations[2])
      do -- order cannot be guaranteed, so double check
        if get_op.method ~= "get" then -- switch
          get_op, post_op = post_op, get_op
        end
        assert.equal("get", get_op.method)
        assert.equal("post", post_op.method)
      end

      assert.same({
        ["request-termination"] = {
          name = "request-termination",
          value = 1,
        },
        ["response-transformer"] = {
          name = "response-transformer",
          value = 4,
        }
      }, get_op:get_plugins())

      assert.same({
        ["request-termination"] = {
          name = "request-termination",
          value = 2,
        },
        ["request-transformer"] = {
          name = "request-transformer",
          value = 3,
        },
        ["response-transformer"] = {
          name = "response-transformer",
          value = 4,
        }
      }, post_op:get_plugins())
    end)

    it("dereferences plugins", function()
      local openapi_obj = assert(openapi({
        openapi = "3.0",
        components = {
          plugins = {
            terminate = {
                value = 1,
            },
            transform = {
                value = 2,
            },
          }
        },
        paths = {
          ["/"] = {
            get = {
              ["x-kong-plugin-request-termination"] = {
                ["$ref"] = "#/components/plugins/terminate"
              }
            },
          },
        },
        ["x-kong-plugin-response-transformer"] = {
          ["$ref"] = "#/components/plugins/transform"
        },
      }))

      local get_op = assert(openapi_obj.paths[1].operations[1])

      assert.same({
        ["request-termination"] = {
          name = "request-termination",
          value = 1,
        },
        ["response-transformer"] = {
          name = "response-transformer",
          value = 2,
        }
      }, get_op:get_plugins())
    end)

  end)

end)
