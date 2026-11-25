# FFBE Remastered — Feature Master List

**Status:** Living scope inventory / review required  
**Updated:** 2026-11-25  
**Target:** Standalone offline Windows/Linux Godot 4 PC game, native landscape UI  
**Scope:** Recoverable Global (GL) and Japan (JP) content from the earliest available releases through each region's final era.

This document expands the feature coverage of README.md and PROJECT_PLAN.md. It is a research and planning checklist, not proof of data availability, implementation, rights clearance, or complete restoration. Do not change the active milestone merely because an item is listed here.

## 1. Tracking contract

Every feature has a stable ID, proposed delivery milestone (Pxx means prompt number), evidence reference, and a measurable acceptance target. Unless explicitly stated otherwise, implementation status is **PLANNED / NOT VERIFIED**, region coverage is **GL/JP TO AUDIT**, source completeness is **UNKNOWN**, and rights status is **NOT CLEARED**. A source listed at category level is a research starting point, not proof of each regional rule. Unconfirmed original-feature candidates are marked with a question mark and must be checked before implementation.

Record separate per-region, per-version statuses for each feature in subsequent audit reports:
- Evidence: VERIFIED, RECOVERED, PARTIAL, UNVERIFIED, UNAVAILABLE.
- Implementation: PLANNED, IN_PROGRESS, IMPLEMENTED, TESTED, BLOCKED, OUT_OF_SCOPE.
- Rights: NOT_REVIEWED, REVIEW_REQUIRED, CLEARED_FOR_SPECIFIED_USE, BLOCKED.
- Design: ORIGINAL_RULE, REMASTERED_ADAPTATION, CUSTOM_EXTENSION.

Evidence requires a source URL/revision, date, regional scope, rule or content reference, and verification notes. A successful parse or synthetic fixture does not establish original-rule fidelity. Never mark a feature fully complete without testing and evidence. Retain source snapshots outside public Git unless distribution is authorized.

### Reference index

Primary:
- S1 — Square Enix Japanese official FFBE site: https://www.jp.square-enix.com/FFBE/
- S2 — Official Global eighth anniversary announcement (late-era units, Overdrive, Clash of Wills): https://na.finalfantasy.com/topics/530
- S3 — JP end-of-service letter, 2025-08-25, including Season 5 milestone: https://www.jp.square-enix.com/FFBE/blog/2025/08/250825-2.html
- S4 — Official JP Memorial Edition announcement, 2025-10-31: https://www.jp.square-enix.com/FFBE/blog/2025/10/251031-2.html

Community research (verify independently, especially GL/JP differences):
- W1 — https://exvius.fandom.com/wiki/Basic_Information
- W2 — https://exvius.fandom.com/wiki/Mechanics
- W3 — https://exvius.fandom.com/wiki/Beginner%27s_guide
- W4 — https://exvius.fandom.com/wiki/Update_Schedule
- W5 — https://exvius.fandom.com/wiki/Leader_Skill
- W6 — https://exvius.fandom.com/wiki/Category:Espers
- W7 — https://exvius.fandom.com/wiki/Expedition
- W8 — https://exvius.fandom.com/wiki/General_Quests
- W9 — https://finalfantasy.fandom.com/wiki/Final_Fantasy_Brave_Exvius
- J1 — https://altema.jp/ffbe/overdrive

Data candidates (actual revisions must be recorded in local audit manifests):
- D1 — https://github.com/DaddyRaegen/ffbe_asset_dump
- D2 — https://github.com/DanUgore/ffbe_data
- D3 — supplemental sources recorded by the Phase 1 agent in data/manifests/supplemental-sources.json (review actual local file).
- P — proposed PC design, not historical evidence.

Neither D1 nor D2 establishes redistribution rights; the Phase 0 audit reported no declared license. D2 is an older snapshot and does not prove final-era mechanics. Memorial Edition is a reference lead, not a complete game-server archive or permission to redistribute.

## 2. Core characters and progression

| ID | Feature / research target | Stage | Evidence leads | Acceptance target |
|---|---|---|---|---|
| U01 | Full regional character roster, rarity, forms, aliases, limited/exclusive/collab flags | P04/P10 | W4,D1,D2,D3 | No GL/JP overwrite; roster counts by era and region with provenance |
| U02 | Level, EXP, stat growth, caps, HP/MP/ATK/DEF/MAG/SPR | P04 | W1,W3,D2 | Verify thresholds, growth and cap cases |
| U03 | 1–7 star awakening and required materials | P04 | W3,W4 | Valid transitions and material consumption; invalid ones rejected |
| U04 | Neo Vision awakening and EX+1/2/3 | P04 | W3,W4 | Form and progression gates tested by regional rules |
| U05 | NV+ and late-era awakening resources | P04 | W4,S2,J1 | Audit availability by era; verify upgrade requirements and resulting stats |
| U06 | Brave Shift, shift types, cooldown/duration and separate form builds | P03/P04 | W3,W4,S2 | Form switching and cooldowns tested in battle and save/load |
| U07 | Super Limit Burst and EX-dependent availability | P03/P04 | W3,S2 | Correct availability, timing and resource rules |
| U08 | TMR, trust percentage, Trust Moogles, Trust Ability | P04 | W1,W3 | Deterministic progress and unique reward claims |
| U09 | STMR and related moogles/tickets | P04 | W3,W4 | Correct unlock and reward constraints |
| U10 | Ability awakening, latent abilities, Brave Ability enhancement | P04 | W3,W4 | Verified upgrade trees and material rules |
| U11 | Master Crowns and character-specific upgrades | P04 | W4 | Explicit unit and region applicability |
| U12 | Leader Skills and Unit Categories | P03/P04 | W5,W4 | Category-aware bonuses and exclusions |
| U13 | Overdrive | P03/P04 | S2,J1 | Per-unit activation limits, EX conditions and action economy |
| U14 | Fragments, duplicate exchange, awakening resources | P04/P05 | W3,W4 | Resource changes and duplicate policy tested |
| U15 | Pots, doors, cactuars, moogles and stat enhancement | P04 | W3,W4 | Caps, item quantities and save persistence |
| U16 | Unit lock/favorites, sorting, filters, fusion/sale safeguards | P04 | W1,W3 | No accidental loss of locked units |
| U17 | CG/illustrations, sprite/animation forms and unit lore | P10 | D1,W4,S4 | Media/metadata coverage by region and rights status |
| U18 | Additional late-era upgrade or unit mechanics not yet inventoried | P10 | W4,D3,J1 | Explicit discovery checklist; unknowns remain visible |

## 3. Equipment, items and collections

| ID | Feature | Stage | Evidence leads | Acceptance target |
|---|---|---|---|---|
| EQ01 | Weapons, armor, accessories, equipment types and slot restrictions | P04 | W1,W2,D2 | Valid equipment assignment, stat recalculation |
| EQ02 | Materia slots, passive effects, unique/stacking restrictions | P04 | W2,D2 | Correct stacking rules and slot validation |
| EQ03 | Vision Cards, progression, unit/category bonuses | P04 | W3,W4,D1 | Card bonuses, upgrade gates and form applicability |
| EQ04 | Inventory, sorting, capacity, locking, item sale and consumption | P04 | W1,D2 | Atomic transactions and no negative quantities |
| EQ05 | Equipment/party presets and shared-item handling | P04 | W1,W4 | Restore legal builds without duplicating gear |
| EQ06 | Crafting recipes, materials, rewards and exchange | P05 | W1,D2 | Typed recipe references (ITEM/EQUIP/MATERIA); no false missing refs |
| EQ07 | Item World / Steel Castle Melfikya weapon enhancement | P08 | W4,W9 | Replayable enhancement flow with verified or explicitly adapted rules |
| EQ08 | Special equipment, event exclusives, upgrades, crowns and series bonuses | P04/P07 | W4,D3 | Record per-region source and acquisition path |
| EQ09 | Collection encyclopedia (units, equipment, items, monsters, cards) | P10 | W1,S4,D1 | Filterable collection with missing-content labels |

## 4. Battle systems

| ID | Feature | Stage | Evidence leads | Acceptance target |
|---|---|---|---|---|
| B01 | Party combat, player/enemy phases, action queue, target selection | P03 | W1,W2,W9 | Complete deterministic win/loss loop |
| B02 | Physical, magic, hybrid, fixed/evocation and other damage types | P03/P04 | W2 | Versioned formulas and edge-case tests; unsupported rules labeled |
| B03 | Elements, resistances, immunities, imperils, imbue, amplification | P03/P04 | W2,W4 | Correct order, caps and damage outcomes |
| B04 | Stat buffs/breaks, mitigation, barriers, healing, MP recovery | P03/P04 | W2 | Effect lifecycle, stacking and expiration |
| B05 | Status ailments, resistance, dispel, cleanse, death, reraise | P03/P04 | W2 | State transitions and invalid targets tested |
| B06 | Chaining, chain families, elemental/spark/tag chains, caps | P03/P04 | W2,W4 | Deterministic hit timeline and individual action activation |
| B07 | LB gauge, LB effects, SLB, gauge recovery | P03/P04 | W2,W3 | Correct consumption and activation constraints |
| B08 | Dual wield, multicast, skill unlocks and cooldowns | P03/P04 | W2,W3 | Ordered action/effect execution and costs |
| B09 | Killers, weapon imperil, accuracy, evasion, mirage | P04 | W2,W4 | Race/type interaction and counterexamples |
| B10 | Cover, provoke, guard, redirects | P04 | W2 | Correct eligible targets and mitigation |
| B11 | Jump, delayed actions, counter, passive triggers | P04 | W2 | Turn and trigger ordering, no infinite loops |
| B12 | Field effects, break gauge, morale gauge, leader/Overdrive interactions | P04/P08 | W4,S2,J1 | Explicit mode applicability and regional rules |
| B13 | Boss AI, HP thresholds, multi-wave encounters, difficulty and enrage | P03/P08 | W2,D2,D3 | Reproducible AI and encounter transitions |
| B14 | Party size, companion slot, swap battles and mode restrictions | P03/P08 | W1,W9 | Mode-specific constraints, including historical 10-unit trials |
| B15 | Battle missions, drops, results, retries and rewards | P03/P06 | W1,W9 | Idempotent rewards and completion criteria |
| B16 | Auto/repeat and battle speed with safe deterministic simulation | P03/P09 | W1,P | Same logical results when presentation speed changes |
| B17 | Attack, skill, damage, defeat, victory and summon animations | P03/P10 | D1,W2 | Valid frame offsets, timing, alpha; no silent asset substitution |

## 5. Espers, summon and economy

| ID | Feature | Stage | Evidence leads | Acceptance target |
|---|---|---|---|---|
| ES01 | Esper discovery, unlock quests/trials, roster by region and era | P05/P06 | W1,W6 | Documented unlock path per available Esper |
| ES02 | Esper stars, level, skill boards, Magicite/Megacite/Supercite/Ore | P05 | W3,W6 | Progression and resource transaction tests |
| ES03 | Equip Esper, stat bonuses, resistances, learned abilities | P05 | W2,W6 | Correct assignment and stat recomputation |
| ES04 | Evocation gauge, summon action, animation and effects | P05 | W2,W6 | Gauge, targeting and deterministic effects |
| SM01 | Standard, ticket, EX, friend point and other summon pools | P05/P07 | W1,W4 | Pool versions, eligible units and documented rates |
| SM02 | Limited, step-up, guaranteed/pity and historical banner rules | P05/P07 | W4,S2 | Explicit rates, steps and guarantees; unverified rates flagged |
| SM03 | Lapis, gil, tickets, energy and mode-specific resources | P05 | W1,W4 | No negative balances, documented offline earning/spending |
| SM04 | Duplicate handling, unit exchange, coin/token shops | P05/P07 | W3,W4 | Correct transactions and idempotent exchange |
| SM05 | Offline reward economy and no real-money payment | P05 | P | No payment service; all usable resources earned in game |

## 6. World, story and exploration

| ID | Feature | Stage | Evidence leads | Acceptance target |
|---|---|---|---|---|
| ST01 | Main story Seasons 1–5, chapter order and regional differences | P06/P10 | S1,S3,S4,W9 | Chapter inventory, GL/JP boundaries, missing content visible |
| ST02 | World map, towns, dungeons, routes and unlock conditions | P06 | W1,W9 | Navigation and progression tested |
| ST03 | NPCs, dialogue, shops, treasure and hidden quests | P06 | W1,W8 | Valid triggers, branches and one-time rewards |
| ST04 | Exploration encounters, movement, maps and environmental assets | P06 | W1,W9,D1 | Navigable desktop maps without distorted artwork |
| ST05 | Farplane / Dimensional Vortex hubs and unlocks | P06 | W9,W3 | Correct mode routing and progression gates |
| ST06 | Madam's Manor, side stories and optional long-form questlines | P06/P10 | W4,W8 | Quest dependency and chapter coverage |
| ST07 | Story event scripts, CG, voice, music and sound effects | P06/P10 | S4,D1,D3 | Rights-cleared playback or explicit unavailable status |
| ST08 | Memorial Edition reference inventory | P10 | S4 | Record supported archive content; no assumption of complete battle data |

## 7. Historical events and crossover

| ID | Feature | Stage | Evidence leads | Acceptance target |
|---|---|---|---|---|
| EV01 | Historical event catalog with original start/end, region, reruns and versions | P07 | W4,S2 | Region/date metadata; distinguish rerun from original |
| EV02 | Collaboration units, forms, skills, gear, Vision Cards, banners | P07/P10 | W4,D1,D3 | Cross-reference character/event/pool and separate rights status |
| EV03 | Raid events, raid summons, rewards and exchanges | P07 | W3,W4 | Offline raid progression and reward integrity |
| EV04 | King Mog / exchange farming and event currency | P07 | W3,W4 | Valid drops, exchange inventory, no double claims |
| EV05 | Story events, wave battles, challenge events, missions | P07 | W4 | Replayable event flow where recovered |
| EV06 | Seasonal events: Halloween, winter/Christmas, Lunar New Year and other festivals | P07 | W4 | Per-region evidence, exclusivity and rewards |
| EV07 | Anniversary, login campaigns, special missions and limited summons | P07 | S2,W4 | Historical metadata and offline adaptations |
| EV08 | Event Center with manual replay/unlock | P07 | P | Browse/search by region, date, type, series; no reliance on live server |
| EV09 | Collaboration completeness audit | P07/P10 | W4,D1,D3 | Inventory every evidenced collaboration, not only popular examples |
| EV10 | Future original/custom characters and events | P11 | P | Separate CUSTOM namespace; validated pack import |

Examples for EV09 research: NieR:Automata, Kingdom Hearts, Xenogears, Dragon Quest, Parasite Eve, War of the Visions, other Square Enix series and external collaborations. This is a candidate list, not an exhaustive confirmed roster. Determine dates, participating units, regional availability, reruns, event stages, bosses, rewards, story, assets and licensing independently. Missing historical banners or event scripts must not be invented.

## 8. Endgame, challenges and trials

| ID | Feature | Stage | Evidence leads | Acceptance target |
|---|---|---|---|---|
| EN01 | Dark Visions / related scoring challenges | P08 | W4 | Verify eligible missions, scoring inputs and thresholds |
| EN02 | Clash of Wills and morale mechanics | P08 | S2,W4 | Difficulty, morale, modifiers and score tests |
| EN03 | World of Visions | P08 | W4 | Encounter and scoring definitions by event |
| EN04 | Chamber of the Fallen, Indignant, Vengeful, Reborn | P08 | W4,W9 | Audit exact names and availability; replayable trials |
| EN05 | Chamber of Arms / 10-unit swap battles | P08 | W9 | Swap restrictions and shared battle state |
| EN06 | Series Boss Battle, Chronicle Battle | P08 | W4 | Series/category bonuses and progression |
| EN07 | Twelve Types Takedown, Sealed Tower and other regional trials | P08 | W4,D3 | Audit region/era before claiming implementation |
| EN08 | Training Dummy / practice mode | P08/P09 | W4,P | Reproducible damage and chain experiments |
| EN09 | Offline personal scores, records and rewards | P08 | P | Local scoring, no fabricated online rankings |

## 9. Auxiliary systems and live-service adaptations

| ID | Feature | Stage | Evidence leads | Acceptance target |
|---|---|---|---|---|
| AX01 | Arena | P09 | W1,W9 | Offline AI opponents; clearly labeled adaptation |
| AX02 | Colosseum | P09 | W1,W9 | PvE rounds and progression |
| AX03 | Friend Units / Companion | P09 | W1,W8 | Local roster or synthetic companions; no online dependency |
| AX04 | Expedition | P09 | W7 | Availability by region, dispatch, return, success/rewards |
| AX05 | Fragment Dungeon and resource farming chambers | P09 | W3,W4 | Repeatable resource flow and historical restrictions audit |
| AX06 | Player rank, energy/stamina, unlocks | P09 | W1,W3 | Progression and local resource persistence |
| AX07 | Daily/general missions, rookie panels, achievements | P09 | W8,W4 | Local completion tracking and reward claims |
| AX08 | Mailbox, gift/reward history, login rewards | P09 | W1,W4 | Offline delivery; no dependency on server clock |
| AX09 | Party management and mode-specific loadouts | P04/P09 | W1,W4 | Preset persistence and validation |
| AX10 | Shops, exchange menus, crafting and item acquisition | P05/P09 | W1,W3 | No external payments, atomic transactions |
| AX11 | Notices, help, tutorial, encyclopedias and historical update archive | P09/P10 | W1,W4,S4 | Searchable local help and provenance |
| AX12 | Additional historical modes and progression systems | P10 | W4,D3 | Gap audit with explicit unknowns |

## 10. Native PC features (proposals, not original claims)

| ID | Feature | Stage | Evidence | Acceptance target |
|---|---|---|---|---|
| PC01 | Landscape 16:9 UI; 1280×720 and 1920×1080 | P02 onward | P | Actual screenshots and no clipping |
| PC02 | Responsive windows, fullscreen, high-resolution / ultrawide | P12 | P | Document tested resolutions; preserve pixel aspect |
| PC03 | Mouse, keyboard and configurable controller support | P03/P12 | P | Input/focus/rebinding tests |
| PC04 | Battle speed, skip/fast animation, reduced motion and accessibility | P03/P12 | P | No gameplay divergence; readable UI |
| PC05 | Local profiles, save slots, backups, corruption recovery, migrations | P02 onward | P | Round-trip and interrupted write tests |
| PC06 | Offline mode; no publisher servers or mandatory network | All | P | Run actual packaged game with network disabled |
| PC07 | Content packs and mods with schema/version/dependency validation | P11 | P | Safe loading; no executable plugins by default |
| PC08 | Localization EN/JP and proposed Vietnamese translation | P11 | P | Locale fallback, fonts, overflow and provenance |
| PC09 | New Game+ and optional sandbox/training mode | P11 | P | Separate save semantics and explicit design review |
| PC10 | Windows/Linux builds, release packaging, licenses and documentation | P12 | P | Actual exported binary launches on both platforms |
| PC11 | Performance, startup, loading, memory and frame pacing | P12 | P | Measured benchmarks; no unsupported FPS claims |

## 11. Content-pack architecture requirements (proposed)

Plan for versioned local packs, not a remote service. Each pack manifest must include pack ID, namespace, region, source version, schema version, dependencies, hashes, evidence and rights metadata. A pack may reference units, forms, abilities, assets, encounters, quests, events, banners and rewards. Do not silently overwrite existing keys or combine GL/JP by native ID. Keep historical and custom records distinct. Validate all relationships and asset references before enabling a pack. Support staged import, rollback and save compatibility. Treat pack input as untrusted; no executable content or network dependency by default.

Never fabricate rates, missing event stories, unit stats or original mechanics. Distinguish a replayable remastered adaptation from the original timed live-service design. Real-money purchases, original online accounts, publisher-server emulation, multiplayer and online rankings are excluded from initial scope.

## 12. Milestones and reported baseline

This expanded prompt sequence is a proposed refinement of the existing PROJECT_PLAN.md, not authorization to start every task at once.

| Prompt | Focus | Status |
|---|---|---|
| P01 | Full Data Audit | Initial audit reported complete; coverage/rights limitations remain |
| P02 | Godot Foundation & Character Viewer | Reported 14/15 criteria; export/runtime verification blocked |
| P03 | Battle Engine vertical slice | Current assigned milestone; report pending |
| P04 | Character progression, equipment, NV/NV+, TMR/STMR, advanced combat | Planned |
| P05 | Esper, summon, crafting and offline economy | Planned |
| P06 | World, exploration and story | Planned |
| P07 | Event Center, historical events and collaborations | Planned |
| P08 | Endgame and trials | Planned |
| P09 | Auxiliary systems | Planned |
| P10 | Regional content audit expansion and controlled imports | Planned |
| P11 | Content packs, mod support, localization | Planned |
| P12 | Full QA, optimization and Windows/Linux release | Planned |

Reported prior local audit/foundation work must be verified against actual local Git and reports. The public repository does not necessarily contain those commits. Current known gates include rights review, final-era structured data gaps, independent mechanic verification and matching export templates. Synthetic prototypes may be implemented within the authorized scope, but do not mark original content recovered.

## 13. Next-agent handoff

At the beginning of the next authorized prompt:
1. Inspect local branch, working tree, current milestone report and commit. Preserve all local audit, foundation, skill and battle work.
2. Fetch origin. Inspect the feature-list commit/PR, verify the diff is documentation only and whether it is already present.
3. Integrate only the reviewed feature-list commit onto the next milestone branch (cherry-pick if appropriate, or use the already-integrated version). Do not reset to origin/main, discard local work or merge unrelated branches. Stop and report unexpected conflicts.
4. Read this file and AGENTS.md before planning. Use only relevant project-local skills. Incorporate dependencies and acceptance criteria of the next milestone, without implementing later milestones prematurely.
5. Update tracking with actual evidence, tests, limitations and new feature discoveries. Treat this as a living backlog, not a claim that everything is implemented.

## 14. Release gate

A release must disclose actual GL and JP coverage by category and era, missing/unverified records, implemented versus adapted mechanics, historical event coverage, supported languages/platforms, known bugs and rights status. A complete audit is not the same as a complete playable game. Only include content lawfully distributable. Square Enix and crossover rights holders are not affiliated with this independent working-title project.
