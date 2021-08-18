#!/usr/bin/env resty
-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

setmetatable(_G, nil)  -- Suppress OpenResty warnings

local kong = require "openapi2kong"
local utils = require "pl.utils"
local lapp = require "pl.lapp"

warn("@on")  -- luacheck: ignore
utils.raise_deprecation {
  source = "Kong Enterprise",
  message = "the 'openapi2kong' cli tool is deprecated, please " ..
            "use Insomnia to generate Kong declarative configurations " ..
            "from OAS files instead",
  version_removed = "3.0.0.0",
  deprecated_after = "2.5.0.0",
  no_trace = true,
}

local args = lapp [[
Usage: openapi2kong [OPTIONS] <input...>

Convert OpenAPI spec 3.x into Kong declarative format
  --tags (default "") Comma separated list of tags to apply
  --json              Write output as json (yaml is the default)
  --output (default "stdout")
                      Output file where to write to
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

if args.output:lower() ~= "stdout" then
  assert(utils.writefile(args.output, kong_encoded))
else
  io.stdout:setvbuf("no")
  io.stdout:write(kong_encoded)
  io.stdout:write("\n")
end
