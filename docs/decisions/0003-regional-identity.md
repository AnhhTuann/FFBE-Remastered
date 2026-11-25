# ADR 0003 — Regional identity and form discrimination

- **Status:** Accepted
- **Date:** 2026-11-25
- **Context:** Phase 0 recorded 5,181 collision candidates and 11 GL/JP unit-form conflicts. Native numeric IDs are not globally unique across regions.

## Decision

Use composite identities of the form:

```text
kind:REGION:native_id@form
```

Examples:

```text
unit:GL:401008507@base
unit:JP:401008507@base
anim:GL:401008507@limit_burst
```

- `kind` is the entity type (`unit`, `anim`, etc.).
- `REGION` is `GL` or `JP`.
- `native_id` is kept as a string.
- `form` is an explicit discriminator (`base`, `brave_shift`, `limit_burst`, etc.).
- `ContentId.as_text()` includes the form; `to_base_text()` omits it for display grouping only.

## Rationale

- It prevents silent cross-region overwrites even when both regions use the same native ID.
- It preserves unit forms without inventing a new native ID.
- String IDs avoid JSON integer precision issues.
- Parsing is centralized in `game/core/content_id.gd`, so scenes do not manually split identity strings.

## Consequences

- Every content fixture and save reference must use the composite form.
- Lookup is region-aware by construction; there is no global numeric-ID dictionary.
- Imported content must retain `region`, `native_id`, `form`, `provenance`, and `verification_status`.
- The 11 conflict IDs documented in Phase 0 remain distinct records; this ADR does not resolve their content differences.
