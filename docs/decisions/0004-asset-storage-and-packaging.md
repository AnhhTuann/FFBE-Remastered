# ADR 0004 — Asset storage and packaging

- **Status:** Accepted for M2/M3
- **Date:** 2026-11-25
- **Context:** Phase 0 inventoried 148,168 files and 3,674,191,680 bytes of FFBE-derived assets with no redistribution permission. The project needs a working animation prototype without committing protected material.

## Decision

Ship only **project-authored synthetic assets** in `game/assets/` for M2/M3. The current atlas is generated deterministically by `tools/fixtures/generate_synthetic_assets.py` and is explicitly recorded as `SYNTHETIC_FIXTURE` in the content manifest.

- Preserve native pixel dimensions and alpha.
- Use nearest-neighbour filtering (`default_texture_filter=0`).
- Generate `SpriteFrames` at runtime from JSON rectangles, offsets, origins, durations, and loop flags.
- Commit Godot `.import` metadata; ignore `.godot/imported/` and runtime `user://` data.
- Include `*.json`, `*.png`, and `*.svg` in export presets so non-resource files are packed.
- Never add CPK, APK, ZIP, or extracted FFBE assets to a public commit.

## Rationale

- Synthetic fixtures prove the import, validation, animation, and UI pipeline without relying on unresolved rights.
- A deterministic generator makes the small binary atlas reviewable and reproducible.
- Runtime-generated `AtlasTexture` resources avoid hand-authoring large `.tres` sprite-frame libraries.
- Explicit diagnostics for missing or invalid frames prevent silent frame substitution.

## Consequences

- The viewer does **not** demonstrate a restored FFBE animation; it demonstrates a validated synthetic prototype.
- Before any source-derived asset is added, rights, region, revision, checksum, and frame metadata must pass the import gate in [`supplemental-source-discovery.md`](../audit/supplemental-source-discovery.md).
- Lossy conversion or upscaling of source pixel art remains prohibited by default.
