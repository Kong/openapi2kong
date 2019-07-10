#!/usr/bin/env resty

local kong = require "openapi2kong"
local utils = require "pl.utils"
local lapp = require "pl.lapp"

local args = lapp [[
Usage: openapi2kong [OPTIONS] <output> <input...>

Convert OpenAPI spec 3.x into Kong declarative format
  --tags (default "") Comma separated list of tags to apply
  --json              Write output as json (yaml is the default)
  <output> (string)   output file
  <input...> (string) input files (either json or yaml files)

]]

local options = {}

if args.tags and args.tags ~= "" then
  options.tags = utils.split(args.tags, ",")
end

local kong_spec = assert(kong.convert_files(args.input, options))

local kong_encoded
if not args.json then
  local lyaml = require "lyaml"
  kong_encoded = lyaml.dump({ kong_spec })
else
  local cjson = require "cjson.safe"
  kong_encoded = cjson.encode(kong_spec)
end

assert(utils.writefile(args.output, kong_encoded))

