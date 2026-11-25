# ADR 0001 — Godot engine and renderer

- **Status:** Accepted for M2/M3
- **Date:** 2026-11-25
- **Context:** `PROJECT_PLAN.md` leaves the exact Godot 4.x patch and renderer open. The foundation must be reproducible on Windows and Linux x86_64.

## Decision

Pin the project to **Godot 4.7.2-stable** and use the **Compatibility (`gl_compatibility`) renderer** for both desktop and mobile feature paths.

The development machine reports:

```text
$ godot --version
4.7.2.stable.arch_linux.ed1daf0bf
```

`game/project.godot` records `config/features=PackedStringArray("4.7", "GL Compatibility")`.

## Rationale

- 4.7.2-stable is a published stable release; 4.8 was beta at the time of inspection.
- Compatibility offers predictable 2D sprite rendering across the two desktop targets and avoids Forward+ GPU assumptions for a pixel-art viewer.
- GDScript keeps the codebase reviewable without a C# toolchain or additional runtime dependency.
- The engine binary was found locally after an earlier period of absence; no elevated install was performed by this project.

## Consequences

- Engine-patch upgrades require a deliberate ADR update and a fresh import, test, and export check.
- Before a release build, matching export templates must be installed; configuration alone is not proof of export.
- If a 2D feature requires Forward+, revisit this ADR with measured evidence rather than silently changing the renderer.
