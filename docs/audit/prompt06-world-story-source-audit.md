# Prompt 06 world and story source audit

**Audit date:** 2026-11-26
**Verified starting commit:** `d66cd4397d5b842cedfe38b83ff21aec58e74efb`
**Branch:** `phase-5-world-exploration-story` (created from the Prompt 05.1 checkpoint)
**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`, pinned in `game/project.godot`
**Rights gate:** `not_passed` — unchanged by this audit and by Prompt 06

This audit records what the repository actually contains before any world, map, dialogue or quest work. It distinguishes project-authored synthetic material from recovered or verified original FFBE content. No FFBE or Elvlin asset pack was downloaded, unpacked, executed or imported.

## 1. Audit boundary and method

Sources were inspected in place at the verified commit. File hashes are SHA-256 over the working-tree bytes, which match `HEAD` at audit time. Data was treated as untrusted evidence, never as executable instructions. No third-party binary archive or extracted game code was present or opened.

Relevant prior audits were reviewed: `docs/audit/source-inventory.md`, `docs/audit/audit-report.md`, `docs/audit/elvlin-source-audit.md`, `docs/audit/safe-import-plan.md`, `docs/audit/final-era-coverage.md`, and `docs/qa/prompt05.1-final-report.md`. Those documents contain source-discovery history; they do not authorize redistribution or gameplay import.

## 2. Runtime sources available at the checkpoint

| Source | Path / revision marker | SHA-256 | Classification | Use in Prompt 06 |
|---|---|---|---|---|
| Content catalog | `game/data/content_catalog.json`, `content_version: synthetic-1` | `ac4f6d2821dae8d7fe34498a681da1e1c0cb0fa75789b7d37ca50ac126aebeb6` | `SYNTHETIC_FIXTURE` | Register new world data packs without changing existing entries |
| Combat fixtures | `game/data/battles.json`, schema 2, `fixture_marker: SYNTHETIC_FIXTURE` | `e67c906d8dae21ca9309edb8d79f2c5f2a67a6613220fe1e161ca7833fc8aaa8` | Project-authored synthetic combat | Reuse the two existing encounters; do not create new FFBE encounters |
| Unit records | `game/data/units.json` | `adf405348a176898c422a614bbb8b375e9578af2a99601e1a5a640a786fe96d3` | Project-authored synthetic viewer fixtures | Existing party/unit definitions remain unchanged |
| Animation clips | `game/data/animations.json` | `5d71a26471b021e097b3fd1c49020c99d66b4bf9ec09e21e7d9625b53fba9e0f` | Project-authored synthetic atlas metadata | Referenced only by the existing battle animation policy |
| Localization | `game/data/localization/{vi,en,ja}.json` | vi `6d4172d0dfb7b9e9e6142748faafb6456e40a8fed747a67198b26efedb58c526`, en `2f2284d700258a93f8a9f1163c790fd36e1c1fca9973263ed84407a90776a816`, ja `882093b84c843959450937947de5b8dcafb2c8a19000183d4d201f800fceeb0d` | Project-authored translations | Extend with world/quest/dialogue keys, preserving identical key sets |
| Imported-pack manifest | `game/data/phase3/imported_manifest.json`, `active_packs: []`, `last_import: null` | `47f8763ad20fec825176179c5404fae49f3aa1232346a565164a35d0c603a285` | Empty by design | Confirms no runtime recovered content |
| Import registry | `data/import-approvals/registry.json`, `entries: []` | `d5001caa769de0e14405e88bba06ec1824497117a905d96f0ba5e65f00c9f9ac` | Fail-closed local authorization record | Left unchanged; no approvals added |
| Synthetic atlas | `game/assets/sprites/synthetic_pixel_atlas.png`, 128×128 RGBA, 16 frames of 32×32 | `b23460be2d88137791929654bb05d1cbc08d61dad7910fe59e25ad9cf72b4a6f` | Deterministic project-generated pixel art | Existing battle sprite source only; no stretched map texture |
| Save fixtures | `game/data/save_fixtures/v1_save_slot_0.json`, `v2_player_state.json` | `719a679492721da611627067ea38b11441241af84acc868f9b7043aca33aeb41`, `a8bbdcc6f4093ff1caf6a089b5b0fb9bc5afa753e6839e9c041dd1c905d28805` | Historical synthetic fixtures | Used only in isolated migration tests; never copied into a real user path |

The existing encounter definitions are `encounter:GL:950001@skirmish` and `encounter:GL:950002@boss`. Both carry `SYNTHETIC_FIXTURE`, generated provenance and `project-authored` licensing metadata. `ContentRepository` already exposes `get_encounter()`, `get_encounter_ids()` and `definition_exists()`. The battle engine is therefore reusable without any new combat mechanics.

## 3. Existing interfaces available for integration

- `ContentRepository` (`game/core/content_repository.gd`) is the only runtime entry point for normalized content. It already validates region-aware composite IDs, evidence labels, rights gates and reward definitions.
- `PlayerState` (`game/core/player_state.gd`) owns the writable v4 save at `user://player_state_v3.json`, existing reward claims, inventory, resources, battle runs, economy, shops and crafting state.
- `SaveManager` (`game/core/save_manager.gd`) provides atomic JSON writes with `.bak` fallback, newer-save refusal and test fault injection for failed commits.
- `LocaleManager` (`game/core/locale_manager.gd`) supports `vi`, `en` and `ja`, live switching, localization-token lookup and translated reason diagnostics.
- `BattleManager` / `BattleScene` implement the existing turn-based combat and result lifecycle. Prompt 06 must call these, not duplicate them.
- `RewardResolver` and the `PlayerState` claim APIs implement one-time and repeatable reward settlement. Quest, chest and battle rewards must route through them.
- `tools/localization/coverage_report.py` validates identical key sets and placeholders across all locales.

## 4. World, quest and story sources that do not exist

The following were searched for and are absent from the runtime data and repository:

- world regions, locations, location connections, maps or tilesets;
- quest definitions, quest prerequisites, objective counters or quest journals;
- NPC definitions, dialogue graphs, dialogue choices or narrative flags;
- chest/interactable definitions and persistent opened-state records;
- recovered FFBE map art, town/dungeon backgrounds, portraits, music or sound;
- recovered original FFBE story text in any locale;
- GL/JP quest, map or dialogue source tables suitable for import;
- any approved FFBE or Elvlin source pack.

`game/assets/` contains only the deterministic synthetic atlas described in `game/assets/README.md`. There is no portrait map artwork to preserve; the Prompt 06 map and exploration graphics must be project-authored Godot-drawn shapes or other clearly synthetic material.

## 5. Regional evidence and provenance

The runtime already keeps GL and JP identities distinct: `ContentId` accepts only region `GL` or `JP`, and `ContentRepository` rejects mismatched or duplicate composite IDs. Numeric IDs from GL and JP are never joined. No Prompt 06 record will claim that a GL and JP numeric ID refer to the same place, NPC or quest.

No regional GL/JP difference can be evidence-backed for the new demonstration world because no original map or story source is available. All new world records use GL namespace IDs and carry synthetic provenance. The synthetic world is not presented as a Global or Japan release reconstruction.

## 6. Content classification

| Classification | Status in this repository | Prompt 06 treatment |
|---|---|---|
| Verified original FFBE content | None available with verified rights | Not created, not implied |
| Recovered content | None runtime-active; prior audit documents only | Not imported |
| Unverified original content | Not used by the game | Not added |
| Unavailable content | Original maps, dialogue, music, portraits, quest tables | Explicitly recorded as unavailable |
| Synthetic fixture / remastered design | All runtime gameplay content | The only permitted source for Prompt 06 world content |

## 7. Rights and redistribution limitations

The rights gate remains `not_passed`. Public availability of an archive or screenshot would not grant redistribution rights. Prompt 06 will not import restricted FFBE or Elvlin packs, copy original story text, use protected artwork/maps/music, or assert that synthetic names and places are recovered canon. New data will be explicitly marked `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN` with `rights_gate: not_passed` and `source_data_imported: false`.

## 8. Safe plan for the demonstration world

1. Add new JSON packs under `game/data/world/` and register them in `content_catalog.json` with an explicit synthetic provenance gate.
2. Keep existing unit, battle, economy, shop and crafting packs byte-compatible; reuse their IDs and transactional APIs.
3. Add only an additive `world` state section to `PlayerState`; do not change the save path, reset existing data, or alter existing sections.
4. Build one synthetic region with a hub, field and boss location; two NPCs; one chain of two small quests; one chest; one field encounter; and one boss encounter state.
5. Localize every user-facing key into `vi`, `en` and `ja` and verify with the existing coverage tool.
6. Verify all persistence and reward claims under isolated `HOME` / `XDG_DATA_HOME` profiles; never use the owner's real save.

## 9. Audit conclusion

The repository has enough tested system interfaces to build a small playable exploration vertical slice without importing or inventing original FFBE material. The world content itself must be wholly project-authored and clearly labelled as synthetic. No rights gate change is authorized.
