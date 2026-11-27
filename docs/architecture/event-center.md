# Event Center architecture

**Status:** Prompt 07 foundation, hardened in Prompt 07.1; presentation redesigned in Prompt 07.2 — implemented architecture and verification record. All runtime event content is project-authored `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN`.
**Rights gate:** `not_passed`. No FFBE/Elvlin story, character, art, music, banner rate, guarantee, pool or dialogue is used or claimed.
**Engine:** Godot 4.7.2 stable; Godot project root `game/`.
**Save format:** additive `events` section inside the existing v4 `user://player_state_v3.json`. Prompt 07.1 adds `mission_cycles` without changing `PLAYER_STATE_VERSION`.

Prompt 07.1 objective-qualified progression, repeatable cycles, claim identity and unlock evaluation are specified in [event-progression-integrity.md](event-progression-integrity.md) and [event-mission-schema.md](../data-dictionary/event-mission-schema.md). The presentation-only Prompt 07.2 redesign is specified in [event-center-visual-design.md](event-center-visual-design.md). This document remains the historical Prompt 07 architecture record plus the integration points updated below.

## 1. Scope and non-goals

Prompt 07 adds an offline, data-driven Event Center foundation: scheduled/permanent/archive events, stages, first-clear and repeatable rewards, event currency and shop foundation, event missions, collaboration fixtures, replay, and event-linked summon references. It is **not** a restoration of original FFBE events and does not add real-money purchases, new battle rules or a second reward system. Prompt 08 is not started.

## 2. Integration plan (authorized before implementation)

The following existing systems were inspected and will be reused rather than duplicated:

| Existing system | File | Integration decision |
|---|---|---|
| Save/migration | `game/core/player_state.gd` | Add `events` beside `world` in `default_state()` (after line 211); add `default_event_state()` after `default_world_state()` (line 234); backfill with `_ensure_events_state()` called from `migrate_state()` (line 383); include `events` in `_needs_migration_backup()` (line 390), nested-version refusal (lines 318–320, 377–380) and `validate_state()` (lines 553–573). Keep `PLAYER_STATE_VERSION = 4`; v1–v4 data is preserved. |
| Atomic writes / rollback | `game/core/player_state.gd::transaction()` (627–651), `game/core/save_manager.gd::atomic_write()` (401–443) | All event mutations use one `transaction("events", ...)`; failed writes restore the full snapshot and keep pending result for Retry. Existing fault hooks are used in tests. |
| Reward ledger | `player_state.gd::_stage_world_claim()` (1019–1043), `reward_claims` / `claimed_rewards` | Event claims reuse the canonical `world|event|...` key family through `_stage_world_claim()` inside the event transaction — no new ledger and no unprotected prefix. |
| Battle result routing | `game/scenes/battle/battle_scene.gd::_record_result()` | An event branch runs before the world branch: when `_world_context` contains `event_id`, call `PlayerState.settle_event_battle(result, context)`; only then fall back to `settle_world_battle()` and `claim_battle_reward()`. |
| Navigation context | `game/world/world_context.gd::META_KEYS` | Whitelist gains `event_id`, `stage_id`, `region`. `BattleScene._world_return_context()` copies the context, so the Event Center return path survives battle. Event contexts omit `trigger_id` so world settlement validation cannot be triggered. |
| Content loading | `game/core/content_repository.gd` (55–233), `game/data/content_catalog.json` | Register one new `events` pack; apply the same fail-closed fixture gate and `_validated_records()` checks as world packs; expose `get_event(s)` / `get_event_stage(s)` getters and a `summary()` count. |
| Summon | `game/systems/summon_system.gd`, `game/data/phase3/summon_banners.json` | Events hold banner reference IDs only. The Event Center navigates to the existing summon screen; no new rates, guarantees, pools or purchase code. |
| Quests / missions | `game/world/quest_manager.gd`, `quest_settlement.gd` | Event missions are a separate, minimal counter model in `events`; they do not modify world quest definitions or objectives. Prompt 07.1 adds objective-qualified counters, repeatable cycles and unlock evaluation through the new `EventUnlockEvaluator`, which reads existing world quest completion read-only. |
| Locale | `game/core/locale_manager.gd::t()` (80–91), `data/localization/{en,vi,ja}.json` | Every visible string is a stable `event.*` or existing key; live switching and persisted locale stay unchanged. |
| UI | `docs/decisions/0006-ui-scaling.md`, `game/scenes/world/world_map.tscn` | Full-rect `Control`, `VBoxContainer`/`HBoxContainer`, anchors, autowrap, scroll containers; 1280×720 design baseline with portrait adaptation via `_apply_layout_profile()`. |
| Navigation entry | `game/scenes/menu/main_menu.gd/.tscn`, `game/scenes/phase3/economy_hub.gd` | Event Center buttons were added to both the main menu and economy hub. Summon consumes an Event Center `WorldContext` and restores that return path once. |
| Tests | `game/tests/test_runner.gd` | `test_prompt07_event_suite` is registered in the full runner; a dedicated focused runner and Python data/QA-tool suites run in isolated `/tmp/opencode/ffbe-profiles/prompt-07-*` profiles only. |
| QA capture | `tools/qa/capture_prompt06.sh`, `tools/qa/prompt06_visual_report.py` | Add a Prompt 07 scenario allow-list/wrapper and report covering landscape + portrait, three locales, zero runtime error lines. |

No event-system skill exists in `.agents/skills/`; the loaded skills were `ffbe-godot-foundation`, `ffbe-battle-engine`, `save-systems`, `rpg`, `ffbe-project-quality`, `godot-gdscript-headless-testing`, `godot-export`, `ffbe-source-audit` and `ffbe-asset-restoration`.

## 3. Layering

```text
Main Menu / Economy Hub
        |
        v
Event Center (event_center.gd) -- EventRepository, EventSchedule, EventStateService, EventUnlockEvaluator
        |  stage selection + WorldContext.write(event_id, stage_id, encounter_id, return_scene)
        v
BattleScene (existing engine) -- EventRepository + PlayerState.settle_event_battle
        |  result snapshot + event return context
        v
Event Center (stage status, rewards, currency, archive, replay)
```

`WorldContext` remains the transit contract. `EventRepository` is read-only over the validated content pack; `EventSchedule` owns the injectable clock and availability states; `EventUnlockEvaluator` evaluates authored event prerequisites read-only; `EventStateService` owns staged progression and idempotent claims inside `PlayerState.transaction`. Presentation never mutates definitions or the save directly.

## 4. Event definition shape

One pack `game/data/events/events.json` holds `events` and `stages` arrays. Each event carries a stable region-aware ID (`event:GL:980001@stargarden`), category, type, name/description keys, `regions` config with GL/JP schedules, unlock requirements, stage references, event currency, shop and banner references, boss encounter, replay/archive policy, missions, and provenance metadata. Stages carry stable `stage:GL:980101@gate` IDs, ordering, unlock rules, encounter ID, first-clear reward, repeatable reward and completion requirements. Prompt 07.1 adds a mission `objective` object and makes `unlock` a validated, evaluated prerequisite; see `docs/data-dictionary/event-schema.md` and `docs/data-dictionary/event-mission-schema.md`. All timestamps are synthetic integers; GL and JP schedules are different but neither is claimed as history.

## 5. Availability and injectable clock

`EventSchedule` accepts a clock object with `now() -> int`. Production uses a system-UTC clock; tests use a fixed clock. States are derived, never persisted:

- `permanent` when `availability.mode == "permanent"` (always enterable).
- `upcoming` before `start_unix`, `active` inside `[start_unix, end_unix)`.
- `ended` after `end_unix` when the event has no replay/archive policy.
- `archived` after `end_unix` when `replay_policy.archive_after_end == true` and replay is disabled.
- `replayable` after `end_unix` when `replay_policy.replay_enabled == true` and entry requirements are met.

Region selection is explicit: `region` is `GL` or `JP`, and a missing region config yields `ended`/unavailable rather than another region's schedule.

## 6. Progression, rewards, idempotence

`events` state contains `version`, `progress` (per event), `first_clears`, `completions`, `currency`, `mission_progress`, `mission_cycles`, `processed_runs`, `claims`, `last_result`. `EventSchedule` still owns schedule availability; `EventUnlockEvaluator` evaluates authored `unlock` prerequisites; `EventStateService.can_launch_stage()` is the single gameplay guard used by both the UI and `settle_event_battle()`. Prompt 07.1 mission counters are objective-qualified: only a successful victory on the mission's `objective.ref` (and, for `boss_clear`, the event boss encounter) advances that mission. `settle_event_battle()` checks `processed_runs[run_id]` before any mutation, then one transaction records the receipt, first-clear or repeatable reward, currency and mission counters. Defeat records no reward. Duplicate run or duplicate claim returns a no-op result; a failed atomic write preserves the pending result for the existing Retry Save path.

Claim receipts use the existing canonical reward ledger with keys
`world|event|<kind>|<identity>` — for example
`world|event|mission|event:GL:980001@stargarden|clear_gate`. Repeatable cycle N uses
`world|event|mission|<event>|<mission>|cycle:N`; no reward kind prefix is duplicated,
and no separate event claim table was introduced. `mission_cycles` is additive and legacy
flat v4 counters are interpreted at read time, so `PLAYER_STATE_VERSION` stays `4`. The
pending-event retry branch remains in-memory only; no crash/process-termination recovery
is claimed. The full transaction and save-compatibility contract is in
[event-progression-integrity.md](event-progression-integrity.md).

## 7. Collaboration and summon framework

Collaboration events use the same schema with `category = "collaboration"`. Guest characters are synthetic references (`guest:GL:990001@lumen`) with original name keys; no copyrighted character, art, audio, logo or dialogue is included. `banner_ref` points at a synthetic banner ID in the existing summon pack; the Event Center only navigates to the summon screen. The rights gate stays `not_passed`.

## 8. UI and responsive layout

The Event Center scene has an overview (category tabs, active/upcoming/ended/archive filters, event cards with designed artwork panels), a detail panel (description, schedule, currency, stages, first-clear/repeat rewards, missions, shop items and banner link), stage selection with completion status, and an archive/replay view. Artwork areas use coloured panels with a localized `SYNTHETIC PLACEHOLDER ART` caption — never empty placeholder dots. `_on_resized()` triggers `_rebuild()`; `_portrait_override` is a QA-only deterministic override for the responsive-suite test. Desktop 1024×640 / 1280×720 / 1920×1080 uses a side-by-side landscape hierarchy, and 720×1280 uses a stacked portrait layout.

## 9. Verification

Verification uses: Godot import, focused Prompt 07 suite, full Godot suite, negative control, Python discovery, importer security, world/QA tools, localization coverage, Linux/Windows export, Linux exported binary smoke, `git diff --check`, and staged-file/security audit. Visual QA captures real Godot windows at the four required resolutions in three locales and records zero runtime error lines. Prompt 07 evidence remains in `docs/qa/prompt07-final-report.md` and `docs/qa/prompt07-visual-review.md`; fresh Prompt 07.1 evidence is in `docs/qa/prompt07-1-final-report.md`.
