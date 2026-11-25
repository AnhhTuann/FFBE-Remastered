# Prompt 04.6 test and verification report

All commands were run from the repository root unless shown otherwise. Logs were
written outside Git in the prompt-scoped QA log area; no log, save file, export
template or executable was committed.

## 1. Regression matrix

| Check | Command | Exit | Result |
|---|---|---:|---|
| Godot import | `godot --headless --path game --import` | `0` | Project import completed; three pre-existing `Unicode parsing error ... (400000)` warnings emitted while scanning older binary files |
| Godot full suite | `godot --headless --path game --script res://tests/test_runner.gd` | `0` | `2153 passed, 0 failed` |
| Negative control | `FFBE_TEST_NEGATIVE_CONTROL=1 godot --headless --path game --script res://tests/test_runner.gd` | `1` | `2153 passed, 1 failed`; the only failure is the deliberate control |
| Baseline subset | Temporary runner from the Phase 3 baseline with Phase 3 and hardening suites removed | `0` | `224 passed, 0 failed` |
| Python suite | `python3 -m unittest discover -s tests -v` | `0` | `61 tests`, `OK` |
| Importer suite | `python3 -m unittest tests.test_phase3_importer -v` | `0` | `22 tests`, `OK` |
| Localization suite | `python3 -m unittest tests.test_phase3_localization -v` | `0` | `11 tests`, `OK` |
| QA tool suite | `python3 -m unittest tests.test_phase3_qa_tools -v` | `0` | `8 tests`, `OK` |
| Localization report | `python3 tools/localization/coverage_report.py` | `0` | `status: pass`, `union keys: 495`, `missing keys: 0`, `placeholder mismatches: 0` |
| Visual report | `python3 tools/qa/phase3_visual_report.py --captures-dir docs/qa/screenshots/hardening --output docs/qa/phase3-hardening-visual-review.md` | `0` | `30` hardening captures, `0` runtime error lines |
| Diff hygiene | `git diff --check` | `0` | No whitespace errors |

The full Godot count includes the original baseline checks, the Phase 3 suite,
the new 214-assertion layout suite, the new UI-flow suite, and the negative
control test entry. The UI-flow suite is awaited explicitly because it drives
real scene transitions.

## 2. Importer adversarial coverage

`tests/test_phase3_importer.py` now contains 22 passing tests: the original 11
plus self-declared clearance rejection, forged pack approval rejection, exact
registry authorization, hash mismatch and modified-pack rejection, expiry and
revocation denial, explicit `VERIFIED` evidence requirement, strict status
allowlists, restricted FFBE/Elvlin rejection, malformed-registry fail-closed,
declared-hash non-authorization, and transactional rollback after partial
failure.

## 3. Layout and interaction coverage

`game/tests/hardening_layout_test_suite.gd` reports `214 passed, 0 failed` when
run directly. It checks viewport geometry, minimum widths and heights, card
budgets, clipped names, sprite containment and aspect ratio, debug/player
separation, no empty companion slot, and long Japanese/Vietnamese labels at
`1024x640`, `1280x720`, and `1920x1080`.

`game/tests/hardening_ui_flow_test_suite.gd` drives real Godot control signals
and scene navigation across boot/menu, locale switching and persistence,
collection search/details, upgrade, equipment, materia, Vision Cards, party
composition, battle action selection, victory rewards, save reload, and
v1→v2→v3 migration plus newer-save refusal. It snapshots and restores state,
settings, locale, environment and `user://` files. It does not use OS-level
input injection or claim visual verification.

## 4. Export verification

See `docs/qa/phase3-hardening-export-report.md`. Both Linux and Windows release
exports exited `0`; the Linux executable smoke exited `0` with no error lines.
Windows launch and Windows runtime remain `NOT RUN` because this host is Linux.

## 5. Security and size review

| Check | Result |
|---|---|
| Publishable files scanned | `580` |
| Publishable bytes scanned | `19,568,725` |
| Secret-pattern hits | `0` |
| Protected archive / executable extensions in Git scope | `0` |
| Local save candidates in Git scope | `1` synthetic fixture: `game/data/save_fixtures/v1_save_slot_0.json` |
| Machine-specific absolute paths in changed/new text files | `0` |
| `.git` size | `14 MB` |
| Working tree excluding ignored build outputs | `22 MB` |
| Tracked Agent Skill files | `12` files across all nine skills |

The synthetic save fixture is test data, not owner save state. Build outputs,
export templates, logs, and user data are ignored by Git.
