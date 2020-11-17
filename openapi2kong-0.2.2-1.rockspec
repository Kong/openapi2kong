package = "openapi2kong"
version = "0.2.2-1"
source = {
   url = "git://github.com/kong/openapi2kong",
   branch = "master"
}
description = {
   summary = "Tool to convert OpenAPI specs into Kong declarative config format",
   detailed = [[
      Reads an OpenAPI spec and outputs a file with Upstream, Service, Route
      definitions to be imported in Kong.
   ]],
   license = "Proprietary",
   homepage = "https://github.com/Kong/openapi2kong"
}
dependencies = {
  "lua-cjson",
  "lyaml",
  "penlight",
}
build = {
   type = "builtin",
   install = {
     bin = {
       ["openapi2kong"] = "bin/openapi2kong.lua",
     },
   },
   modules = {
     ["openapi2kong.init"]                = "src/openapi2kong/init.lua",
     ["openapi2kong.common"]              = "src/openapi2kong/common.lua",
     ["openapi2kong.encoding"]            = "src/openapi2kong/encoding.lua",
     ["openapi2kong.encodings"]           = "src/openapi2kong/encodings.lua",
     ["openapi2kong.header"]              = "src/openapi2kong/header.lua",
     ["openapi2kong.headers"]             = "src/openapi2kong/headers.lua",
     ["openapi2kong.mediaType"]           = "src/openapi2kong/mediaType.lua",
     ["openapi2kong.oauthFlow"]           = "src/openapi2kong/oauthFlow.lua",
     ["openapi2kong.openapi"]             = "src/openapi2kong/openapi.lua",
     ["openapi2kong.operation"]           = "src/openapi2kong/operation.lua",
     ["openapi2kong.parameter"]           = "src/openapi2kong/parameter.lua",
     ["openapi2kong.parameters"]          = "src/openapi2kong/parameters.lua",
     ["openapi2kong.path"]                = "src/openapi2kong/path.lua",
     ["openapi2kong.paths"]               = "src/openapi2kong/paths.lua",
     ["openapi2kong.requestBody"]         = "src/openapi2kong/requestBody.lua",
     ["openapi2kong.schema"]              = "src/openapi2kong/schema.lua",
     ["openapi2kong.securityRequirements"]= "src/openapi2kong/securityRequirements.lua",
     ["openapi2kong.securityRequirement"] = "src/openapi2kong/securityRequirement.lua",
     ["openapi2kong.securityScheme"]      = "src/openapi2kong/securityScheme.lua",
     ["openapi2kong.server"]              = "src/openapi2kong/server.lua",
     ["openapi2kong.servers"]             = "src/openapi2kong/servers.lua",
   }
}
