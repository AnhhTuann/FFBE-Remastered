# World exploration architecture

**Status:** Prompt 06 synthetic vertical slice; implementation complete, gameplay evidence pending final QA.
**Rights gate:** `not_passed`. No protected FFBE map, story, art, music, text or source pack is used.
**Scene root:** `game/` (Godot 4.7.2 stable); repository paths below are relative to the project root.

## 1. Scope

Prompt 06 adds a data-driven World Map, an explorable area, dialogue, quest journal,
treasure and battle transition on top of the preserved Prompt 01–05.1 save and battle
systems. The world is wholly project-authored: one synthetic region, three locations,
nine interactables, two dialogue graphs and two quests. No recovered original game
story or geography is represented or claimed.

The three scenes are:

| Scene | Responsibility |
|---|---|
| `game/scenes/world/world_map.tscn` | Region overview, location selection, locked/unlocked state, quest journal entry and travel into an exploration area |
| `game/scenes/world/exploration_area.tscn` | Player movement, obstacle collision, interaction markers, dialogue panel, pause panel, exits and encounter triggers |
| `game/scenes/world/dialogue_panel.tscn` | Presentation-only speaker, line, choices and navigation buttons using localization keys |

Scripts live in `game/world/`. World records live in `game/data/world/*.json` and are
registered in `game/data/content_catalog.json` and loaded by `game/core/content_repository.gd`.

## 2. Layering

```text
Main Menu / WorldContext
        |
        v
World Map (world_map.gd, WorldMapMarkerArea)
        |  selected location + WorldContext.write
        v
Exploration Area (exploration_area.gd)
        |  Movement / Interaction / Dialogue / Quest / WorldStateService
        |  encounter trigger + WorldContext.write
        v
BattleScene (existing battle system)
        |  result snapshot + return_scene
        v
Exploration Area (battle_result consumed) or World Map
```

`WorldContext` stores metadata on the persistent `SceneTree` root under the
`ffbe_world_context_` prefix. The previous child-node transit pattern could not be
created or removed during a scene's `_ready()` while the parent was still setting up
children; root metadata is immediately readable, survives scene changes and requires
no child mutations. QA encounter transitions defer the scene change to the next idle
frame for the same reason.

Context keys:

| Key | Meaning |
|---|---|
| `location_id` | Destination area selected on the World Map |
| `encounter_id` | Encounter override supplied by an interaction trigger |
| `return_scene` | Scene to restore after battle or result confirmation |
| `trigger_id` | Interaction that started the encounter |
| `battle_result` | Snapshot written by BattleScene for the return path |

## 3. Content loading and identity gate

`ContentRepository.load_content()` reads six world packs registered in the catalog:

- `world_regions` — `regions.json`
- `world_locations` — `locations.json`
- `world_connections` — `location_connections.json`
- `world_interactables` — `interactables.json`
- `world_dialogues` — `dialogues.json`
- `world_quests` — `quests.json`

Loading is fail-closed. A missing, malformed or policy-invalid pack leaves the
repository's world section unavailable rather than substituting recovered data. Each
pack must declare `fixture_marker = SYNTHETIC_FIXTURE`, `policy.rights_gate =
not_passed`, `policy.source_data_imported = false` and `policy.evidence_class =
REMASTERED_DESIGN`. Each record carries `verification_status = REMASTERED_DESIGN` and
project-authored provenance.

IDs follow the repository's GL namespace convention, for example
`loc:GL:1101@haven`, `quest:GL:3100@oath` and
`encounter:GL:950001@skirmish`. The compact `loc:` prefix is normalized to the
repository's canonical `location` kind by `_canonical_kind()`; IDs are stable and are
not renamed. GL and JP records remain separately namespaced; no equivalence is implied.

## 4. Exploration controls and presentation

`ExplorationController` owns logical movement in a 1280×720 design space. WASD and
arrow keys set a movement vector; mouse clicks set a clamped finite target. Obstacles
are `Rect2` definitions and reject both keyboard and mouse movement into blocked
space. `InteractionController` uses each interactable's design-space position and
radius, so input is independent of window size.

`ExplorationArea` maps design coordinates into the actual viewport using
`_viewport_scale`, derived from `size` with a `get_viewport_rect()` fallback. Marker
buttons, the player marker, playfield drawing and mouse picking all use the same
mapping. This keeps 1024×640, 1280×720 and 1920×1080 layouts reachable without
changing authored gameplay coordinates. Spatial labels are anchored to the right edge
where needed.

Input contract:

| Input | Action |
|---|---|
| WASD / arrows | Move the player; keyboard movement cancels an active mouse target |
| Mouse click in playfield | Set a movement target |
| E / Space | Interact with the nearest in-range interactable; confirm dialogue advances |
| Enter | Confirm the highlighted choice / primary action |
| Escape | Open or close pause; close dialogue; return from pause to World Map |

## 5. Dialogue and quests

`DialogueRepository` returns a dialogue graph with nodes, keyed lines, conditional
visibility (`when.quest_status`) and keyed choices. `DialogueManager` resolves conditions
against `WorldStateService`, presents one page at a time, and applies effects only when
a choice is selected. Supported effects are `flag`, `quest_accept`, `quest_event` and
`unlock_location`. `DialoguePanel` is presentation-only; it resolves all displayed
strings through `LocaleManager` and emits `next_pressed`, `choice_selected` and
`close_pressed`.

`QuestRepository` exposes prerequisites, objectives and rewards. `QuestManager` tracks
`not_started`, `active` and `completed` status per quest in the additive world state.
`record_event()` accepts the existing event vocabulary `talk_to`, `visit_location`,
`defeat_encounter`, `open_treasure`, `collect` and `complete_quest`. Objective progress
is clamped to its required count and initialized from already-observed world facts,
so older progress is not lost when a quest is accepted later. Completion is atomic with
reward settlement and unlocks.

Rewards use only existing synthetic resource IDs and are claimed through
`PlayerState.claim_world_reward()` with `world|quest|...` and `world|treasure|...`
claim keys. A repeated interaction, retry or reload cannot claim the same reward twice.

## 6. Persistence and migration

`user://player_state_v3.json` remains the only player-state file; no v5 file was
introduced. `PlayerState.default_state()` adds a `world` section with world-state
`version = 1` while the top-level format stays at version 4. `_ensure_world_state()`
backfills missing fields conservatively for v1, v2, v3 and v4 saves. Migration never
drops existing resources, units, equipment, claimed rewards, battle runs, economy,
shops, crafting, summon or esper data.

`SaveManager.backup_for_migration()` writes `player_state_v3.json.mig.bak` before the
first committed world mutation of an older save. A save with a future top-level
version is refused rather than downgraded. `PlayerState.transact_world()` stages a
snapshot, commits it through the existing writer and rolls back in-memory state if the
write fails. The state validator checks the additive world section alongside all
Prompt 01–05.1 sections.

## 7. Battle identity and reward isolation

An encounter trigger writes `location_id`, `encounter_id`, `return_scene` and
`trigger_id` to `WorldContext`, then changes to `BattleScene`. `BattleScene` consumes
the context, uses `encounter_id` as an override for the existing encounter lookup and
stores `return_scene` for the result path. The result snapshot is written back to
`WorldContext` when the player returns, and `InteractionController.on_battle_result()`
calls `QuestManager.record_event()` only for a successful result with a matching
location/encounter/trigger identity.

Defeat produces no reward claim and no quest progress. Retry creates a new battle
`run_id`; existing battle claim keys remain prefixed `battle|run|`, `battle|once|`,
`battle|first|` and `battle|mission|`. World reward keys remain separate. This keeps
battle settlement, treasure settlement and quest settlement independently idempotent.

## 8. Localization

`vi` is the default locale, with `en` and `ja` supported through `LocaleManager`.
All scene labels, prompts, dialogue lines, quest text and battle-result statuses are
localization keys. The QA-only `FFBE_QA_LOCALE` override starts a capture in a chosen
locale without writing settings, preserving the player's saved locale. Live switching
emits `locale_changed`, which world scenes and the dialogue panel reconnect to. The
generated coverage snapshot is `data/validation/localization-coverage.json`; it
includes a scan over the world JSON key fields.

## 9. Verification hooks

- `game/tests/prompt06_world_test_suite.gd`: isolated GDScript tests for catalog gates,
  migration v1–v4, transactional rollback, movement/collision, dialogue, quests,
  treasure, battle identity, defeat isolation and scene wiring.
- `tests/test_prompt06_world_data.py`: static JSON/schema/provenance/reference checks.
- `tools/qa/capture_prompt06.sh`: live-window screenshot harness using a fresh isolated
  profile for every capture.
- `tools/qa/prompt06_visual_report.py`: validates the scenario × resolution × locale
  capture matrix and renders `docs/qa/prompt06-visual-review.md` from sidecars.
