# Phase 0 — Full data and asset audit

This report is generated from the machine-readable files in `data/validation/`. It describes only sources that were actually inspected. A parsed record is classified RECOVERED, never VERIFIED, unless independently cross-checked.

## 1. Source revisions

| Source | Revision | Region coverage | Files inventoried | Bytes inventoried |
|---|---|---|---|---|
| DaddyRaegen/ffbe_asset_dump | f82d603c90ec799f539280267d3af7589c79f117 | GL + JP + shared assets; GL/JP split only for 11 conflicting unit form IDs | 148131 | 3596307289 |
| DanUgore/ffbe_data | ce7d98a6499bb8c2f6656f0698f60c30001a05b0 | GL and JP directories present; README describes the project as JP data | 37 | 77884391 |

## 2. Global structured-data coverage

### Global

| Source | Category | Path | Total | Valid | Partial | Dupes | Unverified | Unavailable |
|---|---|---|---|---|---|---|---|---|
| DanUgore/ffbe_data | Abilities | gl/ability.json | 451 | 451 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Esper beasts | gl/beasts.json | 6 | 6 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Esper boards | (none) | 0 | 0 | 0 | 0 | 0 | 1 |
| DanUgore/ffbe_data | Colosseum rewards | gl/colorewards.json | 3 | 3 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Enemy AI | gl/ai.json | 309 | 309 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Enhancement data | gl/enhance.json | 0 | 0 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Equipment | gl/equip.json | 261 | 261 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Important items | gl/important.json | 4 | 4 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Items | gl/item.json | 247 | 247 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Learnsets | gl/learns.json | 110 | 110 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Limit Bursts | gl/limits.json | 293 | 293 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Magic | gl/magic.json | 80 | 80 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Materia | gl/materia.json | 154 | 154 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Missions | (none) | 0 | 0 | 0 | 0 | 0 | 1 |
| DanUgore/ffbe_data | Monster skills | gl/monskills.json | 579 | 579 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Quests | (none) | 0 | 0 | 0 | 0 | 0 | 1 |
| DanUgore/ffbe_data | Recipes | gl/recipe.json | 252 | 252 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Units | gl/unit.json | 269 | 269 | 0 | 0 | 0 | 0 |

### Japan

| Source | Category | Path | Total | Valid | Partial | Dupes | Unverified | Unavailable |
|---|---|---|---|---|---|---|---|---|
| DanUgore/ffbe_data | Abilities | jp/ability.json | 6062 | 6062 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Esper beasts | jp/beasts.json | 16 | 16 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Esper boards | jp/boards.json | 16 | 16 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Colosseum rewards | jp/colorewards.json | 2 | 2 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Enemy AI | jp/ai.json | 1461 | 1461 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Enhancement data | jp/enhance.json | 151 | 151 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Equipment | jp/equip.json | 934 | 934 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Important items | jp/important.json | 22 | 22 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Items | jp/item.json | 606 | 606 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Learnsets | jp/learns.json | 372 | 372 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Limit Bursts | jp/limits.json | 1116 | 1106 | 10 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Magic | jp/magic.json | 210 | 210 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Materia | jp/materia.json | 500 | 500 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Missions | jp/missions.json | 3440 | 3440 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Monster skills | jp/monskills.json | 4452 | 4452 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Quests | quests.json | 74 | 74 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Recipes | jp/recipe.json | 456 | 456 | 0 | 0 | 0 | 0 |
| DanUgore/ffbe_data | Units | jp/unit.json | 1115 | 1115 | 0 | 0 | 0 | 0 |

### Shared / region-neutral catalogs

| Source | Category | Path | Total | Valid | Partial | Dupes | Unverified | Unavailable |
|---|---|---|---|---|---|---|---|---|
| DaddyRaegen/ffbe_asset_dump | Monster asset catalog | catalog/monsters.json | 3628 | 3627 | 1 | 0 | 0 | 0 |
| DaddyRaegen/ffbe_asset_dump | Unit asset catalog | catalog/units.json | 3953 | 3953 | 0 | 0 | 0 | 0 |
| DaddyRaegen/ffbe_asset_dump | Region-aware unit master | catalog/unit_master.json | 3964 | 3943 | 21 | 0 | 0 | 0 |
| DaddyRaegen/ffbe_asset_dump | Vision card asset catalog | catalog/vision_cards.json | 360 | 360 | 0 | 0 | 0 | 0 |

## 3. Verification status totals

| Status | Records / category rows |
|---|---|
| PARTIAL | 32 |
| RECOVERED | 35896 |
| UNAVAILABLE | 3 |
| UNVERIFIED | 0 |
| VERIFIED | 0 |

VERIFIED requires independent evidence, not successful parsing only. Status counts are computed per row; a category-level UNAVAILABLE row represents a whole absent source file.

## 4. Cross-region collisions

Total collision candidates: **5181**.

| Collision type | Count |
|---|---|
| different_ids_same_name_candidate | 2948 |
| same_native_id_different_regional_names | 2217 |
| same_native_id_label_variant | 16 |

Unit form IDs with documented GL/JP identity conflicts: **11** (401008507, 401008607, 401008707, 401014207, 401014217, 401014307, 401014317, 401014507, 401014517, 401014607, 401014617). These are kept separate with composite identities; no automatic merge is performed.

Examples (unit identity conflicts shown first):

- `same_native_id_different_regional_names` — unit 401008507: ['Kaito', 'Yoshikiri']
- `same_native_id_different_regional_names` — unit 401008607: ['Godrea', 'Starlight Elena']
- `same_native_id_different_regional_names` — unit 401008707: ['Emperor Foo', 'Ibara']
- `same_native_id_different_regional_names` — unit 401014207: ['Master Machinist Abigail', 'Dark Knight Duane']
- `same_native_id_different_regional_names` — unit 401014217: ['Master Machinist Abigail', 'Dark Knight Duane']
- `same_native_id_different_regional_names` — unit 401014307: ['Curse of Immunity Melissa', 'Eternal Radiance Elena']
- `same_native_id_different_regional_names` — unit 401014317: ['Curse of Immunity Melissa', 'Eternal Radiance Elena']
- `same_native_id_different_regional_names` — unit 401014507: ['Dark Knight Duane', 'Hyoh & Panthera Ultimus']
- `same_native_id_different_regional_names` — unit 401014517: ['Dark Knight Duane', 'Hyoh & Panthera Ultimus']
- `same_native_id_different_regional_names` — unit 401014607: ['Ruin Explorer Nora', 'Richt']
- `same_native_id_different_regional_names` — unit 401014617: ['Ruin Explorer Nora', 'Richt']
- `different_ids_same_name_candidate` — abilities 2回行動: {'JP': ['205670', '703210', '703220']}

## 5. Missing references

Total unresolved record references: **651**.

Every entry includes its source path and revision in `data/validation/missing-references.json`. Missing means unresolved against the inspected dataset only; it is not proof that the original game lacked the record.

## 6. Asset coverage

Files inventoried: **148168**; bytes: **3674191680**.

| Category | Files | Bytes | Hashed | Formats |
|---|---|---|---|---|
| ability-art | 480 | 5526295 | 0 | bmb:31, png:447, ssbp:2 |
| animations-gif | 37968 | 1511890954 | 0 | gif:37968 |
| battle-backgrounds | 4007 | 937135263 | 5 | jpg:1351, json:1, png:1389, ssbp:1266 |
| catalogs | 9 | 45881743 | 9 | json:9 |
| chain-ability-art | 61 | 615980 | 0 | png:61 |
| emblem-art | 472 | 3932542 | 0 | png:472 |
| equipment-art | 2968 | 9082832 | 0 | png:2968 |
| gallery | 10 | 1809847 | 0 | png:10 |
| gambit-icons | 30 | 204119 | 0 | png:30 |
| global-ability-art | 273 | 2616663 | 0 | png:273 |
| global-emblem-art | 262 | 2043872 | 0 | png:262 |
| global-equipment-art | 1135 | 7539379 | 0 | png:1135 |
| global-item-art | 1038 | 7758896 | 0 | png:1038 |
| global-materia-art | 26 | 211489 | 0 | png:26 |
| global-structured-data | 15 | 7876857 | 15 | json:15 |
| item-art | 9826 | 52023540 | 0 | plist:4, png:9822 |
| japan-structured-data | 18 | 69497574 | 18 | json:17, txt:1 |
| materia-art | 272 | 1338161 | 0 | png:272 |
| misc-assets | 15 | 83876 | 0 | png:15 |
| monster-animation-metadata | 13604 | 13232646 | 0 | csv:13604 |
| monster-assets | 113 | 289206 | 0 | png:113 |
| monster-icons | 3599 | 32433524 | 6 | png:3599 |
| monster-sprites | 3729 | 130874002 | 6 | bmb:11, png:3718 |
| regional-unit-bundles | 352 | 5335884 | 16 | csv:286, png:66 |
| root | 9 | 41284149 | 8 | (none):2, json:5, md:2 |
| town-assets | 93 | 2278652 | 0 | jpg:1, png:92 |
| ui-effects | 46 | 472113 | 0 | png:46 |
| unit-animation-metadata | 53450 | 200394119 | 0 | csv:53450 |
| unit-assets | 415 | 25299843 | 0 | fnt:17, plist:11, png:381, ssbp:6 |
| unit-bundles | 1 | 6444686 | 0 | zip:1 |
| unit-icons | 3953 | 3962755 | 8 | png:3953 |
| unit-illustrations | 3952 | 10897849 | 8 | png:3952 |
| unit-sprite-sheets | 4035 | 473472000 | 8 | png:4035 |
| upstream-reports | 33 | 8756505 | 31 | csv:2, json:21, md:6, png:2, py:1, txt:1 |
| upstream-tools | 18 | 166483 | 18 | md:1, py:16, txt:1 |
| vision-card-animation-metadata | 720 | 17353731 | 0 | csv:720 |
| vision-card-art | 360 | 16137081 | 5 | png:360 |
| vision-card-backgrounds | 6 | 448405 | 0 | png:6 |
| vision-card-frames | 6 | 204417 | 0 | png:6 |
| vision-card-icons | 361 | 12745315 | 0 | png:361 |
| vision-card-items | 395 | 2217049 | 0 | png:395 |
| world-assets | 33 | 2421384 | 0 | jpg:8, png:25 |

Animation CSV summary:

```json
{
  "checked": 0,
  "csv_files": 68062,
  "duplicate_frame_ids": 0,
  "errors": [],
  "examples": [],
  "invalid_rows": 0,
  "non_decreasing": 0,
  "not_non_decreasing": 0,
  "rows": 0,
  "sequence_csv_candidates": 59919,
  "starts_at_zero": 0
}
```

## 7. Asset integrity

| Check | Result |
|---|---|
| Files with SHA-256 | 161 |
| Metadata-only files | 148007 |
| Duplicate hash groups | 1 |
| Files in duplicate groups | 2 |
| Zero-length files | 0 |
| Unsupported formats | 0 |

Missing catalog asset references: **0** of 31725 checked.

## 8. Shared, equivalent and region-specific content

Shared or equivalent content is reported only as a candidate when IDs and names differ across regions; records are never merged automatically. Region-specific records keep composite identities such as `unit:GL:<id>` and `unit:JP:<id>`. See `data/validation/id-collisions.json` for the exact evidence.

## 9. Legal and redistribution blockers

- Neither inspected repository declares a license in GitHub metadata. Public access is not permission to redistribute third-party game data or assets.
- FFBE names, characters, artwork, text and audio may be protected by Square Enix or other rights holders. No original asset is copied into this repository during this phase.
- The asset dump's own reports describe source archives extracted from local game dumps; those extraction details are provenance, not a license.

## 10. Limitations

- Source A was inspected from Git tree metadata; binary blobs were not bulk-downloaded. Checksum coverage is therefore limited to materialized files.
- Source B is a historical extraction ending in 2018; it is not evidence of current game coverage.
- No category is reported as complete or VERIFIED solely because a file parsed successfully.
