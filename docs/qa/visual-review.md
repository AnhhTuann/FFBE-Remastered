# Visual and GUI QA review — Phase 1

**Date:** 2026-11-25
**Display:** X11 `:0`, 1920×1080, NVIDIA GeForce GTX 1660 Ti, Godot Compatibility renderer.
**Screenshots:** real captures of the running Godot project; no mockups or rendered-on-paper previews.

## 1. Sessions run

| Launch command | Window geometry | Screenshot |
|---|---|---|
| `godot --path game --windowed --resolution 1280x720 --position 0,0` (default boot scene) | 1280×720 at (0,70) | `screenshots/default-boot-to-menu-1280x720.png` |
| `godot --path game --windowed --resolution 1280x720 --position 0,0 --scene res://scenes/menu/main_menu.tscn` | 1280×720 at (0,70) | `screenshots/main-menu-1280x720.png` |
| `godot --path game --windowed --resolution 1280x720 --position 0,0 --scene res://scenes/viewer/character_viewer.tscn` | 1280×720 at (0,70) | `screenshots/character-viewer-1280x720.png` |
| `godot --path game --fullscreen --resolution 1920x1080 --scene res://scenes/viewer/character_viewer.tscn` | 1920×1080 at (0,0) | `screenshots/character-viewer-1920x1080.png` |
| `godot --path game --windowed --resolution 1280x720 --position 0,0 --scene res://scenes/settings/settings.tscn` | 1280×720 at (0,70) | `screenshots/settings-1280x720.png` |

Each screenshot was captured with `import -window <window-id>` after a 4–5 second wait. Window identity and geometry were read with `xdotool search --onlyvisible --name 'FFBE Remastered'` and `xdotool getwindowgeometry`.

## 2. Image checks

| Screenshot | Dimensions | Colours | Standard deviation |
|---|---|---:|---:|
| `default-boot-to-menu-1280x720.png` | 1280×720 | 208 | 0.0671 |
| `main-menu-1280x720.png` | 1280×720 | 208 | 0.0671 |
| `character-viewer-1280x720.png` | 1280×720 | 213 | 0.0867 |
| `character-viewer-1920x1080.png` | 1920×1080 | 213 | 0.0882 |
| `settings-1280x720.png` | 1280×720 | 211 | 0.0608 |

The non-trivial colour counts and standard deviations show that the captured windows contain rendered UI rather than blank/black frames. The boot-flow capture and the direct main-menu capture have identical image statistics, consistent with the boot scene transitioning to the menu.

Every GUI log was scanned for `SCRIPT ERROR`, leading `ERROR:`, and `WARNING:`; none of the five final sessions produced any of these lines. Earlier parser findings were fixed and are documented in `test-report.md`.

## 3. Interaction evidence

Deterministic interaction checks were performed headlessly by `test_viewer_scene_behavior` in `game/tests/test_runner.gd`:

- all four units listed, first selection `unit:GL:900001@base`;
- JP filter reduces the list to one unit and selects `unit:JP:900001@base`;
- playback starts, pauses, and restarts;
- clip switch selects `attack` and confirms `loop = false`;
- selecting the deliberate `unit:GL:900003@base` fixture shows `Missing animation metadata` and stops playback.

These checks verify behaviour; the screenshots verify that the same scenes render in a real window at two viewport sizes.

## 4. Honest limitations

- The model performing this QA could not visually inspect the images (image input unsupported in this session). Therefore no subjective claim about colour harmony, spacing, or aesthetic quality is made. The evidence above is file metadata, window geometry, log cleanliness, and code-level interaction assertions.
- OCR was not used: `tesseract` is present but the `eng.traineddata` language file is missing, so text extraction would be unreliable. Screen text assertions are covered by the headless scene tests instead.
- A windowed 1920×1080 request was constrained by the desktop panel to 1920×950; the final 1920×1080 capture used fullscreen instead.
- No Windows runtime was launched; no export template exists for that platform.
- All displayed content is `SYNTHETIC_FIXTURE`; no restored FFBE art is shown.
