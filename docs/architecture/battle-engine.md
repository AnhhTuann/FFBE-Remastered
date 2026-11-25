# Battle engine architecture

**Milestone:** Phase 2 offline combat vertical slice
**Engine:** Godot 4.7.2-stable, GDScript
**Status:** Implemented and tested with synthetic fixtures only
**Scope boundary:** The simulation is independent of Godot nodes, animation playback, and the battle HUD.

---

## 1. Purpose

This document describes the runtime design of the offline battle slice added in `game/battle/`. It explains module ownership, the deterministic execution model, event contracts, and the boundary between simulation and presentation. Mechanics evidence and evidence labels live in [combat-mechanics-research.md](../game-design/combat-mechanics-research.md); field-level data contracts live in [battle-schema.md](../data-dictionary/battle-schema.md).

No FFBE sprite, ability, unit, enemy, item, reward, or extracted game table is used. All combat data comes from `game/data/battles.json`, whose top-level marker is `SYNTHETIC_FIXTURE`.

## 2. Module map

| Module | File | Responsibility |
|---|---|---|
| `BattleManager` | `game/battle/battle_manager.gd` | Orchestrates validation, queueing, player execution, enemy execution, outcome and rewards. Emits events. |
| `BattleState` | `game/battle/battle_state.gd` | Mutable encounter snapshot: party, enemies, turn, phase, events, chain display values, result. |
| `TurnManager` | `game/battle/turn_manager.gd` | Explicit phase state machine: `player`, `player_execution`, `enemy_execution`, `victory`, `defeat`. |
| `ActionQueue` | `game/battle/action_queue.gd` | Holds validated `BattleAction` objects and expands them into scheduled hits/effects. |
| `CombatantState` | `game/battle/combatant_state.gd` | Mutable per-combatant HP/MP/LB/status/guard, with immutable definitions copied at construction. |
| `DamageCalculator` | `game/battle/damage_calculator.gd` | Physical/magical damage factor trace and amount. |
| `ElementResolver` | `game/battle/element_resolver.gd` | Multi-element averaging and resist/imperil multiplier. |
| `TargetResolver` | `game/battle/target_resolver.gd` | Legality checks and `all_allies`/`all_enemies` expansion. |
| `StatusEffectManager` | `game/battle/status_effect_manager.gd` | Buffs, breaks, imperils, ailments, potency replacement, durations and turn ticks. |
| `ChainManager` | `game/battle/chain_manager.gd` | Frame-window chain registration, spark detection and modifier cap. |
| `LimitBurstManager` | `game/battle/limit_burst_manager.gd` | Gauge fill, per-turn automatic cap, readiness and consumption. |
| `EnemyAI` | `game/battle/enemy_ai.gd` | Deterministic data-driven action choice, cooldowns and target rules. |
| `BattleResult` | `game/battle/battle_result.gd` | Plain-data outcome record for UI and persistence. |
| `RewardResolver` | `game/battle/reward_resolver.gd` | Victory-only gil and item reward snapshot. |
| `BattleRNG` | `game/battle/battle_rng.gd` | Seedable, snapshottable randomness. |
| `BattleClock` | `game/battle/battle_clock.gd` | Integer logical frame counter. |
| `BattleEvent`, `ScheduledHit`, `BattleAction` | `game/battle/*.gd` | Typed data carriers. |
| `BattleSprite` | `game/battle/battle_sprite.gd` | Reuses the Phase 1 synthetic animation pipeline for combat clips. |

The battle scene (`game/scenes/battle/battle_scene.gd`) builds its UI from `Control` nodes at runtime. It owns no damage rules: it submits commands to `BattleManager`, consumes emitted events, and advances the visual clock on a `Timer`.

## 3. Execution lifecycle

1. **Construction.** `BattleManager._init()` receives encounter, combatant, ability and item dictionaries plus an integer seed. It deep-copies definitions, so runtime mutations never modify immutable content.
2. **Start.** `start_battle()` resets clock, RNG, turn state, chain state, LB turn state and enemy cooldowns, then emits `battle_start`.
3. **Player input.** `validate_action()` checks actor availability, target legality, MP, action-blocking statuses, LB readiness and item uses. `queue_action()`, `queue_guard()` and `use_item()` add only validated actions.
4. **Execution start.** `begin_execution()` spends MP, consumes ready LB gauges, increments item use counts, emits `action_started`, and expands actions into a sorted `Array[ScheduledHit]`.
5. **Logical advance.** `advance_frames(n)` moves `BattleClock`, applies every scheduled entry whose `frame <= clock.frame`, emits resulting events, and checks outcome after each damage application.
6. **Enemy phase.** When the player schedule is exhausted, `_begin_enemy_phase()` asks `EnemyAI` for actions and schedules them on the same clock.
7. **Turn boundary.** Status ticks, outcome checks, turn flag resets, LB turn reset and chain reset occur in `_after_execution()`. `TurnManager.end_turn()` then returns control to the player.
8. **Result.** `_check_outcome()` calls `finish()` when one side is empty. `finish()` creates `BattleResult`, resolves rewards, sets phase to `victory`/`defeat`, and emits `battle_end` plus an animation event.

`execute_turn(max_frames)` is a convenience loop used by tests and non-visual callers. It never depends on the scene tree.

## 4. Determinism and time

- `BattleRNG` owns all stochastic decisions: weapon variance, final variance, heal variance, status chance, AI weighted choices and random targeting.
- `BattleClock` uses integer logical frames. Speed controls in the UI change how many logical frames are advanced per visual timer tick; they do not change any rule.
- Scheduled effects sort by frame, actor order, hit index and effect index. This makes overlapping hits reproducible.
- `BattleState.snapshot()` and `BattleRNG.snapshot()` are compared byte-for-byte in deterministic replay tests.
- QA-only environment hooks (`FFBE_QA_SCENARIO`, `FFBE_QA_ENCOUNTER`, `FFBE_QA_SEED`, `FFBE_QA_FREEZE_FRAME`) control setup and capture timing. They do not add gameplay rules.

## 5. Event contract

Every emitted event is a dictionary with `frame`, `type`, and `data`. Important types include:

| Type | Meaning |
|---|---|
| `battle_start`, `battle_end` | Encounter lifecycle. |
| `action_queued`, `action_rejected`, `action_started`, `queue_cleared` | Command flow. |
| `execution_started`, `phase_changed`, `turn_started` | Phase transitions. |
| `animation` | Presentation hint only (`attack`, `skill`, `damage`, `victory`, `defeat`). |
| `damage`, `heal`, `mp_restore`, `lb_fill`, `guard` | Applied state changes. |
| `chain` | Chain count, modifier, spark flag and actor/frame. |
| `buff`, `break`, `imperil`, `status`, `status_tick`, `status_expired` | Effect application and duration. |
| `limit_burst` | Gauge consumption. |
| `defeat_combatant` | Individual combatant downed. |
| `unsupported_effect` | Unknown or deliberately unsupported effect; no silent mutation. |

The HUD translates events into labels and card refreshes. Damage calculation never waits for animation completion.

## 6. Rule implementation summary

### Damage and mitigation

`DamageCalculator.calculate()` follows the documented factor structure: `offensive_stat² / defensive_stat × modifier × level_correction × weapon_variance × final_variance × chain_bonus × element_multiplier × guard_multiplier`, with a minimum of 1. Physical uses ATK/DEF and magical uses MAG/SPR. Hybrid damage, equipment killers, critical hits, weapon ATK correction and passive layers are intentionally absent and are not claimed.

Guard multiplies incoming damage by 0.5. Element resistances are stored as whole percentages and divided by 100 before averaging. Imperil increases the multiplier for its element.

### Buffs, breaks and statuses

Same-kind buffs/breaks replace by potency; a buff and a break of the same stat coexist and net add (`buff - break`). Supported stats are HP, MP, ATK, DEF, MAG and SPR. Sleep, paralyze, petrify and confuse block actions; silence blocks magical actions. Poison and regen tick at turn boundaries. The dormant/active layer model is not implemented and is not claimed.

### Chaining

Desktop chaining is implemented as overlapping timed hits from different actors. A different actor within 20 logical frames links a chain; a zero-frame gap is a spark. Normal links add 10%, sparks add 40%, each shared non-neutral element adds 20%, and the modifier is capped at 300%. The same actor or a gap above 20 frames resets the chain. This is an explicit remastered desktop equivalent, not a claim of exact frame-for-frame original behaviour.

### Limit Burst

Automatic gauge filling is capped at 12 crysts per combatant per turn. Explicit ability/item gauge effects are fixture-authored. `lb_cost` comes from each combatant definition; readiness and consumption are checked before scheduling.

### Enemy AI

`EnemyAI.decide_actions()` selects abilities from each enemy's data-driven pattern using seeded weights, HP gates and cooldowns. Target rules are actor-relative: `all_allies` means the enemy's own side, `all_enemies` means the player party; `lowest_hp`, `highest_atk` and `random` select party members. This distinction is tested, including a regression where enemy area abilities previously used `all_allies` and struck the wrong side.

## 7. Presentation boundary

- `battle_scene.gd` constructs enemies on the left, party on the right, a reserved companion slot, bottom character panels, HP/MP/LB bars, command buttons, ability/item panels, target highlighting, speed/pause controls, result overlay, turn/chain labels and floating event labels.
- Only implemented commands are enabled. Items are limited to synthetic potion/ether fixtures; guard, abilities and Limit Bursts are enabled only when legal.
- Mouse and keyboard are supported. Controller input is intentionally not supported and is documented as absent.
- Pixel-art proportions are preserved: the synthetic 128×128 atlas uses 32×32 frames with nearest-neighbour filtering. No background or sprite is stretched by battle logic.

## 8. Persistence boundary

`BattleManager` does not write saves. The scene calls `SaveManager.record_battle_result(result.to_dict())` when a result is shown. `SaveManager` stores version 2 JSON at `user://battle_progress.json` with atomic writes, backup fallback, validation and version 1 migration. Reward totals are local synthetic progression only; there is no inventory, equipment or summon system.

## 9. Testing strategy

`game/tests/battle_test_suite.gd` exercises the engine directly through `RefCounted` classes. It covers initialization, role coverage, definition immutability, validation, target legality, turn transitions, physical/magical damage, guard, elements, healing, MP, buffs, breaks, statuses, multi-hit, chain timing/reset/cap, LB, AI, victory, defeat, rewards, save migration, unsupported effects, items, deterministic replay and clock/event behaviour. A negative control changing one expected party count makes the runner exit non-zero, proving failures are detectable.
