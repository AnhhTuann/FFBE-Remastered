# Phase 3 visual review

**Schema version:** 1  
**Capture tool:** `tools/qa/capture_phase3.sh`  
**Report generator:** `tools/qa/phase3_visual_report.py`

All images below are real captures from running Godot windows. The harness
records window geometry, ImageMagick pixel statistics and runtime error counts
in a `.txt` sidecar next to each PNG. Automated checks validate real-window
geometry, metadata presence and recorded runtime error counts. Pixel statistics
are recorded for review but are not threshold-gated; subjective visual sign-off
remains a human QA task.

- Captures: 30
- Resolutions: 1024x640, 1280x720, 1920x1080
- Locales: en, ja, vi
- Runtime error lines across all captures: 0

## Captures

| Screenshot | Scene | Resolution | Locale | Geometry | Pixel statistics | Errors |
|---|---|---|---|---|---|---:|
| `docs/qa/screenshots/hardening/hardening-battle-abilities-en-1024x640.png` | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `en` | window=178257927 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=2483 stddev=0.122849` | 0 |
| `docs/qa/screenshots/hardening/hardening-battle-abilities-en-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `en` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2680 stddev=0.135589` | 0 |
| `docs/qa/screenshots/hardening/hardening-battle-abilities-en-1920x1080.png` | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `en` | window=178257927 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=2938 stddev=0.136669` | 0 |
| `docs/qa/screenshots/hardening/hardening-battle-abilities-ja-1024x640.png` | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `ja` | window=178257927 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=2126 stddev=0.114924` | 0 |
| `docs/qa/screenshots/hardening/hardening-battle-abilities-ja-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `ja` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2364 stddev=0.127277` | 0 |
| `docs/qa/screenshots/hardening/hardening-battle-abilities-ja-1920x1080.png` | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `ja` | window=178257927 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=2629 stddev=0.129105` | 0 |
| `docs/qa/screenshots/hardening/hardening-battle-abilities-vi-1024x640.png` | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `vi` | window=178257927 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=2486 stddev=0.124311` | 0 |
| `docs/qa/screenshots/hardening/hardening-battle-abilities-vi-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2675 stddev=0.135307` | 0 |
| `docs/qa/screenshots/hardening/hardening-battle-abilities-vi-1920x1080.png` | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `vi` | window=178257927 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=2803 stddev=0.138427` | 0 |
| `docs/qa/screenshots/hardening/hardening-collection-en-1280x720.png` | `res://scenes/phase3/collection.tscn` | 1280x720 | `en` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=932 stddev=0.109628` | 0 |
| `docs/qa/screenshots/hardening/hardening-collection-ja-1280x720.png` | `res://scenes/phase3/collection.tscn` | 1280x720 | `ja` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=849 stddev=0.0858547` | 0 |
| `docs/qa/screenshots/hardening/hardening-collection-vi-1280x720.png` | `res://scenes/phase3/collection.tscn` | 1280x720 | `vi` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=943 stddev=0.114712` | 0 |
| `docs/qa/screenshots/hardening/hardening-details-en-1280x720.png` | `res://scenes/phase3/character_details.tscn` | 1280x720 | `en` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=516 stddev=0.130062` | 0 |
| `docs/qa/screenshots/hardening/hardening-details-ja-1280x720.png` | `res://scenes/phase3/character_details.tscn` | 1280x720 | `ja` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=451 stddev=0.10338` | 0 |
| `docs/qa/screenshots/hardening/hardening-details-vi-1280x720.png` | `res://scenes/phase3/character_details.tscn` | 1280x720 | `vi` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=526 stddev=0.189071` | 0 |
| `docs/qa/screenshots/hardening/hardening-equipment-en-1280x720.png` | `res://scenes/phase3/equipment.tscn` | 1280x720 | `en` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=657 stddev=0.110662` | 0 |
| `docs/qa/screenshots/hardening/hardening-equipment-ja-1280x720.png` | `res://scenes/phase3/equipment.tscn` | 1280x720 | `ja` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=642 stddev=0.0848108` | 0 |
| `docs/qa/screenshots/hardening/hardening-equipment-vi-1280x720.png` | `res://scenes/phase3/equipment.tscn` | 1280x720 | `vi` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=688 stddev=0.119532` | 0 |
| `docs/qa/screenshots/hardening/hardening-menu-en-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `en` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=210 stddev=0.0651302` | 0 |
| `docs/qa/screenshots/hardening/hardening-menu-ja-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `ja` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=209 stddev=0.0494035` | 0 |
| `docs/qa/screenshots/hardening/hardening-menu-vi-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `vi` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=210 stddev=0.0689365` | 0 |
| `docs/qa/screenshots/hardening/hardening-settings-en-1280x720.png` | `res://scenes/settings/settings.tscn` | 1280x720 | `en` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0581763` | 0 |
| `docs/qa/screenshots/hardening/hardening-settings-ja-1280x720.png` | `res://scenes/settings/settings.tscn` | 1280x720 | `ja` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0437998` | 0 |
| `docs/qa/screenshots/hardening/hardening-settings-vi-1280x720.png` | `res://scenes/settings/settings.tscn` | 1280x720 | `vi` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0572954` | 0 |
| `docs/qa/screenshots/hardening/hardening-viewer-en-1280x720.png` | `res://scenes/viewer/character_viewer.tscn` | 1280x720 | `en` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0955585` | 0 |
| `docs/qa/screenshots/hardening/hardening-viewer-ja-1280x720.png` | `res://scenes/viewer/character_viewer.tscn` | 1280x720 | `ja` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0683405` | 0 |
| `docs/qa/screenshots/hardening/hardening-viewer-vi-1280x720.png` | `res://scenes/viewer/character_viewer.tscn` | 1280x720 | `vi` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0958084` | 0 |
| `docs/qa/screenshots/hardening/hardening-vision-en-1280x720.png` | `res://scenes/phase3/vision_card.tscn` | 1280x720 | `en` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=679 stddev=0.10309` | 0 |
| `docs/qa/screenshots/hardening/hardening-vision-ja-1280x720.png` | `res://scenes/phase3/vision_card.tscn` | 1280x720 | `ja` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=806 stddev=0.0988557` | 0 |
| `docs/qa/screenshots/hardening/hardening-vision-vi-1280x720.png` | `res://scenes/phase3/vision_card.tscn` | 1280x720 | `vi` | window=178257927 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=646 stddev=0.108879` | 0 |

## Reproduction

Each capture is reproducible with the same environment and scene. Example:

```sh
NAME=phase3-main-menu-vi-1280x720 \
  SCENE=res://scenes/menu/main_menu.tscn RES=1280x720 LOCALE=vi \
  ./tools/qa/capture_phase3.sh
python3 tools/qa/phase3_visual_report.py
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
