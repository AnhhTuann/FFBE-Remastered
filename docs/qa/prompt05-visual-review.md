# Prompt 05 visual review

**Capture tool:** `tools/qa/capture_phase3.sh`\
**Report generator:** `tools/qa/prompt05_visual_report.py`

All images below are real captures from running Godot windows. The harness
records window geometry, ImageMagick pixel statistics and runtime error counts
in a `.txt` sidecar next to each PNG. Automated checks validate real-window
geometry, metadata presence and recorded runtime error counts. Pixel statistics
are recorded for review but are not threshold-gated; subjective visual sign-off
remains a human QA task.

- Captures: 19
- Resolutions: 1024x640, 1280x720, 1920x1080
- Locales: en, ja, vi
- Runtime error lines across all captures: 0

## Captures

| Screenshot | Scene | Resolution | Locale | Geometry | Pixel statistics | Errors |
|---|---|---|---|---|---|---:|
| `docs/qa/screenshots/prompt05/prompt05-battle-vi-1920x1080.png` | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `vi` | window=199229447 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1411 stddev=0.0609967` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-boot-offline-vi-1280x720.png` | `boot` | 1280x720 | `vi` | window=211812359 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=210 stddev=0.0712129` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-crafting-vi-1280x720.png` | `res://scenes/phase3/crafting.tscn` | 1280x720 | `vi` | window=199229447 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=938 stddev=0.125414` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-economy-en-1280x720.png` | `res://scenes/phase3/economy_hub.tscn` | 1280x720 | `en` | window=199229447 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=506 stddev=0.121924` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-economy-ja-1280x720.png` | `res://scenes/phase3/economy_hub.tscn` | 1280x720 | `ja` | window=199229447 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=434 stddev=0.0937519` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-economy-vi-1024x640.png` | `res://scenes/phase3/economy_hub.tscn` | 1024x640 | `vi` | window=199229447 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=655 stddev=0.119955` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-economy-vi-1280x720.png` | `res://scenes/phase3/economy_hub.tscn` | 1280x720 | `vi` | window=199229447 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=593 stddev=0.127128` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-economy-vi-1920x1080.png` | `res://scenes/phase3/economy_hub.tscn` | 1920x1080 | `vi` | window=199229447 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=639 stddev=0.131141` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-esper-en-1280x720.png` | `res://scenes/phase3/esper_management.tscn` | 1280x720 | `en` | window=199229447 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1212 stddev=0.125151` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-esper-ja-1280x720.png` | `res://scenes/phase3/esper_management.tscn` | 1280x720 | `ja` | window=199229447 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1038 stddev=0.0902045` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-esper-vi-1024x640.png` | `res://scenes/phase3/esper_management.tscn` | 1024x640 | `vi` | window=199229447 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1270 stddev=0.129478` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-esper-vi-1280x720.png` | `res://scenes/phase3/esper_management.tscn` | 1280x720 | `vi` | window=199229447 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1339 stddev=0.136045` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-menu-en-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `en` | window=211812359 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=210 stddev=0.0676308` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-menu-ja-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `ja` | window=211812359 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=209 stddev=0.0518002` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-menu-vi-1024x640.png` | `res://scenes/menu/main_menu.tscn` | 1024x640 | `vi` | window=211812359 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=210 stddev=0.066945` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-menu-vi-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `vi` | window=211812359 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=210 stddev=0.0712129` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-menu-vi-1920x1080.png` | `res://scenes/menu/main_menu.tscn` | 1920x1080 | `vi` | window=211812359 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=210 stddev=0.0726541` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-shop-vi-1280x720.png` | `res://scenes/phase3/shop.tscn` | 1280x720 | `vi` | window=199229447 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=680 stddev=0.0819451` | 0 |
| `docs/qa/screenshots/prompt05/prompt05-summon-vi-1280x720.png` | `res://scenes/phase3/summon.tscn` | 1280x720 | `vi` | window=199229447 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=693 stddev=0.145162` | 0 |

## Reproduction

Each capture is reproducible with the same environment and scene. Example:

```sh
NAME=prompt05-esper-vi-1280x720 \
  SCENE=res://scenes/phase3/esper_management.tscn RES=1280x720 LOCALE=vi \
  QA_SHOT_DIR=docs/qa/screenshots/prompt05 \
  ./tools/qa/capture_phase3.sh
python3 tools/qa/prompt05_visual_report.py
```

Optional capture variables: `SCENARIO`, `INSTANCE_ID`, `PARTY_ID`,
`ENCOUNTER`, `SEED`, `FREEZE_FRAME`, `FULLSCREEN=1`, and `WAIT_SECONDS`.
`FFBE_QA_LOCALE` is a QA-only starting-locale override and does not write
player settings; normal locale switching remains available in Settings.

## Limitations

- Distinct pixel statistics and zero error lines prove renders occurred; they
  do not prove subjective layout quality or text readability.
- Fullscreen 1920×1080 captures are taken at `(0,0)` when `FULLSCREEN=1`;
  windowed captures include desktop decoration offsets recorded in metadata.
- No mockups or composited images are used.
