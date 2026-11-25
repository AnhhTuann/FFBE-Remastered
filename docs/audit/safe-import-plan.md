# Safe import plan — Phase 0 findings

**Status:** recommendation only. No gameplay import is performed in this phase.

This plan is derived from the exact revisions recorded in `source-manifest.json`:

- `DaddyRaegen/ffbe_asset_dump` @ `f82d603c90ec799f539280267d3af7589c79f117` (148,131 files; 3,596,307,289 bytes from GitHub tree metadata).
- `DanUgore/ffbe_data` @ `ce7d98a6499bb8c2f6656f0698f60c30001a05b0` (37 files; 77,884,391 bytes).

No record is VERIFIED solely because it parsed. The current classification counts are:

| Region | Records | RECOVERED | PARTIAL | VERIFIED | UNAVAILABLE categories |
|---|---:|---:|---:|---:|---:|
| GL | 3,018 | 3,018 | 0 | 0 | 3 (boards, missions, quests) |
| JP | 21,005 | 20,995 | 10 | 0 | 0 |
| SHARED catalogs | 11,905 | 11,883 | 22 | 0 | 0 |

## Legal and rights gate — blocking

Neither repository declares a license. The asset dump contains third-party FFBE artwork; the structured dump contains extracted game text and metadata. Public visibility is not redistribution permission.

**Rule:** nothing in `docs/audit/`, `data/validation/`, or `data/manifests/` grants the right to ship original content. Before any runtime import:

1. Determine which specific data fields and images are needed for a non-public development build.
2. Obtain rights review or use original/licensed replacements for distribution.
3. Keep third-party files outside the public repository. Only manifests, checksums and derived metadata are committed here.
4. Record the decision per content batch, with source revision and legal status.

This gate blocks public distribution, not local research on already-available files.

## Priority 1 — region identity and schema (no game content)

1. Adopt composite identities `kind:GL:<id>` / `kind:JP:<id>` in every future data interface. Never use a native numeric ID as a primary key on its own.
2. Import the 11 source-documented GL/JP unit form collisions as explicit separate identities. Evidence is in `data/validation/id-collisions.json` (`same_native_id_different_regional_names`, entity `unit`) and upstream report `reports/2026-10-02-unit-series/CONFLICTS.md` in Source A.
3. Preserve the 21 unresolved asset-only forms with `series: null`; do not invent a region, base ID, rarity or acquisition type.
4. Build a small region-resolution test set before importing any runtime records.

Exit gate: a lookup by composite ID resolves the correct region and no numeric-only lookup is used in new code.

## Priority 2 — structured data batches (recovered, not verified)

Import in this order, each batch with validation rerun:

1. **Units and forms** — GL 269, JP 1,115 records. Keep the 10 JP Limit Burst records missing `levels` as PARTIAL; do not fabricate level data.
2. **Abilities, magic, Limit Bursts, monster skills** — GL 451/80/293/579; JP 6,062/210/1,116/4,452. Damage modifiers, elements, effects and targeting exist as raw fields but combat formulas are not validated in this phase.
3. **Items, equipment, materia, recipes** — GL 247/261/154/252; JP 606/934/500/456. Treat the 651 unresolved recipe references in `missing-references.json` (617 `crafts.id`, 34 `materials[].id`) as unresolved against `item.json` only; they may point into another category.
4. **Enemy AI, beasts, boards, quests/missions** — GL AI 309 and beasts 6; JP AI 1,461, beasts 16, boards 16, quests 74, missions 3,440. No GL boards/missions/quests source file exists in the inspected revision.
5. **Learnsets and enhancements** — GL learnsets 110; JP learnsets 372, enhancements 151. GL `enhance.json` is present but empty (0 records).

Exit gate: per-batch coverage, collision and reference reports are regenerated from the pinned revisions; no silent region overwrite occurs.

## Priority 3 — asset batches (respect source boundaries)

Source assets are inventoried by category, but only 161 files were hashed in this phase because binary blobs were not bulk-downloaded. Before importing any image:

1. Fetch only the specific paths named in a catalog entry, preserving native files and filenames.
2. Compute SHA-256 and byte length on arrival; compare with the catalog/source manifest where available.
3. Keep GL and JP bundles separate. Use `regional_units/gl/...` and `regional_units/jp/...` for the 22 collision identities; never fill a GL form from a JP bundle.
4. Pair each animation sequence (`*_cgs_*.csv`) with its own frame table (`*_cgg_*.csv`) and texture page. Upstream reports identify 11 source-invalid sequences and 259 texture-rectangle warnings; keep them excluded from active animations, not silently repaired.
5. Do not apply lossy conversion to pixel art. Any runtime derivative must be reproducible from the retained original.

Exit gate: every imported asset resolves to a catalog path, a source revision and a SHA-256; unresolved or clipping-warning assets stay excluded and reported.

## Priority 4 — content that remains unavailable or unverified

Do not import or invent:

- Audio, video, master data and general story text: inventoried upstream as out of scope for the visual-asset recovery, not present in the inspected public tree.
- 128,905 optional `additional/` destinations (~15.19 GB upstream estimate): not imported into Source A; not present here.
- Original CPK/DAT sources referenced by upstream SHA-256 paths: provenance only, not publicly accessible in the inspected repositories.
- Current-game coverage beyond the 2018 Source B snapshot or the October 2026 Source A snapshot.
- 126 untranslated JP unit names reported upstream: retain native names unless a verified localization source is added.
- Any VERIFIED status: no independent cross-source verification was performed in this phase.

## Validation commands

See `tools/README.md`. Repeat the full pipeline from the pinned revisions before any import; reports must be byte-stable apart from explicitly changed inputs.

## Deferred until after this milestone

Godot project creation, data interfaces, asset viewer, battle engine, summon mechanics, world map, quests/story gameplay, and any public distribution build are explicitly out of scope here.
