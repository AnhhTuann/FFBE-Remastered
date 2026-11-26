# Prompt 07 Event Center visual review

**Schema version:** 1
**Capture tool:** `tools/qa/capture_prompt07.sh`
**Report generator:** `tools/qa/prompt07_visual_report.py`

All images below are real captures from running Godot windows. Each capture uses a
fresh isolated `user://` profile and the injected clock `1740000000`, so no owner
save is read or modified and scheduled states are deterministic. The harness records
window geometry, ImageMagick pixel statistics and runtime error counts in a `.txt`
sidecar next to each PNG. This report validates the complete scenario × resolution ×
locale matrix, requires zero runtime error lines, and rejects blank or near-blank
captures by inspecting ImageMagick pixel variance. Pixel statistics are recorded
for review but are not an art-direction threshold; subjective visual sign-off remains
a human QA task. All card art is an explicitly labelled synthetic placeholder panel.

- Captures: 156
- Scenarios: 13
- Resolutions: 1024x640, 1280x720, 1920x1080, 720x1280
- Locales: vi, en, ja
- Runtime error lines across all captures: 0

## Coverage matrix

| Scenario | Resolutions | Locales | Captures |
|---|---|---|---:|
| Overview and cards | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Active filter | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Upcoming filter | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Ended filter | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Category filter | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Event details | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Stage selection | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| First-clear and repeat rewards | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Event currency and shop | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Summon-banner navigation | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Archive filter | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Replay archive | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |
| Synthetic collaboration fixture | 1024x640, 1280x720, 1920x1080, 720x1280 | vi, en, ja | 12 |

## Captures

| Screenshot | Scenario | Scene | Resolution | Locale | Clock | Geometry | Pixels | Errors |
|---|---|---|---|---|---|---|---|---:|
| `docs/qa/screenshots/prompt07/prompt07-overview-vi-1024x640.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=195035143 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=225 stddev=0.0807125` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-en-1024x640.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=192937991 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=225 stddev=0.0785835` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-ja-1024x640.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=183 stddev=0.0576551` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-vi-1280x720.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0877643` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-en-1280x720.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=192937991 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0856756` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-ja-1280x720.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=197132295 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=197 stddev=0.0610805` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-vi-1920x1080.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=225 stddev=0.0896779` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-en-1920x1080.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=192937991 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=225 stddev=0.0874771` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-ja-1920x1080.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=220 stddev=0.063029` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-vi-720x1280.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=225 stddev=0.0531154` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-en-720x1280.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=223 stddev=0.0519769` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-overview-ja-720x1280.png` | Overview and cards | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=160 stddev=0.0409639` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-vi-1024x640.png` | Active filter | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=224 stddev=0.0720832` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-en-1024x640.png` | Active filter | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=225 stddev=0.0697363` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-ja-1024x640.png` | Active filter | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=195035143 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=165 stddev=0.0541064` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-vi-1280x720.png` | Active filter | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0776497` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-en-1280x720.png` | Active filter | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0753453` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-ja-1280x720.png` | Active filter | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=192937991 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=194 stddev=0.0569163` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-vi-1920x1080.png` | Active filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=225 stddev=0.0790955` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-en-1920x1080.png` | Active filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=225 stddev=0.0766244` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-ja-1920x1080.png` | Active filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=192937991 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=220 stddev=0.0583433` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-vi-720x1280.png` | Active filter | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=225 stddev=0.0463883` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-en-720x1280.png` | Active filter | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=223 stddev=0.0451044` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-active-ja-720x1280.png` | Active filter | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=138 stddev=0.0369328` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-vi-1024x640.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=224 stddev=0.0688805` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-en-1024x640.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=195035143 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=221 stddev=0.06735` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-ja-1024x640.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=165 stddev=0.0530439` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-vi-1280x720.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=192937991 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0739714` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-en-1280x720.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0725643` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-ja-1280x720.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=194 stddev=0.0556861` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-vi-1920x1080.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=195035143 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=225 stddev=0.0752838` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-en-1920x1080.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=224 stddev=0.0737688` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-ja-1920x1080.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=220 stddev=0.0569246` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-vi-720x1280.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=223 stddev=0.0438611` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-en-720x1280.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=222 stddev=0.0430631` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-upcoming-ja-720x1280.png` | Upcoming filter | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=137 stddev=0.0354809` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-vi-1024x640.png` | Ended filter | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=192937991 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=225 stddev=0.0752048` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-en-1024x640.png` | Ended filter | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=225 stddev=0.0735807` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-ja-1024x640.png` | Ended filter | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=183 stddev=0.0556393` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-vi-1280x720.png` | Ended filter | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0812409` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-en-1280x720.png` | Ended filter | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0797214` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-ja-1280x720.png` | Ended filter | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=197 stddev=0.0587554` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-vi-1920x1080.png` | Ended filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=225 stddev=0.0829354` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-en-1920x1080.png` | Ended filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=225 stddev=0.0812793` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-ja-1920x1080.png` | Ended filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=220 stddev=0.0603768` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-vi-720x1280.png` | Ended filter | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=225 stddev=0.0488484` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-en-720x1280.png` | Ended filter | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=223 stddev=0.0480053` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-ended-ja-720x1280.png` | Ended filter | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=160 stddev=0.0385505` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-vi-1024x640.png` | Category filter | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=225 stddev=0.0717365` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-en-1024x640.png` | Category filter | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=225 stddev=0.0693618` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-ja-1024x640.png` | Category filter | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=165 stddev=0.0540287` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-vi-1280x720.png` | Category filter | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0772691` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-en-1280x720.png` | Category filter | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=225 stddev=0.0748927` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-ja-1280x720.png` | Category filter | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=194 stddev=0.0568155` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-vi-1920x1080.png` | Category filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=225 stddev=0.0786663` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-en-1920x1080.png` | Category filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=225 stddev=0.0761358` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-ja-1920x1080.png` | Category filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=220 stddev=0.0581996` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-vi-720x1280.png` | Category filter | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=225 stddev=0.0462132` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-en-720x1280.png` | Category filter | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=222 stddev=0.0449321` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-categories-ja-720x1280.png` | Category filter | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=138 stddev=0.0369184` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-vi-1024x640.png` | Event details | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=693 stddev=0.116405` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-en-1024x640.png` | Event details | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=684 stddev=0.112049` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-ja-1024x640.png` | Event details | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=485 stddev=0.079594` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-vi-1280x720.png` | Event details | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=699 stddev=0.123228` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-en-1280x720.png` | Event details | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=455 stddev=0.117812` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-ja-1280x720.png` | Event details | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=523 stddev=0.0849692` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-vi-1920x1080.png` | Event details | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=713 stddev=0.126069` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-en-1920x1080.png` | Event details | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=702 stddev=0.121355` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-ja-1920x1080.png` | Event details | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=634 stddev=0.0881056` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-vi-720x1280.png` | Event details | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=617 stddev=0.0772831` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-en-720x1280.png` | Event details | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=621 stddev=0.0751276` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-detail-ja-720x1280.png` | Event details | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=427 stddev=0.0577208` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-vi-1024x640.png` | Stage selection | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=693 stddev=0.116405` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-en-1024x640.png` | Stage selection | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=684 stddev=0.112049` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-ja-1024x640.png` | Stage selection | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=493 stddev=0.133313` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-vi-1280x720.png` | Stage selection | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=699 stddev=0.123228` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-en-1280x720.png` | Stage selection | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=692 stddev=0.118851` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-ja-1280x720.png` | Stage selection | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=523 stddev=0.0849692` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-vi-1920x1080.png` | Stage selection | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=713 stddev=0.126069` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-en-1920x1080.png` | Stage selection | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=702 stddev=0.121355` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-ja-1920x1080.png` | Stage selection | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=634 stddev=0.0881056` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-vi-720x1280.png` | Stage selection | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=617 stddev=0.0772831` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-en-720x1280.png` | Stage selection | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=621 stddev=0.0751276` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-stages-ja-720x1280.png` | Stage selection | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=427 stddev=0.0577208` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-vi-1024x640.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=693 stddev=0.116405` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-en-1024x640.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=684 stddev=0.112049` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-ja-1024x640.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=485 stddev=0.079594` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-vi-1280x720.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=699 stddev=0.123228` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-en-1280x720.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=692 stddev=0.118851` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-ja-1280x720.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=523 stddev=0.0849692` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-vi-1920x1080.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=713 stddev=0.126069` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-en-1920x1080.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=702 stddev=0.121355` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-ja-1920x1080.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=634 stddev=0.0881056` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-vi-720x1280.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=617 stddev=0.0772831` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-en-720x1280.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=621 stddev=0.0751276` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-rewards-ja-720x1280.png` | First-clear and repeat rewards | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=427 stddev=0.0577208` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-vi-1024x640.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=693 stddev=0.116405` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-en-1024x640.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=684 stddev=0.112049` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-ja-1024x640.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=485 stddev=0.079594` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-vi-1280x720.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=699 stddev=0.123228` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-en-1280x720.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=692 stddev=0.118851` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-ja-1280x720.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=523 stddev=0.0849692` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-vi-1920x1080.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=713 stddev=0.126069` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-en-1920x1080.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=702 stddev=0.121355` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-ja-1920x1080.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=634 stddev=0.0881056` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-vi-720x1280.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=617 stddev=0.0772831` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-en-720x1280.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=621 stddev=0.0751276` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-shop-ja-720x1280.png` | Event currency and shop | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=427 stddev=0.0577208` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-vi-1024x640.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=693 stddev=0.116405` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-en-1024x640.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=684 stddev=0.112049` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-ja-1024x640.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=493 stddev=0.133313` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-vi-1280x720.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=699 stddev=0.123228` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-en-1280x720.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=692 stddev=0.118851` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-ja-1280x720.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=523 stddev=0.0849692` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-vi-1920x1080.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=713 stddev=0.126069` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-en-1920x1080.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=702 stddev=0.121355` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-ja-1920x1080.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=634 stddev=0.0881056` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-vi-720x1280.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=617 stddev=0.0769733` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-en-720x1280.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=621 stddev=0.0751276` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-summon-ja-720x1280.png` | Summon-banner navigation | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=427 stddev=0.0577208` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-vi-1024x640.png` | Archive filter | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=683 stddev=0.104291` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-en-1024x640.png` | Archive filter | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=680 stddev=0.100829` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-ja-1024x640.png` | Archive filter | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=496 stddev=0.0715616` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-vi-1280x720.png` | Archive filter | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=700 stddev=0.112424` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-en-1280x720.png` | Archive filter | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=696 stddev=0.109134` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-ja-1280x720.png` | Archive filter | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=550 stddev=0.0771889` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-vi-1920x1080.png` | Archive filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=709 stddev=0.115017` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-en-1920x1080.png` | Archive filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=709 stddev=0.111245` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-ja-1920x1080.png` | Archive filter | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=656 stddev=0.079975` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-vi-720x1280.png` | Archive filter | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=624 stddev=0.0653121` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-en-720x1280.png` | Archive filter | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=607 stddev=0.0635285` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-archive-ja-720x1280.png` | Archive filter | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=441 stddev=0.0478808` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-vi-1024x640.png` | Replay archive | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=683 stddev=0.104291` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-en-1024x640.png` | Replay archive | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=680 stddev=0.100829` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-ja-1024x640.png` | Replay archive | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=496 stddev=0.0715616` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-vi-1280x720.png` | Replay archive | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=700 stddev=0.112424` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-en-1280x720.png` | Replay archive | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=696 stddev=0.109134` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-ja-1280x720.png` | Replay archive | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=550 stddev=0.0771889` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-vi-1920x1080.png` | Replay archive | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=709 stddev=0.115017` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-en-1920x1080.png` | Replay archive | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=709 stddev=0.111245` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-ja-1920x1080.png` | Replay archive | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=656 stddev=0.079975` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-vi-720x1280.png` | Replay archive | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=624 stddev=0.0653121` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-en-720x1280.png` | Replay archive | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=607 stddev=0.0635285` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-replay-ja-720x1280.png` | Replay archive | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=441 stddev=0.0478808` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-vi-1024x640.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 1024x640 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=659 stddev=0.109163` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-en-1024x640.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 1024x640 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=697 stddev=0.106283` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-ja-1024x640.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 1024x640 | `ja` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1024 HEIGHT=640 SCREEN=0 | `1024x640 colors=518 stddev=0.0767705` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-vi-1280x720.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 1280x720 | `vi` | `1740000000` | window=188743687 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=680 stddev=0.111652` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-en-1280x720.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 1280x720 | `en` | `1740000000` | window=190840839 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=699 stddev=0.10899` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-ja-1280x720.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 1280x720 | `ja` | `1740000000` | window=186646535 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0 | `1280x720 colors=571 stddev=0.077582` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-vi-1920x1080.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 1920x1080 | `vi` | `1740000000` | window=188743687 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=694 stddev=0.114156` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-en-1920x1080.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 1920x1080 | `en` | `1740000000` | window=190840839 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=710 stddev=0.111029` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-ja-1920x1080.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 1920x1080 | `ja` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=1920 HEIGHT=1080 SCREEN=0 | `1920x1080 colors=651 stddev=0.0799466` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-vi-720x1280.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 720x1280 | `vi` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=585 stddev=0.0673132` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-en-720x1280.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 720x1280 | `en` | `1740000000` | window=186646535 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=618 stddev=0.0656134` | 0 |
| `docs/qa/screenshots/prompt07/prompt07-collaboration-ja-720x1280.png` | Synthetic collaboration fixture | `res://scenes/event/event_center.tscn` | 720x1280 | `ja` | `1740000000` | window=69206023 X=0 Y=0 WIDTH=720 HEIGHT=1280 SCREEN=0 | `720x1280 colors=461 stddev=0.0501578` | 0 |

## Reproduction

Every capture is reproducible with a real display and the pinned Godot binary:

```sh
NAME=prompt07-overview-vi-1280x720 \
  SCENE=res://scenes/event/event_center.tscn RES=1280x720 LOCALE=vi \
  SCENARIO=overview ./tools/qa/capture_prompt07.sh
python3 tools/qa/prompt07_visual_report.py
```

Set `SCENARIO` to one of the thirteen required scenarios: `overview`, `active`,
`upcoming`, `ended`, `categories`, `detail`, `stages`, `rewards`, `shop`, `summon`,
`archive`, `replay`, or `collaboration`. The wrapper converts it to
`FFBE_QA_EVENT_CENTER_VIEW`, injects `FFBE_QA_EVENT_NOW_UNIX=1740000000` and selects a
synthetic event ID where needed. `FULLSCREEN=1` and `WAIT_SECONDS` are accepted by the
shared capture harness. `FFBE_QA_LOCALE` is a QA-only starting-locale override and
does not write player settings.

## Limitations

- Distinct pixel statistics and zero error lines prove renders occurred; they
  do not prove subjective layout quality or text readability.
- Fullscreen 1920×1080 captures are taken at `(0,0)` when `FULLSCREEN=1`;
  windowed captures include desktop decoration offsets recorded in metadata.
- 720×1280 captures exercise the portrait layout profile; the other three
  resolutions exercise the landscape profile. Because a 720×1280 window cannot fit
  the 1920×1080 desktop, those captures temporarily switched the X display to a
  720×1280 mode and restored 1920×1080 afterwards; geometry metadata confirms it.
- The generator parses each sidecar's pixel standard deviation and rejects blank
  frames, but does not claim readability or art-direction approval.
- Rewards, shop and summon captures scroll an existing rendered detail section
  into view; they do not compose or mock UI.
- No mockups or composited images are used, and no protected art, logo, music,
  dialogue or collaboration character appears in the captured scene.
