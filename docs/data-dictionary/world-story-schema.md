# World and story data dictionary

**Schema version:** 1 for all six `game/data/world/*.json` packs.
**Evidence class:** `REMASTERED_DESIGN`; **fixture marker:** `SYNTHETIC_FIXTURE`; **rights gate:** `not_passed`.
**Scope:** Prompt 06 synthetic demonstration world. These records are not recovered FFBE data.

## 1. Files and top-level sections

| File | Catalog key | Root array | Records |
|---|---|---|---|
| `regions.json` | `world_regions` | `regions` | 1 |
| `locations.json` | `world_locations` | `locations` | 3 |
| `location_connections.json` | `world_connections` | `connections` | 2 |
| `interactables.json` | `world_interactables` | `interactables` | 9 |
| `dialogues.json` | `world_dialogues` | `dialogues` | 2 |
| `quests.json` | `world_quests` | `quests` | 2 |

Every pack has `schema_version: 1`, `fixture_marker`, `description` and a `policy`
object with `rights_gate`, `source_data_imported` and `evidence_class`. A pack that
does not satisfy the policy is rejected at load time.

## 2. Identity convention

Stable IDs use `<kind>:<region>:<native_id>@<form>`. World records use region `GL`
only; `JP` is not mixed into these synthetic records. The location prefix is `loc:` in
stable IDs and is normalized to the canonical repository kind `location` during
validation. No GL/JP equivalence is asserted.

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Stable composite ID; unique across all six packs |
| `kind` | string | `region`, `location`, `connection`, `npc`, `treasure`, `encounter_trigger`, `exit`, `dialogue` or `quest` |
| `region` | string | Two-letter namespace (`GL` here) |
| `native_id` | string | Numeric local identifier inside the namespace |
| `form` | string | Lowercase stable variant slug |
| `verification_status` | string | Always `REMASTERED_DESIGN` |
| `provenance.origin` | string | `remastered_design` |
| `provenance.source` | string | `prompt06-synthetic-world` |
| `provenance.license` | string | `project-authored` |
| `provenance.rights_gate` | string | `not_passed` |

## 3. Regions and locations

### Region

| Field | Type | Meaning |
|---|---|---|
| `start_location` | string | Location ID used when no world save exists |
| `name_key`, `description_key` | string | Localization keys |
| `background_ref` | string | Style-only reference such as `style:vale`; no protected art asset |

### Location

| Field | Type | Meaning |
|---|---|---|
| `region_id` | string | Owning region ID |
| `location_kind` | string | `town`, `field`, `dungeon` or `boss` |
| `name_key`, `description_key` | string | Localization keys |
| `background_ref` | string | Style-only reference |
| `map_position.x`, `map_position.y` | number | Normalized position in `[0, 1]` on the synthetic World Map |
| `unlock_requirements.quests` | string[] | Quest IDs that must be completed before travel |
| `unlock_requirements.flags` | string[] | World flags required before travel |
| `encounter_id` | string | Optional encounter attached to the location; empty string means none |
| `initial_unlocked` | boolean | Whether a fresh world state begins with this location unlocked |

The only region is `region:GL:1001@vale`. Its start location is
`loc:GL:1101@haven`. `loc:GL:1102@meadow` requires `quest:GL:3100@oath` and
`loc:GL:1103@spire` requires `quest:GL:3101@lantern`.

### Connection

| Field | Type | Meaning |
|---|---|---|
| `from`, `to` | string | Location IDs; must differ and exist |
| `requirement.location_id` | string | Location that must be unlocked to traverse the edge |

Edges are `haven ↔ meadow` and `meadow ↔ spire`. There is no direct haven–spire edge.

## 4. Interactables

| Field | Type | Meaning |
|---|---|---|
| `area_id` | string | Location containing the object |
| `position.x`, `position.y` | number | Design-space coordinates in the 1280×720 exploration layout |
| `radius` | number | Positive interaction radius in design-space units |
| `name_key`, `prompt_key` | string | Localization keys |
| `interaction_policy` | string | `one_time` or `repeatable` |
| `dialogue_id` | string | Required for `npc` |
| `reward.gil`, `reward.items[]` | number/string[] | Required for `treasure`; only validated synthetic resource IDs |
| `encounter_id` | string | Required for `encounter_trigger`; must exist in `battles.json` |
| `destination` | string | `world_map` or a valid location ID for `exit` |
| `requirement.location_id` | string | Optional unlock gate for an exit |

There are two NPCs, one one-time treasure (`treasure:GL:4101@meadow`, 150 gil and
`fragment:GL:910101@base`), two encounter triggers and four exits.

## 5. Dialogue graph

| Field | Type | Meaning |
|---|---|---|
| `speaker_key` | string | Localization key for the speaker name |
| `portrait_ref` | string | Style-only reference |
| `start_node` | string | Node ID presented first |
| `nodes[].id` | string | Unique node ID inside the dialogue |
| `nodes[].lines` | (string or object)[] | Localization keys, or `{ key, when }` for conditional lines |
| `nodes[].choices[].id` | string | Choice ID used in the world state's `dialogue_choices` map |
| `nodes[].choices[].label_key` | string | Localization key |
| `nodes[].choices[].next` | string | Destination node ID |
| `nodes[].choices[].when` | object | Optional `{ quest_id, quest_status }` visibility gate |
| `nodes[].choices[].effects[]` | object[] | Ordered effects applied on selection |
| `nodes[].next` | string | Fallback destination when there are no choices |
| `nodes[].effects[]` | object[] | Effects applied when the node is entered |

Effect types:

| Type | Fields | Meaning |
|---|---|---|
| `flag` | `key`, `value` | Set a boolean world flag |
| `quest_accept` | `quest_id` | Accept a quest if currently `not_started` and prerequisites pass |
| `quest_event` | `event` | Record an event with `type`, `target` and `count` |
| `unlock_location` | `location_id` | Add a location to the unlocked set |

`quest_status` values are `not_started`, `active` and `completed`. The keeper dialogue
accepts `quest:GL:3100@oath`; the scout dialogue conditionally shows active, intro and
done lines for `quest:GL:3101@lantern`.

## 6. Quests

| Field | Type | Meaning |
|---|---|---|
| `name_key`, `description_key` | string | Localization keys |
| `prerequisites.quests`, `prerequisites.flags` | string[] | Acceptance gates |
| `objectives[].id` | string | Unique objective ID inside the quest |
| `objectives[].type` | string | Event type that advances the objective |
| `objectives[].target` | string | Interactable, location, encounter, resource or quest ID matching the type |
| `objectives[].count` | integer | Positive required count |
| `objectives[].description_key` | string | Localization key |
| `rewards.gil`, `rewards.items[]` | number/string[] | One-time reward; item IDs must exist in `battles.json` |
| `unlocks[]` | string[] | Location IDs unlocked on completion |

Objective types and valid targets:

| Type | Target refers to |
|---|---|
| `talk_to` | NPC interactable |
| `visit_location` | location |
| `defeat_encounter` | encounter in `battles.json` |
| `open_treasure` | treasure interactable |
| `collect` | validated `fragment:`, `item:` or `material:` resource ID |
| `complete_quest` | quest |

`quest:GL:3100@oath` has one talk objective, rewards 200 gil plus
`item:GL:940001@base`, and unlocks the meadow. `quest:GL:3101@lantern` has six
objectives (talk, visit, treasure, encounter, collect and prerequisite quest), rewards
1000 gil plus two `item:GL:940001@base`, and unlocks the spire.

## 7. Additive save state

`player_state_v3.json` remains the save path. Its top-level format remains version 4;
the world state adds an internal `world.version = 1` section:

| Field | Type | Meaning |
|---|---|---|
| `current_region`, `current_location` | string | Last synthetic region/location |
| `discovered_locations`, `unlocked_locations` | string[] | Travel and discovery sets |
| `completed_locations` | string[] | Locations marked complete |
| `quests` | object | `quest_id → { status, progress }` |
| `flags` | object | Boolean story flags |
| `dialogue_choices` | object | `dialogue_id → chosen choice ID` |
| `interactions` | object | `interactable_id → interaction counts/state` |
| `opened_treasures` | string[] | One-time treasure claim state |
| `defeated_one_time_encounters` | string[] | One-time encounter state |
| `processed_battle_runs` | object | `run_id → { run_id, encounter_id, outcome, trigger_id, one_time }` settlement receipt written during battle |
| `last_battle_result` | object | Most recent result snapshot used by the return path |

`PlayerState` also exposes transient, non-serialized guards: `save_status`
(`NORMAL`, `MIGRATING`, `READ_ONLY_FUTURE_VERSION`, `LOAD_FAILED`), `read_only_reason`
and `pending_battle_result`. Only the first two allow writes; the last two terminal
states preserve on-disk bytes for owner recovery. The pending result is retained only
when a settlement write fails, so a retry can replay it without a second reward.

World mutation uses `PlayerState.transaction(section, mutator)` through
`transact_world()`. Reward settlement uses `claim_world_reward()` with claim keys
`world|quest|<quest_id>` and `world|treasure|<treasure_id>`. Quest completion uses
`QuestSettlement.stage_event()` inside the same transaction as the triggering action.
Battle rewards keep their existing `battle|...` claim keys; a world one-time encounter
uses the stable `battle|once|<encounter_id>` key regardless of `run_id`, while a
repeatable encounter uses `battle|run|<run_id>` per attempt. Missing world fields in
older v1–v4 saves are backfilled without resetting other progress; a `.mig.bak` backup
is written before the first committed world migration. A future top-level or world
version is refused before backup creation and the target path is registered read-only.
