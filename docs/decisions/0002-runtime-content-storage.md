# ADR 0002 — Runtime content storage

- **Status:** Accepted for M2/M3; revisit before bulk content import
- **Date:** 2026-11-25
- **Context:** `PROJECT_PLAN.md` requires a choice between SQLite and generated Godot resources. No protected FFBE content may be imported yet; the current data set is small and synthetic.

## Decision

Use **versioned JSON content packages under `game/data/`**, loaded through `ContentRepository`, as the runtime content store for M2/M3. Generate `SpriteFrames` at runtime from a small synthetic atlas plus JSON frame metadata. Keep player state in a separate versioned save format under `user://`.

SQLite is **not adopted** in this milestone.

## Rationale

- The current scope is one Character Viewer with a handful of synthetic units and clips. JSON is sufficient and diffable.
- SQLite in Godot would require a maintained plugin or GDExtension. Packaging, ABI, and lifecycle risks on both Windows and Linux have not been validated.
- No complex query, transaction, or large-table workload exists yet.
- JSON files can be included in exports with an explicit `include_filter="*.json"`.
- The repository abstraction keeps the storage format replaceable. Gameplay/domain code never reads raw JSON directly.

## Consequences

- If bulk GL/JP import proceeds, add a measured SQLite prototype or generated `.tres` packages with load-time and package-size evidence before changing this ADR.
- JSON numbers can load as floats. Identifiers are stored as strings and versions are cast with `int()`.
- Content files are immutable definitions; player mutations must live in saves, not content resources.
- Rights review remains a separate gate. This ADR does not permit importing protected data.
