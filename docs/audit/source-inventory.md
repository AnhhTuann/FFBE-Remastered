# Source inventory

Generated from `data/manifests/source-manifest.json`. Values are taken from the inspected repositories and their recorded revisions; no metadata is inferred.

| Source | Repository | Region | Inspected branch | Commit | Commit date | License | Files | Size (bytes) |
|---|---|---|---|---|---|---|---|---|
| DaddyRaegen/ffbe_asset_dump | https://github.com/DaddyRaegen/ffbe_asset_dump | GL + JP + shared assets; GL/JP split only for 11 conflicting unit form IDs | main | f82d603c90ec799f539280267d3af7589c79f117 | 2026-10-10T01:43:51Z | No LICENSE file at repository root; GitHub API license=null | 148131 | 3596307289 |
| DanUgore/ffbe_data | https://github.com/DanUgore/ffbe_data | GL and JP directories present; README describes the project as JP data | master | ce7d98a6499bb8c2f6656f0698f60c30001a05b0 | 2018-02-09T05:14:32Z | No LICENSE file; GitHub API license=null | 37 | 77884391 |

## Restrictions and limitations

### DaddyRaegen/ffbe_asset_dump

- Source type: public visual-asset dump with catalogs and upstream validation reports
- Redistribution: No redistribution permission found. Contains third-party FFBE visual assets; public availability is not a license.
- Confirmed confidence: MEDIUM: file inventory is exact from Git tree API; identity/source claims are upstream assertions not independently reproduced
- Provenance: Inspected through authenticated GitHub REST metadata, a blobless Git clone, exact Git tree listing via the GitHub tree API, and targeted materialization of text catalogs/reports plus a small asset sample. No original CPK/DAT source was accessed.
- Last update: HEAD commit 2026-10-10T01:43:51Z 'Merge pull request #3 from DaddyRaegen/complete-unit-bundles'; lastUpdated.json=10/09/2026; repository pushed_at=2026-10-13T03:10:07Z
- Categories: unit catalogs, region-aware unit identities, monster catalog, vision card catalog, animation CSV frame data, frame metadata, unit sprites, monster sprites, vision card art, backgrounds, UI effects, equipment/item/ability/materia art, upstream audit reports
- Missing/inaccessible: Original CPK archive contents are not public in this repository; Audio, video, master data and general story text were inventoried upstream but not imported; 128,905 optional additional/ destinations (~15.19 GB upstream estimate) were not imported; Local DAT/CPK source paths are provenance only and were not accessible to this audit
- Recorded branches:

| Branch | Commit |
|---|---|
| main | f82d603c90ec799f539280267d3af7589c79f117 |
| beta | 45b111dac51f7cd7ad1485248b299cdbe970d222 |
| complete-unit-bundles | 9e722f151df0a1ba7cc36772eb0eb62af4f71044 |
| memorial-edition-source | 51b547c4e191d90c84f62d62542ec706a143a106 |
| recover-gl-jp-assets | 1d7d37742a16bbbfe9e9f865f43838b0e548d3eb |

- Limitations:
  - 148,131 files / 3,596,307,289 uncompressed bytes measured from GitHub tree API at exact HEAD; GitHub API reports repository size 3,080,682 KB
  - Blobless inspection: binary files were not bulk-downloaded; SHA-256 is recorded only for deliberately materialized text catalogs and a small asset sample
  - Upstream reports document 11 GL/JP unit form ID collisions, 21 unresolved asset-only forms, 126 untranslated JP names, 11 source-invalid animation sequences and 259 texture-rectangle warnings
  - Upstream coverage counts are source-provided evidence and are not promoted to VERIFIED without independent cross-checking
  - No gameplay implementation or asset import is performed in this phase

### DanUgore/ffbe_data

- Source type: public extracted structured JSON datasets
- Redistribution: No redistribution permission found. Extracted game data may contain protected text and metadata.
- Confirmed confidence: HIGH for structure and record counts at the exact checked-out revision; LOW for present-day game coverage because the last data update is from 2018
- Provenance: Inspected through authenticated GitHub REST metadata and a full clone at the exact checked-out revision. No original game access was used.
- Last update: HEAD commit 2018-02-09T05:14:32Z 'JP Data Update'; repository pushed_at=2018-02-09T05:15:17Z
- Categories: units, abilities, magic, limit bursts, items, equipment, materia, recipes, learnsets, monster skills, enemy AI, esper beasts and boards, quests, missions, colosseum rewards
- Missing/inaccessible: No visual assets; No vision cards; GL enhance.json is an empty object; GL missions/boards and JP counterpart gaps are recorded per dataset in data-coverage.json; Source extraction method and original game revision are not documented in the repository
- Recorded branches:

| Branch | Commit |
|---|---|
| master | ce7d98a6499bb8c2f6656f0698f60c30001a05b0 |
| gh-pages | 874d08b70a118b57ab6e00a03071adfd5d615980 |

- Limitations:
  - 37 JSON/text files / 77,884,391 bytes measured from the exact checked-out tree
  - Datasets are a historical snapshot; absence does not prove that content never existed
  - Name fields in JP are largely native-language text
  - No original game access was used and no access controls were bypassed
