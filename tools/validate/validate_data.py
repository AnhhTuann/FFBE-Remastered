#!/usr/bin/env python3
"""Count, validate and cross-reference structured records from audited sources.

Source layouts are described by JSON specs under ``tools/validate/adapters``.
Nothing about file names, IDs or required fields is hardcoded here. Records are
never promoted to VERIFIED merely because they parse; an explicit evidence file
is required for that status.

Example:
  python3 tools/validate/validate_data.py \
    --spec tools/validate/adapters/ffbe_data.spec.json \
    --spec tools/validate/adapters/ffbe_asset_catalog.spec.json \
    --root GL=/path/to/source-b --root JP=/path/to/source-b \
    --root SHARED=/path/to/source-a \
    --revision DanUgore/ffbe_data=ce7d98a... \
    --coverage-out data/validation/data-coverage.json \
    --csv-out data/validation/data-coverage.csv \
    --collisions-out data/validation/id-collisions.json \
    --refs-out data/validation/missing-references.json
"""

from __future__ import annotations

import argparse
import collections
import json
import logging
import os
import re
import sys
from typing import Any, Iterable

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from audit_utils import (  # noqa: E402
    STATUSES, composite_id, get_path, iter_path_values, iter_records, load_json,
    write_csv, write_json,
)

TOOL_VERSION = "1.0.0"
LOG = logging.getLogger("validate-data")


def parse_pairs(values: list[str], label: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for value in values:
        if "=" not in value:
            raise ValueError(f"{label} must be KEY=VALUE, got {value!r}")
        key, item = value.split("=", 1)
        result[key] = item
    return result


def normalize_text(value: Any) -> str:
    if not isinstance(value, str):
        return ""
    return re.sub(r"\s+", " ", value).strip().casefold()


def strict_name(value: Any) -> str:
    """Case/punctuation-insensitive label used to detect formatting-only variants."""
    return re.sub(r"[^0-9a-z\u3040-\u30ff\u4e00-\u9fff]+", "", normalize_text(value))


def reference_ids(value: Any) -> list[str]:
    """Extract IDs from a scalar, list, or dict-valued reference."""
    if isinstance(value, dict):
        for key in ("id", "value", "name"):
            if key in value and not isinstance(value[key], (dict, list)):
                return [str(value[key])]
        return []
    if isinstance(value, (list, tuple)):
        result: list[str] = []
        for item in value:
            result.extend(reference_ids(item))
        return result
    if value is None or isinstance(value, bool):
        return []
    return [str(value)]


class Auditor:
    def __init__(self, specs: list[dict[str, Any]], roots: dict[str, str],
                 revisions: dict[str, str], verified: set[str], max_examples: int) -> None:
        self.specs = specs
        self.roots = roots
        self.revisions = revisions
        self.verified = verified
        self.max_examples = max_examples
        self.records: dict[str, dict[str, dict[str, Any]]] = {}  # key -> identity -> record
        self.datasets: dict[str, dict[str, Any]] = {}
        self.coverage: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
        self.collisions: list[dict[str, Any]] = []
        self.missing_refs: list[dict[str, Any]] = []

    def run(self) -> None:
        for spec in self.specs:
            source_id = spec.get("source_id", "unknown_source")
            for dataset in spec.get("datasets", []):
                key = str(dataset.get("key"))
                self.datasets[key] = dataset
                for region, root in sorted(self.roots.items()):
                    paths = dataset.get("paths", {})
                    if isinstance(paths, dict):
                        relpath = paths.get(region)
                    else:
                        relpath = str(paths) if region in ("GL", "JP") else None
                    self._audit_dataset(source_id, dataset, region, root, relpath)
        self._detect_collisions()
        self._check_references()

    def _audit_dataset(self, source_id: str, dataset: dict[str, Any], region: str,
                       root: str, relpath: str | None) -> None:
        allowed_regions = dataset.get("regions")
        if allowed_regions and region not in allowed_regions:
            return
        summary: dict[str, Any] = {
            "source_id": source_id,
            "source_revision": self.revisions.get(source_id, "UNRECORDED"),
            "region": region,
            "key": dataset.get("key"),
            "category": dataset.get("category", dataset.get("key")),
            "label": dataset.get("label", dataset.get("key")),
            "path": relpath,
            "total_records": 0,
            "valid_records": 0,
            "invalid_records": 0,
            "duplicate_records": 0,
            "partial_records": 0,
            "unverified_records": 0,
            "unavailable_records": 0,
            "status_counts": {status: 0 for status in STATUSES},
            "missing_required_fields": {},
            "parse_errors": [],
            "examples": [],
        }
        if not relpath:
            summary["status_counts"]["UNAVAILABLE"] = 1
            summary["unavailable_records"] = 1
            self.coverage[region].append(summary)
            return

        absolute = os.path.join(root, relpath)
        data, error = load_json(absolute)
        if error:
            summary["parse_errors"].append(error)
            summary["status_counts"]["UNVERIFIED"] = 1
            summary["unverified_records"] = 1
            self.coverage[region].append(summary)
            LOG.error("Parse error in %s: %s", absolute, error)
            return

        record_path = str(dataset.get("record_path", ""))
        if record_path:
            data = get_path(data, record_path)
            if not isinstance(data, (dict, list)):
                summary["parse_errors"].append(f"record_path {record_path} is not a JSON object/list")
                summary["status_counts"]["UNVERIFIED"] = 1
                summary["unverified_records"] = 1
                self.coverage[region].append(summary)
                return
        id_field = str(dataset.get("id_field", "id"))
        required = [str(field) for field in dataset.get("required_fields", [])]
        name_field = str(dataset.get("name_field", "name"))
        kind = str(dataset.get("entity_type", dataset.get("key")))
        seen: dict[str, dict[str, Any]] = {}
        bucket = self.records.setdefault(str(dataset.get("key")), {})

        for native_id, record in iter_records(data, id_field):
            summary["total_records"] += 1
            missing = [field for field in required
                       if not (dataset.get("id_from_key") and field == id_field)
                       and (field not in record or record[field] in (None, "", [], {}))]
            identity = composite_id(kind, region, native_id)
            if missing:
                status = "PARTIAL"
                summary["partial_records"] += 1
                for field in missing:
                    counter = summary["missing_required_fields"].setdefault(field, 0)
                    summary["missing_required_fields"][field] = counter + 1
            elif identity in seen or identity in bucket:
                status = "PARTIAL"
                summary["duplicate_records"] += 1
            elif identity in self.verified:
                status = "VERIFIED"
            else:
                status = "RECOVERED"

            if native_id is None:
                status = "UNVERIFIED"
                summary["unverified_records"] += 1
            name = record.get(name_field, "")
            stored = {
                "identity": identity,
                "native_id": native_id,
                "region": region,
                "source_id": source_id,
                "source_revision": self.revisions.get(source_id, "UNRECORDED"),
                "source_path": relpath,
                "name": name if isinstance(name, str) else str(name),
                "status": status,
                "record": record,
                "missing_required_fields": missing,
            }
            if status in ("RECOVERED", "VERIFIED"):
                summary["valid_records"] += 1
            summary["status_counts"][status] += 1
            if len(summary["examples"]) < self.max_examples:
                summary["examples"].append({
                    "identity": identity, "name": stored["name"], "status": status,
                })
            if identity not in seen:
                seen[identity] = stored
            if identity not in bucket:
                bucket[identity] = stored
        self.coverage[region].append(summary)
        LOG.info("%s/%s %s: %d records", source_id, region, relpath, summary["total_records"])

    def _detect_collisions(self) -> None:
        # Same composite identity across two source files with different names.
        for key, bucket in sorted(self.records.items()):
            by_identity: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
            for record in bucket.values():
                by_identity[record["identity"]].append(record)
            for identity, entries in sorted(by_identity.items()):
                if len(entries) < 2:
                    continue
                names = {strict_name(entry["name"]) for entry in entries}
                if len(names) < 2:
                    continue
                self.collisions.append({
                    "type": "conflicting_records_between_sources",
                    "entity_type": key,
                    "identity": identity,
                    "names": [entry["name"] for entry in entries],
                    "evidence": [{
                        "source_id": entry["source_id"],
                        "revision": entry["source_revision"],
                        "path": entry["source_path"],
                        "native_id": entry["native_id"],
                    } for entry in entries],
                    "action": "kept_separate",
                })

        # Same native ID in GL and JP with different names.
        for key, bucket in sorted(self.records.items()):
            by_native: dict[str, dict[str, list[dict[str, Any]]]] = collections.defaultdict(lambda: collections.defaultdict(list))
            for record in bucket.values():
                if record["native_id"] is not None:
                    by_native[record["native_id"]][record["region"]].append(record)
            for native_id, regions in sorted(by_native.items()):
                if "GL" not in regions or "JP" not in regions:
                    continue
                gl_names = {normalize_text(item["name"]) for item in regions["GL"]}
                jp_names = {normalize_text(item["name"]) for item in regions["JP"]}
                gl_strict = {strict_name(item["name"]) for item in regions["GL"]}
                jp_strict = {strict_name(item["name"]) for item in regions["JP"]}
                if not (gl_names & jp_names):
                    label_variant = bool(gl_strict & jp_strict)
                    self.collisions.append({
                        "type": ("same_native_id_label_variant" if label_variant
                                 else "same_native_id_different_regional_names"),
                        "entity_type": key,
                        "native_id": native_id,
                        "identities": [item["identity"] for region in ("GL", "JP") for item in regions[region]],
                        "gl_names": sorted({item["name"] for item in regions["GL"]}),
                        "jp_names": sorted({item["name"] for item in regions["JP"]}),
                        "evidence": [{
                            "source_id": item["source_id"],
                            "revision": item["source_revision"],
                            "path": item["source_path"],
                            "identity": item["identity"],
                        } for region in ("GL", "JP") for item in regions[region]],
                        "action": "kept_separate",
                    })

        # Different IDs, same normalized name: candidates only, never merged.
        for key, bucket in sorted(self.records.items()):
            by_name: dict[str, dict[str, set[str]]] = collections.defaultdict(lambda: collections.defaultdict(set))
            for record in bucket.values():
                name = normalize_text(record["name"])
                if name and record["native_id"] is not None:
                    by_name[name][record["region"]].add(record["native_id"])
            for name, regions in sorted(by_name.items()):
                if len(regions.get("GL", set()) | regions.get("JP", set())) < 2:
                    continue
                examples = [record for record in bucket.values()
                            if normalize_text(record["name"]) == name][:self.max_examples]
                self.collisions.append({
                    "type": "different_ids_same_name_candidate",
                    "entity_type": key,
                    "normalized_name": name,
                    "native_ids": {region: sorted(ids) for region, ids in regions.items()},
                    "evidence": [{
                        "source_id": item["source_id"],
                        "revision": item["source_revision"],
                        "path": item["source_path"],
                        "identity": item["identity"],
                        "name": item["name"],
                    } for item in examples],
                    "action": "review_required",
                })

    def _check_references(self) -> None:
        for spec in self.specs:
            for ref in spec.get("references", []):
                from_key = str(ref.get("from"))
                to_key = str(ref.get("to"))
                field = str(ref.get("field"))
                targets = self.records.get(to_key, {})
                target_ids = {item["native_id"] for item in targets.values() if item["native_id"] is not None}
                if not target_ids:
                    continue
                for record in self.records.get(from_key, {}).values():
                    values: Iterable[Any] = iter_path_values(record["record"], field)
                    seen: set[str] = set()
                    for value in values:
                        for reference in reference_ids(value):
                            if reference in seen:
                                continue
                            seen.add(reference)
                            if reference not in target_ids:
                                self.missing_refs.append({
                                    "type": "unresolved_record_reference",
                                    "region": record["region"],
                                    "from_identity": record["identity"],
                                    "from_category": from_key,
                                    "to_category": to_key,
                                    "field": field,
                                    "missing_id": reference,
                                    "evidence": {
                                        "source_id": record["source_id"],
                                        "revision": record["source_revision"],
                                        "path": record["source_path"],
                                    },
                                })

    def output(self) -> dict[str, Any]:
        rows: list[dict[str, Any]] = []
        for region, summaries in sorted(self.coverage.items()):
            for summary in summaries:
                flat = {key: value for key, value in summary.items()
                        if key not in ("status_counts", "missing_required_fields", "parse_errors", "examples")}
                for status in STATUSES:
                    flat[f"status_{status}"] = summary["status_counts"][status]
                flat["missing_required_field_names"] = ",".join(sorted(summary["missing_required_fields"]))
                flat["parse_error_count"] = len(summary["parse_errors"])
                rows.append(flat)
        return {
            "tool": "validate_data.py",
            "tool_version": TOOL_VERSION,
            "source_revisions": dict(sorted(self.revisions.items())),
            "classification_policy": {
                "RECOVERED": "Parsed record with all required fields; not cross-verified.",
                "PARTIAL": "Missing required fields, duplicate identity, or unusable ID.",
                "UNVERIFIED": "Parse error or missing identity.",
                "UNAVAILABLE": "No source file exists for the region/category.",
                "VERIFIED": "Only assigned when the explicit verified-evidence file matched the composite identity.",
            },
            "regions": {region: sorted(summaries, key=lambda item: str(item["key"]))
                        for region, summaries in sorted(self.coverage.items())},
            "rows": rows,
            "collision_count": len(self.collisions),
            "missing_reference_count": len(self.missing_refs),
        }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--spec", action="append", required=True, help="Adapter spec JSON (repeatable)")
    parser.add_argument("--root", action="append", required=True, help="REGION=PATH (repeatable)")
    parser.add_argument("--revision", action="append", default=[], help="source_id=SHA (repeatable)")
    parser.add_argument("--verified-evidence", help="JSON list of composite IDs independently verified")
    parser.add_argument("--extra-collisions", help="JSON with pre-extracted collision evidence to append")
    parser.add_argument("--coverage-out", required=True)
    parser.add_argument("--csv-out", required=True)
    parser.add_argument("--collisions-out", required=True)
    parser.add_argument("--refs-out", required=True)
    parser.add_argument("--max-examples", type=int, default=10)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO,
                        format="%(levelname)s %(name)s: %(message)s")
    try:
        roots = parse_pairs(args.root, "--root")
        revisions = parse_pairs(args.revision, "--revision")
    except ValueError as exc:
        parser.error(str(exc))

    specs: list[dict[str, Any]] = []
    for path in args.spec:
        data, error = load_json(path)
        if error or not isinstance(data, dict):
            parser.error(f"Could not load spec {path}: {error}")
        specs.append(data)

    verified: set[str] = set()
    if args.verified_evidence:
        data, error = load_json(args.verified_evidence)
        if error or not isinstance(data, list):
            parser.error(f"Could not load verified evidence: {error}")
        verified = {str(item) for item in data}

    auditor = Auditor(specs, roots, revisions, verified, args.max_examples)
    auditor.run()
    if args.extra_collisions:
        extra, error = load_json(args.extra_collisions)
        if error:
            parser.error(f"Could not load extra collisions: {error}")
        entries = extra.get("collisions", []) if isinstance(extra, dict) else extra
        if not isinstance(entries, list):
            parser.error("Extra collisions must be a list or an object with a 'collisions' list")
        auditor.collisions.extend(entries)
    report = auditor.output()
    write_json(args.coverage_out, report)
    columns = [
        "source_id", "source_revision", "region", "key", "category", "label", "path",
        "total_records", "valid_records", "invalid_records", "duplicate_records",
        "partial_records", "unverified_records", "unavailable_records",
        "status_VERIFIED", "status_RECOVERED", "status_PARTIAL", "status_UNVERIFIED",
        "status_UNAVAILABLE", "missing_required_field_names", "parse_error_count",
    ]
    write_csv(args.csv_out, report["rows"], columns)
    write_json(args.collisions_out, {
        "tool": "validate_data.py", "tool_version": TOOL_VERSION,
        "total_collisions": len(auditor.collisions), "collisions": auditor.collisions,
    })
    write_json(args.refs_out, {
        "tool": "validate_data.py", "tool_version": TOOL_VERSION,
        "total_missing_references": len(auditor.missing_refs),
        "missing_references": auditor.missing_refs,
    })
    LOG.info("Coverage report: %d categories; %d collisions; %d missing references",
             len(report["rows"]), len(auditor.collisions), len(auditor.missing_refs))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
