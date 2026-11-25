# Phase 2 final report — offline combat vertical slice

**Date:** 2026-11-25 (UTC)
**Branch:** `phase-2-battle-engine`
**Base:** local Phase 1 commit `d025bad3e736f090e60defb4341e3c2d92123f26`
**Earlier foundation:** `ffd3e640e362cc4423039b17274f7cf983481fa9`
**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`
**Commit:** This report is part of the local Phase 2 commit on `phase-2-battle-engine`; the exact hash is available from `git log -1` after commit. Nothing was pushed.

---

## A. Deliverable summary

Phase 2 delivers a playable, offline, deterministic battle vertical slice using only project-authored `SYNTHETIC_FIXTURE` data. It includes a five-character party, skirmish and boss encounters, attacks, representative abilities, healing, buffs, breaks, imperils, status ailments, guard, items, multi-hit skills, desktop chaining, Limit Bursts, enemy AI, victory/defeat, rewards, and local battle-progress persistence.

The simulation is UI-independent. `BattleManager` and its supporting `RefCounted` systems run without scenes, animations or input. The Godot battle scene submits commands, consumes events and advances a logical 60 Hz clock.

No FFBE asset, character, ability, item, enemy or reward was imported. No claim of full game restoration is made.

## B. Git and repository integrity

- Work started from the verified local Phase 1 tip `d025bad3e736f090e60defb4341e3c2d92123f26`.
- The local branch `phase-2-battle-engine` was used; `origin/main` was not used as the base.
- The Phase 1 skill commit `46b68cf3affc12375fadbfd5b22265ddc7940463` is present in the ancestry.
- No merge into `main`, force push, reset, clean, or push was performed.
- Temporary diagnostic files were removed before finalization.
- No protected asset, raw source archive, or generated executable was added to the commit. The Linux PCK is a local build artifact under `game/build/pack/` and is excluded from the intended commit scope unless already tracked.

## C. Skills used

All nine required skills were loaded and actively applied:

| Skill | How it was used |
|---|---|
| `ffbe-battle-engine` | Module boundaries, event-driven execution, chain/LB design, synthetic-only mechanic classification, UI independence. |
| `ffbe-godot-foundation` | Godot 4.7.2 pinning, `Control`-based runtime UI, typed GDScript, pixel-art scaling policy, desktop input mapping. |
| `ffbe-project-quality` | Milestone gates, reproducible commands, Git safety, regression evidence, no protected assets, no push. |
| `ffbe-source-audit` | Reviewed supplemental manifest status `supplemental_evidence_only`, rights gate `not_passed`, regional identity rules and evidence limitations. |
| `ffbe-asset-restoration` | Reused the validated synthetic atlas and animation aliases; verified no protected animation import. |
| `godot-gdscript-headless-testing` | SceneTree runner, non-zero exit on failure, negative control, log inspection for `SCRIPT ERROR`/`ERROR:`. |
| `godot-export` | Reviewed presets, ran export CLI commands, generated a PCK, diagnosed missing export templates. |
| `rpg` | Stat/damage factor structure, buff/break stacking, healing, rewards and role balance for the synthetic fixtures. |
| `save-systems` | Version 2 JSON progress, atomic writes, backup fallback, validation, v1 migration and persistence tests. |

Third-party skill files were inspected, not executed. No untrusted archive was run.

## D. Combat research and evidence policy

`docs/game-design/combat-mechanics-research.md` records cached community-wiki wikitext with literal quotes and section anchors. Every mechanic row is labelled exactly one of `VERIFIED_RULE`, `PARTIAL_RULE`, `UNVERIFIED_RULE`, or `REMASTERED_DESIGN`.

Important separations:

- Damage factor structure and several timing values are community-documented, not rights-cleared or client-source-verified.
- The implemented variance, modifiers, AI patterns, LB explicit fills and reward values are `REMASTERED_DESIGN` fixture values.
- Full dual wield, multi-cast, dormant effect layers, hybrid damage and exact JP/GL divergences are not claimed.
- Where GL/JP evidence is unavailable or uncertain, the research document keeps the difference identifiable rather than merging records.

## E. Engine architecture

`docs/architecture/battle-engine.md` documents the module map and lifecycle. Core files are under `game/battle/`:

- orchestration: `BattleManager`, `BattleState`, `TurnManager`, `ActionQueue`
- state carriers: `CombatantState`, `BattleAction`, `ScheduledHit`, `BattleEvent`, `BattleResult`
- rules: `DamageCalculator`, `ElementResolver`, `TargetResolver`, `StatusEffectManager`, `ChainManager`, `LimitBurstManager`, `EnemyAI`, `RewardResolver`, `EffectResolver`
- determinism: `BattleRNG`, `BattleClock`

The battle scene builds its UI at runtime from `Control` nodes in `game/scenes/battle/battle_scene.gd`; the `.tscn` is a minimal host. Simulation never reads node state.

## F. Playable loop

The Main Menu has a `Battle — Synthetic Encounter` button. In battle, the player can select any of five units, choose Attack, Abilities, Limit Burst, Items or Guard, select targets, queue multiple actions, execute, clear, pause, change speed, retry and return to the Main Menu.

All enabled controls affect real battle state:

- MP is spent at execution, item uses are consumed, guard sets a one-turn flag.
- Damage, healing, statuses, buffs, breaks, imperils and LB gauges are applied from scheduled effects.
- LB commands are enabled only when the actor's gauge is full and the action matches its LB ID.
- Unknown effects emit `unsupported_effect` and mutate nothing.
- Victory and defeat overlays show encounter name, turns, seed, gil and items.

## G. Desktop UI and input

The native landscape layout targets 1280×720 baseline and 1920×1080 primary display. It uses anchors/containers, enemies left, party right, central battlefield, bottom character panels, HP/MP/LB gauges, command row, ability/item panels, target highlighting, turn/chain labels and floating damage/chain labels.

A reserved companion slot is rendered but not interactive. Mouse and keyboard are supported. Controller support is intentionally absent and documented in the visual review. The existing synthetic pixel atlas retains 32×32 frames and nearest-neighbour filtering; battle logic does not stretch sprites.

## H. Determinism and replay

All randomness is seeded through `BattleRNG`. Time is an integer logical frame count in `BattleClock`. Actions become sorted scheduled hits. Speed controls change only how many logical frames advance per visual tick.

Deterministic tests compare event timelines, RNG snapshots and full battle snapshots for identical seed/commands. AI decisions are also replayed with the same seed. Chaining uses logical frame gaps: different actor within 20 frames links, gap 0 is spark, same actor or gap >20 resets, cap 300%.

## I. Automated verification

| Gate | Result |
|---|---|
| Python baseline and final | `20 tests`, `OK`, exit 0 |
| Godot baseline | `74 passed, 0 failed` |
| Godot final | `224 passed, 0 failed`, exit 0 |
| Added assertions | 150 over baseline |
| Negative control | `223 passed, 1 failed`, exit 1; expectation restored and rerun clean |
| Scene smoke | boot, menu, viewer, settings, seven battle scenarios: exit 0, no errors |
| Final error scan | no `SCRIPT ERROR`, leading `ERROR:`, or `FAIL` lines |

Detailed commands and evidence are in `docs/qa/phase2-test-report.md`.

## J. Persistence and progression

`SaveManager` stores `user://battle_progress.json` at format version 2 with atomic writes, backup fallback and validation. Each result records attempts, last result, per-encounter clears, best turns, total synthetic gil and item counts on victory. Version 1 `completed` arrays migrate to version 2 clears; newer versions are refused.

This is synthetic local progression only. No full inventory, equipment, materia or summon system was added.

## K. Visual QA

Seventeen real screenshots were captured from live Godot windows:

- eight battle states at 1280×720
- the same eight states at 1920×1080
- one smaller 1024×640 resizable window

States include battle start, party formation, ability selection, damage/chain display, Limit Burst, boss encounter, victory and defeat. Every capture has verified geometry, non-uniform pixel statistics and zero runtime errors. State-distinctness comparisons confirm the frames are not duplicates. See `docs/qa/phase2-visual-review.md`.

The model cannot visually inspect PNG content, so no subjective visual-quality claim is made.

## L. Export and runtime status

| Item | Status |
|---|---|
| Export presets configured | PASS — Windows Desktop and Linux in `game/export_presets.cfg`. |
| Linux PCK generated | PASS — `game/build/pack/phase2-linux.pck`, 212,556 bytes. |
| Linux executable generated | BLOCKED — missing matching 4.7.2.stable templates. |
| Windows executable generated | BLOCKED — missing matching 4.7.2.stable templates. |
| Executable launched | NOT RUN — no executable generated. |
| Windows runtime tested | NOT RUN — no Windows runtime available on this host. |

Exact missing files: `linux_debug.x86_64`, `linux_release.x86_64`, `windows_debug_x86_64.exe`, `windows_release_x86_64.exe` under `/home/tuan/.local/share/godot/export_templates/4.7.2.stable/`.

To unblock: install the official Godot `4.7.2.stable` export templates for this exact version into that directory, then rerun the two `--export-release` commands from the test report. No silent upgrade or unauthorized installation was performed.

## M. Scope limits and unresolved risks

- Complete summon, equipment, materia, inventory progression, world exploration, story campaign, multiplayer and server reconstruction remain out of scope.
- FFBE asset/data redistribution rights remain unresolved; supplemental manifest status is `supplemental_evidence_only` and rights gate is `not_passed`.
- GL/JP differences are documented as uncertainty, not merged into a single canon.
- Chaining is a deterministic desktop equivalent, not a claim of frame-perfect original behaviour.
- Controller support is absent.
- Standalone Windows/Linux executables are blocked by missing export templates.

## N. Definition of Done

| # | Criterion | Status | Evidence |
|---:|---|---|---|
| 1 | Local branch created from completed Phase 0/Phase 1 foundation; no push or merge | **PASS** | `phase-2-battle-engine` from `d025bad`; Git graph and status reviewed. |
| 2 | All nine required skills verified and actively used | **PASS** | Section C; skill instructions and project-local references applied. |
| 3 | Phase 0/1 regressions preserved: 20 Python and 74 Godot checks still pass; scenes functional | **PASS** | Baseline logs and final 20/224 results; boot/menu/viewer/settings smoke clean. |
| 4 | Evidence-led combat research with explicit mechanic labels and identifiable GL/JP uncertainty | **PASS** | `combat-mechanics-research.md`. |
| 5 | Modular UI-independent battle engine | **PASS** | `game/battle/` modules; suite runs without scene/animation. |
| 6 | Deterministic seeded randomness, logical clock and explicit events | **PASS** | `BattleRNG`, `BattleClock`, replay/snapshot tests. |
| 7 | Complete playable loop with real state changes, victory/defeat, retry and menu return | **PASS** | Battle scene, smoke scenarios, outcome tests. |
| 8 | Native 1280×720/1920×1080 desktop UI; only implemented controls enabled; controller absence documented | **PASS** | Visual review and scene code. |
| 9 | Desktop chaining equivalent with overlap, counts and deterministic timing tests | **PASS** | `ChainManager`; chain QA scenario; chain tests. |
| 10 | Synthetic animation pipeline reused for combat events without tying damage to animation completion | **PASS** | `BattleSprite`, animation aliases, scheduling architecture. |
| 11 | Five distinct controllable fixtures plus boss/multi-enemy encounter, all synthetic | **PASS** | `battles.json`; initialization tests. |
| 12 | SaveManager battle records, local rewards, synthetic progression and migration compatibility | **PASS** | Version 2 progress, tests for persistence and v1 migration. |
| 13 | Automated deterministic tests for required cases; runner exits non-zero on failure | **PASS** | 224 checks; negative control exit 1. |
| 14 | Real visual QA screenshots at required resolutions and states, no fabrication | **PASS** | 17 PNG captures with geometry, logs and distinctness metrics. |
| 15 | Export templates checked; executables generated if available, otherwise exact blocker documented | **BLOCKED** | PCK generated; release exports fail on missing 4.7.2.stable templates; Windows/Linux executable launch and runtime test `NOT RUN`. |

**Final verdict:** The Phase 2 offline combat vertical slice is functionally complete and verified by automated and visual evidence. Native executable release packaging is blocked solely by missing matching Godot export templates, not by unresolved source-code defects.
