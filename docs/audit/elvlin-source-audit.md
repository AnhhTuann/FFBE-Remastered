# Elvlin `exvius-offline` source audit

**Status:** supplemental evidence only; reference-only. No source from this audit is imported, altered, packaged, or treated as a redistribution licence.
**Evidence date:** 2026-11-25 (UTC). Claims of current validity after this date are not made.
**Access method:** GitHub REST metadata returned HTTP 403; evidence was read from pinned raw file paths, an exact Git tree listing, and the Atom feed. No archive, APK, ZIP, or data pack was downloaded or executed.
**Machine-readable companion:** [`data/manifests/elvlin-source-manifest.json`](../../data/manifests/elvlin-source-manifest.json)
**Rights gate:** `not_passed`. The repository has no `LICENSE` (raw `LICENSE` returned 404). The README describes an unofficial fan project built from the original Global game, not affiliated with Square Enix or gumi, and credits content owners including Square Enix/gumi. Inspection grants **no redistribution permission**.

All raw paths below are relative to `https://raw.githubusercontent.com/Elvlin/exvius-offline/b520e563cbc4364a07ee40331012340dc8aeb841/`. The repository tree is `https://github.com/Elvlin/exvius-offline/tree/b520e563cbc4364a07ee40331012340dc8aeb841`; the release tag is `https://github.com/Elvlin/exvius-offline/releases/tag/v0.1.36`.

## 1. Revision scope

| Item | Observed value | Basis |
|---|---|---|
| Repository | `Elvlin/exvius-offline` — <https://github.com/Elvlin/exvius-offline> | Raw/tree/Atom inspection |
| Default branch HEAD | `b520e563cbc4364a07ee40331012340dc8aeb841` | 2026-11-16T09:47:38Z |
| Tag | `v0.1.36` | Commit `65da3ca6b7924774c6c22dfbe397157c4a8966c4` |
| Release | 16 Nov, 09:44; 5 assets | Release page metadata |
| API access | HTTP 403 | GitHub REST endpoint refused; raw/tree/Atom used instead |
| Download requirement | No account required | Root `README.md` |
| Runtime target stated by project | Android 7.0+, 64-bit ARM; ~17.8 GB download, ~21 GB free space | Root `README.md` |
| Phase 0 effect | None. Phase 0 remains 35,928 normalized records, 148,168 files, 5,181 collision candidates, **0 VERIFIED** records. | `docs/audit/safe-import-plan.md`, `data/manifests/supplemental-sources.json` |

The word “verified” in the research record means *observed on 2026-11-25*. It does not promote any record to the project’s `Verified` status.

## 2. Root README observations

| Observation | Classification | Import consequence |
|---|---|---|
| Fan project built from the original Global game; unofficial; not affiliated with Square Enix or gumi | `UNVERIFIED` as rights evidence | Reference only; no rights grant |
| Credits content owners, including Square Enix/gumi | `ORIGINAL_SOURCE` attribution signal | Attribution does not equal permission |
| No `LICENSE`; raw `LICENSE` 404 | `UNVERIFIED` | Rights gate remains `not_passed` |
| `.gitignore` excludes repository snapshots, `*.apk` except release, `*.zip`, `*.jks`, keystore, `.env` | `COMMUNITY_MODIFIED` | Do not fetch or commit excluded material |
| Download needs no account | `UNVERIFIED` project claim | No inferred access to original client |
| Replay stages farm Lapis; missing campaign details use replacements; shared raid progress adjusted for one player; former cash bundles cost Lapis; restored text/art/events may contain mistakes; advanced upgrades/event interactions need fixes | `COMMUNITY_MODIFIED` / `UNVERIFIED` | These are fan-project adaptations, not original rules |

## 3. Original / recovered / overlay distinction

| Layer | Evidence at pinned revision | Classification | Handling |
|---|---|---|---|
| Original | `source/README.md` expects `repository snapshots/FFBE-Global-v9.0.0-original.apk` with SHA-256 `955deacfbe4b3d0cd04e2947eb005e310915ba98132d71216626bfb3554ad246`; original client binaries and signing keys are absent | `ORIGINAL_SOURCE` | Path/hash reference only; file not present here |
| Original contract | `source/docs/analysis/FFBE_SERVER_CONTRACT.md` cites `[FFBEWW] libgame.so` ARM64 v9.0.0 and an APK dump; `[Community]` BraveHaxvius notes; status `INVENTORY`; schemas partially recovered | `ORIGINAL_SOURCE` + `COMMUNITY_RECOVERED` | Contract inventory, not a content licence |
| Recovered | Event, banner, equipment-growth and reward JSON layers carry source/revision/hash fields and native reward tuples | `COMMUNITY_RECOVERED` | Partial, not cross-verified FFBE truth |
| Overlay | `build_release_data.py` uses `original` → `recovered` → `overlay` precedence; `banner_campaigns.json` `_meta` says era grouping, class filter and art join are “OURS”; `ffbe_gacha.py` says “the rates are ours” | `COMMUNITY_MODIFIED` | Must stay visually/label-wise separate from recovered data |
| Unverified | APK provenance, full `event_encounters.json`, exact banners/rates/guarantees, post-2026-11-25 validity | `UNVERIFIED` | Blocked or explicitly unclaimed |

## 4. Release metadata observed in `data/latest.json`

| Field | Value |
|---|---|
| `schema` / `revision` / `version` | `1` / `13` / `2026.11.16.13` |
| `minAppVersionCode` | `9076` |
| Packs | `23` |
| `downloadBytes` | `18634180032` (~18.63 GB) |
| `installedBytes` | `19052071696` (~19.05 GB) |
| `files` | `16433` |
| App version / offline version / code | `0.1.36` / `9.0.0-offline.36` / `9076` |
| APK size | `41295064` bytes |
| APK SHA-256 | `280cd1bc9abae9ecbc3fcb0ba5d1138dbc08511763166e2b120e2be0f41a42a7` |

Supporting observations:

| Path | Observation | Classification |
|---|---|---|
| `data-001` link | `v0.1.35`, `1215396487` bytes, SHA-256 `654f5c8ef2b7f1e5659ba04ff126e807aaa7acdd495c72736698da76d5fe97b7` | `UNVERIFIED` historical/direct link |
| `content-003` link | `v0.1.36`, `942665918` bytes, SHA-256 `a9afb35563310317cdc7cbc56b3998a279fafcb9cdf7e7dd03753fc3f395fb1f` | `UNVERIFIED` historical/direct link |
| `equipment-enhancement` | `r13`, `5523384` bytes | `COMMUNITY_RECOVERED` metadata |
| `update/latest.json` | Same `schema`/`revision`/`version`; points packs at `v0.1.35`, e.g. `client-assets` `103701960` bytes | `UNVERIFIED` mixed-tag reference |
| `release/app.json` | Repeats APK size and SHA-256 above | `UNVERIFIED` self-consistent metadata, independent provenance absent |

**No pack was downloaded**; all sizes and hashes are manifest observations only.

## 5. `release/notes-v0.1.36.md` claims

| Claim | Classification | Note |
|---|---|---|
| Repeat-cleared-stage Lapis award fixed | `COMMUNITY_MODIFIED` | Fan-project bug fix |
| Duplicate-unit-to-shard crash/data-loss fixed | `COMMUNITY_MODIFIED` | Fan-project bug fix |
| Ticket exchange refusal fixed | `COMMUNITY_MODIFIED` | Fan-project bug fix |
| Download completes before opening; fixes missing banners, connection errors, old Guard Mog menu, reduced unit limit after `v0.1.35` | `COMMUNITY_MODIFIED` | Client-flow adaptation |

## 6. Contract and endpoint evidence

| Path | Observation | Classification |
|---|---|---|
| `source/docs/analysis/FFBE_SERVER_CONTRACT.md` | `[FFBEWW]` `libgame.so` ARM64 v9.0.0 and APK dump; `[Community]` BraveHaxvius notes; status `INVENTORY`; request/response schemas partially recovered; target is single-player reconstruction, not commercial server deployment | `ORIGINAL_SOURCE` + `COMMUNITY_RECOVERED` |
| `source/docs/reference/tbmonkey_api_calls/` | Docs for endpoint discovery, boot-to-home, validated endpoints, arena/colosseum, support/friends, events/unlocks, gacha, towns/maps, missing CDN packs, response tag map | `COMMUNITY_RECOVERED` |
| Same directory `README` | Warns that response bodies are padded twice | `COMMUNITY_RECOVERED` parser caution |

## 7. Named JSON structures

| File | Observed structure / provenance | Classification |
|---|---|---|
| `banner_campaigns.json` | `_meta` states era grouping, class filter and art join are **OURS**, not recovered | `COMMUNITY_MODIFIED` |
| `event_archive.json` | `events[]` with `area`, `name`, `group`, `release`, `dungeons`, `missions`, `source_page`, plus `version`, `source_revision`, `source_sha256` | `COMMUNITY_RECOVERED` |
| `event_battles.json` | `provenance`, `global_counterparts`, `local_english_translations`, `policy`, `missions`; code reads `native_battle_support` / `resource_missions` | `COMMUNITY_RECOVERED` |
| `event_encounters.json` | Exists, but raw fetch exceeded the 20 MB cap; structure known only from `battle_content.py` `missions[]` with `bundle` and optional `clash_scale` | `UNVERIFIED` for contents; `COMMUNITY_RECOVERED` for structure |
| `event_banner_tree.json` | `roots[]` / `parents{}` with `area_id`, `dungeon_id`, `label`, `filename`, `release`, `season`, `source`, `order` | `COMMUNITY_RECOVERED` |
| `equipment_growth.json` | `editions[]` with `area_id`, `dungeon_id`, `missions`, `categories`, `release`, `offers.floors[].generic[]` | `COMMUNITY_RECOVERED` |
| `equipment_growth_bonus.json` | `baseline_season_schedules[]` keyed by 8-character tokens | `COMMUNITY_RECOVERED` |

## 8. Python behaviour observations

| File | Observation | Classification |
|---|---|---|
| `battle_content.py` | JP derivation chain; comments label community break data **NOT first-party** | `COMMUNITY_MODIFIED` |
| `ffbe_gacha.py` | Docstring: “the rates are ours” | `COMMUNITY_MODIFIED` |
| `exvius_events.py` | Persistent event selection policy using `DATE_START` / `DATE_END` and atomic save | `COMMUNITY_MODIFIED` |
| `exvius_rewards.py` | `parse(raw)` reads native reward tuples | `COMMUNITY_RECOVERED` |
| `exvius_raid_progress.py` | “Battle stats and personal milestone thresholds are unchanged”; shared HP budgets and target solo clears are locally authored pacing | `COMMUNITY_MODIFIED` |
| `exvius_arena.py` | Local rivals, neutral `1.00` ratio, lowest original ranking tier; original hidden tie-break unavailable | `COMMUNITY_MODIFIED` + `UNVERIFIED` for hidden behaviour |
| `exvius_colosseum.py` | Original rules: 100 points per win / 50 per loss; local Advanced rounds explicitly labelled | `ORIGINAL_SOURCE` + `COMMUNITY_MODIFIED` |
| `exvius_actions_expedition.py` | Original masters define requirements, durations and rewards; offline grade/XP/random policies authored where backends are unrecoverable | `ORIGINAL_SOURCE` + `COMMUNITY_MODIFIED` |
| `exvius_shop_catalogue.py` | Recovered shop stock, fragment exchanges and VIP stock cited to `exvius.fandom.com`, plus `content/permanent_shops.json` | `COMMUNITY_RECOVERED` |

## 9. Coverage matrix (Elvlin evidence only)

| Domain | Observed | Missing or blocked | Classification | Import decision |
|---|---|---|---|---|
| Unit/event metadata | Event archive, banner tree, equipment growth, reward tuples | No cross-verified final-era unit truth | `COMMUNITY_RECOVERED` | Reference only |
| Gacha / banners | `banner_campaigns.json` `_meta` OURS; `ffbe_gacha.py` rates ours | Exact original rates/guarantees unknown | `COMMUNITY_MODIFIED` / `UNVERIFIED` | Do not import as original |
| Encounters / battles | `event_battles.json` missions; `event_encounters.json` structure | Full encounter file >20 MB cap | `COMMUNITY_RECOVERED` / `UNVERIFIED` | Structure note only |
| Equipment growth | Editions and season schedules | Original backend validation absent | `COMMUNITY_RECOVERED` | Reference only |
| Shops | Recovered stock; Fandom-cited VIP stock | Original server truth unavailable | `COMMUNITY_RECOVERED` / `UNVERIFIED` | Reference only |
| Arena / colosseum / raid / expeditions | Original fragments plus labelled local policies | Hidden tie-break, shared pacing backends | `COMMUNITY_MODIFIED` | Do not import as original rules |
| Server contract | Partially recovered schemas and endpoint docs | `INVENTORY` status; not commercial server truth | `COMMUNITY_RECOVERED` | Contract reference only |
| APK / packs | Hashes and sizes in manifests | Original APK absent; no pack downloaded | `UNVERIFIED` | No acquisition, no execution |
| Visual assets | 82 PNG and manifest references in tree metadata | Binary blobs not fetched; no rights | `UNVERIFIED` | Not imported |

## 10. Known conflicts and access blockers

| ID | Issue | Classification | Consequence |
|---|---|---|---|
| ELV-01 | GitHub REST returned 403; raw/tree/Atom used | `UNVERIFIED` | API-derived claims are limited to observed paths |
| ELV-02 | Raw `LICENSE` 404; no repository licence | `UNVERIFIED` | Rights gate `not_passed` |
| ELV-03 | `event_encounters.json` raw fetch exceeded 20 MB cap | `UNVERIFIED` | No full-content assertion |
| ELV-04 | Expected original APK absent; signing keys absent | `ORIGINAL_SOURCE` reference only | Hash cannot be rechecked here |
| ELV-05 | `original`/`recovered`/`overlay` precedence and OURS metadata | `COMMUNITY_MODIFIED` | Never present overlay as recovered/original |
| ELV-06 | Historical/direct links mix `v0.1.35` and `v0.1.36` | `UNVERIFIED` | Do not infer a single coherent pack revision |
| ELV-07 | README caveats about replacements, mistakes and needed fixes | `COMMUNITY_MODIFIED` / `UNVERIFIED` | No claim of faithful/complete restoration |
| ELV-08 | No claim beyond observed 2026-11-25 | `UNVERIFIED` | Later validity not asserted |

## 11. Evidence classification counts

Counts are for classified **evidence groups in this audit**, not game records and not VERIFIED status.

| Classification | Count | Meaning here |
|---|---:|---|
| `ORIGINAL_SOURCE` | 4 | Original-client references, expected APK hash, original-rule/masters statements |
| `COMMUNITY_RECOVERED` | 9 | Recovered JSON layers, native tuples, partially recovered contract schemas |
| `COMMUNITY_MODIFIED` | 10 | OURS metadata, locally authored rates/pacing/rivals/rounds/policies, replacements |
| `UNVERIFIED` | 5 | Blocked contents, provenance, exact rates, caveats, post-observation validity |
| `SYNTHETIC_FIXTURE` | 0 | No Elvlin-provided synthetic fixture evidence in this audit |
| `REMASTERED_DESIGN` | 0 | No local remaster design decision is attributed to Elvlin |

Phase 0 remains **0 VERIFIED**. Nothing in this audit changes that count.

## 12. Not imported

No Elvlin APK, pack, JSON payload, Python file, image or derived table has been copied into `game/`, `data/normalized/`, or any distributable build. This document and its companion manifest are audit records only. The project continues to use `SYNTHETIC_FIXTURE` data for the Godot foundation and combat slice; any future import requires a separate rights-reviewed batch with exact revision, checksum, region, category coverage and a report that preserves the original/recovered/overlay distinction.
