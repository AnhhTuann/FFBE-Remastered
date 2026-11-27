# Prompt 07.1 final QA report

**Scope:** Event Progression Integrity Hardening on the synthetic Event Center.
**Branch:** `phase-6.1-event-progression-integrity`.
**Parent baseline:** `f9f4ed595026a4e49ce579b6c31ffb95cc7d8e62` (verified parent of PR #10).
**Implementation commit:** `f6849093c9fd7a11ad7c3d14c679abdbe9b771eb` — `fix(event): enforce mission progression and unlock integrity`.
**Documentation/evidence commit:** the commit containing this report and the linked generated artifacts.
**Engine:** Godot 4.7.2 stable, `--headless`; project root `game/`.
**Rights gate:** `not_passed`. No original FFBE event data, collaboration identity, art, audio, dialogue, rate table, protected archive, save, credential or build executable was added.
**Logs:** fresh Prompt 07.1 evidence is under `/tmp/opencode/ffbe-logs/prompt-07.1/`. No Prompt 07 test number is reused as Prompt 07.1 evidence.

## 1. Outcome summary

| Item | Status |
|---|---|
| Objective-qualified mission progression | PASS |
| Repeatable cycle claims with stable IDs | PASS |
| Centralized data-driven unlock evaluation | PASS |
| Gameplay-service unlock enforcement | PASS |
| Transactional reward/save integrity | PASS |
| Save version preservation (`PLAYER_STATE_VERSION = 4`) | PASS |
| Fresh Godot import / focused / full / negative control | PASS |
| Python discovery / importer security / world + QA tooling | PASS |
| Localization parity (`vi`, `en`, `ja`) | PASS |
| Linux and Windows export | PASS |
| Linux exported-binary smoke | PASS |
| Repository security, size and rights audit | PASS |
| Windows runtime execution | NOT RUN (Linux host; export is not runtime proof) |
| Subjective approval of retained visual captures | NOT VERIFIED (human review item) |
| Process-termination recovery beyond pending-result retry | NOT VERIFIED |
| Prior Prompt 07 evidence preservation | PASS |

## 2. Preserved prior work

The concurrent Prompt 07 Event Battle QA session stopped with completed capture evidence and an in-progress Prompt 07.1 patch. No destructive history edit was used.

| Preservation item | Result |
|---|---|
| Parent baseline | Owner accepted `f9f4ed5` instead of restoring `de1c9f5`; forcing the old parent would have required a forbidden force update. |
| Prompt 07 capture evidence | 360 files: 180 PNG + 180 sidecar TXT, about 12 MB; largest 158,340 bytes; all PNGs validated; zero files over 1 MB. Saved on `backup/prompt07-event-battle-qa` at `b75c82131707214663b4ce2e292e72f035c5f806`; remote verified; no PR created; not merged. |
| Partial Prompt 07.1 patch | Saved on local-only `backup/prompt07.1-partial-implementation` at `bfbd4f3`, then applied cleanly to the recreated worktree. |
| Full parent delta patch | `/tmp/opencode/ffbe-logs/prompt-07.1/backup/full-parent-delta-de1c9f-to-f9f4ed5.patch`, SHA-256 `04b27fe09cbc3d8960a49db5fffae92f9d2ad76bec86a737454b3f7b22dfdc3a`. |
| Prompt 07 QA patch | `/tmp/opencode/ffbe-logs/prompt-07.1/backup/prompt07-event-battle-qa.patch`, SHA-256 `611bfbc34bde382ea8a64eeb9aab0ed07603b9bf54787bfcb2f3cad83fb22704`. |
| Partial implementation patch | `/tmp/opencode/ffbe-logs/prompt-07.1/backup/partial-implementation-complete.patch`, SHA-256 `534d2d763f1201f201c3b7711a5252634873a6519fbd050e9a4282a65c73a68e`. |
| Protected work files | `battle_scene.gd`, `event_center.gd`, capture scripts, visual report, all Prompt 07 screenshots and sidecars preserved; no Prompt 07 report was overwritten. |

## 3. Implemented changes

- `game/events/event_state_service.gd`: mission status is objective-qualified; `settle_battle()` advances only missions whose objective references the settled stage and validates event/stage ownership, encounter, region, unlock and `unlock_after` gating before mutation. Duplicate run IDs are a no-op before the write guard. `claim_mission()` claims numbered cycles through the canonical reward ledger and rolls back with the save transaction.
- `game/events/event_unlock_evaluator.gd`: centralized `none`, `event`, `stage` and `quest` evaluator. Malformed references, unknown kinds, missing definitions and cross-region IDs fail closed. `stage` and `event` use saved first-clear/completion data; `quest` reads existing world quest completion read-only.
- `game/events/event_repository.gd`: exposes objectives and unlock records to gameplay/UI.
- `game/core/content_repository.gd`: validates objective type/reference/event ownership/boss encounter and unlock kind/reference at content load.
- `game/core/player_state.gd`: additive `mission_cycles` inside the v4 `events` section, included in default state, migration backfill and validation. Version remains `4`.
- `game/scenes/event/event_center.gd`: uses evaluated unlock state and displays localized cycle/next-cycle labels for repeatable missions; layout and navigation unchanged.
- `game/data/events/events.json`: five synthetic missions across three events with explicit objectives and repeatability; six events and eight stages unchanged.
- Localization: `event.center.cycle`, `event.center.next_cycle` added to `vi`, `en`, `ja`; generated coverage artifact and report refreshed.
- Tests: focused GDScript suite and Python data contracts extended without removing baseline assertions.

## 4. Fresh validation evidence

All commands were run from `/tmp/opencode/ffbe-worktrees/prompt07.1` unless noted. Isolated user directories under `/tmp/opencode/ffbe-profiles/prompt-07.1-final-*` were used for Godot runs.

| # | Check | Actual command / log | Exit | Result |
|---|---|---|---:|---|
| 1 | Godot import | `godot --headless --editor --quit --path game --user-dir /tmp/opencode/ffbe-profiles/prompt-07.1-final-import` → `import/final-import.log` | 0 | 0 `SCRIPT ERROR` / `Parse Error` |
| 2 | Prompt 07 focused suite | focused runner → `focused/final-focused.log` | 0 | `PROMPT07_FOCUSED passed=334 failed=0 suite_ok=true`; 0 `ERROR: FAIL` |
| 3 | Full Godot suite | `godot --headless --path game --script res://tests/test_runner.gd` → `full/final-full.log` | 0 | `Results: 4184 passed, 0 failed`; 0 `ERROR: FAIL` |
| 4 | Negative control | `FFBE_TEST_NEGATIVE_CONTROL=1 godot --headless ... test_runner.gd` → `negative/final-negative.log` | 1 | `Results: 4184 passed, 1 failed`; expected deliberate-failure line present |
| 5 | Python discovery | `python3 -m unittest discover -s tests -v` → `python/final-discovery.log` | 0 | `Ran 119 tests`; `OK` |
| 6 | Importer security | `python3 -m unittest tests.test_phase3_importer -v` → `security/final-importer.log` | 0 | `Ran 22 tests`; `OK` |
| 7 | World + QA tooling | `python3 -m unittest tests.test_prompt06_world_data tests.test_phase3_qa_tools -v` → `world/final-world-qa.log` | 0 | `Ran 41 tests`; `OK` |
| 8 | Localization coverage | `python3 tools/localization/coverage_report.py` → `localization/final-coverage.log` | 0 | `status: pass`; union 919; world keys 45; event keys 33; missing 0; placeholder mismatches 0; dynamic references 280; dynamic errors 0; long labels 123 |
| 9 | Visual report | `python3 tools/qa/prompt07_visual_report.py` → `qa/final-visual.log` | 0 | `captures: 180` retained; no new capture matrix claimed |
| 10 | Linux export | Godot `--export-release "Linux"` → `linux-export/final-export.log` | 0 | ELF 64-bit x86-64 binary produced |
| 11 | Windows export | Godot `--export-release "Windows Desktop"` → `windows-export/final-export.log` | 0 | PE32+ x86-64 executable produced |
| 12 | Linux smoke | exported binary `--headless --quit-after 300` → `linux-smoke/final-smoke.log` | 0 | 0 error lines; v4 PlayerState reported with 6 owned units |
| 13 | Whitespace | `git diff --check` → `diff/final-diff-check.log` | 0 | clean |
| 14 | Staged audit | `git diff --cached --check` + `git diff --cached --name-status` → `staged/final-staged-check.log`, `final-staged-files.log` | 0 | clean; 14 implementation files in commit 1 (`f684909`) |
| 15 | Security / rights | staged extension, secret, protected-term, policy, count and size scan → `security/final-security-rights.log` | 0 | no forbidden binaries/archives/saves/executables; no secrets; protected terms none on word-boundary recheck; `rights_gate: not_passed`; 6 events / 8 stages |

Localization artifact check: 919 union keys, 45 world data keys, 33 event data keys, 0 missing, 0 placeholder mismatches, 280 dynamic references and 0 dynamic errors. The generated JSON and Markdown report are committed with the evidence.

## 5. Rights and repository safety

- All event records remain `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN`, `source_data_imported: false`, `rights_gate: not_passed`.
- No protected term matched on a word-boundary recheck of `events.json`; an earlier broad substring scan only matched the synthetic word `training`.
- No real-money purchase path, summon rate, guarantee, pool or historical banner was introduced.
- No secret pattern, protected archive, local save, executable, DLL/shared object or oversized asset was staged.
- Largest staged implementation source file: `game/tests/prompt07_event_test_suite.gd`, 50,916 bytes. No staged file exceeds 1 MB.
- No force push, hard reset, `git clean`, destructive rebase, automatic merge or `main` change was performed.

## 6. Skills and documentation

Loaded project skills: `ffbe-godot-foundation`, `ffbe-battle-engine`, `rpg`, `save-systems`, `godot-gdscript-headless-testing`, `ffbe-project-quality`, `ffbe-source-audit`, `godot-export`. No event-system skill exists; vendored instructions were inspected but no third-party script was executed.

Created:

- `docs/architecture/event-progression-integrity.md`
- `docs/data-dictionary/event-mission-schema.md`
- `docs/qa/prompt07-1-final-report.md` (this file)

Updated: `docs/architecture/event-center.md`, `docs/data-dictionary/event-schema.md`, `docs/localization/coverage-report.md` and `data/validation/localization-coverage.json`. Prompt 07 reports were left intact as historical evidence. README and PROJECT_PLAN were not changed because no milestone scope or top-level workflow changed.

## 7. Remaining limitations

- Successful and unsuccessful unlock prerequisites are exercised with synthetic test-local packs; shipped fixtures still declare `unlock.kind = "none"` so the retained Prompt 07 visual matrix is unchanged.
- Subjective visual approval of the 180 retained captures is a human review item; automated evidence covers structure, capture count and zero runtime error lines only.
- Windows runtime compatibility is NOT RUN; only a Windows export artifact was produced on Linux.
- Crash/process-termination recovery beyond the existing in-memory pending-result Retry path is NOT VERIFIED.
- Event missions remain a minimal counter model and do not create or mutate world quests.
- No PR merge is performed; owner review is required before any next prompt.
