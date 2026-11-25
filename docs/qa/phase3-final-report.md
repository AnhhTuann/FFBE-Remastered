# Phase 3 final report — character progression and advanced integration

**Branch:** `phase-3-character-progression`  
**HEAD:** `32afa0f7ad46cf1c799b8226dc27b9abf6884f55`  
**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf` (unchanged)  
**Status:** Phase 3 implementation and verification evidence complete; full gameplay/restoration claim **not** made.

---

## A. Scope and milestone boundary

Phase 3 added local character progression, equipment, party management, advanced battle integration, Vietnamese-first localization, and further GL/JP evidence audits. It remains research/verification-first. No full GL/JP restoration, banner/rates/guarantees fidelity, event/story/dialogue completeness, or original asset reuse is claimed. Prompt 05 was **not** started.

All gameplay content used here is synthetic (`SYNTHETIC_FIXTURE`) or documentation/evidence. No protected archive was downloaded, unpacked, or imported.

## B. Baseline and branch integrity

| Item | Evidence |
|---|---|
| Phase 2 baseline commit | `bd9bb68a20900a67603710e3cd8d8d342886cb37` |
| Phase 2 baseline | `20` Python tests; `224` Godot checks |
| Phase 3 branch | Created locally from the Phase 2 commit |
| PR #2 documentation commit | Upstream `90d6563901f67bf681e22571d8a357ba5d156880`, cherry-picked as `32afa0f7ad46cf1c799b8226dc27b9abf6884f55` |
| Destructive operations | No push, merge, force push, reset, or `git clean` |
| Baseline recheck | Temporary runner with the Phase 3 test removed reported `224 passed, 0 failed`, exit `0`; log `final-baseline-subset.log` |

The temporary baseline runner was deleted after the check. The full runner now reports `1412 passed, 0 failed`, which includes the unchanged baseline assertions.

## C. Source audit and rights gate

- Elvlin source audited at repository HEAD `b520e563cbc4364a07ee40331012340dc8aeb841`, tag `v0.1.36`, revision `13`, version `2026.11.16.13`.
- Pack inventory: `23` packs, compressed size `18,634,180,032`, installed size `19,052,071,696`, `16,433` files.
- Pass/fail: rights gate `not_passed`. The data is supplemental evidence only; no pack was bulk-downloaded or imported.
- Elvlin `event_encounters.json` exceeded the `20 MB` fetch cap, so that file remains unaudited.
- Phase 0 totals retained: `35,928` normalized records, `148,168` files, `5,181` collision candidates, `0 VERIFIED` recovered records.
- Regional identity conflicts remain recorded for native IDs `401008507`, `401008607`, `401008707`, `401014207/217`, `401014307/317`, `401014507/517`, and `401014607/617`.
- Service history: GL ended `2024-10-30`; JP ended `2025-10-31`. Later repositories are snapshots or fan continuations, not service truth.

Evidence files: `docs/audit/elvlin-source-audit.md`, `docs/audit/final-era-coverage.md`, `docs/audit/source-comparison.md`, `data/manifests/elvlin-source-manifest.json`, `data/validation/final-era-coverage.json`, `data/validation/source-conflicts.json`.

## D. Safe local content importer

`tools/importer/import_content.py` supports local raw → staging → normalized → pack flow with explicit rights gate, dry run, rollback, and JSONL reporting. `content-local/` contains only tracked `.gitkeep` placeholders; no restricted or recovered asset is present. `tests/test_phase3_importer.py` adds `11` passing tests. Real-content import remains rights-blocked by design.

## E. Content model and evidence labels

- Composite IDs are parsed through `ContentId`; region and native ID stay distinct. GL/JP records are never collapsed by numeric ID, and display names are never primary keys.
- `game/data/phase3/` contains synthetic unit definitions, progression rules, equipment, materia, vision cards, advanced abilities, mechanic labels, and an imported manifest.
- `ContentRepository.get_battle_package()` merges advanced abilities without mutating the source fixture.
- Mechanics are labelled `VERIFIED_RULE`, `PARTIAL_RULE`, `UNVERIFIED_RULE`, `REMASTERED_DESIGN`, or `SYNTHETIC_FIXTURE`. These labels describe evidence strength; they do not grant redistribution rights and do not create `VERIFIED` recovered records.
- Trust rewards now include a synthetic ability definition in `equipment.json`, so ability-type TMR rewards are claimable without importing original data.

## F. Character progression

Implemented in `game/progression/progression_system.gd`: EXP/leveling, stat pots and caps, duplicate conversion, star awakening, NV, EX +1/2/3, NV+, Brave Shift, trust/TMR/STMR claims, and ability unlocks. Invalid operations return failure reasons without resource loss.

Three defects found by the new suite were fixed rather than accepted:

1. Form-specific definition abilities were stringified as dictionaries; `build_resolver.gd` now extracts their `id`.
2. Unsupported star targets such as star 8/9 now return `no_transition` instead of falling through an empty transition.
3. Ability-type TMR rewards are now recognized and granted into an `abilities` inventory section.

## G. Equipment, materia, and vision cards

Implemented in `game/progression/inventory_system.gd`: slot and role restrictions, unique item ownership, materia stacking limits, equip/unequip stat recalculation without drift, lock/sell guards, vision-card assignment, level-scaled bonuses, and upgrade costs. All definitions come from synthetic fixtures.

## H. Party and build resolution

`BuildResolver` resolves stats, leader skills, category bonuses, passive caps, form-specific builds, and combatant definitions. `PlayerState` owns parties, active party selection, owned instances, and reward claims. The battle scene reads `active_party` (or `FFBE_QA_PARTY_ID`) and replaces the synthetic encounter party only when every slot resolves; otherwise it keeps the original fixture party.

## I. Battle integration and advanced mechanics

`game/scenes/battle/battle_scene.gd` now:

- Localizes all visible UI copy through `LocaleManager.t(...)`, including title, VS, turn/phase/chain, commands, hints, HP cards, companion, result, reward status, overlays, and event labels.
- Exposes `mechanic_label`/`verification_status` in localized ability and card tooltips.
- Uses `name_key` for synthetic advanced-ability names where dictionaries provide one.
- Preserves `FFBE_QA_SCENARIO`, `FFBE_QA_ENCOUNTER`, `FFBE_QA_SEED`, `FFBE_QA_FREEZE_FRAME`, and `FFBE_QA_PARTY_ID`.
- Calls `PlayerState.claim_battle_reward(result_dict)` once per completed battle, then `SaveManager.record_battle_result(result_dict)`. Retrying a victory reports `battle.reward_already_claimed` and grants nothing twice.

Seven battle scenarios (`start`, `formation`, `abilities`, `chain`, `limit`, `victory`, `defeat`) all exited `0` with zero error lines in the final smoke run.

## J. Localization

| Check | Result |
|---|---|
| Locales | `vi` default, `en` fallback, `ja` |
| Dictionary keys | `294` in each locale; union `294` |
| Missing keys / placeholder mismatches | `0` / `0` |
| Vietnamese diacritics | `281 / 294` (`0.9558`); 13 token-only values intentionally keep `NV`, `EX`, `LB`, `SLB`, `STMR`, `TMR`, `UID`, `Overdrive`, `HP`, or numeric placeholders |
| Japanese glyphs | `294 / 294` (`1.0`) |
| Long labels over 40 chars | `31` (diagnostic, not failure) |
| Static call sites | `101` (`84` literal) across `49` GDScript files |

Locale choice persists through `PlayerState`; fallback is current locale → `en` → stable key; Settings switches locale live and emits `locale_changed`. `FFBE_QA_LOCALE` is a capture-only starting-locale override and does not write settings. Evidence: `data/validation/localization-coverage.json`, `docs/localization/coverage-report.md`, `docs/localization/glossary.md`, `docs/localization/translation-guide.md`.

## K. Saves and offline integrity

`PlayerState` uses a version-3 file separate from the version-2 battle-progress slot. Version 2 migration preserves battle progress and adds profile, rewards, inventory, parties, and locale fields. `claimed_rewards` makes battle rewards idempotent across retries and reloads. `SaveManager` retains atomic writes, backup fallback, and newer-version refusal. No local save file was added to Git.

## L. Tests and negative control

| Check | Command | Result | Log |
|---|---|---|---|
| Import | `godot --headless --path game --import` | exit `0`, no script/parse errors | `final-import.log` |
| Godot full suite | `godot --headless --path game --script res://tests/test_runner.gd` | `1412 passed, 0 failed`, exit `0` | `final-godot.log` |
| Baseline subset | temporary runner without Phase 3 test | `224 passed, 0 failed`, exit `0` | `final-baseline-subset.log` |
| Negative control | `FFBE_TEST_NEGATIVE_CONTROL=1 ... test_runner.gd` | `1412 passed, 1 failed`, exit `1` | `final-negative.log` |
| Python suite | `python3 -m unittest discover -s tests -v` | `45 tests`, `OK` | `final-python.log` |
| Localization report | `python3 tools/localization/coverage_report.py` | `status: pass` | `final-localization.log` |
| Visual report | `python3 tools/qa/phase3_visual_report.py` | `123` captures | `visual-report-final5.log` |

Logs are under `/tmp/opencode/ffbe-logs/phase3/`. Normal and negative Godot logs contain no `SCRIPT ERROR` or `Parse Error` lines.

## M. Scene and smoke verification

All eleven scenes exited `0` with zero `SCRIPT ERROR`, `Parse Error`, or leading `ERROR:` lines: boot, menu, viewer, settings, and the seven Phase 3 screens. Battle scenarios were checked separately with the same result. Evidence is under `/tmp/opencode/ffbe-logs/phase3/final-smoke/` and `/tmp/opencode/ffbe-logs/phase3/`.

## N. Real GUI QA

`tools/qa/capture_phase3.sh` captured **123** real PNGs from running Godot windows. Every capture has a sidecar with scene, resolution, locale, fullscreen flag, geometry, ImageMagick pixel statistics, and runtime error count.

- Resolutions: `1280x720`, `1920x1080` fullscreen, `1024x640` smaller resizable window.
- Locales: `vi`, `en`, `ja`.
- Scenes: menu, settings, viewer, battle, and all seven Phase 3 screens. The full 11-scene × 3-locale × 3-resolution matrix is present.
- Additional battle scenario captures cover abilities, chain, limit, victory, defeat, formation, and three locales.
- All `123` sidecars report `runtime_error_lines=0`; geometry validation confirms requested dimensions and fullscreen origin.
- The report generator now rejects mismatched geometry, a check added after two stale-window captures were detected and recaptured.
- No mockups or composited images were used.

Limitation: this model cannot inspect PNG pixel content directly. Logs, geometry, and pixel statistics were reviewed; subjective readability/layout inspection requires a human. This is why the corresponding DoD row is `BLOCKED`, not `PASS`.

Evidence: `docs/qa/phase3-visual-review.md`, `docs/qa/screenshots/phase3/`, and logs under the phase-3 log directory.

## O. Export and runtime distinction

| Item | Status |
|---|---|
| Export presets configured | PASS |
| Matching 4.7.2.stable templates present | BLOCKED |
| Linux PCK generated | PASS |
| PCK loaded and smoke-run | PASS |
| Linux executable generated | BLOCKED |
| Windows executable generated | BLOCKED |
| Executable launched | NOT RUN |
| Windows runtime tested | NOT RUN |

The four missing template files are `linux_debug.x86_64`, `linux_release.x86_64`, `windows_debug_x86_64.exe`, and `windows_release_x86_64.exe`. `game/build/pack/phase3-linux.pck` was generated and ran headlessly with exit `0` and no error lines. No template was downloaded or substituted, and no silent engine upgrade occurred. Details: `docs/qa/phase3-export-report.md`.

## P. Known limitations

- Complete lawful final-era GL/JP data was not found; exact banners, rates, guarantees, story, event, and dialogue completeness remain unverified.
- Real-content import remains rights-blocked; the Elvlin manifest is `supplemental_evidence_only` with rights gate `not_passed`.
- `event_encounters.json` was not fetched because it exceeded the size cap.
- Phase 2 synthetic ability proper names without a `name_key` remain data labels; Phase 3 advanced abilities use localized `name_key` values where provided.
- 31 long labels are flagged for future layout review; they are not translation failures.
- 237 dictionary keys are diagnostic-only "unused" under the static scanner because some screens use local helpers or dynamic/data-driven keys.
- Subjective visual inspection and Windows runtime testing remain unavailable.
- No full gameplay completion claim is made.

## Q. Definition of Done — 22 items

| # | Item | Status | Evidence / caveat |
|---:|---|---|---|
| 1 | Phase 2 baseline verified (`20` Python, `224` Godot) | PASS | Baseline logs and `final-baseline-subset.log` |
| 2 | Branch from local Phase 2 commit; PR #2 documentation commit preserved | PASS | `bd9bb68` → `phase-3-character-progression` → `32afa0f` |
| 3 | No push, merge, force push, hard reset, clean, credentials, or local saves committed | PASS | Git history and status review |
| 4 | Rights gate `not_passed`; no protected assets imported | PASS | `docs/audit/elvlin-source-audit.md`, empty `content-local/` |
| 5 | Evidence-led GL/JP audits and conflict records generated | PASS | `docs/audit/`, `data/validation/source-conflicts.json` |
| 6 | Safe local importer with rights gate, dry run, rollback, and logs | PASS | `tools/importer/import_content.py`; `11` importer tests |
| 7 | Region-aware composite identity; no GL/JP numeric collapse | PASS | `ContentId`, unit fixtures, GDScript assertions |
| 8 | Mechanics classified; no fabricated `VERIFIED` recovered records | PASS | `mechanic_labels.json`, audit reports |
| 9 | Character Collection screen functional | PASS | Scene smoke, GUI captures, tests |
| 10 | Character Details screen functional | PASS | Scene smoke, GUI captures, tests |
| 11 | Upgrade screen functional | PASS | Scene smoke, GUI captures, tests |
| 12 | Awakening screen functional | PASS | Scene smoke, GUI captures, tests |
| 13 | Equipment/Materia screen functional | PASS | Scene smoke, GUI captures, tests |
| 14 | Vision Card screen functional | PASS | Scene smoke, GUI captures, tests |
| 15 | Party screen functional | PASS | Scene smoke, GUI captures, tests |
| 16 | Battle: active party, advanced abilities, localized labels, idempotent rewards | PASS | `game/scenes/battle/battle_scene.gd`, tests, battle captures |
| 17 | Localization `vi`/`en`/`ja`; persistence, fallback, live switching | PASS | `294` keys, `status: pass`, Settings signal |
| 18 | Save v2→v3 migration and offline integrity | PASS | v3 state, migration fixture, reward persistence tests |
| 19 | Python/GDScript suites plus negative control | PASS | `45` Python tests, `1412` Godot checks, negative exit `1` |
| 20 | Scene and battle smoke checks | PASS | `final-smoke/`, all exits `0`, zero error lines |
| 21 | Real GUI screenshots for all screens/locales/resolutions; no mockups | BLOCKED | `123` real captures and logs complete; subjective pixel inspection not available to this model |
| 22 | Export status distinction and final report; Prompt 05 not started | PASS | `docs/qa/phase3-export-report.md`, this report |

## R. Conclusion and next boundary

Phase 3 is implemented and verified to the extent possible offline and with the pinned engine. The `224` Phase 2 checks remain intact; the expanded suite reports `1412` passing checks and `45` passing Python tests. Real GUI captures exist for the full scene/locale/resolution matrix, and export states are reported separately and honestly.

Remaining blockers are external or evidentiary: matching export templates, rights-cleared real content, complete final-era source truth, subjective visual review by a human, and any platform executable runtime test. Prompt 05 must not begin automatically.
