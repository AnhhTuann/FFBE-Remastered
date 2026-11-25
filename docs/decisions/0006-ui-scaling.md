# ADR 0006 — UI scaling and responsive layout

- **Status:** Accepted for M2/M3
- **Date:** 2026-11-25
- **Context:** The game targets resizable desktop windows with a 1280×720 baseline and a 1920×1080 QA viewport. It must not assume mobile-only input or fixed pixel positions.

## Decision

- Use `Control` roots with `VBoxContainer` / `HBoxContainer`, anchors, and margins rather than absolute coordinates.
- Set the project viewport to 1280×720, resizable, with `window/stretch/mode="canvas_items"` and `aspect="expand"`.
- Validate at 1920×1080 in QA.
- Use nearest-neighbour texture filtering and 2D pixel snapping for sprite presentation.
- Keep keyboard and mouse input resolution-independent through Godot Input Map actions and Control focus.
- Prefer readable default theme fonts; no proprietary UI art is used.

## Rationale

- Container-driven layout survives resizing without per-resolution scene variants.
- `canvas_items` stretching keeps UI text crisp while scaling the game canvas predictably.
- `expand` avoids forced letterboxing on 16:9 desktop windows.
- Explicit focus order supports keyboard-only navigation.

## Consequences

- Scene files must keep container nodes and avoid hardcoded control rectangles for primary UI.
- Visual QA must record actual window sizes; mockups are not evidence.
- If a future HUD needs pixel-perfect battle framing, add a dedicated sub-container rather than changing the global stretch mode.
