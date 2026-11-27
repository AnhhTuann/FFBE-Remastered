# Event progression integrity architecture

**Status:** Prompt 07.1 hardening of the synthetic Event Center. It corrects mission qualification, repeatable claims and unlock enforcement without changing the Event Center visual design, the save format version or the rights gate.
**Rights gate:** `not_passed`. All shipped event records remain `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN`; no original FFBE event data, art, music, dialogue or summon history was added.
**Engine:** Godot 4.7.2 stable; project root `game/`.
**Save format:** additive fields inside the existing v4 `events` section of `user://player_state_v3.json`. `PLAYER_STATE_VERSION` stays `4`.

## 1. Scope and non-goals

Prompt 07.1 fixes three integrity defects found in the Prompt 07 foundation:

1. Every victory incremented every mission in the event, regardless of the stage actually cleared.
2. `repeatable` existed in data but had no gameplay semantics; each mission had one static claim identity.
3. Event Center passed a literal `true` for event unlock state, and no gameplay service evaluated authored unlock references.

The phase does not redesign screens, add new missions or events beyond the existing six-event/eight-stage fixture set, restore protected FFBE content, implement real-money purchases, or start Prompt 07.2 / Prompt 08.

## 2. Integration decisions

The existing Prompt 07 architecture was reused rather than duplicated.

| Concern | Seam | Decision |
|---|---|---|
| Definitions | `ContentRepository` + `EventRepository` | One validated read-only event pack. The repository also accepts an explicit synthetic pack in focused tests so invalid/unknown/unlock branches can be exercised without changing shipped content or visual QA matrices. |
| Availability | `EventSchedule` | Unchanged injectable clock and derived `upcoming`/`active`/`ended`/`archived`/`replayable`/`permanent` states. Availability is **not** merged with unlock state. |
| Unlocks | New `EventUnlockEvaluator` | Centralized, data-driven evaluation of `none`, `event`, `stage` and existing `quest` prerequisites. Reads event/stage definitions and existing `world.quests` records read-only. Unknown kinds, invalid references and cross-region references fail closed. |
| Progression | `EventStateService` | `mission_status()` reports a single objective-qualified record; `settle_battle()` advances only missions whose `objective.ref` matches the settled stage and whose objective is valid for the owning event. |
| Repeat cycles | `EventStateService` + additive `mission_cycles` | Completed cycles are derived from saved counts, tracked explicitly, and claimed through distinct stable identities. Legacy v4 flat counters are interpreted rather than discarded. |
| Rewards | Existing `PlayerState._stage_world_claim()` | All reward grants still use the canonical `world|event|<kind>|<identity>` ledger inside one `PlayerState.transaction()`. No parallel reward ledger was introduced. |
| Settlement | `PlayerState.settle_event_battle()` | Delegates to `EventStateService.settle_battle()`; the service enforces region, event/stage ownership, encounter identity, unlock and stage prerequisites before any mutation. Duplicate run receipts remain a hard no-op. |
| UI | `event_center.gd` | Reads `mission_status()` and evaluated unlock state. Buttons and labels reflect claimable cycles and localized locked state. Layout, art panels and navigation structure are unchanged. |
| Locale | `LocaleManager` + `vi`/`en`/`ja` dictionaries | Two new keys, `event.center.cycle` and `event.center.next_cycle`, added consistently to all three dictionaries. No technical IDs or raw claim keys are shown. |
| Tests | `prompt07_event_test_suite.gd` + Python contracts | Existing assertions were preserved; new focused tests and static data tests cover objectives, cycles, unlock branches, save/reload and fault injection. |

A dedicated event-system skill does **not** exist in `.agents/skills`. Loaded project skills were `ffbe-godot-foundation`, `ffbe-battle-engine`, `rpg`, `save-systems`, `godot-gdscript-headless-testing`, `ffbe-project-quality`, `ffbe-source-audit` and `godot-export`; no localization skill is configured.

## 3. Mission objectives

Each mission now declares a stable `objective` object:

```json
{ "type": "stage_clear", "ref": "stage:GL:980101@gate" }
```

Only the two objective types actually required by shipped fixtures are supported:

- `stage_clear`: a successful victory on the referenced stage owned by the same event.
- `boss_clear`: the same, additionally requiring the stage encounter to equal the event's `boss_encounter`.

`ContentRepository` rejects a pack when an objective is missing, has an unknown type, references an unknown stage, references a stage owned by another event, or fails the boss-encounter rule. At runtime, `EventStateService._objective_valid()` and `_objective_qualifies()` repeat the fail-closed checks so an injected or malformed definition cannot advance progress. Defeats, duplicate run IDs, unrelated stages and unrelated events never advance a mission.

## 4. Repeatable cycle model

Mission state is kept in two additive save maps:

- `mission_progress[event|mission]`: remainder toward the current cycle.
- `mission_cycles[event|mission]`: `{ completed, claimed }` cycle counters.

Rules:

1. A qualifying victory increments the remainder. When the remainder reaches `target`, the remainder resets to zero and `completed` increases by one.
2. Non-repeatable missions complete once; extra qualifying runs do not reopen them.
3. Repeatable missions retain every completed-but-unclaimed cycle; cycles are claimed oldest first.
4. A failed claim transaction rolls back both the reward and the cycle counter; no cycle is consumed.
5. `mission_status()` exposes `count`, `target`, `complete`, `claimable`, `claimed`, `completed_cycles`, `claimed_cycles`, `next_claimable_cycle`, `repeatable` and the deterministic `claim_key`.

Legacy v4 saves with only a flat `mission_progress` counter are interpreted at read time: repeatable counters are split into completed cycles plus a remainder and non-repeatable counters become a single completed cycle. Existing canonical claim records are also counted, so old claims are not duplicated. The save version is not bumped.

## 5. Claim identity

Canonical reward identity remains `world|event|<kind>|<identity>`:

| Claim kind | Identity | Example |
|---|---|---|
| Non-repeatable mission | `<event>|<mission>` | `world|event|mission|event:GL:980001@stargarden|clear_gate` |
| Repeatable mission cycle | `<event>|<mission>|cycle:N` | `world|event|mission|event:GL:980001@stargarden|farm_gate|cycle:1` |
| First clear / run / shop | Existing forms | unchanged |

The kind prefix is never duplicated. Cycle numbers are deterministic, persisted in the canonical reward ledger and mirrored in the additive `events.claims` receipt map.

## 6. Unlock evaluation

`EventUnlockEvaluator.status()` first checks that the event exists, that the requested region is configured, and that the authored unlock is well formed. It then evaluates:

| Kind | Requirement |
|---|---|
| `none` | Unlocked, but only when the reference is empty. |
| `event` | All stages of the referenced event are completed in the same region. |
| `stage` | The referenced stage has a first clear or completion in the same region. |
| `quest` | The referenced existing world quest is completed; the quest ID must match the requested region. |

A missing definition, unknown kind, invalid reference, region mismatch, malformed `none` reference or unmet prerequisite returns a structured failure with a localized message key. Availability remains in `EventSchedule`: a `permanent` event with an unmet prerequisite is still locked.

`EventStateService.can_launch_stage()` combines event unlock, region configuration and `unlock_after` stage gating. It is used by the Event Center launch path **and** by `settle_battle()`, so a locked stage cannot be launched or rewarded through a direct gameplay call.

## 7. Transaction and save behavior

`claim_mission()` and `settle_battle()` stage all changes through `PlayerState.transaction("events" | "event_settlement" | "event_mission", ...)`. A failed atomic write restores the full snapshot, grants no reward, records no cycle claim and keeps the pending event result for the existing Retry path. Duplicate settlement is checked before the write guard and transaction; it returns a clean no-op without mutating progress.

Migration, validation and future-version refusal continue to use the existing helpers. `mission_cycles` is backfilled by `_ensure_events_state()` and checked by `validate_state()`. No claim of crash/process-termination recovery beyond the existing pending-result mechanism is made.

## 8. Verification and limitations

Fresh evidence is recorded in [docs/qa/prompt07-1-final-report.md](../qa/prompt07-1-final-report.md). The focused GDScript suite reports `334 passed, 0 failed`; the full suite reports `4184 passed, 0 failed`; the negative control reports one intentional failure and exit code `1`. Python discovery runs `119` tests with `OK`.

Known limitations:

- Unlock fixtures for successful and unsuccessful prerequisite branches are synthetic test-local packs; shipped events still declare `unlock.kind = "none"` so the Prompt 07 visual matrix is unchanged.
- Windows runtime was not executed on this Linux host; only a Windows export was produced.
- Subjective visual approval of the retained PNG captures remains a human review item.
- Event missions remain a minimal counter model; they do not create or mutate world quests.

Detailed field contracts are in [docs/data-dictionary/event-mission-schema.md](../data-dictionary/event-mission-schema.md). The Prompt 07 reports remain unchanged as historical evidence.
