# Phase 1 final report — Godot foundation and Character Viewer

**Date:** 2026-11-25
**Branch:** `phase-1-godot-foundation` (local only)
**Base:** Phase 0 commit `ffd3e640e362cc4423039b17274f7cf983481fa9`; skills commit `46b68cf3affc12375fadbfd5b22265ddc7940463`
**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`
**Content status:** all runtime content is `SYNTHETIC_FIXTURE`; no protected FFBE asset or source record was added or modified.

## A. Scope

This milestone implements a Godot 4.7.2 technical foundation and an offline Character Viewer. It does **not** claim FFBE restoration and does **not** implement Battle Engine gameplay, chaining, Limit Bursts, AI, progression, or inventory. Audit approval and rights review remain gates before any protected content import.

## B. Branch and repository integrity

All work stayed on the local `phase-1-godot-foundation` branch. No merge into `main`, force push, `reset --hard`, `git clean`, or push was performed. `origin/main` remains at `6232aca`. Phase 0 files and validation outputs are unchanged; new evidence is additive.

## C. Phase 0 preservation

The original Python suite still passes unchanged: `Ran 10 tests`, `OK`. The combined suite now reports `Ran 20 tests`, `OK`. Phase 0 counts remain 35,928 records, 3,018 GL / 21,005 JP / 11,905 SHARED, 0 VERIFIED, 148,168 files, 3,674,191,680 bytes, 5,181 collision candidates, and 11 regional unit-form conflicts.

## D. Agent Skills

Nine project-local skills plus licence/attribution files were preserved from PR #1. Runtime discovery was exercised for `ffbe-godot-foundation`, `ffbe-source-audit`, `ffbe-asset-restoration`, `ffbe-project-quality`, `godot-gdscript-headless-testing`, `godot-export`, and `save-systems`; `ffbe-battle-engine` and `rpg` were read from project files. No untrusted script was executed. `docs/AGENT_SKILLS.md` records this.

## E. Supplemental source evidence

`docs/audit/supplemental-source-discovery.md` and `data/manifests/supplemental-sources.json` record nine discovered repositories with URLs, 40-character revisions, dates, regions, categories, coverage, licensing, provenance, limitations, and differences from Phase 0. Status is `supplemental_evidence_only`; rights gate is `not_passed`. None is an import source or redistribution licence.

## F. Validation clarifications

All 651 Phase 0 “unresolved references” are false positives from a validator that routes recipe references only to `item.json`, while the records declare `EQUIP` or `MATERIA`. `data/validation/unresolved-reference-classification.json` records 617 `crafts.id` and 34 `materials[].id`, 213 GL / 438 JP, 444 crafted `EQUIP`, 173 crafted `MATERIA`, 25 material `EQUIP`, 9 material `MATERIA`, and 0 unresolved after declared-catalog checking. `missing-references.json` was not edited.

The frame-ID example in Source A was inspected: 53 rows, IDs 30–78, repeated 62 and 63 three times each, two `63 → 62` transitions, all IDs within the 108-row companion CGG table. It is documented as a likely deliberate oscillation, not corruption, in `docs/audit/animation-frame-validation-note.md`. No source file was altered.

## G. Engine and architecture

`game/project.godot` pins 1280×720 resizable baseline, 1920×1080 QA setting, Compatibility renderer, nearest texture filter, 2D pixel snapping, viewer input actions, and `ContentRepository`/`SaveManager` autoloads. Import exits 0 with no parser errors. Six ADRs cover engine/renderer, runtime content storage, regional identity, asset packaging, save format/versioning, and UI scaling.

## H. Content model

Units use `kind:REGION:native_id@form` composite IDs with string native IDs, explicit forms, provenance, and `verification_status`. GL and JP fixtures deliberately share native ID `900001` to prove cross-region separation. `game/data/*.json` and the deterministic 128×128 RGBA atlas are project-authored and labelled `SYNTHETIC_FIXTURE`. No CPK, APK, archive, extracted sprite, or FFBE data is inside `game/`.

## I. Character Viewer

Scenes: boot → main menu → viewer/settings. The viewer filters by region, selects units and clips, generates `SpriteFrames` from atlas rectangles, applies origin plus per-frame pixel offsets, exposes play/pause/restart/speed controls, and shows stats, abilities, provenance, and visible diagnostics. A deliberate missing-animation fixture proves that invalid metadata is reported instead of silently substituted.

## J. Animation validation

`AnimationValidator` rejects empty clips, missing/invalid loop flags, non-positive or non-finite durations and speeds, non-positive or out-of-atlas rectangles, malformed offsets/origins, and origins outside 0–1. It intentionally accepts repeated and non-monotonic frame IDs to preserve hold/oscillation sequences. The `hold_oscillation` fixture and a dedicated test lock this behaviour in.

## K. Persistence

`SaveManager` writes versioned JSON under `user://` using temp-file staging, backup of the previous target, and backup fallback on corrupt primaries. Current version is `2`; a tested `1 → 2` migration renames `selected_unit` to `selected_unit_id`. Newer versions are refused. Settings and three viewer slots are separate. No gameplay state is saved.

## L. Tests and QA evidence

- Godot headless: `Results: 74 passed, 0 failed`, exit 0.
- Negative control: injected wrong expectation → `73 passed, 1 failed`, exit 1; file restored.
- Python: `Ran 20 tests`, `OK`, exit 0.
- Clean import and GUI logs; parser errors found during work were fixed and are listed in `docs/qa/test-report.md`.
- Real GUI screenshots exist at 1280×720 and fullscreen 1920×1080, with window geometry, pixel statistics, and clean logs recorded in `docs/qa/visual-review.md`. The model could not visually inspect images, so no subjective visual claim is made.
- Export evidence is separated into configured, generated, launched, and runtime-tested in `docs/qa/export-report.md`.

## M. Definition of Done

| # | Criterion | Status | Evidence |
|---:|---|---|---|
| 1 | Phase 0 preserved; original 10 Python tests rerun and passing | **PASS** | `ffd3e64` unchanged; `Ran 10 tests`, `OK` |
| 2 | Local branch only; no merge, force push, reset, clean, or push | **PASS** | Branch `phase-1-godot-foundation`; `origin/main` at `6232aca` |
| 3 | Agent Skills inspected and actually discovered/used | **PASS** | `docs/AGENT_SKILLS.md`; seven loaded, two read locally |
| 4 | Supplemental sources, unresolved references, and frame sequence documented without source edits | **PASS** | supplemental manifest; classification JSON; animation note |
| 5 | Godot 4.7.2 pinned and project imports without parser errors | **PASS** | `game/project.godot`; import exit 0 |
| 6 | Six required ADRs present | **PASS** | `docs/decisions/0001`–`0006` |
| 7 | Region-aware composite IDs with form, provenance, and validation status | **PASS** | `ContentId`, `UnitRecord`, fixtures, ADR 0003 |
| 8 | Deterministic synthetic atlas and fixtures; no protected assets | **PASS** | generator + Python determinism test; asset README |
| 9 | Character Viewer with region/unit/clip selection, playback controls, and diagnostics | **PASS** | `test_viewer_scene_behavior`; GUI screenshots |
| 10 | Animation validator rejects malformed metadata and accepts holds | **PASS** | 12 valid clips, 2 invalid examples, 1 hold example |
| 11 | Versioned saves with atomic writes, backup recovery, and migration | **PASS** | GDScript save tests; ADR 0005 |
| 12 | Godot headless tests exit non-zero on failure | **PASS** | negative control exit 1; final run exit 0 |
| 13 | Python tests pass, including new foundation checks | **PASS** | `Ran 20 tests`, `OK` |
| 14 | Real GUI QA screenshots at 1280×720 and 1920×1080 | **PASS** | four final captures in `docs/qa/screenshots/` |
| 15 | Windows/Linux executable export and runtime verification | **BLOCKED** | presets configured; Linux PCK generated; executable templates absent; no Windows runtime launched |

**Overall:** foundation and Character Viewer are complete for M2/M3. Protected-content import, FFBE restoration claims, Battle Engine gameplay, and exported-executable verification remain gated/blocked as stated above.
