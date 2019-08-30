# openapi2kong

Lib to convert OpenAPI specs into Kong specs

# History

See [CHANGELOG.md](https://github.com/Kong/openapi2kong/blob/master/CHANGELOG.md).

# Usage & installation

It can be installed from the repo using LuaRocks

```shell
$ git clone https://github.com/kong/openapi2kong
$ cd openapi2kong
$ luarocks make
```

From here the CLI utility can be used as follows:

```
Usage: openapi2kong [OPTIONS] <input...>

Convert OpenAPI spec 3.x into Kong declarative format
  --tags (default "") Comma separated list of tags to apply
  --json              Write output as json (yaml is the default)
  --output (default "stdout")
                      Output file where to write to
  <input...> (string) input files (either json or yaml files)
```

# Quick start

See [the examples](https://github.com/Kong/openapi2kong/tree/master/examples),
and try to convert them. The annotations in the files explain how most of the
properties work.

# Generating Kong entities

### Tags

Each generated entity will get the tags as specified as well as the following
tags:

* `OAS3_import`
* `OAS3file_<filename>`

### Service and Upstream

Services and Upstreams are generated from the OpenAPI property `servers` (which
lives on the `OpenAPI`, `Path`, and `Operation` objects). Each `service` uses
its accompanying `upstream`.

The servers listed will be added to the `upstream` object as `targets`, but the
property may also be an empty list in which case no `targets` will be generated.

__NOTE 1__: The server variables defined in the server url's will be substituted
by their default values.

__NOTE 2__: A pre-requisite is that the entries in the `servers` property only
differ by `hostname` and `port`, since a Kong `service` or `upstream` cannot
have multiple paths or schemes/protocols.

Defaults for the generated `upstream` and `service` objects can be set by using
the custom extensions `x-kong-upstream-defaults` and `x-kong-service-defaults`.
The properties can be specified on the `OpenAPI`, `Path`, and `Operation` objects.

Those defaults are 'inherited' from the top down. So defaults set on an `OpenAPI`
top-level object will also apply to `upstreams` and `services` generated
from a `servers` property on a `Path` or `Operation` object.

So to get the `upstream` defaults for a `servers` property on an `Operation` object:

- Use the `x-kong-upstream-defaults` entry of the `Operation` object, or
- fallback to the `x-kong-upstream-defaults` entry of the `Path` object, or
- fallback to the `x-kong-upstream-defaults` entry of the `OpenAPI` object, or
- fallback and do not use anything and hence use Kong defaults

This similarly applies to the `service` object.

### Route

Routes are generated for each `Operation` object. They are defined as regex
routes and must have an exact match.

# Entity naming

Entity naming is relevant to be able to match OpenAPI spec content with the
entities in the running Kong system.

__NOTE__: Every name will be normalized to remove unallowed characters!

## Generating names (OpenAPI spec)

To facilitate naming there is a custom specification `x-kong-name` which can
set the name of an entity.

Every entity is named in a hierarchical manner. So for example an `Operation`
name will be starting with the `OpenAPI` name, then the `Path` name, and then
the `Operation` name.

Whenever a name is not unique, the second one will get a number appended, which
will be incremented for each next duplicate.

### OpenAPI object

The name will be set in the following order:

- use `x-kong-name` property, or if not set fallback to
- `openapi.info.title` property, or if not set fallback to
- a default string `"openapi"`

### Servers object

Will share the name with its parent (either an `OpenAPI`, `Path`, or `Operation`)

### Path object

The name will be the `OpenAPI` object name, with appended (in the following order):

- use `x-kong-name` property, or if not set fallback to
- `path.summary` property, or if not set fallback to
- a default string `"path"`

### Operation object

The name will be the `Path` object name, with appended the operations method.
Eg. `get`, `post`, etc.

## Generated names (Kong spec)

### Upstream & Service

The `Upstream` and `Service` entities will get the name of the `servers` property
they were derived from.

### Route

A `Route` entity will get the name of its related `Operation` object.

# Security

The `security` property can be defined on the top-level `openapi` object as well
as on `operation` objects. The information contained cannot be directly mapped
onto Kong, due to the logical and/or nature of how the specs have been set up.

To overcome this Kong will only accept a single `securityScheme` from the `security`
property.

The additional properties that Kong supports on its plugins can be configured
by using custom extensions. The custom extensions are
`x-kong-security-<plugin-name>`.

Supported types are:

- `oauth2`
    - NOT YET IMPLEMENTED!
    - except for the implicit flow
    - implemented using the Kong plugin `openid-connect`
    - extended by: `x-kong-security-openid-connect`
- `openIdConnect`
    - implemented using the Kong plugin `openid-connect`
    - extended by: `x-kong-security-openid-connect`
    - properties set from OpenAPI spec:
        - `issuer` (from `openIdConnectUrl` property)
        - `scopes_required` will get the combined set of scopes from the
          extension defaults and the scopes from the Security Requirement
          Object
- `apiKey`
    - except for the `in` property, since the Kong plugin will by default
      look in header and query already. Cookie is not supported.
    - implemented using the Kong plugin `key-auth`
    - extended by: `x-kong-security-key-auth`
    - properties set from OpenAPI spec:
        - `key_names` will get the defaults from the extension and then the
          `name` from the `securityScheme` object will be added to that list
    - requires to add credentials to Kong, which is not supported through
      OpenAPI specs.
- `http`
    - only `Basic` scheme is supported
    - implemented using the Kong plugin `basic-auth`
    - extended by: `x-kong-security-basic-auth`
    - properties set from OpenAPI spec:
        - none
    - requires to add credentials to Kong, which is not supported through
      OpenAPI specs.

# Plugins

Generic plugins can be added on an `operation` object. The custom extension to
use is `x-kong-plugin-<plugin-name>`. The `name` property is not required
(since it's already in the extension name). Optional properties not specified
will get Kong defaults.

Plugins can also be added on the `OpenAPI` object level, in which case they
will be applied to every `Operation` in the spec. If a plugin is specified on
both, the `Operation` level one will take precedence.

This extension needs to hold an object that contains the entire plugin
config.

```json
"x-kong-plugin-key-auth": {
  "name": "key-auth",
  "enabled": true,
  "config": {
    "key_names": ["api_key", "apikey"],
    "key_in_body": false,
    "hide_credentials": true
  }
}
```

References are also supported, so this is valid as well (provided the
reference exists):

```json
"x-kong-plugin-key-auth": {
  "$ref": "#/components/kong/plugins/key_auth_config"
}
```

# Validation

To enable validation the `request-validation` plugin must be added to an
`operation` object. You can either specify the full configuration, or have it
be auto-generated based on the OpenAPI spec.

To enable auto generation, add the plugin, but do not include the `config`
property. The `config` property will then be auto-generated and added to
the generated spec.


