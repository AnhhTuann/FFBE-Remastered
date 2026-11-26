# FFBE Remastered — Project Plan

**Document:** Project charter and technical delivery plan  
**Status:** Planning  
**Working title:** FFBE Remastered  
**Repository:** AnhhTuann/FFBE-Remastered  
**Target platforms:** Windows and Linux (x86_64)  
**Content scope:** Recoverable Final Fantasy Brave Exvius Global and Japan content

---

## 1. Executive summary

FFBE Remastered is a proposed standalone, offline-first PC RPG project. It aims to preserve and recreate the recognizable 2D, party-based, turn-based gameplay experience of Final Fantasy Brave Exvius (FFBE), using recoverable data from both Global and Japan.

This is not a revival of the original publisher-operated service. The project does not assume access to original server source code, production infrastructure, player accounts, or online entitlements. It will use a new local game architecture and independently implemented systems.

The project will proceed in evidence-led stages: source discovery, full data and asset audit, technical foundation, a playable vertical slice, core-system expansion, content integration, and cross-platform QA.

## 2. Product definition

### 2.1 Vision

Deliver a PC game that:
- Runs on Windows and Linux.
- Supports offline play after installation.
- Preserves the core FFBE-style collection, party-building, and battle experience.
- Supports recoverable Global and Japan content without regional ID corruption.
- Provides reliable local saves, backups, and restore.
- Distinguishes verified original content, recovered-but-unverified content, and newly authored replacements.

### 2.2 Product principles

- Offline-first; no mandatory hosted services.
- Data-driven gameplay rather than large amounts of hardcoded content.
- Immutable raw source snapshots.
- Region-aware identities and imports.
- Evidence-based restoration with explicit uncertainty labels.
- Automated validation and reproducible builds.
- Windows and Linux are first-class targets.
- Original and newly authored materials remain distinguishable.

### 2.3 Target users

- Players interested in preserving the FFBE experience.
- Game preservation and data researchers.
- Developers and testers contributing to a lawful restoration effort.

## 3. Scope

### 3.1 In scope

**Game client**
- Main menu, settings, and local profile.
- Character collection, character details, and party formation.
- Turn-based battle and target selection.
- Skills, damage, elements, resistances, buffs, debuffs, and status effects.
- Chaining and Limit Burst where supported by evidence.
- Equipment, materia, inventory, and progression.
- Monsters, bosses, and enemy behaviour.
- Offline summon/collection mechanics.
- Quests, maps, dialogue, and story content where recoverable.
- Local save slots, autosave, backup, restore, and migration.

**Data restoration**
- Global and Japan source discovery and independent audits.
- Units, forms, stats, abilities, effects, and Limit Bursts.
- Weapons, armor, accessories, materia, and items.
- Monsters, resistances, and AI.
- Vision Cards.
- Quests, missions, recipes, rewards, maps, dialogue, and story data where available.
- Sprites, portraits, sprite sheets, animation metadata, UI, backgrounds, and audio where available and lawfully usable.
- Provenance, checksums, coverage, and validation reports.

**Platform**
- Windows x86_64 build.
- Linux x86_64 build.
- Offline smoke tests on both platforms.

### 3.2 Out of scope for the initial project

- Recreating the original publisher's production servers.
- Restoring original online accounts, purchases, or player entitlements.
- Multiplayer, PvP, guilds, rankings, or live-service features.
- Payment processing or real-money purchases.
- Bypassing DRM, authentication, access controls, or technical protections.
- Claiming complete restoration where no adequate source exists.
- Public redistribution of protected original assets without the required rights.

Any change to these exclusions requires explicit scope and legal review.

## 4. Technical architecture

### 4.1 Logical architecture

The application is divided into five areas:

1. **Presentation:** Godot scenes, menus, HUD, character views, battle presentation, animation, and input.
2. **Gameplay/domain:** battle rules, turn order, damage, effects, party, progression, quests, and rewards.
3. **Data access:** region resolver, repositories, content lookup, schema validation, and version handling.
4. **Persistence:** local player saves, settings, backups, and migrations.
5. **Data toolchain:** source inventory, extraction support, normalization, asset processing, validation, and reports.

Gameplay systems should depend on stable domain/data interfaces, not directly on raw Global or Japan source files.

### 4.2 Proposed technology stack

| Area | Proposed technology | Decision notes |
|---|---|---|
| Game engine | Godot 4.x stable | Pin a tested version for each release |
| Gameplay language | GDScript | Primary game logic |
| Data audit | Python | Inventory, parsing, validation, reporting |
| Auxiliary tooling | TypeScript/Node.js | Optional, only where useful |
| Runtime content store | SQLite or generated Godot resources | Decide after a cross-platform prototype |
| Player saves | Versioned local format | Must support backup and migration |
| Version control | Git | Reviewable, traceable changes |
| Automated tests | Godot tests plus Python data tests | Data, battle, save, and integration |
| Build | Godot command-line export | Windows and Linux presets |

**Storage decision gate:** SQLite support in a Godot project may require a maintained plugin or GDExtension. Before committing to runtime SQLite, verify packaging, compatibility, and maintenance on both Windows and Linux. If this creates excessive risk, package read-only game data as generated Godot resources or versioned JSON bundles and use a separate local save format. Record the final decision in an architecture decision record.

### 4.3 Runtime module boundaries

Proposed modules include:
- BattleManager
- TurnManager
- ActionQueue
- DamageCalculator
- ElementResolver
- StatusEffectManager
- ChainManager
- LimitBurstManager
- TargetResolver
- EnemyAI
- PartyManager
- ProgressionService
- InventoryService
- QuestManager
- SaveManager

These are architectural boundaries, not a requirement to create every module before the first playable slice.

### 4.4 Data pipeline

1. Discover publicly accessible or lawfully obtained sources.
2. Record source metadata, revision, terms, and provenance.
3. Create immutable raw snapshots where permitted.
4. Inventory and extract supported files.
5. Normalize records into a versioned schema.
6. Validate schema, integrity, relationships, and regional identities.
7. Generate runtime content packages.
8. Import packages into the Godot game.
9. Preserve reports and checksums for every import.

Raw source files must never be edited in place. Every transformation produces a new versioned output with logs and validation results.

## 5. Regional identity and data model

### 5.1 Regional identity

Global and Japan are separate source namespaces. A numeric native ID alone is not a globally unique key.

Use composite identities such as:
- unit:GL:<native_id>
- unit:JP:<native_id>
- ability:GL:<native_id>
- ability:JP:<native_id>

For records with multiple forms, include a form discriminator in the normalized identity. Do not assume matching numeric IDs mean matching content across regions.

### 5.2 Proposed entities

| Entity | Purpose |
|---|---|
| Region | Global or Japan source namespace |
| Unit | Base character record |
| UnitForm | Variant/form and source identity |
| UnitStats | Stats by form, level, and progression state |
| Ability | Skill definition |
| AbilityEffect | Structured effect sequence |
| LimitBurst | Limit Burst definition |
| Equipment | Weapons, armor, and accessories |
| Materia | Passive and equipment-related content |
| Item | Consumables and other inventory objects |
| Monster | Enemy and boss definition |
| MonsterAI | Enemy action logic and conditions |
| VisionCard | Vision Card content |
| Quest | Quest and story progression |
| Mission | Quest conditions and rewards |
| Recipe | Crafting data |
| Asset | Sprite, portrait, background, audio, and asset metadata |
| SourceRecord | Provenance and source reference |
| DataVersion | Import and schema version |

### 5.3 Provenance fields

Where available, every normalized record should retain:
- Region and native source ID.
- Source repository/archive and revision.
- Original file path.
- Importer and schema version.
- Source checksum.
- Verification status.
- Known conflicts and limitations.

### 5.4 Verification labels

| Status | Meaning |
|---|---|
| Verified | Checked against sufficient evidence |
| Recovered | Extracted but not fully cross-verified |
| Partial | Known to be incomplete |
| Unverified | Evidence is insufficient |
| Unavailable | No usable source has been found |

A record must not be marked Verified merely because it loads in the game.

## 6. Full data and asset audit

Audit Global and Japan independently before combining content into runtime packages.

### 6.1 Structured data coverage

- Units, forms, rarity, stats, and progression.
- Abilities, effect parameters, and targeting.
- Limit Bursts.
- Weapons, armor, accessories, materia, and items.
- Monsters, stats, resistances, and AI.
- Vision Cards.
- Quests, missions, recipes, and rewards.
- Maps, dialogue, and story data where available.
- Historical banners and summon pools where recoverable.

### 6.2 Asset coverage

- Unit sprites and portraits.
- Sprite sheets and animation frame metadata.
- Monster sprites and animations.
- Backgrounds and map tiles.
- UI assets and icons.
- Effects and battle visuals.
- Music and sound effects, subject to rights and source availability.

### 6.3 Required audit checks

- File integrity and SHA-256 checksums.
- Parse errors and invalid records.
- Duplicate records within each region.
- Cross-region ID collisions.
- Missing references and broken relationships.
- Missing sprites, portraits, or animation files.
- Invalid animation frame ranges.
- Unexpected dimensions or alpha-channel loss.
- Unexplained source/version conflicts.
- Coverage by region and content category.

### 6.4 Audit deliverables

- source-inventory.csv
- source-manifest.json
- data-coverage.csv
- data-coverage.json
- asset-coverage.json
- id-collisions.json
- missing-references.json
- validation-report.json
- audit-report.md
- safe-import-plan.md

All counts must be generated from inspected source files. Reports must identify the exact source revisions and tools used; they must not rely on assumed or historical counts.

## 7. Asset restoration strategy

1. Inventory source files, formats, terms, and provenance.
2. Preserve original files in immutable snapshots where permitted.
3. Identify image, texture, audio, and metadata formats.
4. Extract only through permitted methods.
5. Hash and deduplicate without deleting source copies.
6. Reconstruct sprite animations using verified frame metadata.
7. Validate alpha, frame dimensions, alignment, timing, and scale.
8. Import into Godot using repeatable tooling.
9. Keep original and newly authored assets distinguishable.

Do not apply lossy conversion to pixel-art source assets by default. Preserve native dimensions, transparency, and original source files. Optimized runtime derivatives must be reproducible from retained sources.

## 8. Gameplay implementation plan

### 8.1 Character system

- Character identity and regional variant.
- Forms and rarity.
- Level, EXP, stats, and progression.
- Active and passive abilities.
- Limit Burst.
- Equipment slots and materia.
- Elemental and status resistance.
- Portrait, sprite, and animation references.

### 8.2 Battle system

- Party and enemy setup.
- Turn order and action queue.
- Target selection.
- Physical and magical damage.
- Elemental damage and resistance.
- Buffs, debuffs, and status effects.
- Multi-hit actions.
- Chaining.
- Limit Burst.
- Counter and passive effects where supported.
- Enemy AI.
- Victory, defeat, rewards, and post-battle state.

Combat effects should be data-driven where practical. Combat formulas must be researched and tested. Unknown behaviour must be documented rather than silently invented.

### 8.3 Collection and progression

- Character acquisition and collection.
- Duplicate handling.
- Summon pools and rates where verified.
- Inventory and currencies.
- Equipment and materia.
- Enhancement and awakening.
- Party presets.
- Quest and reward progression.

Offline summon rules must not depend on real-money purchases or external payment services.

### 8.4 World and story

- World map and locations.
- Town and dungeon scenes.
- NPC interactions and dialogue.
- Quest progression.
- Encounters and boss battles.
- Treasure and rewards.

Integrate original story/map content only where usable source material is available. Clearly label reconstructed or newly authored substitutes.

## 9. Save and offline design

Normal gameplay must not require a publisher-operated server, remote authentication, or network API.

Save requirements:
- Multiple local save slots.
- Manual save and autosave.
- Versioned save schema.
- Backup rotation.
- Restore and corruption detection.
- Safe write strategy to reduce partial-save risk.
- Migration tests between game versions.
- No save deletion during a normal game update.

Store player progress separately from immutable game content. Save data must never modify source archives or normalized source records.

## 10. Milestones and exit criteria

### M0 — Project definition and source discovery

**Work**
- Establish repository conventions and documentation.
- Inspect candidate sources and current revisions.
- Review source terms, licenses, provenance, and limitations.
- Create immutable source snapshots where permitted.
- Record hashes and acquisition metadata.

**Exit criteria**
- Source inventory exists for Global and Japan.
- Every inspected source has a recorded revision/reference.
- Licensing and access blockers are documented.
- No source snapshot has been silently modified.

### M1 — Full data and asset audit

**Work**
- Parse accessible structured data.
- Inventory accessible assets.
- Detect collisions, duplicates, missing references, and incomplete records.
- Generate coverage and validation reports.

**Exit criteria**
- Reports are generated from actual inspected source files.
- Global and Japan coverage are reported separately.
- ID collisions and missing references are documented.
- A safe import plan is reviewed.
- No unsupported claim of complete restoration is made.

### M2 — Technical foundation

**Work**
- Create the Godot project.
- Establish scene and script conventions.
- Implement region-aware data interfaces.
- Test the runtime storage choice on Windows and Linux.
- Add logging, error handling, and automated tests.
- Create platform export presets.

**Exit criteria**
- Project launches on the development machine.
- A minimal export test succeeds on Windows and Linux.
- A sample record loads through the data abstraction.
- Automated tests run repeatably.

### M3 — Character and asset viewer

**Work**
- Import a small verified sample from both regions.
- Display character portrait and sprite.
- Reconstruct at least one supported animation per sample.
- Display stats and abilities from normalized data.

**Exit criteria**
- No cross-region record mix-up.
- Asset references resolve correctly.
- Animation playback follows verified frame metadata.
- Missing assets produce visible diagnostics.

### M4 — Battle vertical slice

**Work**
- Implement one complete battle with a party of up to five characters and at least one enemy/boss.
- Add turn order, targeting, basic attacks, representative skills, damage, elements, effects, battle result, and rewards.
- Add save/load for battle results and player state.

**Exit criteria**
- A player can start, complete, win, and lose a battle.
- Battle state transitions are tested.
- Damage/effect calculations have deterministic unit tests where applicable.
- Rewards persist after closing and reopening the game.
- The vertical slice works offline.

### M5 — Core gameplay systems

**Work**
- Character progression.
- Equipment, materia, and inventory.
- Expanded abilities and Limit Bursts.
- Enemy AI.
- Summon/collection.
- Quest and reward progression.

**Exit criteria**
- Each system has tests and documented data requirements.
- Systems operate from local data.
- Save/load and migration tests pass.

### M6 — World and story integration

**Work**
- Integrate recoverable maps, backgrounds, NPCs, dialogue, quests, and encounters.
- Restore content in validated batches.
- Track missing or reconstructed content.

**Exit criteria**
- Each integrated area has a data/asset coverage report.
- Broken references are fixed or explicitly tracked.
- The included content path can be completed.

### M7 — Global and Japan content expansion

**Work**
- Import content in controlled batches.
- Re-run collision, relationship, and asset validation.
- Review region-specific differences.
- Add regression tests for known conflicts.

**Exit criteria**
- Coverage is measurable by region and category.
- No silent region overwrites occur.
- Known import blockers are documented.
- Content is traceable to source.

### M8 — QA and PC release

**Work**
- Test Windows and Linux builds.
- Test offline operation.
- Test saves, backups, and migrations.
- Profile loading, memory, and battle performance.
- Prepare legal notices and asset attribution.
- Package builds and user documentation.

**Exit criteria**
- Both target builds launch and run the agreed content scope.
- Normal gameplay works with networking disabled.
- Save recovery and migration tests pass.
- No known release-blocking crashes remain in the tested scope.
- Distribution contains only materials the project is permitted to distribute.

## 11. Quality assurance strategy

| Test area | Required checks |
|---|---|
| Data | Parse validity, schema, duplicates, collisions, missing references |
| Assets | File integrity, dimensions, alpha, frame ranges, missing files |
| Character | Stats, forms, abilities, equipment references |
| Battle | Turn order, targeting, damage, elements, effects, chaining |
| Progression | EXP, levels, enhancement, rewards |
| Save | Save/load, backup, restore, migration, corruption handling |
| Integration | Battle result → rewards → inventory → save |
| Offline | No network required for normal gameplay |
| Windows | Startup, input, rendering, save path, packaged assets |
| Linux | Startup, input, rendering, permissions, save path, packaged assets |

## 12. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Incomplete or unavailable source data | Missing content | Report coverage honestly; prioritize verified sources |
| Global/JP ID collisions | Incorrect records | Composite regional identities and collision tests |
| Unknown combat formulas | Inaccurate battles | Research, isolate formulas, document approximations |
| Missing animation metadata | Visual defects | Asset viewer and per-animation validation |
| Runtime database dependency | Packaging failures | Prototype SQLite support early; retain a resource-based fallback |
| Large asset volume | Slow import/builds | Batch processing, manifests, deduplication, lazy loading where suitable |
| Save corruption | Lost progress | Atomic writes, backups, migration tests |
| Copyright/trademark restrictions | Distribution blocked | Review rights; use original/licensed replacements where required |
| Scope expansion | Delayed playable build | Require a tested vertical slice before broad content expansion |

## 13. Repository structure

- README.md
- PROJECT_PLAN.md
- LICENSES/
- docs/architecture/
- docs/data-dictionary/
- docs/decisions/
- docs/audit/
- game/project.godot
- game/scenes/
- game/scripts/
- game/resources/
- game/assets/
- data/raw/global/
- data/raw/japan/
- data/normalized/
- data/manifests/
- data/validation/
- tools/inventory/
- tools/extract/
- tools/normalize/
- tools/validate/
- tools/asset-import/
- tools/reports/
- tests/data/
- tests/assets/
- tests/battle/
- tests/save/
- tests/integration/
- builds/windows/
- builds/linux/

These directories are target structure only. Add them as the relevant work begins.

## 14. Governance and working rules

- Keep main stable.
- Use focused branches for audit, engine, gameplay, assets, and platform work.
- Require review for schema changes and bulk data imports.
- Keep raw source snapshots immutable.
- Store generated reports with source revision and tool version.
- Never commit credentials, private keys, or personal account data.
- Do not commit large copyrighted asset collections to a public repository without the necessary rights.
- Record significant technical choices in architecture decision records.
- Do not mark a milestone complete without evidence against its exit criteria.

## 15. Decisions still open

Do not assume these before source audit and prototypes:
- Exact Godot 4.x patch version to pin.
- Runtime content storage: SQLite plugin/GDExtension versus generated Godot resources.
- Initial UI language and localization policy.
- Supported screen resolutions and scaling rules.
- Save file format and migration policy.
- Which historical Global and Japan versions can be represented.
- Which original assets can lawfully be included in a distributed build.
- Whether a public release is feasible under the available rights.

## 16. Legal and intellectual-property considerations

FFBE and related names, characters, designs, artwork, music, code, text, and other original materials may be owned or controlled by Square Enix and/or other rights holders. This project is independent and is not affiliated with or endorsed by them.

A public repository or community archive does not automatically grant redistribution rights. Review licenses and terms for every source. Do not bypass DRM, authentication, access controls, or technical protections. Do not distribute protected game assets, music, text, or code unless the project has the required rights.

If a distributable build cannot lawfully include original assets, use original or properly licensed replacement content. The project name is a working title and should receive trademark/legal review before public distribution.

## 17. Definition of project success

The project is successful when it has:
- A stable Windows and Linux PC game.
- Offline operation for all included core gameplay.
- A playable, tested battle loop.
- Reliable local saves and recovery.
- Region-safe Global and Japan content handling.
- Auditable data and asset provenance.
- Transparent reporting of recovered, partial, unverified, and unavailable content.
- A release package containing only content the project is permitted to distribute.

## 18. Implementation checkpoint status

The original M0–M9 roadmap remains the long-term charter. The delivered checkpoints are tracked separately because source-gated restoration work and synthetic vertical slices have different evidence requirements:

| Checkpoint | Branch | Scope | Owner approval |
|---|---|---|---|
| Phase 1–3 / hardening | `phase-3-hardening` | Character viewer, battle slice, desktop UI, offline save and localization foundation | Published; see `docs/qa/phase3-hardening-report.md` |
| Prompt 05 / 05.1 | `phase-4-esper-summon-economy` | Additive v4 economy, summon, shop, crafting and Esper systems with integrity hardening | Published as draft PR #8; approval pending |
| Prompt 06 | `phase-5-world-exploration-story` | Synthetic World Map, exploration, dialogue, quests, treasure and battle-return vertical slice | Draft PR #9; approval pending |

Prompt 06 adds `game/scenes/world/`, `game/world/` and six `game/data/world/` packs. The world state is additive inside `user://player_state_v3.json`; the top-level format remains v4 and v1–v4 saves are normalized with a migration backup. All records are `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN` with `rights_gate: not_passed`. No recovered FFBE story, map, art or audio was imported.

Prompt 06 evidence and exit criteria are in [docs/qa/prompt06-final-report.md](docs/qa/prompt06-final-report.md). Architecture and record fields are in [docs/architecture/world-exploration.md](docs/architecture/world-exploration.md) and [docs/data-dictionary/world-story-schema.md](docs/data-dictionary/world-story-schema.md).

**Immediate next milestone:** M0 — Project definition and source discovery, followed by M1 — Full Data and Asset Audit. Do not begin broad gameplay implementation until the audit and technical risks have been reviewed. Prompt 07 must not start until the owner approves the Prompt 06 checkpoint.
