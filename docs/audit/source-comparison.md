# FFBE source comparison

**Status:** audit record only; supplemental/comparative evidence. No listed source is imported, downloaded into the repository, executed, or treated as a redistribution licence.
**Evidence date:** 2026-11-25 (UTC). No claim is made about validity after that date.
**Access method:** exact Git revisions through REST metadata, tree listings and targeted raw reads; cached MediaWiki parse API text for community rules; Altema through the `r.jina.ai` proxy after direct 403; official pages read as notices/promotional text only. No APK, ZIP, CPK, or data pack was downloaded.
**Rights gate:** `not_passed`. MIT and GPL labels apply to repository code; CC BY-NC-SA applies to article text; none waive rights in game-derived names, art, text, data or music. No redistribution permission is claimed.
**Machine-readable companion:** [`data/validation/source-conflicts.json`](../../data/validation/source-conflicts.json)
**Related:** [`final-era-coverage.md`](final-era-coverage.md), [`elvlin-source-audit.md`](elvlin-source-audit.md)

## 1. Sources compared

| Source | Revision / date | Size evidence | Regions | Strong evidence | Missing | Rights signal | Classification |
|---|---|---|---|---|---|---|---|
| [DaddyRaegen/ffbe_asset_dump](https://github.com/DaddyRaegen/ffbe_asset_dump) | `f82d603c90ec799f539280267d3af7589c79f117`, 2026-10-10 | 148,131 files / 3,596,307,289 bytes tree metadata | GL, JP, shared | Unit/master/data.json identity, regional bundles, series/acquisition/rarity labels, sprites, illustrations, icons, animation CSV/frame data, backgrounds, UI effects, monster/VC catalogs, reports | No structured skills/passives/TMR/STMR/leader skills/categories, banners/rates/events/story/dialogue/localization | No licence; third-party art | `COMMUNITY_RECOVERED` |
| [DanUgore/ffbe_data](https://github.com/DanUgore/ffbe_data) | `ce7d98a6499bb8c2f6656f0698f60c30001a05b0`, 2018-02-09 | 37 files / 77,884,391 bytes | GL, JP | Structured units, abilities, magic, LBs, learns, equip, items, materia, recipes, beasts, boards, monskills, AI, quests, colorewards; GL enhance/important; JP missions/lastmodified | No vision cards, NV/NV+/EX, Brave Shift, Overdrive, leader skills/categories, banners/rates/events/story/dialogue/localization/assets | No licence | `COMMUNITY_RECOVERED` |
| [aEnigmatic/ffbe](https://github.com/aEnigmatic/ffbe) | `95727376e82d27acc1290b6dc8ad27ce3c89ea71`, 2024-09-02 | 32 files; counts below | GL | Later structured units/equipment/items/materia/abilities/LBs/monster skills/missions/recipes/vision cards | No visual assets; no declared extraction revision/method; raw `units.json` too large to fetch; NV/NV+/EX claims unchecked | MIT is repo code metadata, not game-data rights waiver | `COMMUNITY_RECOVERED` / `UNVERIFIED` |
| [aEnigmatic/ffbe-jp](https://github.com/aEnigmatic/ffbe-jp) | `ea7d9fa82659e66fed1a0a5dba4616089cc807dc`, 2025-10-03 | 32 files; counts below | JP | Later structured JP equivalents including vision cards | Same limitations as GL; no README at revision | MIT is repo code metadata, not game-data rights waiver | `COMMUNITY_RECOVERED` / `UNVERIFIED` |
| [TBMonkey/ffbe-gl-server](https://github.com/TBMonkey/ffbe-gl-server) | `2a940d88d9209283f07c801eef067c058735ef4c`, 2026-11-22 | 83 files / 33,686,831 bytes | GL v9.0.0 | Protocol/battle/mission tables, event spine, Clash of Wills, server contract | Contract evidence, not complete content dataset; protocol/replies partly authored by fan project | MIT covers code; `ACKNOWLEDGEMENTS.md` reserves game content rights to Square Enix/gumi | `COMMUNITY_RECOVERED` |
| [Elvlin/exvius-offline](https://github.com/Elvlin/exvius-offline) | `b520e563cbc4364a07ee40331012340dc8aeb841`, 2026-11-16 | Tree metadata only; no packs fetched | GL | Offline-client metadata, event/banner/equipment JSON layers, partially recovered contract schemas | Original APK and keys absent; OURS/rates/pacing overlays; API 403; `event_encounters.json` >20 MB cap | No licence; fan project built from original Global game | `COMMUNITY_RECOVERED` / `COMMUNITY_MODIFIED` / `UNVERIFIED` |
| exvius.fandom.com | Cached `action=parse&prop=wikitext` responses; direct HTML 403 | Article-level | GL+JP archive | Unit/TMR/STMR/ability/LB/item/materia/VC/enemy/esper/event/story/gacha/chaining categories | Article text, not bulk data; no captured page revision | CC BY-NC-SA; not official documentation or rights grant | `COMMUNITY_RECOVERED` / `UNVERIFIED` |
| Altema (via `r.jina.ai`; direct 403) | Last updated 2026-11-01 | Article-level | JP | NV list, NV awakening, NV+, EX awakening/bonus, Overdrive, leader/category rankings, chain families, TMR/STMR, equipment/materia, VC, espers, bosses, events, story digest, gacha/reroll | Article prose, not structured dump; rights notice forbids unauthorized reuse; records JP closure 2025-10-31 12:00 JST | Rights notice forbids unauthorized reuse | `COMMUNITY_RECOVERED` / `UNVERIFIED` |
| Official GL/JP pages | Notices/promotional text only | No dataset | GL / JP | GL sunset 2024-10-30 after 8 years/4 seasons; JP service ended with notice/refund/support and season 1–5 character pages | No dump; exact URLs not retained in permitted evidence | © Square Enix; developed by gumi; logo/illustration © Yoshitaka Amano | `ORIGINAL_SOURCE` attribution only |

## 2. Structured counts from aEnigmatic revisions

Top-level record counts, not verified gameplay coverage.

| Category | GL | JP |
|---|---:|---:|
| Units | 1,751 | 1,683 |
| Equipment | 4,275 | 3,715 |
| Items | 4,729 | 3,851 |
| Materia | 1,675 | 1,599 |
| Abilities | 28,212 | 27,051 |
| Limit Bursts | 3,584 | 3,386 |
| Monster skills | 19,432 | 17,926 |
| Missions | 17,915 | 17,924 |
| Recipes | 2,051 | 1,995 |
| Vision cards | 339 | 252 |

## 3. Coverage matrix by source

| Domain | Source A asset dump | Source B 2018 | aEnigmatic GL/JP | TBMonkey GL v9.0.0 | Elvlin | Fandom / Altema |
|---|---|---|---|---|---|---|
| Unit identity / catalogs | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | `UNVERIFIED` | `UNVERIFIED` | `COMMUNITY_RECOVERED` |
| Skills / abilities / LBs | `UNAVAILABLE` | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | `UNVERIFIED` derivation chain | `COMMUNITY_RECOVERED` |
| Equipment / items / materia | `UNAVAILABLE` | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | `UNVERIFIED` | `RECOVERED_PARTIAL` growth/shops | `COMMUNITY_RECOVERED` |
| Monsters / AI / bosses | Catalogs only | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` tables | Encounter structure only; full file blocked | `COMMUNITY_RECOVERED` |
| Vision cards | Catalogs only | `UNAVAILABLE` | `RECOVERED_PARTIAL` | `UNVERIFIED` | `UNVERIFIED` | `COMMUNITY_RECOVERED` |
| Events / missions / quests | `UNAVAILABLE` | JP only; GL files absent | `RECOVERED_PARTIAL` | `RECOVERED_PARTIAL` event spine | `COMMUNITY_MODIFIED` policies | `COMMUNITY_RECOVERED` |
| Banners / rates / guarantees | `UNAVAILABLE` | `UNAVAILABLE` | `UNAVAILABLE` | `UNVERIFIED` | `COMMUNITY_MODIFIED` OURS/ours | `UNVERIFIED` article-level |
| Story / dialogue / localization | `UNAVAILABLE` | `UNAVAILABLE` | `UNAVAILABLE` | `UNVERIFIED` | `UNVERIFIED` | `UNVERIFIED` article-level |
| Visual assets / animation | `RECOVERED_PARTIAL` | `UNAVAILABLE` | `UNAVAILABLE` | `UNAVAILABLE` | 82 PNG metadata; no blobs | `UNVERIFIED` |
| NV / NV+ / EX / Overdrive / leader skills | `UNAVAILABLE` animation sets only | `UNAVAILABLE` | Claimed fields unchecked | `UNVERIFIED` | `UNVERIFIED` | JP article evidence only |

No row above is `VERIFIED`.

## 4. Key differences

1. **Visual inventory vs. structured data.** Source A exposes GL/JP/shared asset forms and identity metadata but not structured skills, passives, TMR/STMR, leader skills, categories, banners, rates, events, story or dialogue. Source B supplies structured 2018 data but no vision cards or later systems.
2. **Historical vs. final-era structured data.** aEnigmatic revisions are later than Source B and include vision cards, but declare no extraction method or original game revision. Their MIT metadata is a code licence, not a content waiver.
3. **Contract vs. content.** TBMonkey targets the GL v9.0.0 client and provides battle/mission/event tables plus a contract; `ACKNOWLEDGEMENTS.md` reserves game content rights. It is contract evidence, not a content licence or proof of complete final-era data.
4. **Offline client layers.** Elvlin mixes original-client references, recovered layers, and explicitly authored overlay: `banner_campaigns.json` `_meta` says grouping/filter/art join are OURS; `ffbe_gacha.py` says rates are ours; raid pacing, arena rivals and expedition policies are local. Do not treat these as original rules.
5. **Community encyclopedias.** Fandom self-describes as a GL+JP archive with broad categories but provides article text, not bulk data. Altema provides JP article-level coverage through a proxy, with a rights notice and a recorded JP closure date.
6. **Temporal truth.** GL ended 2024-10-30; JP ended 2025-10-31. Later repositories are snapshots or fan continuations, not evidence of live-service truth.

## 5. Conflict list

| ID | Conflict | Classification | Handling |
|---|---|---|---|
| SC-01 | 11 native IDs are different GL/JP units: `401008507` Kaito/Yoshikiri; `401008607` Godrea/Starlight Elena; `401008707` Emperor Foo/Ibara; `401014207/217` Abigail/Duane and Duane/Hyoh & Panthera Ultimus; `401014307/317` Melissa/Eternal Radiance Elena; `401014507/517` Duane/Hyoh & Panthera Ultimus; `401014607/617` Nora/Richt | `COMMUNITY_RECOVERED` | Composite `kind:REGION:id` identities; no numeric-only lookup |
| SC-02 | Translated JP payload had 420 GL-only IDs absent from raw JP and omitted 126 raw JP forms | `COMMUNITY_MODIFIED` | Keep translation layer distinct from raw JP |
| SC-03 | Raw tables: 3,932 native IDs (2,891 shared, 420 GL-only, 621 JP-only), 21 asset-only unresolved | `COMMUNITY_RECOVERED` / `UNVERIFIED` | Preserve `series: null`; do not invent region/rarity/acquisition |
| SC-04 | GL dump carried JP Duane bundles at Abigail IDs, byte-identical to JP `unit27.cpk` | `COMMUNITY_RECOVERED` | Cross-region asset contamination; never fill GL from JP bundle |
| SC-05 | GL animation CGS `401008507` oscillates 63→62 | `ORIGINAL_SOURCE` observation via Source A | Strict monotonic frame validation is wrong |
| SC-06 | 651 Source B “missing” refs are validator type-routing false positives resolving in `equip.json` / `materia.json` | `COMMUNITY_RECOVERED` | Fix validator routing, not content |
| SC-07 | Elvlin `original`/`recovered`/`overlay` precedence and OURS metadata | `COMMUNITY_MODIFIED` | Preserve layer distinctions |
| SC-08 | aEnigmatic raw `units.json` too large to fetch; NV/NV+/EX field claims unverified | `UNVERIFIED` | No final-era progression claim |
| SC-09 | Altema direct 403; proxy-mediated text; rights notice forbids reuse | `UNVERIFIED` | Article reference only |
| SC-10 | No licence for Source A/B/Elvlin; MIT/GPL/CC labels elsewhere do not cover game content | `UNVERIFIED` | Rights gate `not_passed` |
| SC-11 | Source B 2018 snapshot and Source A 2026 snapshot cannot establish current final-era truth | `UNVERIFIED` | No completeness claim |

## 6. Evidence classification counts

Counts are classified evidence groups in this comparison, not game records.

| Classification | Count | Examples |
|---|---:|---|
| `ORIGINAL_SOURCE` | 5 | Official GL/JP notices, `[FFBEWW]` client citation, expected original APK hash, CPK/DAT hash provenance |
| `COMMUNITY_RECOVERED` | 8 | Source A, Source B, aEnigmatic GL/JP, TBMonkey, Elvlin recovered layers, Fandom, Altema |
| `COMMUNITY_MODIFIED` | 6 | Elvlin OURS/rates/pacing, translated JP payload, arandooku derivative GIFs, fan-authored protocol replies |
| `UNVERIFIED` | 8 | Exact rates, completeness, wiki accuracy, APK provenance, rights, NV claims, later validity, unresolved forms |
| `SYNTHETIC_FIXTURE` | 1 | Local Godot fixture data |
| `REMASTERED_DESIGN` | 1 | Local M4/M5 combat approximations |

## 7. Not imported

Nothing in this comparison has been copied into `game/`, `data/normalized/`, or a distributable build. Phase 0 remains **0 VERIFIED** records. No source here grants redistribution permission; all later imports require a separate rights-reviewed batch with exact revision, checksum, region, category coverage, and explicit separation of `ORIGINAL_SOURCE`, `COMMUNITY_RECOVERED`, `COMMUNITY_MODIFIED`, `UNVERIFIED`, `SYNTHETIC_FIXTURE` and `REMASTERED_DESIGN` material.
