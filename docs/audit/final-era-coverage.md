# Final-era coverage assessment

**Status:** audit record only; supplemental evidence. No record below is promoted to project `Verified` status and no content is imported.
**Evidence date:** 2026-11-25 (UTC). Later validity is not claimed.
**Access method:** exact Git revisions via REST/tree/raw/Atom where available; cached MediaWiki `action=parse&prop=wikitext` responses for community rules; Altema read through the `r.jina.ai` proxy because direct access returned 403; targeted raw reads only. No APK, ZIP, CPK, or data pack was downloaded or executed.
**Rights gate:** `not_passed`. Public access, MIT/GPL labels on code, or CC BY-NC-SA on article text do **not** waive rights in FFBE names, art, text, music or extracted game data. No redistribution permission is claimed.
**Machine-readable companion:** [`data/validation/final-era-coverage.json`](../../data/validation/final-era-coverage.json)
**Related:** [`source-comparison.md`](source-comparison.md), [`source-conflicts.json`](../../data/validation/source-conflicts.json)

## 1. Baseline and temporal boundary

| Item | Value | Basis |
|---|---|---|
| Phase 0 normalized records | 35,928 | `safe-import-plan.md`, `supplemental-sources.json` |
| Phase 0 inventoried files | 148,168 | Same |
| Phase 0 collision candidates | 5,181 | Same |
| Phase 0 regional unit-form conflicts | 11 | Same |
| Phase 0 `VERIFIED` records | **0** | Same; unchanged by this assessment |
| Global service end | 2024-10-30, after 8 years and 4 seasons of story | Official GL page (promotional text only; exact URL not retained in permitted evidence) |
| Global copyright notice | © Square Enix; developed by gumi; logo/illustration © Yoshitaka Amano | Official GL page |
| Japan service end | Ended; notice/refund/support links; season 1–5 character pages | Official JP page; Altema records 2025-10-31 12:00 JST |
| Later repositories | 2024–2026 snapshots or fan continuations, not live-service truth | Revision dates in `supplemental-sources.json` and observed evidence |

## 2. Coverage matrix

Statuses are `RECOVERED_PARTIAL`, `UNVERIFIED`, `UNAVAILABLE`, `SYNTHETIC_FIXTURE`, or `REMASTERED_DESIGN`. No row is `VERIFIED`.

| Domain | GL | JP | Best evidence | Classification | Gap / blocker |
|---|---|---|---|---|---|
| Units, forms, identity metadata | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | Source A catalog/master identity; Source B 2018; aEnigmatic 1,751 / 1,683 units | `COMMUNITY_RECOVERED` | 11 native-ID collisions; 21 asset-only unresolved forms; 126 raw JP forms without translated names |
| Abilities, magic, Limit Bursts | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | Source B; aEnigmatic 28,212 / 27,051 abilities and 3,584 / 3,386 LBs; TBMonkey battle tables | `COMMUNITY_RECOVERED` | Damage/effect fields are raw, not combat-verified; Elvlin community break data explicitly not first-party |
| Equipment, materia, items, recipes | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | Source B; aEnigmatic 4,275 / 3,715 equipment, 4,729 / 3,851 items, 1,675 / 1,599 materia, 2,051 / 1,995 recipes; Elvlin `equipment_growth*.json` | `COMMUNITY_RECOVERED` | 651 “missing” refs were validator type-routing false positives resolving in `equip.json` / `materia.json` |
| Monsters, bosses, enemy AI | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | Source B beasts/monster skills/AI; aEnigmatic 19,432 / 17,926 monster skills; TBMonkey `F_MONSTER_MST.tsv`, `F_MONSTER_SKILL_MST.tsv`, `F_BATTLE_GROUP_MST.tsv` | `COMMUNITY_RECOVERED` / `UNVERIFIED` | Elvlin `event_encounters.json` full content blocked; original AI decisions not established |
| Vision Cards | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | Source A catalogs; aEnigmatic 339 / 252 vision cards | `COMMUNITY_RECOVERED` | Absent from Source B and from aEnigmatic visual assets; no cross-verified effect text |
| Quests, missions, events | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | Source B JP 74 quests / 3,440 missions (no GL boards/missions/quests file); aEnigmatic 17,915 / 17,924 missions; Elvlin `event_archive.json`, `event_battles.json`, `event_banner_tree.json`; TBMonkey `event_spine.json`, Clash of Wills | `COMMUNITY_RECOVERED` / `COMMUNITY_MODIFIED` | Elvlin selection policy and OURS metadata; completeness unknown |
| Banners, rates, guarantees | `UNVERIFIED` | `UNVERIFIED` | Elvlin `banner_campaigns.json` `_meta` says grouping/filter/art join are OURS; `ffbe_gacha.py` says rates are ours; Fandom gacha category; Altema gacha/reroll articles | `COMMUNITY_MODIFIED` / `UNVERIFIED` | Exact historical pools, rates and guarantees not available |
| Story, dialogue, localization | `UNVERIFIED` | `UNVERIFIED` | Fandom story/event categories; Altema story digest; official pages are promotional only | `UNVERIFIED` | No complete dump; translated JP payload is not raw JP (420 GL-only IDs absent from raw JP; 126 raw JP forms omitted) |
| Visual assets, sprites, animation | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | Source A 148,131 files / 3,596,307,289 bytes; Source A animation CSV and frame data; Elvlin 82 PNG in tree metadata; arandooku derivative GIFs | `COMMUNITY_RECOVERED` / `COMMUNITY_MODIFIED` | No packs fetched; GL CGS `401008507` has deliberate 63→62 oscillation, so strict monotonic validation is wrong; derivative GIFs add no provenance |
| NV / NV+ / EX / Overdrive / leader skills / categories | `UNVERIFIED` | `UNVERIFIED` | Altema JP articles; aEnigmatic raw fields claimed but not independently checked | `UNVERIFIED` | Source B predates these systems; Source A `animation_sets` main/overdrive/effect is animation metadata, not gameplay Overdrive data |
| Audio, video, master text | `UNAVAILABLE` | `UNAVAILABLE` | Not present in inspected public trees | `UNVERIFIED` | No usable source; do not fabricate |
| Runtime game content | `SYNTHETIC_FIXTURE` | `SYNTHETIC_FIXTURE` | Local Godot fixtures and combat slice | `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN` | Project-authored, explicitly not original FFBE data |

## 3. Regional identity conflicts

Numeric native IDs are not globally unique. These 11 GL/JP unit-form collisions must use composite IDs such as `unit:GL:401008507` and `unit:JP:401008507`.

| Native ID | GL form | JP form |
|---:|---|---|
| 401008507 | Kaito | Yoshikiri |
| 401008607 | Godrea | Starlight Elena |
| 401008707 | Emperor Foo | Ibara |
| 401014207 | Master Machinist Abigail | Dark Knight Duane |
| 401014217 | Dark Knight Duane | Hyoh & Panthera Ultimus |
| 401014307 | Melissa | Eternal Radiance Elena |
| 401014317 | Eternal Radiance Elena | (distinct JP form at same native ID; do not merge) |
| 401014507 | Dark Knight Duane | Hyoh & Panthera Ultimus |
| 401014517 | Hyoh & Panthera Ultimus | (distinct JP form at same native ID; do not merge) |
| 401014607 | Ruin Explorer Nora | Richt |
| 401014617 | Richt | (distinct JP form at same native ID; do not merge) |

The shorthand in the research record pairs `401014307/317`, `401014507/517` and `401014607/617`; the table preserves each native ID separately rather than guessing unnamed labels. Additional identity hazards: translated JP payloads contained 420 GL-only IDs absent from raw JP and omitted 126 raw JP forms; raw tables hold 3,932 native IDs (2,891 shared, 420 GL-only, 621 JP-only), plus 21 asset-only forms with unresolved region.

## 4. Conflict list

| ID | Conflict | Classification | Action |
|---|---|---|---|
| FC-01 | 11 native form IDs denote different GL/JP units | `COMMUNITY_RECOVERED` | Composite regional identities only |
| FC-02 | Translated JP is not raw JP (420 GL-only IDs; 126 omitted raw forms) | `COMMUNITY_MODIFIED` | Keep translation layer separate from raw namespace |
| FC-03 | GL dump carried JP Duane bundles at Abigail IDs, byte-identical to JP `unit27.cpk` | `COMMUNITY_RECOVERED` | Cross-regional asset contamination; do not auto-fill GL from JP |
| FC-04 | GL animation CGS `401008507` oscillates 63→62 | `ORIGINAL_SOURCE` observation via Source A | Do not enforce strict monotonic frame validation |
| FC-05 | Elvlin `original`/`recovered`/`overlay` precedence and OURS metadata | `COMMUNITY_MODIFIED` | Preserve layer labels; no original-rule claim |
| FC-06 | Source B’s 651 “missing” refs resolve in other categories | `COMMUNITY_RECOVERED` | Validator routing fix, not content loss |
| FC-07 | GL ended 2024-10-30; JP ended 2025-10-31; later repos are snapshots/fan continuations | `ORIGINAL_SOURCE` / `UNVERIFIED` | No claim of current service truth |
| FC-08 | MIT/GPL/CC labels cover code or article terms, not game content | `UNVERIFIED` | Rights gate stays `not_passed` |
| FC-09 | aEnigmatic NV/NV+/EX field claims not independently checked | `UNVERIFIED` | No final-era progression assertion |
| FC-10 | Exact banners/rates/guarantees, event/story/dialogue completeness, Altema/Fandom accuracy, Elvlin APK provenance and redistribution rights remain unresolved | `UNVERIFIED` | Exclude from import |

## 5. Access blockers

| Blocker | Evidence | Consequence |
|---|---|---|
| GitHub REST 403 for Elvlin | Observed 2026-11-25 | Raw/tree/Atom only; no API-derived expansion |
| Raw `LICENSE` 404 for Elvlin | Observed | No rights grant |
| `event_encounters.json` raw fetch exceeded 20 MB cap | Elvlin observation | Full contents not assessed |
| `aEnigmatic/ffbe` `units.json` too large to fetch | Source comparison record | NV/NV+/EX field claims unchecked |
| Altema direct 403; read via `r.jina.ai` proxy | Final-era research record | Proxy-mediated article text only; rights notice forbids unauthorized reuse |
| Official GL/JP pages | Promotional text / notices only | No structured dump |
| No packs, APKs, ZIPs or CPKs downloaded | This audit and `supplemental-source-discovery.md` | Size/hash claims are metadata only |

## 6. Evidence classification counts

Counts are classified evidence groups, not game records.

| Classification | Count | Examples |
|---|---:|---|
| `ORIGINAL_SOURCE` | 5 | Official GL/JP notices, `[FFBEWW]` client citation, expected original APK hash, CPK/DAT hash provenance |
| `COMMUNITY_RECOVERED` | 10 | Source A tree metadata, Source B JSON, aEnigmatic GL/JP, TBMonkey tables, Elvlin recovered layers, Fandom, Altema |
| `COMMUNITY_MODIFIED` | 6 | Elvlin OURS/replacements, local pacing/rivals/rounds, arandooku GIF conversion, translated JP payload |
| `UNVERIFIED` | 9 | Exact rates, story completeness, wiki accuracy, APK provenance, rights, later validity, unresolved forms |
| `SYNTHETIC_FIXTURE` | 1 | Local Godot fixture data |
| `REMASTERED_DESIGN` | 1 | Local M4/M5 combat approximations |

## 7. Not imported

No final-era source, pack, APK, JSON payload, image, or derived table has been imported into the Godot project or any distributable build. Phase 0 remains **0 VERIFIED** records. The lawful-evidence and rights gates remain unresolved (`not_passed`); any future content batch must record lawful basis, exact revision, checksum, region, category coverage, separation of authored and game-derived material, and must not promote recovered or synthetic data to `VERIFIED`.
