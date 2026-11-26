# Event data dictionary

**Scope:** Prompt 07 synthetic event fixtures. All records are `SYNTHETIC_FIXTURE` with `verification_status: REMASTERED_DESIGN`, `rights_gate: not_passed` and `source_data_imported: false`. No FFBE event history is represented.
**Pack:** `game/data/events/events.json`, registered as `events` in `game/data/content_catalog.json`.

## Pack header

| Field | Type | Meaning |
|---|---|---|
| `schema_version` | int | Pack schema version (`1`). |
| `fixture_marker` | string | Must be `SYNTHETIC_FIXTURE`. |
| `content_version` | string | Project-authored content revision. |
| `description` | string | Human-readable pack description. |
| `policy.rights_gate` | string | Must be `not_passed`. |
| `policy.source_data_imported` | bool | Must be `false`. |
| `policy.evidence_class` | string | `REMASTERED_DESIGN`. |
| `events` | array[object] | Event definitions. |
| `stages` | array[object] | Stage definitions referenced by events. |

## Event record

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Stable composite ID `event:<GL|JP>:<native>@<form>`. |
| `kind` | string | `event`. |
| `region`, `native_id`, `form` | string | Parsed parts of `id`; the region must match the `id` and every stage's region. |
| `category` | string | `story`, `limited`, `permanent`, `collaboration`, `seasonal`, `challenge`. |
| `type` | string | Remastered subtype, e.g. `story_arc`, `boss_rush`, `guest_arc`. |
| `name_key` / `description_key` | string | Locale keys in all three dictionaries. |
| `regions` | object | `GL` and/or `JP` region config (see below). |
| `availability.mode` | string | `scheduled` or `permanent`. |
| `unlock` | object | `{ "kind": "none"\|"event"\|"stage", "id": string }`. |
| `stage_ids` | array[string] | Ordered stage IDs owned by this event. |
| `event_currency` | string | Currency item ID, or empty string. |
| `shop_ref` | string | Event shop definition ID, or empty string. |
| `banner_ref` | string | Synthetic summon banner ID, or empty string. |
| `boss_encounter` | string | Encounter ID shown as the event boss, or empty string. |
| `replay_policy` | object | `archive_after_end`, `replay_enabled`, `keep_rewards_on_replay`. |
| `missions` | array[object] | `{ id, key, target, repeatable, reward }` foundations; reward is an existing gil/items bundle. |
| `shop` | object | `{ id, items: [{ id, currency, cost, reward, shop_id }] }`; no purchase or real-money flow is implemented. |
| `guests` | array[object] | Synthetic collaboration references `{ id, name_key, role_key, source, rights_gate }`; no protected character identity. |
| `art` | object | `{ "panel": "synthetic_placeholder", "label_key": string }`; rendered as a labelled colour panel, not an empty dot. |
| `provenance` | object | `{ source: "project_authored", evidence: "REMASTERED_DESIGN", rights_gate: "not_passed" }`. |
| `verification_status` | string | `REMASTERED_DESIGN`. |

### Region config

| Field | Type | Meaning |
|---|---|---|
| `start_unix` | int | Inclusive start timestamp. `0` for permanent events. |
| `end_unix` | int | Exclusive end timestamp. `0` for permanent events. |
| `stage_ids` | array[string] | Optional regional stage override; empty means the event's shared list. |
| `banner_ref` | string | Optional region-specific banner override. |

GL and JP records are never joined by numeric ID. Different schedules are intentional and are not historical claims.

## Stage record

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Stable composite ID `stage:<GL|JP>:<native>@<form>`. |
| `kind` | string | `event_stage` (`stage:` IDs are aliased to this prefix at load time). |
| `region`, `native_id`, `form` | string | Parsed parts of `id`; must match the owning event's region. |
| `event_id` | string | Owning event ID. |
| `region` | string | `GL` or `JP`. |
| `order` | int | Display and unlock order (0-based). |
| `name_key` | string | Locale key. |
| `encounter_id` | string | Existing encounter in `battles.json`. |
| `unlock_after` | array[string] | Stage IDs that must have a first clear. |
| `first_clear_reward` | object | Granted once per event/stage. |
| `repeat_reward` | object | Granted per unique successful run, including replay when policy allows. |
| `currency` | object | `{ "id": string, "amount": int }` event currency grant. |
| `completion_target` | int | Required successful runs for stage completion; `1` by default. |
| `reward_policy` | object | `{ "one_time": bool, "repeatable": bool }`. |
| `provenance` / `verification_status` | object/string | Same policy as events. |

Reward objects use the existing bundle shape (`gil`, `item:<region>:<id>@<form>`, `material:<...>`, `fragment:<...>`), already accepted by `player_state.gd::_collect_reward()`.

## Runtime state (`events` section of the save)

| Field | Type | Meaning |
|---|---|---|
| `version` | int | Additive section version (`1`). Future versions are refused like future `world` versions. |
| `progress` | object | Per-event per-stage `{ "runs": int, "cleared": bool }`; `completed` is derived from `completions` for display. |
| `first_clears` | object | `event_id|stage_id -> true`. |
| `completions` | object | `event_id|stage_id -> true` when the completion target is reached. |
| `currency` | object | Event currency ID -> amount. |
| `mission_progress` | object | `event_id|mission_id -> count`. |
| `processed_runs` | object | `run_id -> receipt` (idempotency boundary). |
| `claims` | object | Claim key -> receipt; mirrors canonical `world|event|...` ledger entries. |
| `last_result` | object | Latest presentation snapshot; never authority for rewards. |

## Claim keys

- First clear: `world|event|first|<event_id>|<stage_id>` — one per event/stage.
- Repeat run: `world|event|run|<run_id>` — one per unique successful run.
- Mission: `world|event|mission|<event_id>|<mission_id>` — one per mission, or per run when the mission is repeatable.
- Shop purchase: `world|event|shop|<purchase_id>` — one per synthesized purchase identity.

All claims go through `_stage_world_claim()` inside a single `PlayerState.transaction("events", ...)`, so they share the existing ledger, resource grant and rollback path.
