# Battle data dictionary

**Schema version:** 2
**Runtime file:** `game/data/battles.json`
**Catalog entry:** `game/data/content_catalog.json` → `files.battles`
**Provenance marker:** top-level `fixture_marker = "SYNTHETIC_FIXTURE"`
**Status:** Project-authored combat fixture data. No FFBE content is imported.

---

## 1. Identity and policy rules

All combat records use composite identities of the form `<kind>:<REGION>:<native_id>@<form>`:

- `unit:GL:910101@base`
- `enemy:GL:920001@boss`
- `ability:JP:931104@base`
- `item:GL:940001@base`
- `encounter:GL:950002@boss`

Rules:

1. `region` is `GL` or `JP`; numeric IDs are never unique across regions by themselves.
2. Every record carries `verification_status: "SYNTHETIC_FIXTURE"`.
3. Every encounter carries `fixture_marker: "SYNTHETIC_FIXTURE"`.
4. `ContentRepository.load_content()` rejects the whole battle package if the top-level marker is missing or wrong.
5. `provenance` records `origin: "generated"`, `source: "phase2-synthetic-fixture"` and `license: "project-authored"`. None of these records claims restored FFBE data.

## 2. Top-level structure

| Field | Type | Meaning |
|---|---|---|
| `schema_version` | int | Version of this battle package. Currently `2`. |
| `fixture_marker` | string | Must be `SYNTHETIC_FIXTURE`. |
| `description` | string | Human-readable policy statement. |
| `animation_policy` | object | Animation ID plus clip aliases used by combat. |
| `combatants` | object | Map from combatant ID to unit/enemy definition. |
| `abilities` | object | Map from ability ID to ability definition. |
| `items` | object | Map from item ID to item definition. |
| `encounters` | object | Map from encounter ID to encounter definition. |

`ContentRepository` exposes deep copies via `get_battle_package()`, `get_battle_combatant()`, `get_ability_definition()`, `get_item_definition()`, `get_encounter()` and `get_encounter_ids()`.

## 3. Combatant definition

| Field | Type | Required | Meaning |
|---|---|---|---|
| `id` | string | yes | Composite identity; must match its map key. |
| `kind` | string | yes | `unit` or `enemy`. |
| `region` | string | yes | `GL` or `JP`. |
| `native_id` | string | yes | Region-scoped numeric ID as text. |
| `form` | string | yes | Form discriminator, e.g. `base`, `boss`, `brave_shift`. |
| `display_name` | string | yes | UI label; synthetic name. |
| `verification_status` | string | yes | Must be `SYNTHETIC_FIXTURE`. |
| `role` | string | yes | Behaviour label used by tests and UI colouring. |
| `level` | int | yes | Used by level correction `1 + level / 100`. |
| `stats` | object | yes | `hp`, `mp`, `atk`, `def`, `mag`, `spr`. |
| `resist` | object | no | Element name → whole percent, e.g. `fire: 20`. |
| `weapon_variance` | array[float] | no | Two-element inclusive range, e.g. `[0.95, 1.05]`. |
| `lb_cost` | int | yes | Gauge threshold, clamped to at least 1. |
| `basic_attack` | string | yes | Ability ID used as fallback/AI basic attack. |
| `abilities` | array[string] | yes | Legal ability IDs for the combatant. |
| `limit_burst` | string | no | LB ability ID; empty string if none. |
| `animation_id` | string | yes | Existing synthetic animation clip ID. |
| `ai` | object | enemies only | Decision pattern described in section 7. |
| `provenance` | object | yes | Generated-source metadata. |

Required party roles in the synthetic skirmish and boss encounters are `physical_attacker`, `magical_attacker`, `healer`, `support` and `defensive`. The boss encounter adds `enemy:GL:920001@boss` with `role: "boss"` and two additional enemies.

## 4. Ability definition

| Field | Type | Required | Meaning |
|---|---|---|---|
| `id` | string | yes | Composite ability identity. |
| `name` | string | yes | UI label. |
| `kind` | string | yes | `physical`, `magical`, `white`, `green`, or `unknown`. Only damaging kinds are `physical`/`magical`. |
| `targeting` | string | yes | `self`, `ally`, `enemy`, `all_allies`, `all_enemies`. |
| `mp_cost` | int | yes | Spent at execution start. |
| `modifier` | float | yes | Damage/heal factor. |
| `chain_family` | string | no | Recorded on damage events for traceability. |
| `is_limit_burst` | bool | no | Requires full LB and the actor's `limit_burst` ID. |
| `hits` | array[object] | no | Each object: `frame` (int), `weight` (float), `element` (string). |
| `effects` | array[object] | no | Structured effects described in section 6. |
| `verification_status` | string | yes | Must be `SYNTHETIC_FIXTURE`. |

`hits` and `effects` frames are relative to the action's execution start and are converted into absolute logical frames by `ActionQueue`.

Targeting is **actor-relative**. `all_allies` means the caster's side; `all_enemies` means the opposing side. This applies to enemy abilities as well: a boss area attack that should hit the party uses `all_enemies`.

## 5. Item definition

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Composite item identity. |
| `name` | string | UI label. |
| `targeting` | string | Usually `ally`. |
| `effects` | array[object] | Same effect schema as abilities. |
| `verification_status` | string | Must be `SYNTHETIC_FIXTURE`. |

Items use `uses_per_battle` from the item definition if present, defaulting to `1`. The current fixtures are a potion (`heal`) and an ether (`mp_restore`). There is no persistent inventory system.

## 6. Effect types

| `type` | Fields | Behaviour |
|---|---|---|
| `damage` | implicit from ability/hit | Uses `DamageCalculator`; emitted for each timed hit. |
| `heal` | `base`, `modifier`, `targeting`, `frame` | `(base + (SPR/2 + MAG/10) × modifier) × variance(0.85–1.00)`, clamped to max HP. |
| `mp_restore` | `amount`, `targeting`, `frame` | Restores MP, clamped to max MP. |
| `buff` | `stat`, `percent`, `turns`, `targeting`, `frame` | Adds/refresh a same-stat buff; strongest potency wins. |
| `break` | `stat`, `percent`, `turns`, `targeting`, `frame` | Adds/refresh a same-stat break; strongest potency wins. |
| `imperil` | `element`, `percent`, `turns`, `targeting`, `frame` | Raises elemental damage taken; strongest imperil wins. |
| `status` | `status`, `chance`, `turns`, `targeting`, `frame` | Applies an ailment with seeded chance. |
| `lb_fill` | `amount`, `targeting`, `frame` | Explicit gauge fill; separate from the automatic per-turn cap. |
| `guard` | implicit | Sets actor guard for the current turn. |
| any other value | — | Emits `unsupported_effect` and changes no state. The `ability:GL:939999@base` negative fixture proves this path. |

Supported stats for buffs/breaks are `hp`, `mp`, `atk`, `def`, `mag`, `spr`. Supported ailment keys include `sleep`, `silence`, `poison`, `regen`, `paralyze`, `petrify`, `confuse` and `disease`. Full dormant-layer effect stacking is not implemented.

## 7. Enemy AI definition

`ai` is an object on enemy combatants:

| Field | Type | Meaning |
|---|---|---|
| `max_actions` | int | Number of distinct abilities selected per enemy phase. |
| `action_start_frames` | array[int] | Logical frame offset for each selected action; the last value repeats if needed. |
| `pattern` | array[object] | Weighted candidate abilities. |

Each `pattern` entry contains:

| Field | Type | Meaning |
|---|---|---|
| `ability` | string | Ability ID. |
| `weight` | int | Weighted-selection weight; zero excludes the entry. |
| `min_hp_percent`, `max_hp_percent` | float | Inclusive HP gates for the enemy. |
| `target_rule` | string | `all_allies`, `all_enemies`, `lowest_hp`, `highest_atk`, `random`. Actor-relative for the two group rules. |
| `cooldown` | int | Enemy phases before reuse; `0` means no cooldown. |

If no pattern entry is eligible, the enemy uses `basic_attack`. Cooldowns are deterministic and reset when a battle starts.

## 8. Encounter definition

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Composite encounter identity. |
| `name` | string | UI label. |
| `fixture_marker` | string | Must be `SYNTHETIC_FIXTURE`. |
| `party` | array[string] | Combatant IDs, up to five controllable units. |
| `enemies` | array[string] | Enemy/boss combatant IDs. |
| `boss` | bool | Marks the boss encounter and event metadata. |
| `reward` | object | `gil` (int) and `items` (array[string]). |
| `provenance` | object | Generated-source metadata. |

Current encounters:

- `encounter:GL:950001@skirmish` — five units vs. Hollow Adept + Hollow Brute; reward 400 gil and one synthetic potion.
- `encounter:GL:950002@boss` — five units vs. Hollow Warden boss + two enemies; reward 1200 gil and one synthetic ether.

## 9. Battle result record

`BattleResult.to_dict()` produces the record handed to `SaveManager`:

| Field | Type | Meaning |
|---|---|---|
| `encounter_id`, `encounter_name` | string | Source encounter identity and label. |
| `victory` | bool | Whether the player side won. |
| `outcome` | string | `victory` or `defeat`. |
| `turns` | int | Turn number at completion. |
| `seed` | int | Battle seed for replay. |
| `boss` | bool | Boss flag. |
| `rewards` | object | `gil`, `items`. Defeat yields zero/empty. |
| `defeated_enemies` | array[string] | Enemy IDs at zero HP. |

## 10. Persistent battle progress format

File: `user://battle_progress.json`. Format version: `2`. Writes are atomic with a `.bak` fallback.

```json
{
  "version": 2,
  "progress": {
    "attempts": 0,
    "clears": {},
    "best_turns": {},
    "total_gil": 0,
    "item_counts": {},
    "last_result": {}
  }
}
```

`record_battle_result()` increments attempts, stores the last result, and on victory increments per-encounter clears, updates best turns, adds gil and counts item IDs. `validate_battle_progress()` rejects wrong versions and non-object map fields. `migrate_battle_progress()` converts version 1 records shaped as `{"version": 1, "completed": [...]}` into version 2 clears and refuses newer versions.

## 11. Validation checklist for future edits

1. IDs match their map keys and follow the composite form.
2. Every record is marked `SYNTHETIC_FIXTURE` unless a lawful rights gate has passed and the verification label is updated deliberately.
3. All referenced combatants, abilities, items and animation IDs exist.
4. Enemy group-targeting uses actor-relative semantics.
5. `weapon_variance` has two ordered values; resistances use whole percentages.
6. Effect types are from the supported table or intentionally exercise the unsupported path in a test.
7. Re-run `godot --headless --path game --script res://tests/test_runner.gd` after any data change.
