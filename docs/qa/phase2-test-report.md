# Phase 2 test report

**Milestone:** Phase 2 — offline combat vertical slice
**Date:** 2026-11-25 (UTC)
**Branch:** `phase-2-battle-engine`
**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`
**Scope:** Deterministic engine tests, regression tests, scene smoke tests, negative control, and export verification.

---

## 1. Environment and method

All automated checks were run from the repository root with the pinned Godot binary. Logs were written under `/tmp/opencode/ffbe-logs/`. Python uses the repository's standard `unittest` discovery; Godot uses the SceneTree runner `game/tests/test_runner.gd`, which exits non-zero on any failed assertion.

The battle suite (`game/tests/battle_test_suite.gd`) is a `RefCounted` class that loads the engine scripts directly. It does not instantiate the battle scene, so it proves UI independence.

## 2. Baseline regression preservation

| Check | Command | Result | Exit | Log |
|---|---|---|---|---|
| Python baseline before implementation | `python3 -m unittest discover -s tests -v` | `Ran 20 tests`, `OK` | 0 | `phase2-baseline-python.log` |
| Godot import before implementation | `godot --headless --path game --import` | clean | 0 | `phase2-baseline-import.log` |
| Godot baseline before implementation | `godot --headless --path game --script res://tests/test_runner.gd` | `74 passed, 0 failed` | 0 | `phase2-baseline-godot.log` |
| Phase 1 scenes after integration | headless smoke of boot, menu, viewer, settings | no `SCRIPT ERROR` or `ERROR:` | 0 each | `phase2-smoke-*-final.log` |

The Phase 1 negative control from the earlier milestone was preserved: changing the expected unit count to `77` produced `73 passed, 1 failed` and exit `1`, then the file was restored.

## 3. Final automated results

| Check | Command | Result | Exit | Log |
|---|---|---|---|---|
| Python after implementation | `python3 -m unittest discover -s tests -v` | `Ran 20 tests`, `OK` | 0 | `phase2-python-final.log` |
| Godot import after implementation | `godot --headless --path game --import` | clean | 0 | `phase2-import-final.log` |
| Godot after implementation | `godot --headless --path game --script res://tests/test_runner.gd` | `224 passed, 0 failed` | 0 | `phase2-godot-final.log`, `phase2-godot-restored.log` |
| Repeated Godot run after QA UI edits | same command | `224 passed, 0 failed` | 0 | `phase2-godot-qa-ui.log` |

The final runner has 150 more assertions than the 74-check baseline. Final logs contain no `SCRIPT ERROR`, leading `ERROR:`, or `FAIL` lines.

## 4. Negative control on the new battle suite

An intentional wrong expectation was temporarily introduced in `game/tests/battle_test_suite.gd`:

```gdscript
_eq(state.party.size(), 6, "party size")
```

Result:

- Exit code: `1`
- Runner: `223 passed, 1 failed`
- Failure line: `ERROR: FAIL party size: expected 6, got 5`

The expectation was immediately restored to `5`, and the suite was rerun successfully (`224 passed, 0 failed`). This proves the added battle assertions are wired into the runner's non-zero exit path.

The temporary scripts `game/tests/compile_check.gd` and `game/tests/diag.gd` used during development were removed. Script compilation is now covered by the permanent runner loading `battle_test_suite.gd`, which in turn loads every engine script.

## 5. Battle test coverage

| Area | Assertions examined |
|---|---|
| Initialization | five-unit party, skirmish/boss enemy counts, turn/phase, role coverage, boss flag, fixture markers. |
| Immutability | JSON of an immutable combatant definition unchanged after battle actions. |
| Action validation | unknown actor, unknown ability, wrong-side target, LB not ready, heal target side, guard queue, input locked during execution. |
| Targeting | `all_allies`, `all_enemies`, `self`, missing target, downed target. |
| Turn transitions | player → player execution → player, turn increment, second execution. |
| Damage | physical ATK/DEF, magical MAG/SPR, level correction, final variance range, unsupported damage kind. |
| Mitigation/elements | guard multiplier and reduced damage, elemental resistance, imperil multiplier increase. |
| Healing/MP | heal increases HP, MP consumed, exact MP cost, overheal clamp. |
| Buffs/breaks/statuses | effective ATK rises, strongest effect dominates, duration expiry, sleep action block, poison tick, silence magic block. |
| Multi-hit/chains | seven hits from two multi-hit abilities, chain events, normal link, spark link, element bonus, same-actor reset, timeout reset, 300% cap. |
| Limit Burst | 12-cryst automatic cap, readiness at full gauge, consumption/reset, turn cap reset, LB damage event. |
| Enemy AI | boss schedules two distinct actions, cooldown tracking, deterministic decisions for the same seed. |
| Outcome/rewards | victory result, gil/item rewards, defeat no-reward path, save record, clear/gil/item persistence, v1 migration. |
| Defeat | party wiped by deterministic seeded enemy area attack; defeat result has no reward. |
| Unsupported effects | unknown effect is reported and does not mutate target HP. |
| Items | potion heals, one-use exhaustion. |
| Deterministic replay | identical event timeline, RNG snapshot and state snapshot for the same seed/commands. |
| Clock/events | reset, frame advance, negative clamp, one `battle_start`, no effects without a schedule. |

A regression found during testing was fixed: enemy area abilities were labelled with actor-relative `all_allies`, which made them hit the enemy side. Fixture targeting and `EnemyAI` group rules now use `all_enemies` for attacks against the party, and defeat tests assert the corrected behaviour.

## 6. Scene smoke tests

Each command used `--headless --quit-after` and was checked for exit code and error lines.

| Scene / scenario | Exit | Errors |
|---|---|---|
| `res://scenes/boot/boot.tscn` | 0 | 0 |
| `res://scenes/menu/main_menu.tscn` | 0 | 0 |
| `res://scenes/viewer/character_viewer.tscn` | 0 | 0 |
| `res://scenes/settings/settings.tscn` | 0 | 0 |
| battle scenario `start` | 0 | 0 |
| battle scenario `formation` | 0 | 0 |
| battle scenario `abilities` | 0 | 0 |
| battle scenario `chain` | 0 | 0 |
| battle scenario `limit` | 0 | 0 |
| battle scenario `victory` | 0 | 0 |
| battle scenario `defeat` | 0 | 0 |

Two QA UI defects were found by these smoke runs and fixed before final capture: a `BattleResult` property was read with a two-argument dictionary `get()`, and the victory QA hook iterated the reserved companion slot with a null combatant reference. Both were corrected and the scenarios were rerun clean.

## 7. Export verification

| Item | Status | Evidence |
|---|---|---|
| Windows and Linux presets configured | PASS | `game/export_presets.cfg`: `Windows Desktop`, `Linux`, JSON/PNG/SVG/import filters. |
| Linux PCK generated | PASS | `game/build/pack/phase2-linux.pck`, 212,556 bytes, exit 0. |
| Linux executable generated | BLOCKED | Missing `linux_debug.x86_64` and `linux_release.x86_64` templates. |
| Windows executable generated | BLOCKED | Missing `windows_debug_x86_64.exe` and `windows_release_x86_64.exe` templates. |
| Windows executable launched/runtime tested | NOT RUN | No executable was generated and no Windows runtime is available on this host. |

The export directory `/home/tuan/.local/share/godot/export_templates/4.7.2.stable/` is absent. Godot release export exits 1 and names the four exact missing template files. Export logs: `phase2-export-linux.log`, `phase2-export-windows.log`, `phase2-export-pack-2.log`.

The PCK export logs three non-fatal `Unicode parsing error, some characters were replaced with...` messages during project initialization. The PCK still completed with exit 0; these messages are recorded but not treated as a gameplay test failure.

## 8. Conclusion

All automated gameplay, persistence, replay and regression checks pass. The only unresolved verification item is native executable export, which is blocked by missing matching Godot export templates and is not a source-code failure. See [phase2-final-report.md](phase2-final-report.md) for the Definition of Done matrix.
