# Supplemental source discovery

**Status:** Supplemental evidence only. No source from this document has been imported into the Godot project, altered, or added to a distributable build.

**Evidence date:** 2026-11-25 (UTC). Revision references were read from GitHub REST metadata and exact Git tree listings. No archive or installer was executed.

**Machine-readable companion:** [`data/manifests/supplemental-sources.json`](../../data/manifests/supplemental-sources.json).

## 1. Purpose

Phase 0 audited two sources exactly: `DaddyRaegen/ffbe_asset_dump` and `DanUgore/ffbe_data`. This document records additional public candidates discovered afterwards so that later milestones can evaluate them without treating a public repository as a licence or treating third-party claims as verified FFBE facts.

Nothing here changes the Phase 0 counts, manifests, or validation reports. The 35,928 normalized records, 148,168 inventoried files, 5,181 collision candidates, and 11 regional unit-form conflicts remain the Phase 0 evidence of record.

## 2. Sources inspected

| Source | Revision | Date | Region | Categories | License / rights signal | Decision |
|---|---|---|---|---|---|---|
| [DaddyRaegen/ffbe_asset_dump](https://github.com/DaddyRaegen/ffbe_asset_dump) | `f82d603c90ec799f539280267d3af7589c79f117` | 2026-10-10 | GL + JP + shared | Visual assets, catalogs, animation CSV, upstream reports | No licence file; game-derived art © Square Enix | Phase 0 source; retained, not imported |
| [DanUgore/ffbe_data](https://github.com/DanUgore/ffbe_data) | `ce7d98a6499bb8c2f6656f0698f60c30001a05b0` | 2018-02-09 | GL + JP | Structured JSON datasets | No licence file; extracted game text/metadata | Phase 0 source; historical snapshot only |
| [Elvlin/exvius-offline](https://github.com/Elvlin/exvius-offline) | `b520e563cbc4364a07ee40331012340dc8aeb841` | 2026-11-16 | GL | Offline client metadata, 1,214 JSON, 187 Python, 82 PNG, release APKs | No licence file; fan project built from original Global game | Reference only; do not download or ship APK/data |
| [arandooku/ffbe-sprites](https://github.com/arandooku/ffbe-sprites) | `082cea674dd4d26441e5b37a8bc35a0e341f473f` | 2026-11-19 | GL + JP derived from Source A | 57,794 files: 37,968 GIF, 19,823 PNG, one JSON index | No licence; README says original files © Square Enix, “for fan use” | Derivative of Phase 0 Source A; no independent provenance, no redistribution permission |
| [arandooku/ffbe-sprites-index](https://github.com/arandooku/ffbe-sprites-index) | `17ae600bfaf891de1e6ecca65df627a056cf1954` | 2026-11-19 | GL labels, JP names retained | 57,719 labelled rows in one `index.json` | No licence; explicitly fan archive | Indexing aid only; not a rights grant |
| [HmoobGod/ffbe-rev13-metadata-lab](https://github.com/HmoobGod/ffbe-rev13-metadata-lab) | `bf69f0de0958f1c89e83c59af6954425caf3be61` | 2026-11-24 | Unspecified | 19 workflow/toolchain files, 3 JSON, 5 Python | No licence; diagnostics workflows disabled by default | No content evidence; inspect only if a specific revision question arises |
| [TBMonkey/ffbe-gl-server](https://github.com/TBMonkey/ffbe-gl-server) | `2a940d88d9209283f07c801eef067c058735ef4c` | 2026-11-22 | GL v9.0.0 | 83 files; 31 Python, 25 JSON, 9 TSV, battle/mission tables, server contract | MIT covers project code; `ACKNOWLEDGEMENTS.md` states game data/content rights remain with Square Enix | Useful structured contract evidence; not a content licence |
| [lyrgard/ffbeDataExporter](https://github.com/lyrgard/ffbeDataExporter) | `9aeec842ba35f4716c695553c71ea15c1a344daa` | 2022-11-10 | GL user account data | Chrome extension; 14 JS, 19 release ZIPs, screenshots | No licence file; tool for exporting a player's own user data | Tooling reference only; no verified game dataset |
| [S0524/ffbe-offline-localization](https://github.com/S0524/ffbe-offline-localization) | `2006ddb4cf5227eb4e2fe74e471e863310abe750` | 2026-11-23 | FFBE Offline International | 14 files; GPL-3.0 patch scripts and CPK/text hotfix guide | GPL-3.0 applies to repository code; patched game resources are protected | Localization method reference only; no protected resource import |
| [aEnigmatic/ffbe](https://github.com/aEnigmatic/ffbe) | `95727376e82d27acc1290b6dc8ad27ce3c89ea71` | 2024-09-02 | GL | 32 JSON datasets, 1,751 units, 4,275 equipment, 4,729 items, 1,675 materia, 28,212 ability records | GitHub MIT metadata; repository README is only “Data dump for FFBE GL”; game-derived content rights not waived | Structured cross-check candidate, not an import source |
| [aEnigmatic/ffbe-jp](https://github.com/aEnigmatic/ffbe-jp) | `ea7d9fa82659e66fed1a0a5dba4616089cc807dc` | 2025-10-03 | JP | 30 JSON datasets, 1,683 units, 3,715 equipment, 3,851 items, 1,599 materia, 27,051 ability records | GitHub MIT metadata; game-derived content rights not waived | Structured cross-check candidate, not an import source |

Record counts in the final two rows were measured by parsing the exact revision's JSON files through the GitHub API. Counts are top-level record counts, not verified gameplay coverage.

## 3. How these sources differ from Phase 0

1. **Derivative vs. independent.** `arandooku/ffbe-sprites` explicitly states that it was exported from Phase 0 Source A. It is convenient for lookup, but it adds no independent provenance and does not cure the missing licence.
2. **Structured metadata vs. visual inventory.** `aEnigmatic/ffbe`, `aEnigmatic/ffbe-jp`, and `TBMonkey/ffbe-gl-server` provide structured records or protocol tables that Source A's asset dump does not. They can help answer “what did the game call this?” but cannot prove a lawful right to redistribute the resulting text or data.
3. **Final-era GL evidence.** `TBMonkey/ffbe-gl-server` targets the v9.0.0 Global client and includes `server/content/battle/F_MONSTER_MST.tsv`, `F_MONSTER_SKILL_MST.tsv`, `F_MISSION_MST.tsv`, `F_BATTLE_GROUP_MST.tsv`, `event_spine.json`, and Clash of Wills data. This is later than the 2018 Phase 0 structured snapshot. Its `ACKNOWLEDGEMENTS.md` separates MIT-licensed engine code from game-derived content; the distinction must be preserved.
4. **Client/metadata tooling.** `Elvlin/exvius-offline`, `lyrgard/ffbeDataExporter`, and `S0524/ffbe-offline-localization` show how later clients expose offline data or localized resources. They are method evidence, not clean datasets. APKs, release ZIPs, and CPK resources were not downloaded.
5. **No new verified status.** Phase 0 reports `0 VERIFIED` records. Nothing in this discovery set changes that number.

## 4. Licensing and provenance gate

- A GitHub repository, MIT label on tooling, or README statement such as “for fan use” does **not** grant redistribution rights to FFBE art, text, names, music, or extracted game data.
- Source revisions are recorded, but no raw source snapshot from this supplemental set is stored in the public repository.
- No archive, APK, ZIP, or CPK was executed or imported.
- Before any candidate can feed a runtime package, it needs: a documented lawful basis, exact revision, checksum, region, category coverage, and a import report that separates authored code/data from game-derived material.
- If that gate cannot be passed, the game must continue with synthetic or properly licensed replacement assets.

## 5. Effect on the current milestone

This discovery is recorded as supplemental evidence only. The Godot foundation and Character Viewer use `SYNTHETIC_FIXTURE` data generated inside this repository. No repository listed above is a runtime dependency, build input, or content source for the current project.

Related classification notes:

- [`unresolved-reference-classification.md`](unresolved-reference-classification.md) explains the 651 Phase 0 “missing references”.
- [`animation-frame-validation-note.md`](animation-frame-validation-note.md) explains a non-monotonic frame sequence found in Source A.
