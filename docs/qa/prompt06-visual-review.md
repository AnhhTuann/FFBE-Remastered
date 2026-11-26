# Prompt 06 world exploration visual review

**Schema version:** 1
**Capture tool:** `tools/qa/capture_prompt06.sh`
**Report generator:** `tools/qa/prompt06_visual_report.py`

All images below are real captures from running Godot windows. Each capture uses a
fresh isolated `user://` profile, so no owner save is read or modified. The harness
records window geometry, ImageMagick pixel statistics and runtime error counts in a
`.txt` sidecar next to each PNG. This report validates the complete scenario ×
resolution × locale matrix and requires zero runtime error lines. Pixel statistics
are recorded for review but are not threshold-gated; subjective visual sign-off
remains a human QA task.

- Captures: 117
- Scenarios: 13
- Resolutions: 1024x640, 1280x720, 1920x1080
- Locales: vi, en, ja
- Runtime error lines across all captures: 0

## Coverage matrix

| Scenario | Resolutions | Locales | Captures |
|---|---|---|---:|
| World Map | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| World Map selected location | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| Hub exploration | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| NPC dialogue | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| NPC dialogue choice page | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| Quest journal | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| Treasure interaction | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| Battle transition | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| Quest completion | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| Battle victory | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| Battle defeat | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| Battle Retry available | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |
| Battle return state | 1024x640, 1280x720, 1920x1080 | vi, en, ja | 9 |

## Captures

| Screenshot | Scenario | Scene | Resolution | Locale | Geometry | Pixels | Errors |
|---|---|---|---|---|---|---|---:|
| `docs/qa/screenshots/prompt06/prompt06-world_map-vi-1024x640.png` | World Map | `res://scenes/world/world_map.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=404 stddev=0.0963775` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-world_map-en-1024x640.png` | World Map | `res://scenes/world/world_map.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=463 stddev=0.0902994` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-world_map-ja-1024x640.png` | World Map | `res://scenes/world/world_map.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=369 stddev=0.0653358` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-world_map-vi-1280x720.png` | World Map | `res://scenes/world/world_map.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=451 stddev=0.100525` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-world_map-en-1280x720.png` | World Map | `res://scenes/world/world_map.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=445 stddev=0.0964287` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-world_map-ja-1280x720.png` | World Map | `res://scenes/world/world_map.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=398 stddev=0.0668321` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-world_map-vi-1920x1080.png` | World Map | `res://scenes/world/world_map.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=475 stddev=0.10226` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-world_map-en-1920x1080.png` | World Map | `res://scenes/world/world_map.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=458 stddev=0.0986754` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-world_map-ja-1920x1080.png` | World Map | `res://scenes/world/world_map.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=468 stddev=0.0692514` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-selected-vi-1024x640.png` | World Map selected location | `res://scenes/world/world_map.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=404 stddev=0.0963775` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-selected-en-1024x640.png` | World Map selected location | `res://scenes/world/world_map.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=400 stddev=0.0933569` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-selected-ja-1024x640.png` | World Map selected location | `res://scenes/world/world_map.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=367 stddev=0.0678559` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-selected-vi-1280x720.png` | World Map selected location | `res://scenes/world/world_map.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=416 stddev=0.102249` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-selected-en-1280x720.png` | World Map selected location | `res://scenes/world/world_map.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=397 stddev=0.100157` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-selected-ja-1280x720.png` | World Map selected location | `res://scenes/world/world_map.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=383 stddev=0.0701222` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-selected-vi-1920x1080.png` | World Map selected location | `res://scenes/world/world_map.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=439 stddev=0.105991` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-selected-en-1920x1080.png` | World Map selected location | `res://scenes/world/world_map.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=420 stddev=0.102617` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-selected-ja-1920x1080.png` | World Map selected location | `res://scenes/world/world_map.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=439 stddev=0.0728265` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-hub-vi-1024x640.png` | Hub exploration | `res://scenes/world/exploration_area.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=502 stddev=0.07725` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-hub-en-1024x640.png` | Hub exploration | `res://scenes/world/exploration_area.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=480 stddev=0.076756` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-hub-ja-1024x640.png` | Hub exploration | `res://scenes/world/exploration_area.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=367 stddev=0.0655835` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-hub-vi-1280x720.png` | Hub exploration | `res://scenes/world/exploration_area.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=494 stddev=0.0787965` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-hub-en-1280x720.png` | Hub exploration | `res://scenes/world/exploration_area.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=495 stddev=0.0779366` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-hub-ja-1280x720.png` | Hub exploration | `res://scenes/world/exploration_area.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=406 stddev=0.0657018` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-hub-vi-1920x1080.png` | Hub exploration | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=499 stddev=0.0787188` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-hub-en-1920x1080.png` | Hub exploration | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=495 stddev=0.0777601` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-hub-ja-1920x1080.png` | Hub exploration | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=473 stddev=0.0649147` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc-vi-1024x640.png` | NPC dialogue | `res://scenes/world/exploration_area.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1258 stddev=0.0826632` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc-en-1024x640.png` | NPC dialogue | `res://scenes/world/exploration_area.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1144 stddev=0.0803503` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc-ja-1024x640.png` | NPC dialogue | `res://scenes/world/exploration_area.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=809 stddev=0.0613399` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc-vi-1280x720.png` | NPC dialogue | `res://scenes/world/exploration_area.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1370 stddev=0.0861541` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc-en-1280x720.png` | NPC dialogue | `res://scenes/world/exploration_area.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1316 stddev=0.0833348` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc-ja-1280x720.png` | NPC dialogue | `res://scenes/world/exploration_area.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1040 stddev=0.062349` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc-vi-1920x1080.png` | NPC dialogue | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1302 stddev=0.086948` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc-en-1920x1080.png` | NPC dialogue | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1297 stddev=0.084033` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc-ja-1920x1080.png` | NPC dialogue | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1223 stddev=0.0627849` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc_choice-vi-1024x640.png` | NPC dialogue choice page | `res://scenes/world/exploration_area.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1081 stddev=0.0786374` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc_choice-en-1024x640.png` | NPC dialogue choice page | `res://scenes/world/exploration_area.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1078 stddev=0.0775059` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc_choice-ja-1024x640.png` | NPC dialogue choice page | `res://scenes/world/exploration_area.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=759 stddev=0.0622127` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc_choice-vi-1280x720.png` | NPC dialogue choice page | `res://scenes/world/exploration_area.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1272 stddev=0.0853067` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc_choice-en-1280x720.png` | NPC dialogue choice page | `res://scenes/world/exploration_area.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1225 stddev=0.0839704` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc_choice-ja-1280x720.png` | NPC dialogue choice page | `res://scenes/world/exploration_area.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=943 stddev=0.0679947` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc_choice-vi-1920x1080.png` | NPC dialogue choice page | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1358 stddev=0.086357` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc_choice-en-1920x1080.png` | NPC dialogue choice page | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1286 stddev=0.0848502` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-haven_npc_choice-ja-1920x1080.png` | NPC dialogue choice page | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1237 stddev=0.0683982` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-journal-vi-1024x640.png` | Quest journal | `res://scenes/world/world_map.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1199 stddev=0.125474` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-journal-en-1024x640.png` | Quest journal | `res://scenes/world/world_map.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1170 stddev=0.119468` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-journal-ja-1024x640.png` | Quest journal | `res://scenes/world/world_map.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=895 stddev=0.0696046` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-journal-vi-1280x720.png` | Quest journal | `res://scenes/world/world_map.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1169 stddev=0.135763` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-journal-en-1280x720.png` | Quest journal | `res://scenes/world/world_map.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1210 stddev=0.129245` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-journal-ja-1280x720.png` | Quest journal | `res://scenes/world/world_map.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1028 stddev=0.0754404` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-journal-vi-1920x1080.png` | Quest journal | `res://scenes/world/world_map.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1273 stddev=0.139286` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-journal-en-1920x1080.png` | Quest journal | `res://scenes/world/world_map.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1282 stddev=0.133162` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-journal-ja-1920x1080.png` | Quest journal | `res://scenes/world/world_map.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1222 stddev=0.080192` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_chest-vi-1024x640.png` | Treasure interaction | `res://scenes/world/exploration_area.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=809 stddev=0.0800742` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_chest-en-1024x640.png` | Treasure interaction | `res://scenes/world/exploration_area.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=791 stddev=0.0793157` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_chest-ja-1024x640.png` | Treasure interaction | `res://scenes/world/exploration_area.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=577 stddev=0.0639697` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_chest-vi-1280x720.png` | Treasure interaction | `res://scenes/world/exploration_area.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=818 stddev=0.0822466` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_chest-en-1280x720.png` | Treasure interaction | `res://scenes/world/exploration_area.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=812 stddev=0.0809066` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_chest-ja-1280x720.png` | Treasure interaction | `res://scenes/world/exploration_area.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=665 stddev=0.0645297` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_chest-vi-1920x1080.png` | Treasure interaction | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=835 stddev=0.0825693` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_chest-en-1920x1080.png` | Treasure interaction | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=823 stddev=0.0811193` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_chest-ja-1920x1080.png` | Treasure interaction | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=774 stddev=0.0640278` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_battle-vi-1024x640.png` | Battle transition | `res://scenes/world/exploration_area.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1167 stddev=0.0549844` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_battle-en-1024x640.png` | Battle transition | `res://scenes/world/exploration_area.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1176 stddev=0.0546157` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_battle-ja-1024x640.png` | Battle transition | `res://scenes/world/exploration_area.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=936 stddev=0.0456455` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_battle-vi-1280x720.png` | Battle transition | `res://scenes/world/exploration_area.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1283 stddev=0.058058` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_battle-en-1280x720.png` | Battle transition | `res://scenes/world/exploration_area.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1305 stddev=0.0573832` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_battle-ja-1280x720.png` | Battle transition | `res://scenes/world/exploration_area.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1094 stddev=0.0469521` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_battle-vi-1920x1080.png` | Battle transition | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1411 stddev=0.0609967` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_battle-en-1920x1080.png` | Battle transition | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1396 stddev=0.0604336` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-meadow_battle-ja-1920x1080.png` | Battle transition | `res://scenes/world/exploration_area.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1347 stddev=0.0503384` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-quest_complete_journal-vi-1024x640.png` | Quest completion | `res://scenes/world/world_map.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1242 stddev=0.12501` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-quest_complete_journal-en-1024x640.png` | Quest completion | `res://scenes/world/world_map.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=1199 stddev=0.119302` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-quest_complete_journal-ja-1024x640.png` | Quest completion | `res://scenes/world/world_map.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=886 stddev=0.068948` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-quest_complete_journal-vi-1280x720.png` | Quest completion | `res://scenes/world/world_map.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1233 stddev=0.135219` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-quest_complete_journal-en-1280x720.png` | Quest completion | `res://scenes/world/world_map.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1233 stddev=0.128978` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-quest_complete_journal-ja-1280x720.png` | Quest completion | `res://scenes/world/world_map.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=1024 stddev=0.0747578` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-quest_complete_journal-vi-1920x1080.png` | Quest completion | `res://scenes/world/world_map.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1333 stddev=0.138743` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-quest_complete_journal-en-1920x1080.png` | Quest completion | `res://scenes/world/world_map.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1308 stddev=0.132398` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-quest_complete_journal-ja-1920x1080.png` | Quest completion | `res://scenes/world/world_map.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=1221 stddev=0.079349` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_victory-vi-1024x640.png` | Battle victory | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=3142 stddev=0.125373` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_victory-en-1024x640.png` | Battle victory | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=3148 stddev=0.122444` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_victory-ja-1024x640.png` | Battle victory | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=2855 stddev=0.110893` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_victory-vi-1280x720.png` | Battle victory | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=3570 stddev=0.138049` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_victory-en-1280x720.png` | Battle victory | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=3437 stddev=0.133946` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_victory-ja-1280x720.png` | Battle victory | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=3259 stddev=0.119834` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_victory-vi-1920x1080.png` | Battle victory | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=3769 stddev=0.142246` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_victory-en-1920x1080.png` | Battle victory | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=3586 stddev=0.137113` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_victory-ja-1920x1080.png` | Battle victory | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=3667 stddev=0.125941` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_defeat-vi-1024x640.png` | Battle defeat | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=3136 stddev=0.120932` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_defeat-en-1024x640.png` | Battle defeat | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=3056 stddev=0.115991` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_defeat-ja-1024x640.png` | Battle defeat | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=2814 stddev=0.103962` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_defeat-vi-1280x720.png` | Battle defeat | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=3391 stddev=0.131217` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_defeat-en-1280x720.png` | Battle defeat | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=3193 stddev=0.126687` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_defeat-ja-1280x720.png` | Battle defeat | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=3190 stddev=0.115456` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_defeat-vi-1920x1080.png` | Battle defeat | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=3585 stddev=0.134551` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_defeat-en-1920x1080.png` | Battle defeat | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=3373 stddev=0.129536` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_defeat-ja-1920x1080.png` | Battle defeat | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=3627 stddev=0.11696` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_retry-vi-1024x640.png` | Battle Retry available | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=3214 stddev=0.122169` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_retry-en-1024x640.png` | Battle Retry available | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=3010 stddev=0.118093` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_retry-ja-1024x640.png` | Battle Retry available | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=2814 stddev=0.107009` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_retry-vi-1280x720.png` | Battle Retry available | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=3521 stddev=0.132524` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_retry-en-1280x720.png` | Battle Retry available | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=3264 stddev=0.129364` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_retry-ja-1280x720.png` | Battle Retry available | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=3264 stddev=0.117347` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_retry-vi-1920x1080.png` | Battle Retry available | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=3719 stddev=0.135992` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_retry-en-1920x1080.png` | Battle Retry available | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=3435 stddev=0.132601` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_retry-ja-1920x1080.png` | Battle Retry available | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=2705 stddev=0.123444` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_return-vi-1024x640.png` | Battle return state | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `vi` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=842 stddev=0.0867288` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_return-en-1024x640.png` | Battle return state | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `en` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=835 stddev=0.083877` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_return-ja-1024x640.png` | Battle return state | `res://scenes/battle/battle_scene.tscn` | 1024x640 | `ja` | window=150994951 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=601 stddev=0.0648232` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_return-vi-1280x720.png` | Battle return state | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `vi` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=837 stddev=0.0895058` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_return-en-1280x720.png` | Battle return state | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `en` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=825 stddev=0.085872` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_return-ja-1280x720.png` | Battle return state | `res://scenes/battle/battle_scene.tscn` | 1280x720 | `ja` | window=150994951 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=694 stddev=0.0654928` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_return-vi-1920x1080.png` | Battle return state | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `vi` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=843 stddev=0.0904645` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_return-en-1920x1080.png` | Battle return state | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `en` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=825 stddev=0.0865257` | 0 |
| `docs/qa/screenshots/prompt06/prompt06-battle_return-ja-1920x1080.png` | Battle return state | `res://scenes/battle/battle_scene.tscn` | 1920x1080 | `ja` | window=150994951 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=790 stddev=0.0652429` | 0 |

## Reproduction

Every capture is reproducible with a real display and the pinned Godot binary:

```sh
NAME=prompt06-world_map-vi-1280x720 \
  SCENE=res://scenes/world/world_map.tscn RES=1280x720 LOCALE=vi \

  ./tools/qa/capture_prompt06.sh
python3 tools/qa/prompt06_visual_report.py
```

Set `SCENARIO` to one of the thirteen required scenarios: `world_map`, `selected`,
`hub`, `haven_npc`, `haven_npc_choice`, `journal`, `meadow_chest`, `meadow_battle`,
`quest_complete_journal`, `battle_victory`, `battle_defeat`, `battle_retry`, or
`battle_return`. Battle result captures enable `FFBE_QA_MODE` and pass the same
world trigger/location/return context used by exploration. `FULLSCREEN=1` and
`WAIT_SECONDS` are also accepted by the shared capture harness. `FFBE_QA_LOCALE`
is a QA-only starting-locale override and does not write player settings.

## Limitations

- Distinct pixel statistics and zero error lines prove renders occurred; they
  do not prove subjective layout quality or text readability.
- Fullscreen 1920×1080 captures are taken at `(0,0)` when `FULLSCREEN=1`;
  windowed captures include desktop decoration offsets recorded in metadata.
- `meadow_battle` is a transition capture. `battle_victory`, `battle_defeat`,
  `battle_retry` and `battle_return` run a full synthetic battle with world
  settlement in an isolated profile; `battle_return` then navigates back to the
  exploration area with the settled result.
- Geometry, pixel statistics and error lines are evidence that rendering and
  navigation occurred; Retry visibility and choice-page layout still need human
  visual inspection of the retained PNGs.
- No mockups or composited images are used.
