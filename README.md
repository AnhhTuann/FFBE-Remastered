# FFBE Remastered

**Offline PC Restoration Project**  
**Platforms:** Windows and Linux (x86_64)  
**Content scope:** Recoverable FFBE Global and Japan data  
**Status:** Planning

FFBE Remastered is a proposed standalone, offline-first PC RPG project focused on preserving and recreating the recognizable 2D, party-based, turn-based RPG experience of Final Fantasy Brave Exvius (FFBE), using content that can be recovered, verified, and lawfully used.

This is an independent project. It is not the original FFBE service, does not recreate the publisher's production infrastructure, and is not affiliated with or endorsed by Square Enix.

## Project identity

| Field | Value |
|---|---|
| Project name | FFBE Remastered |
| Repository | AnhhTuann/FFBE-Remastered |
| Repository slug | ffbe-remastered |
| Genre | 2D turn-based JRPG |
| Target platforms | Windows and Linux (x86_64) |
| Proposed engine | Godot 4.x |
| Gameplay language | GDScript |
| Data and audit tooling | Python; TypeScript/Node.js when useful |
| Runtime content storage | To be decided after a cross-platform prototype |
| Network requirement | None for normal gameplay |
| Regional scope | Global (GL) and Japan (JP) |

The name is a working title and should receive trademark/legal review before public distribution.

## Vision

Build a standalone PC game that can be played offline and preserves the core FFBE-style experience: character collection, party building, turn-based combat, abilities, equipment, progression, enemies, and recoverable story content.

The project will:
- Target Windows and Linux from the start.
- Keep Global and Japan data separate and traceable.
- Reconstruct systems using a new local game architecture.
- Preserve source snapshots and make data transformations reproducible.
- Label content as verified, recovered, partial, unverified, or unavailable.
- Avoid inventing missing historical data or presenting assumptions as facts.

## Scope overview

### Planned game systems
- Character roster, forms, stats, and progression.
- Party formation and turn-based battles.
- Physical and magical damage, elements, resistances, buffs, debuffs, and status effects.
- Chaining and Limit Burst mechanics where sufficiently documented.
- Weapons, armor, accessories, materia, and inventory.
- Monsters, bosses, and enemy behaviour.
- Offline summon/collection mechanics.
- Quests, maps, dialogue, and story content where recoverable.
- Local save slots, backups, restore, and migration.

### Planned restoration work
- Global and Japan source discovery and independent audits.
- Structured data extraction and normalization.
- Sprite, portrait, animation, background, UI, and audio inventory.
- Source provenance, checksums, coverage, and validation reports.
- Controlled imports into a local runtime content package.

### Not part of the initial scope
- Recreating publisher-operated production servers or online accounts.
- Multiplayer, PvP, guilds, rankings, or live-service features.
- Payment processing or real-money purchases.
- Bypassing DRM, authentication, access controls, or technical protections.
- Claiming complete restoration where source evidence is missing.

## Technology direction

- **Godot 4.x:** game client, scenes, UI, animation, input, and Windows/Linux exports.
- **GDScript:** gameplay and game-domain logic.
- **Python:** source inventory, extraction support, normalization, validation, and reports.
- **TypeScript/Node.js:** optional auxiliary tooling when it provides a clear benefit.
- **SQLite or generated Godot resources:** runtime content storage. This decision remains open until a tested Windows/Linux prototype exists.
- **Git:** source control and reviewable changes.

Normal gameplay must not depend on a hosted API. The runtime data-storage choice must be validated on both target platforms before it is locked.

## Global and Japan data policy

Global and Japan are separate source namespaces. Never assume that the same numeric native ID represents the same record in both regions.

Use region-aware identities such as:
- unit:GL:<native_id>
- unit:JP:<native_id>
- ability:GL:<native_id>
- ability:JP:<native_id>

Normalized records should retain, where available:
- Region and native source ID.
- Source repository/archive and revision.
- Original file path.
- Importer/schema version.
- Source checksum.
- Verification status and known limitations.

Verification labels:
- **Verified:** supported by sufficient evidence and cross-checking.
- **Recovered:** extracted from a source but not fully cross-verified.
- **Partial:** known to be incomplete.
- **Unverified:** evidence is insufficient.
- **Unavailable:** no usable source has been found.

## Repository structure

The intended high-level structure is:

- README.md — project overview and entry point.
- PROJECT_PLAN.md — project charter, architecture, roadmap, and acceptance criteria.
- docs/ — architecture decisions, data dictionary, and audit reports.
- game/ — Godot project, scenes, scripts, resources, and imported assets.
- data/raw/global/ and data/raw/japan/ — immutable source snapshots, when permitted.
- data/normalized/ — region-aware normalized data.
- data/manifests/ and data/validation/ — manifests and audit outputs.
- tools/ — inventory, extraction, normalization, validation, and import utilities.
- tests/ — data, asset, battle, save, and integration tests.
- builds/ — Windows and Linux release outputs.

Directories will be introduced as implementation begins; this plan does not imply that the game code already exists.

## Roadmap

1. **Project definition and source discovery** — inspect candidate sources, revisions, provenance, terms, and limitations.
2. **Full data and asset audit** — measure actual coverage, collisions, missing references, and integrity for both regions.
3. **Technical foundation** — create the Godot project, data interfaces, platform prototype, and test foundation.
4. **Character and asset viewer** — load a small verified sample from both regions.
5. **Battle vertical slice** — deliver one complete playable encounter with rewards and save/load.
6. **Core game systems** — expand character progression, inventory, equipment, abilities, Limit Bursts, and enemy systems.
7. **World and story restoration** — integrate recoverable maps, quests, dialogue, and encounters.
8. **Content expansion** — import and validate Global and Japan content in controlled batches.
9. **Quality assurance and PC release** — verify offline operation, save integrity, Windows/Linux builds, and distribution rights.

See [PROJECT_PLAN.md](PROJECT_PLAN.md) for the detailed architecture, milestones, risks, and exit criteria.

## Project principles

1. Audit before bulk implementation.
2. Preserve raw source snapshots; transformations create new outputs.
3. Keep Global and Japan records distinct.
4. Make imported data traceable to its source wherever possible.
5. Do not fabricate missing or uncertain restoration data.
6. Design normal gameplay to work offline.
7. Test Windows and Linux as first-class platforms.
8. Separate original materials from newly authored replacement content.
9. Do not redistribute material without the necessary rights.

## Current status

The repository contains a playable, offline Godot 4.7 desktop slice built entirely from synthetic fixtures and remastered design data. Phase 3 added character progression, inventory, equipment, abilities, Limit Bursts and desktop UI hardening. Prompt 05/05.1 added additive v4 save migration, battle-run identity, transactional rewards, Leader Skills, per-unit Vision Cards, synthetic Esper progression, seeded summons, capped offline economy, shop and crafting foundations, and `vi` / `en` / `ja` localization. Prompt 06 adds a synthetic World Map, keyboard/mouse exploration, NPC dialogue, quests, treasure and a battle-return integration, all stored in an additive `world` section of the same save file.

No original FFBE or Elvlin data, art, banner rates, guarantees, historical pools, maps, story or music is imported or claimed. The rights gate remains `not_passed`; all runtime gameplay content is labelled `SYNTHETIC_FIXTURE` or `REMASTERED_DESIGN`. See [docs/qa/prompt06-final-report.md](docs/qa/prompt06-final-report.md) for the latest milestone evidence, [docs/qa/prompt05.1-final-report.md](docs/qa/prompt05.1-final-report.md) for the preceding checkpoint, and [docs/architecture/world-exploration.md](docs/architecture/world-exploration.md) for the new world architecture.

## Legal and distribution notice

FFBE and associated names, characters, designs, artwork, music, code, text, and other original materials may be protected intellectual property and trademarks of Square Enix and/or other rights holders.

A publicly accessible archive or repository does not automatically grant permission to reuse, modify, or redistribute its contents. Review the applicable license and terms for every source, and obtain any required permissions before incorporating or distributing protected materials. Do not bypass DRM, authentication, access controls, or other technical protections.

If a distributable build cannot lawfully include original materials, use original or properly licensed replacement assets. The project name is a working title and should receive trademark/legal review before public distribution.

## License

No project-wide license has been selected. A future code license will not grant rights to third-party game assets, data, music, or other protected content.
