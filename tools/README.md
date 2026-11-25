# Audit tooling

Python 3 standard library only. Run from the repository root. Every tool writes deterministic JSON/CSV with sorted keys; no timestamps are embedded.

## 1. Inventory sources

```bash
# Source A: exact Git tree metadata from GitHub tree API, plus materialized text/sample files
python3 tools/inventory/inventory_sources.py \
  --root /path/to/materialized/source-a \
  --git-tree /path/to/a-tree-inventory.txt \
  --metadata /path/to/a-github.json \
  --audit-meta /path/to/a-audit-meta.json \
  --category-map tools/inventory/category-map.json \
  --revision f82d603c90ec799f539280267d3af7589c79f117 \
  --max-hash-bytes 30000000 \
  --inventory-out data/manifests/source-a-inventory.json \
  --manifest data/manifests/source-manifest.json \
  --manifest-csv data/manifests/source-manifest.csv

# Source B: small repository, full worktree hashed
python3 tools/inventory/inventory_sources.py \
  --root /path/to/source-b \
  --git-tree /path/to/b-tree-inventory.txt \
  --metadata /path/to/b-github.json \
  --audit-meta /path/to/b-audit-meta.json \
  --category-map tools/inventory/category-map.json \
  --revision ce7d98a6499bb8c2f6656f0698f60c30001a05b0 \
  --hash-all \
  --inventory-out data/manifests/source-b-inventory.json \
  --manifest data/manifests/source-manifest.json \
  --manifest-csv data/manifests/source-manifest.csv
```

`--git-tree` accepts `git ls-tree -r -l HEAD` output. `--include-tree-files` emits a per-file row for all tree entries (large); by default only materialized worktree files get per-file rows while tree metadata is aggregated.

## 2. Extract catalog asset references

```bash
python3 tools/inventory/extract_asset_refs.py \
  --source-id DaddyRaegen/ffbe_asset_dump \
  --input /path/to/catalog/units.json ... \
  --field sprite_sheet --field 'assets.asset_files[]' ... \
  --output /path/to/catalog-asset-refs.json
```

## 3. Structured data validation

Adapters live in `tools/validate/adapters/`. Each JSON spec declares paths, ID fields, required fields and reference paths per region; no layout is hardcoded in code.

```bash
python3 tools/validate/extract_identity_collisions.py \
  --unit-master /path/to/catalog/unit_master.json \
  --source-id DaddyRaegen/ffbe_asset_dump \
  --revision f82d603c90ec799f539280267d3af7589c79f117 \
  --report-path reports/2026-10-02-unit-series/CONFLICTS.md \
  --output /path/to/a-identity-collisions.json

python3 tools/validate/validate_data.py \
  --spec tools/validate/adapters/ffbe_data.spec.json \
  --spec tools/validate/adapters/ffbe_asset_catalog.spec.json \
  --root GL=/path/to/source-b --root JP=/path/to/source-b \
  --root SHARED=/path/to/materialized/source-a \
  --revision DanUgore/ffbe_data=ce7d98a6499bb8c2f6656f0698f60c30001a05b0 \
  --revision DaddyRaegen/ffbe_asset_dump=f82d603c90ec799f539280267d3af7589c79f117 \
  --extra-collisions /path/to/a-identity-collisions.json \
  --coverage-out data/validation/data-coverage.json \
  --csv-out data/validation/data-coverage.csv \
  --collisions-out data/validation/id-collisions.json \
  --refs-out data/validation/missing-references.json
```

## 4. Asset validation

```bash
python3 tools/validate/validate_assets.py \
  --inventory /path/to/a-inventory-full.json \
  --inventory data/manifests/source-b-inventory.json \
  --references /path/to/catalog-asset-refs.json \
  --coverage-out data/validation/asset-coverage.json \
  --integrity-out data/validation/asset-integrity.json \
  --missing-out data/validation/missing-assets.json
```

Image headers are read only from files present in the materialized worktree. Binary source files are never converted.

## 5. Human-readable reports

```bash
python3 tools/reports/build_reports.py \
  --manifest data/manifests/source-manifest.json \
  --coverage data/validation/data-coverage.json \
  --collisions data/validation/id-collisions.json \
  --missing-refs data/validation/missing-references.json \
  --asset-coverage data/validation/asset-coverage.json \
  --asset-integrity data/validation/asset-integrity.json \
  --missing-assets data/validation/missing-assets.json \
  --out-dir docs/audit
```

## Tests

```bash
python3 -m unittest discover -s tests -v
```

Tests use only synthetic fixtures in `tests/data` and `tests/assets`.
