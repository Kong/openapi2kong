# Changelog

## 0.2.1 7-Jan-2020

- fix: a weak table caused premature garbage collection of entries still
  required

## 0.2.0 22-Nov-2019

- added a trace to errors to identify to originating yaml/json element that
  caused the error.
- fix (sort of) in unsupported Oauth2 security flows, handle an array
  instead of an object.
- do not add plugin array to routes if empty, to improve decK compatibility
- fix body-validation; is now properly added

## 0.1.0

- initial version
