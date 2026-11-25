# ADR 0005 — Save format and versioning

- **Status:** Accepted for M2/M3
- **Date:** 2026-11-25
- **Context:** The project needs multiple slots, settings persistence, safe writes, backup, and migration, but no gameplay progression is implemented yet.

## Decision

Use **plain JSON under `user://`** with an integer `version` field.

| Path | Purpose |
|---|---|
| `user://settings.json` | UI and debug preferences |
| `user://save_slot_0.json` … `user://save_slot_2.json` | Manual profile/viewer state |
| `user://*.bak` | Previous good file |
| `user://*.tmp` | Atomic write staging |

- Current save format version: `2`.
- Writes use temp file → backup previous target → rename temp into place.
- Loads try the primary file, then `.bak`.
- Newer versions are refused. Older versions pass through a stepwise migration chain (`1 → 2`).
- JSON numbers are normalized with `int()` where integer fields are required.
- Saves contain IDs, strings, booleans, and simple dictionaries only — no `Node`, `Resource`, or `Object` instances.
- No inventory, battle result, or progression state is saved in this milestone.

## Rationale

- JSON is readable, diffable, and easy to migrate while the schema is new.
- `user://` works on Windows and Linux without writing beside the executable.
- The backup/primary strategy handles crashes between renames on both target platforms.
- Separating settings from slots prevents a UI preference write from touching profile data.

## Consequences

- Every shipped schema change must add a pure migration and a regression fixture.
- IDs must remain strings to avoid JSON precision loss.
- A local save is player-controlled and must never be treated as authoritative online state.
- The quit-and-relaunch persistence test is still required for release milestones; headless round-trip tests alone are not sufficient.
