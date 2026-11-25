---
name: ffbe-godot-foundation
description: Implement Godot 4 GDScript architecture, scenes, data resources, pixel-art animation and desktop RPG UI after audit approval.
---
# Godot foundation for FFBE

Read the roadmap and verify the pinned Godot version using project.godot and the installed binary. Consult https://docs.godotengine.org/en/stable/ and matching version docs; do not assume newer APIs.

- Prefer typed GDScript, explicit return types, small cohesive scenes and composition over inheritance. Use signals for presentation events and narrow autoload services. Avoid global mutable gameplay state.
- Keep simulation, data repositories and scenes separate. Use stable region-aware IDs and immutable definitions; do not mutate shared Resource instances as player state. Evaluate SQLite packaging versus generated resources on both platforms before choosing.
- Define reusable character, battle and UI scenes. Use Sprite2D/AnimatedSprite2D and SpriteFrames with validated atlas metadata. Preserve transparency, offsets and nearest-neighbor filtering for pixel art.
- Use Control and Container nodes for responsive menus, explicit keyboard/controller focus, readable text and scalable HUDs. Keep mouse and keyboard input independent of resolution. Validate on desktop window sizes; no mobile-only UI assumptions.
- Use TileMapLayer or other supported map APIs only after source availability and engine compatibility are verified.
- Keep player saves under user://. Verify res:// path casing and export inclusion. No mandatory online services.
- Run headless import, script checks and relevant tests before declaring success. Run actual desktop builds for visual and platform checks. If Godot or export templates are absent, report BLOCKED rather than claiming a build.
- Do not start M2 or gameplay during the M0/M1 audit.
