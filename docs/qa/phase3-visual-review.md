# Phase 3 visual review

**Schema version:** 1  
**Capture tool:** `tools/qa/capture_phase3.sh`  
**Report generator:** `tools/qa/phase3_visual_report.py`

All images below are real captures from running Godot windows. The harness
records window geometry, ImageMagick pixel statistics and runtime error counts
in a `.txt` sidecar next to each PNG. Automated checks validate real-window
geometry, pixel variation and error-free runtime; subjective visual sign-off
remains a human QA task.

- Captures: 123
- Resolutions: 1024x640, 1280x720, 1920x1080
- Locales: en, ja, vi
- Runtime error lines across all captures: 0

## Captures

| Screenshot | Scene | Resolution | Locale | Geometry | Pixel statistics | Errors |
|---|---|---|---|---|---|---:|
| `docs/qa/screenshots/phase3/phase3-awakening-en-1024x640.png` | `res://scenes/phase3/awakening.tscn` | 1024x640 | `en` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=625 stddev=0.125432` | 0 |
| `docs/qa/screenshots/phase3/phase3-awakening-en-1280x720.png` | `res://scenes/phase3/awakening.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=601 stddev=0.133379` | 0 |
| `docs/qa/screenshots/phase3/phase3-awakening-en-1920x1080.png` | `res://scenes/phase3/awakening.tscn` | 1920x1080 | `en` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=651 stddev=0.137712` | 0 |
| `docs/qa/screenshots/phase3/phase3-awakening-ja-1024x640.png` | `res://scenes/phase3/awakening.tscn` | 1024x640 | `ja` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=634 stddev=0.115298` | 0 |
| `docs/qa/screenshots/phase3/phase3-awakening-ja-1280x720.png` | `res://scenes/phase3/awakening.tscn` | 1280x720 | `ja` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=641 stddev=0.122807` | 0 |
| `docs/qa/screenshots/phase3/phase3-awakening-ja-1920x1080.png` | `res://scenes/phase3/awakening.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=692 stddev=0.127373` | 0 |
| `docs/qa/screenshots/phase3/phase3-awakening-vi-1024x640.png` | `res://scenes/phase3/awakening.tscn` | 1024x640 | `vi` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=627 stddev=0.123092` | 0 |
| `docs/qa/screenshots/phase3/phase3-awakening-vi-1280x720.png` | `res://scenes/phase3/awakening.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=600 stddev=0.130943` | 0 |
| `docs/qa/screenshots/phase3/phase3-awakening-vi-1920x1080.png` | `res://scenes/phase3/awakening.tscn` | 1920x1080 | `vi` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=652 stddev=0.135126` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-abilities-en-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2845 stddev=0.132454` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-abilities-ja-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `ja` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2644 stddev=0.126346` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-abilities-vi-1024x640.png` | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `vi` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=2760 stddev=0.125626` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-abilities-vi-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2911 stddev=0.135902` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-chain-vi-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2982 stddev=0.13469` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-defeat-vi-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=3124 stddev=0.129776` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-en-1024x640.png` | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `en` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=2701 stddev=0.12238` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-en-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2845 stddev=0.131728` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-en-1920x1080.png` | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `en` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=2951 stddev=0.134419` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-formation-vi-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2497 stddev=0.139195` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-ja-1024x640.png` | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `ja` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=2493 stddev=0.11412` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-ja-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `ja` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2718 stddev=0.123538` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-ja-1920x1080.png` | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=3179 stddev=0.127863` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-limit-vi-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2980 stddev=0.1378` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-start-en-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2845 stddev=0.131728` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-start-ja-1920x1080.png` | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=2975 stddev=0.127359` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-start-vi-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2914 stddev=0.135233` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-vi-1024x640.png` | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `vi` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=2763 stddev=0.123924` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-vi-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=2914 stddev=0.134077` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-vi-1920x1080.png` | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `vi` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=3046 stddev=0.138053` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-victory-en-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=3044 stddev=0.132381` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-victory-ja-1920x1080.png` | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=3291 stddev=0.123194` | 0 |
| `docs/qa/screenshots/phase3/phase3-battle-victory-vi-1280x720.png` | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=3210 stddev=0.134612` | 0 |
| `docs/qa/screenshots/phase3/phase3-collection-en-1024x640.png` | `res://scenes/phase3/collection.tscn` | 1024x640 | `en` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=899 stddev=0.104783` | 0 |
| `docs/qa/screenshots/phase3/phase3-collection-en-1280x720.png` | `res://scenes/phase3/collection.tscn` | 1280x720 | `en` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=932 stddev=0.109752` | 0 |
| `docs/qa/screenshots/phase3/phase3-collection-en-1920x1080.png` | `res://scenes/phase3/collection.tscn` | 1920x1080 | `en` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=977 stddev=0.113421` | 0 |
| `docs/qa/screenshots/phase3/phase3-collection-ja-1024x640.png` | `res://scenes/phase3/collection.tscn` | 1024x640 | `ja` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=843 stddev=0.0842154` | 0 |
| `docs/qa/screenshots/phase3/phase3-collection-ja-1280x720.png` | `res://scenes/phase3/collection.tscn` | 1280x720 | `ja` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=849 stddev=0.0858416` | 0 |
| `docs/qa/screenshots/phase3/phase3-collection-ja-1920x1080.png` | `res://scenes/phase3/collection.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=963 stddev=0.0915177` | 0 |
| `docs/qa/screenshots/phase3/phase3-collection-vi-1024x640.png` | `res://scenes/phase3/collection.tscn` | 1024x640 | `vi` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=899 stddev=0.10753` | 0 |
| `docs/qa/screenshots/phase3/phase3-collection-vi-1280x720.png` | `res://scenes/phase3/collection.tscn` | 1280x720 | `vi` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=943 stddev=0.113109` | 0 |
| `docs/qa/screenshots/phase3/phase3-collection-vi-1920x1080.png` | `res://scenes/phase3/collection.tscn` | 1920x1080 | `vi` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=1108 stddev=0.116934` | 0 |
| `docs/qa/screenshots/phase3/phase3-details-en-1024x640.png` | `res://scenes/phase3/character_details.tscn` | 1024x640 | `en` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=549 stddev=0.161769` | 0 |
| `docs/qa/screenshots/phase3/phase3-details-en-1280x720.png` | `res://scenes/phase3/character_details.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=516 stddev=0.175294` | 0 |
| `docs/qa/screenshots/phase3/phase3-details-en-1920x1080.png` | `res://scenes/phase3/character_details.tscn` | 1920x1080 | `en` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=534 stddev=0.180485` | 0 |
| `docs/qa/screenshots/phase3/phase3-details-ja-1024x640.png` | `res://scenes/phase3/character_details.tscn` | 1024x640 | `ja` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=443 stddev=0.0923387` | 0 |
| `docs/qa/screenshots/phase3/phase3-details-ja-1280x720.png` | `res://scenes/phase3/character_details.tscn` | 1280x720 | `ja` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=450 stddev=0.0985713` | 0 |
| `docs/qa/screenshots/phase3/phase3-details-ja-1920x1080.png` | `res://scenes/phase3/character_details.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=514 stddev=0.103807` | 0 |
| `docs/qa/screenshots/phase3/phase3-details-vi-1024x640.png` | `res://scenes/phase3/character_details.tscn` | 1024x640 | `vi` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=555 stddev=0.162576` | 0 |
| `docs/qa/screenshots/phase3/phase3-details-vi-1280x720.png` | `res://scenes/phase3/character_details.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=524 stddev=0.176256` | 0 |
| `docs/qa/screenshots/phase3/phase3-details-vi-1920x1080.png` | `res://scenes/phase3/character_details.tscn` | 1920x1080 | `vi` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=534 stddev=0.125522` | 0 |
| `docs/qa/screenshots/phase3/phase3-equipment-en-1024x640.png` | `res://scenes/phase3/equipment.tscn` | 1024x640 | `en` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=661 stddev=0.0989703` | 0 |
| `docs/qa/screenshots/phase3/phase3-equipment-en-1280x720.png` | `res://scenes/phase3/equipment.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=656 stddev=0.0986657` | 0 |
| `docs/qa/screenshots/phase3/phase3-equipment-en-1920x1080.png` | `res://scenes/phase3/equipment.tscn` | 1920x1080 | `en` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=684 stddev=0.101466` | 0 |
| `docs/qa/screenshots/phase3/phase3-equipment-ja-1024x640.png` | `res://scenes/phase3/equipment.tscn` | 1024x640 | `ja` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=643 stddev=0.0830773` | 0 |
| `docs/qa/screenshots/phase3/phase3-equipment-ja-1280x720.png` | `res://scenes/phase3/equipment.tscn` | 1280x720 | `ja` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=638 stddev=0.0805683` | 0 |
| `docs/qa/screenshots/phase3/phase3-equipment-ja-1920x1080.png` | `res://scenes/phase3/equipment.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=701 stddev=0.0859669` | 0 |
| `docs/qa/screenshots/phase3/phase3-equipment-vi-1024x640.png` | `res://scenes/phase3/equipment.tscn` | 1024x640 | `vi` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=702 stddev=0.107053` | 0 |
| `docs/qa/screenshots/phase3/phase3-equipment-vi-1280x720.png` | `res://scenes/phase3/equipment.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=684 stddev=0.107778` | 0 |
| `docs/qa/screenshots/phase3/phase3-equipment-vi-1920x1080.png` | `res://scenes/phase3/equipment.tscn` | 1920x1080 | `vi` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=715 stddev=0.111136` | 0 |
| `docs/qa/screenshots/phase3/phase3-main-menu-en-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `en` | window=134217735 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=210 stddev=0.0651302` | 0 |
| `docs/qa/screenshots/phase3/phase3-main-menu-en-1920x1080.png` | `res://scenes/menu/main_menu.tscn` | 1920x1080 | `en` | window=134217735 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=210 stddev=0.0665717` | 0 |
| `docs/qa/screenshots/phase3/phase3-main-menu-ja-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `ja` | window=134217735 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=209 stddev=0.0494035` | 0 |
| `docs/qa/screenshots/phase3/phase3-main-menu-ja-1920x1080.png` | `res://scenes/menu/main_menu.tscn` | 1920x1080 | `ja` | window=134217735 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=210 stddev=0.0507753` | 0 |
| `docs/qa/screenshots/phase3/phase3-main-menu-vi-1024x640.png` | `res://scenes/menu/main_menu.tscn` | 1024x640 | `vi` | window=134217735 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=210 stddev=0.0642076` | 0 |
| `docs/qa/screenshots/phase3/phase3-main-menu-vi-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `vi` | window=134217735 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=210 stddev=0.0689365` | 0 |
| `docs/qa/screenshots/phase3/phase3-main-menu-vi-1920x1080.png` | `res://scenes/menu/main_menu.tscn` | 1920x1080 | `vi` | window=134217735 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=210 stddev=0.0703716` | 0 |
| `docs/qa/screenshots/phase3/phase3-menu-en-1024x640.png` | `res://scenes/menu/main_menu.tscn` | 1024x640 | `en` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=210 stddev=0.0607927` | 0 |
| `docs/qa/screenshots/phase3/phase3-menu-en-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `en` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=210 stddev=0.0651302` | 0 |
| `docs/qa/screenshots/phase3/phase3-menu-en-1920x1080.png` | `res://scenes/menu/main_menu.tscn` | 1920x1080 | `en` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=210 stddev=0.0649716` | 0 |
| `docs/qa/screenshots/phase3/phase3-menu-ja-1024x640.png` | `res://scenes/menu/main_menu.tscn` | 1024x640 | `ja` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=206 stddev=0.0455774` | 0 |
| `docs/qa/screenshots/phase3/phase3-menu-ja-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `ja` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=209 stddev=0.0494035` | 0 |
| `docs/qa/screenshots/phase3/phase3-menu-ja-1920x1080.png` | `res://scenes/menu/main_menu.tscn` | 1920x1080 | `ja` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=210 stddev=0.0507753` | 0 |
| `docs/qa/screenshots/phase3/phase3-menu-vi-1024x640.png` | `res://scenes/menu/main_menu.tscn` | 1024x640 | `vi` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=210 stddev=0.0642076` | 0 |
| `docs/qa/screenshots/phase3/phase3-menu-vi-1280x720.png` | `res://scenes/menu/main_menu.tscn` | 1280x720 | `vi` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=210 stddev=0.0673829` | 0 |
| `docs/qa/screenshots/phase3/phase3-menu-vi-1920x1080.png` | `res://scenes/menu/main_menu.tscn` | 1920x1080 | `vi` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=210 stddev=0.0703716` | 0 |
| `docs/qa/screenshots/phase3/phase3-party-en-1024x640.png` | `res://scenes/phase3/party.tscn` | 1024x640 | `en` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=710 stddev=0.117197` | 0 |
| `docs/qa/screenshots/phase3/phase3-party-en-1280x720.png` | `res://scenes/phase3/party.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=719 stddev=0.112555` | 0 |
| `docs/qa/screenshots/phase3/phase3-party-en-1920x1080.png` | `res://scenes/phase3/party.tscn` | 1920x1080 | `en` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=752 stddev=0.131171` | 0 |
| `docs/qa/screenshots/phase3/phase3-party-ja-1024x640.png` | `res://scenes/phase3/party.tscn` | 1024x640 | `ja` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=603 stddev=0.0940445` | 0 |
| `docs/qa/screenshots/phase3/phase3-party-ja-1280x720.png` | `res://scenes/phase3/party.tscn` | 1280x720 | `ja` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=640 stddev=0.101107` | 0 |
| `docs/qa/screenshots/phase3/phase3-party-ja-1920x1080.png` | `res://scenes/phase3/party.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=8590 stddev=0.16216` | 0 |
| `docs/qa/screenshots/phase3/phase3-party-vi-1024x640.png` | `res://scenes/phase3/party.tscn` | 1024x640 | `vi` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=754 stddev=0.129664` | 0 |
| `docs/qa/screenshots/phase3/phase3-party-vi-1280x720.png` | `res://scenes/phase3/party.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=747 stddev=0.140022` | 0 |
| `docs/qa/screenshots/phase3/phase3-party-vi-1920x1080.png` | `res://scenes/phase3/party.tscn` | 1920x1080 | `vi` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=779 stddev=0.144875` | 0 |
| `docs/qa/screenshots/phase3/phase3-settings-en-1024x640.png` | `res://scenes/settings/settings.tscn` | 1024x640 | `en` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=213 stddev=0.0531523` | 0 |
| `docs/qa/screenshots/phase3/phase3-settings-en-1280x720.png` | `res://scenes/settings/settings.tscn` | 1280x720 | `en` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0581763` | 0 |
| `docs/qa/screenshots/phase3/phase3-settings-en-1920x1080.png` | `res://scenes/settings/settings.tscn` | 1920x1080 | `en` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=213 stddev=0.0638599` | 0 |
| `docs/qa/screenshots/phase3/phase3-settings-ja-1024x640.png` | `res://scenes/settings/settings.tscn` | 1024x640 | `ja` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=213 stddev=0.0400507` | 0 |
| `docs/qa/screenshots/phase3/phase3-settings-ja-1280x720.png` | `res://scenes/settings/settings.tscn` | 1280x720 | `ja` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0437998` | 0 |
| `docs/qa/screenshots/phase3/phase3-settings-ja-1920x1080.png` | `res://scenes/settings/settings.tscn` | 1920x1080 | `ja` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=213 stddev=0.0449312` | 0 |
| `docs/qa/screenshots/phase3/phase3-settings-vi-1024x640.png` | `res://scenes/settings/settings.tscn` | 1024x640 | `vi` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=212 stddev=0.0522075` | 0 |
| `docs/qa/screenshots/phase3/phase3-settings-vi-1280x720.png` | `res://scenes/settings/settings.tscn` | 1280x720 | `vi` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0572954` | 0 |
| `docs/qa/screenshots/phase3/phase3-settings-vi-1920x1080.png` | `res://scenes/settings/settings.tscn` | 1920x1080 | `vi` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=212 stddev=0.0583554` | 0 |
| `docs/qa/screenshots/phase3/phase3-upgrade-en-1024x640.png` | `res://scenes/phase3/upgrade.tscn` | 1024x640 | `en` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=548 stddev=0.10227` | 0 |
| `docs/qa/screenshots/phase3/phase3-upgrade-en-1280x720.png` | `res://scenes/phase3/upgrade.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=528 stddev=0.109398` | 0 |
| `docs/qa/screenshots/phase3/phase3-upgrade-en-1920x1080.png` | `res://scenes/phase3/upgrade.tscn` | 1920x1080 | `en` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=543 stddev=0.112949` | 0 |
| `docs/qa/screenshots/phase3/phase3-upgrade-ja-1024x640.png` | `res://scenes/phase3/upgrade.tscn` | 1024x640 | `ja` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=533 stddev=0.0870138` | 0 |
| `docs/qa/screenshots/phase3/phase3-upgrade-ja-1280x720.png` | `res://scenes/phase3/upgrade.tscn` | 1280x720 | `ja` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=729 stddev=0.0680527` | 0 |
| `docs/qa/screenshots/phase3/phase3-upgrade-ja-1920x1080.png` | `res://scenes/phase3/upgrade.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=543 stddev=0.0730038` | 0 |
| `docs/qa/screenshots/phase3/phase3-upgrade-vi-1024x640.png` | `res://scenes/phase3/upgrade.tscn` | 1024x640 | `vi` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=553 stddev=0.108584` | 0 |
| `docs/qa/screenshots/phase3/phase3-upgrade-vi-1280x720.png` | `res://scenes/phase3/upgrade.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=533 stddev=0.0932171` | 0 |
| `docs/qa/screenshots/phase3/phase3-upgrade-vi-1920x1080.png` | `res://scenes/phase3/upgrade.tscn` | 1920x1080 | `vi` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=544 stddev=0.119772` | 0 |
| `docs/qa/screenshots/phase3/phase3-viewer-en-1024x640.png` | `res://scenes/viewer/character_viewer.tscn` | 1024x640 | `en` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=213 stddev=0.0856975` | 0 |
| `docs/qa/screenshots/phase3/phase3-viewer-en-1280x720.png` | `res://scenes/viewer/character_viewer.tscn` | 1280x720 | `en` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0887967` | 0 |
| `docs/qa/screenshots/phase3/phase3-viewer-en-1920x1080.png` | `res://scenes/viewer/character_viewer.tscn` | 1920x1080 | `en` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=213 stddev=0.09306` | 0 |
| `docs/qa/screenshots/phase3/phase3-viewer-ja-1024x640.png` | `res://scenes/viewer/character_viewer.tscn` | 1024x640 | `ja` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=213 stddev=0.0741586` | 0 |
| `docs/qa/screenshots/phase3/phase3-viewer-ja-1280x720.png` | `res://scenes/viewer/character_viewer.tscn` | 1280x720 | `ja` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0745333` | 0 |
| `docs/qa/screenshots/phase3/phase3-viewer-ja-1920x1080.png` | `res://scenes/viewer/character_viewer.tscn` | 1920x1080 | `ja` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=213 stddev=0.0789148` | 0 |
| `docs/qa/screenshots/phase3/phase3-viewer-vi-1024x640.png` | `res://scenes/viewer/character_viewer.tscn` | 1024x640 | `vi` | window=75497479 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=213 stddev=0.0867285` | 0 |
| `docs/qa/screenshots/phase3/phase3-viewer-vi-1280x720.png` | `res://scenes/viewer/character_viewer.tscn` | 1280x720 | `vi` | window=75497479 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=213 stddev=0.0900844` | 0 |
| `docs/qa/screenshots/phase3/phase3-viewer-vi-1920x1080.png` | `res://scenes/viewer/character_viewer.tscn` | 1920x1080 | `vi` | window=75497479 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=213 stddev=0.0930197` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-card-en-1280x720.png` | `res://scenes/phase3/vision_card.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=839 stddev=0.113333` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-card-ja-1280x720.png` | `res://scenes/phase3/vision_card.tscn` | 1280x720 | `ja` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=806 stddev=0.0965412` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-card-vi-1280x720.png` | `res://scenes/phase3/vision_card.tscn` | 1280x720 | `vi` | window=134217735 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=874 stddev=0.116961` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-en-1024x640.png` | `res://scenes/phase3/vision_card.tscn` | 1024x640 | `en` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=1035 stddev=0.10755` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-en-1280x720.png` | `res://scenes/phase3/vision_card.tscn` | 1280x720 | `en` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=839 stddev=0.113333` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-en-1920x1080.png` | `res://scenes/phase3/vision_card.tscn` | 1920x1080 | `en` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=870 stddev=0.116698` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-ja-1024x640.png` | `res://scenes/phase3/vision_card.tscn` | 1024x640 | `ja` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=842 stddev=0.0909132` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-ja-1280x720.png` | `res://scenes/phase3/vision_card.tscn` | 1280x720 | `ja` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=806 stddev=0.0965412` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-ja-1920x1080.png` | `res://scenes/phase3/vision_card.tscn` | 1920x1080 | `ja` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=868 stddev=0.10051` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-vi-1024x640.png` | `res://scenes/phase3/vision_card.tscn` | 1024x640 | `vi` | window=146800647 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0  | `1024x640 colors=1023 stddev=0.110935` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-vi-1280x720.png` | `res://scenes/phase3/vision_card.tscn` | 1280x720 | `vi` | window=146800647 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0  | `1280x720 colors=874 stddev=0.117164` | 0 |
| `docs/qa/screenshots/phase3/phase3-vision-vi-1920x1080.png` | `res://scenes/phase3/vision_card.tscn` | 1920x1080 | `vi` | window=146800647 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0  | `1920x1080 colors=897 stddev=0.120651` | 0 |

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
