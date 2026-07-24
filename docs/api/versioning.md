# API Versioning Policy

## Scope

This policy applies to every HTTP endpoint under `/v1`.
The goal is to keep the web client stable today and make the upcoming mobile client safe to integrate against the same contract.

## Contract Rules

1. Successful JSON responses must return a top-level `data` object.
2. Failed JSON responses must return a top-level `error` object.
3. `error.code` is the stable machine-readable identifier. Clients should branch on it instead of parsing `error.message`.
4. `error.message` is localized user-facing text and may be improved without being considered a breaking API change.
5. `error.details` is optional and may contain validation issues or endpoint-specific structured context.
6. Route paths, HTTP methods, and authentication requirements are part of the public contract.

## Backward Compatibility

The following changes are non-breaking within `v1`:

1. Adding new optional fields inside `data` payloads.
2. Adding new optional fields inside `error.details`.
3. Adding new `error.code` values for newly introduced failure cases.
4. Improving `error.message` wording without changing semantic meaning.

The following changes are breaking and require a new API version:

1. Removing a response field already used by clients.
2. Renaming a field.
3. Changing a field type.
4. Changing a route path or HTTP method.
5. Changing authentication or CSRF requirements for an existing endpoint.
6. Replacing an existing `error.code` with a different meaning.

## Deprecation Process

1. Mark the field or endpoint as deprecated in the OpenAPI document.
2. Keep the old contract alive for at least one full mobile release cycle.
3. Add migration notes in the changelog or release notes before removal.
4. Remove only in `/v2` or later.

## Client Guidance

1. Mobile and web clients should read only documented fields.
2. Clients must ignore unknown fields.
3. Client logic should branch on `error.code`, not `error.message`.
4. Client DTO parsing should treat nullable fields explicitly instead of assuming empty strings.

## Testing Gate

Contract-sensitive changes must update:

1. `docs/api/openapi.yaml`
2. contract tests in `backend/src/api.contract.test.ts`
3. any frontend DTO parsing that depends on the changed payload