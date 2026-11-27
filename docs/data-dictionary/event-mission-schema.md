# Event mission, cycle and unlock schema

**Applies to:** Prompt 07.1 hardening of `game/data/events/events.json`, `EventRepository`, `EventUnlockEvaluator`, `EventStateService` and the additive `events` section of the v4 player state.
**Policy:** every shipped event/stage is `SYNTHETIC_FIXTURE` with `REMASTERED_DESIGN` evidence, `source_data_imported: false` and `rights_gate: not_passed`. No original FFBE event history, character, art, audio or dialogue is represented.

This document extends, and does not replace, [event-schema.md](event-schema.md).

## Mission record

| Field | Type | Required | Meaning |
|---|---|---|---|
| `id` | string | yes | Stable mission ID unique inside the event. |
| `key` | string | yes | Localized display key present in `vi`, `en` and `ja`. UI never shows raw IDs. |
| `objective` | object | yes | Qualifying condition; see below. |
| `target` | int | yes | Qualifying victories required per cycle. Minimum `1`. |
| `repeatable` | bool | yes | `false`: one completion and one claim. `true`: independent numbered cycles. |
| `reward` | object | yes | Existing gil/items reward bundle; claimed exactly once per completed unit. |

### Objective object

| Field | Type | Allowed values | Meaning |
|---|---|---|---|
| `type` | string | `stage_clear`, `boss_clear` | `stage_clear` accepts any successful victory on `ref`; `boss_clear` additionally requires the stage encounter to match the owning event's `boss_encounter`. |
| `ref` | string | stage ID from the same pack | Stage that must be settled. It must belong to the mission's event. |

Unknown types, missing objectives, unknown stages, cross-event references and `boss_clear` references with a non-boss encounter are rejected at content load and again at runtime. Such missions report `reason: invalid_objective` for status and claim, and settlement advances no mission progress.

### Shipped mission policy

| Event | Mission | Objective | Target | Repeatable |
|---|---|---|---:|---|
| `event:GL:980001@stargarden` | `clear_gate` | `stage_clear` Gate of Stars | 1 | no |
| `event:GL:980001@stargarden` | `farm_gate` | `stage_clear` Gate of Stars | 3 | yes |
| `event:JP:980002@moonlit` | `moonlit_boss` | `boss_clear` Moonlit boss | 1 | no |
| `event:GL:980003@lumenguest` | `guest_bond` | `stage_clear` guest stage | 1 | no |
| `event:GL:980006@evergreen` | `training` | `stage_clear` permanent training stage | 2 | no |

Archive and future events intentionally have no missions.

## Event unlock record

The existing `unlock` object is now evaluated:

```json
{ "kind": "none", "id": "" }
```

| `kind` | `id` contract | Runtime requirement |
|---|---|---|
| `none` | must be empty | Always unlocked. |
| `event` | event ID in the same pack | Every stage of that event is completed in the requested region. |
| `stage` | stage ID in the same pack | That stage has a first clear or completion in the requested region. |
| `quest` | `quest:<GL\|JP>:<native>@<form>` from the existing world quest pack | The existing world quest record is completed. The region prefix must match the requested region. |

Content loading rejects unknown kinds, self-referential event prerequisites, missing references, cross-region stage/event prerequisites and quest IDs absent from the loaded world pack. Runtime evaluation fails closed on the same conditions. Shipped events keep `none`; successful and unsuccessful prerequisite branches are exercised with synthetic test-local packs.

`availability.mode` remains independent. A `permanent` or active scheduled event is not unlocked automatically when a prerequisite is unmet.

## Runtime state fields

All new fields are additive inside `events`; `PLAYER_STATE_VERSION` remains `4`.

| Field | Type | Meaning |
|---|---|---|
| `mission_progress` | object | `event|mission -> int`; remainder toward the next cycle. Existing in v4. |
| `mission_cycles` | object | `event|mission -> { "completed": int, "claimed": int }`. Added in Prompt 07.1; backfilled on load. |
| `claims` | object | `world|event|... -> receipt`; mirrors the canonical reward ledger. |
| `processed_runs` | object | `run_id -> receipt`; duplicate settlement boundary. |
| `progress`, `first_clears`, `completions`, `currency`, `last_result` | object | Existing Prompt 07 fields, unchanged in meaning. |

### Cycle derivation

`_mission_record()` derives the effective record from both maps plus canonical claim keys:

- `completed` starts from `mission_cycles.completed`; if no cycle record exists, legacy `mission_progress` is split by `target` (`target` = 1 for non-repeatable missions in practice).
- `claimed` starts from `mission_cycles.claimed` and is raised to the number of canonical mission claim records found, so pre-07.1 claims are respected.
- For non-repeatable missions, any legacy claim forces `completed >= 1`.

Writing a record updates both maps inside the same transaction as the reward claim.

## Claim identity

Canonical form: `world|event|<kind>|<identity>`.

| Case | Identity | Key |
|---|---|---|
| Non-repeatable mission | `<event>|<mission>` | `world|event|mission|event:GL:980001@stargarden|clear_gate` |
| Repeatable cycle N | `<event>|<mission>|cycle:N` | `world|event|mission|event:GL:980001@stargarden|farm_gate|cycle:2` |

Cycle N is `claimed + 1` at claim time. A completed-but-unclaimed cycle stays claimable after save/reload; a failed save does not consume it. Another cycle cannot reuse a claimed identity. First-clear, repeat-run and shop claim forms are unchanged.

## `mission_status()` contract

| Key | Meaning |
|---|---|
| `ok`, `reason`, `message` | Validation result and localized reason key. |
| `count`, `target` | Current remainder and configured target; `count` reports `target` when a cycle is claimable. |
| `complete`, `claimable`, `claimed` | Completion, pending claim and claimed state derived from counters. |
| `completed_cycles`, `claimed_cycles` | Explicit cycle counters. |
| `next_claimable_cycle` | Oldest unclaimed cycle, or `0`. |
| `repeatable` | Mirrors the authored flag. |
| `claim_key` | Deterministic canonical claim key for the current/future claim. |

UI uses only localized text derived from these values; no technical IDs or claim keys are rendered.

## Transaction invariants

- Mission progress and rewards commit together in `PlayerState.transaction()`.
- Failed atomic writes restore the full state snapshot and grant no reward.
- Duplicate settlement returns before the write guard and cannot advance a cycle.
- Future `events` section versions remain read-only; no bypass was added for missions or unlocks.
