#!/usr/bin/env python3
"""Build human-readable Markdown summaries from machine-readable audit reports."""

from __future__ import annotations

import argparse
import collections
import logging
import os
import sys
from typing import Any

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from audit_utils import load_json  # noqa: E402

TOOL_VERSION = "1.0.0"
LOG = logging.getLogger("build-reports")


def read(path: str, parser: argparse.ArgumentParser, label: str) -> Any:
    data, error = load_json(path)
    if error:
        parser.error(f"Could not read {label} {path}: {error}")
    return data


def table(headers: list[str], rows: list[list[Any]]) -> str:
    lines = ["| " + " | ".join(headers) + " |", "|" + "|".join(["---"] * len(headers)) + "|"]
    for row in rows:
        cells = [str(cell).replace("|", "\\|").replace("\n", " ") for cell in row]
        lines.append("| " + " | ".join(cells) + " |")
    return "\n".join(lines)


def build_inventory_markdown(manifest: dict[str, Any]) -> str:
    sources = manifest.get("sources", [])
    parts = [
        "# Source inventory",
        "",
        "Generated from `data/manifests/source-manifest.json`. Values are taken from "
        "the inspected repositories and their recorded revisions; no metadata is inferred.",
        "",
        table(
            ["Source", "Repository", "Region", "Inspected branch", "Commit", "Commit date", "License", "Files", "Size (bytes)"],
            [[s.get("source_id", ""), s.get("repository_url", ""), s.get("region_coverage", ""),
              s.get("current_branch", ""), s.get("commit_sha", ""), s.get("commit_date", ""),
              s.get("license", ""), s.get("file_count", ""), s.get("total_size_bytes", "")]
             for s in sources],
        ),
        "",
        "## Restrictions and limitations",
        "",
    ]
    for source in sources:
        parts.extend([
            f"### {source.get('source_id', 'unnamed source')}",
            "",
            f"- Source type: {source.get('source_type', 'UNVERIFIED')}",
            f"- Redistribution: {source.get('redistribution_restrictions', 'UNVERIFIED')}",
            f"- Confirmed confidence: {source.get('confidence', 'UNVERIFIED')}",
            f"- Provenance: {source.get('provenance', 'UNVERIFIED')}",
            f"- Last update: {source.get('last_update', 'UNVERIFIED')}",
            f"- Categories: {', '.join(map(str, source.get('available_data_categories', []))) or 'none recorded'}",
            f"- Missing/inaccessible: {'; '.join(map(str, source.get('missing_or_inaccessible', []))) or 'none recorded'}",
            "- Recorded branches:",
            "",
        ])
        branches = source.get("branches", [])
        if isinstance(branches, list) and branches:
            parts.append(table(
                ["Branch", "Commit"],
                [[item.get("branch", ""), item.get("commit_sha", "")] for item in branches if isinstance(item, dict)],
            ))
        else:
            parts.append("- No branch inventory recorded")
        parts.extend(["", "- Limitations:"])
        parts.extend(f"  - {item}" for item in source.get("limitations", []))
        parts.append("")
    return "\n".join(parts).rstrip() + "\n"


def build_audit_markdown(args: argparse.Namespace, manifest: dict[str, Any], coverage: dict[str, Any],
                         collisions: dict[str, Any], missing_refs: dict[str, Any],
                         asset_coverage: dict[str, Any], asset_integrity: dict[str, Any],
                         missing_assets: dict[str, Any]) -> str:
    parts: list[str] = [
        "# Phase 0 — Full data and asset audit",
        "",
        "This report is generated from the machine-readable files in `data/validation/`. "
        "It describes only sources that were actually inspected. A parsed record is "
        "classified RECOVERED, never VERIFIED, unless independently cross-checked.",
        "",
        "## 1. Source revisions",
        "",
        table(["Source", "Revision", "Region coverage", "Files inventoried", "Bytes inventoried"],
              [[s.get("source_id", ""), s.get("commit_sha", ""), s.get("region_coverage", ""),
                s.get("file_count", ""), s.get("total_size_bytes", "")]
               for s in manifest.get("sources", [])]),
        "",
        "## 2. Global structured-data coverage",
        "",
    ]
    columns = ["Source", "Category", "Path", "Total", "Valid", "Partial", "Dupes", "Unverified", "Unavailable"]
    for region, heading in (("GL", "Global"), ("JP", "Japan"),
                            ("SHARED", "Shared / region-neutral catalogs")):
        rows = []
        for summary in coverage.get("regions", {}).get(region, []):
            rows.append([
                summary.get("source_id", ""), summary.get("label", summary.get("key", "")),
                summary.get("path") or "(none)", summary.get("total_records", 0),
                summary.get("valid_records", 0), summary.get("partial_records", 0),
                summary.get("duplicate_records", 0), summary.get("unverified_records", 0),
                summary.get("unavailable_records", 0),
            ])
        parts.extend([f"### {heading}", "", table(columns, rows) if rows else "No categories were audited.", ""])

    statuses = collections.Counter()
    for summaries in coverage.get("regions", {}).values():
        for summary in summaries:
            for status, count in summary.get("status_counts", {}).items():
                statuses[status] += count
    parts.extend([
        "## 3. Verification status totals",
        "",
        table(["Status", "Records / category rows"], [[key, value] for key, value in sorted(statuses.items())]),
        "",
        "VERIFIED requires independent evidence, not successful parsing only. Status counts are "
        "computed per row; a category-level UNAVAILABLE row represents a whole absent source file.",
        "",
        "## 4. Cross-region collisions",
        "",
        f"Total collision candidates: **{collisions.get('total_collisions', 0)}**.",
        "",
    ])
    by_type = collections.Counter(item.get("type", "") for item in collisions.get("collisions", []))
    parts.append(table(["Collision type", "Count"], sorted(by_type.items())))
    unit_conflicts = {
        item.get("native_id") for item in collisions.get("collisions", [])
        if item.get("entity_type") == "unit"
        and item.get("type") == "same_native_id_different_regional_names"
    }
    parts.extend([
        "",
        f"Unit form IDs with documented GL/JP identity conflicts: **{len(unit_conflicts)}** "
        f"({', '.join(sorted(unit_conflicts)) if unit_conflicts else 'none'}). "
        "These are kept separate with composite identities; no automatic merge is performed.",
    ])
    parts.extend(["", "Examples (unit identity conflicts shown first):", ""])
    ordered = sorted(collisions.get("collisions", []),
                     key=lambda item: (0 if item.get("entity_type") == "unit" else 1,
                                       str(item.get("type", "")), str(item.get("native_id", ""))))
    for item in ordered[:12]:
        identity = item.get("identity") or item.get("native_id") or item.get("normalized_name", "")
        parts.append(f"- `{item.get('type')}` — {item.get('entity_type')} {identity}: "
                     f"{item.get('names') or item.get('gl_names', []) + item.get('jp_names', []) or item.get('native_ids', {})}")
    parts.extend([
        "",
        "## 5. Missing references",
        "",
        f"Total unresolved record references: **{missing_refs.get('total_missing_references', 0)}**.",
        "",
        "Every entry includes its source path and revision in `data/validation/missing-references.json`. "
        "Missing means unresolved against the inspected dataset only; it is not proof that the "
        "original game lacked the record.",
        "",
        "## 6. Asset coverage",
        "",
        f"Files inventoried: **{asset_coverage.get('file_count', 0)}**; "
        f"bytes: **{asset_coverage.get('total_bytes', 0)}**.",
        "",
        table(["Category", "Files", "Bytes", "Hashed", "Formats"],
              [[name, bucket.get("files", 0), bucket.get("bytes", 0), bucket.get("hashed_files", 0),
                ", ".join(f"{fmt}:{count}" for fmt, count in sorted(bucket.get("formats", {}).items()))]
               for name, bucket in sorted(asset_coverage.get("categories", {}).items())]),
        "",
        "Animation CSV summary:",
        "",
        "```json",
        __import__("json").dumps(asset_coverage.get("animation_csv", {}), indent=2, sort_keys=True),
        "```",
        "",
        "## 7. Asset integrity",
        "",
        table(["Check", "Result"],
              [["Files with SHA-256", asset_integrity.get("files_with_checksum", 0)],
               ["Metadata-only files", asset_integrity.get("metadata_only_files", 0)],
               ["Duplicate hash groups", asset_integrity.get("duplicate_hash_groups", 0)],
               ["Files in duplicate groups", asset_integrity.get("duplicate_files", 0)],
               ["Zero-length files", asset_integrity.get("zero_length_files", 0)],
               ["Unsupported formats", asset_integrity.get("unsupported_format_count", 0)]]),
        "",
        f"Missing catalog asset references: **{missing_assets.get('missing_asset_count', 0)}** "
        f"of {missing_assets.get('references_checked', 0)} checked.",
        "",
        "## 8. Shared, equivalent and region-specific content",
        "",
        "Shared or equivalent content is reported only as a candidate when IDs and names differ "
        "across regions; records are never merged automatically. Region-specific records keep "
        "composite identities such as `unit:GL:<id>` and `unit:JP:<id>`. See "
        "`data/validation/id-collisions.json` for the exact evidence.",
        "",
        "## 9. Legal and redistribution blockers",
        "",
        "- Neither inspected repository declares a license in GitHub metadata. Public access is not "
        "permission to redistribute third-party game data or assets.",
        "- FFBE names, characters, artwork, text and audio may be protected by Square Enix or other "
        "rights holders. No original asset is copied into this repository during this phase.",
        "- The asset dump's own reports describe source archives extracted from local game dumps; "
        "those extraction details are provenance, not a license.",
        "",
        "## 10. Limitations",
        "",
        "- Source A was inspected from Git tree metadata; binary blobs were not bulk-downloaded. "
        "Checksum coverage is therefore limited to materialized files.",
        "- Source B is a historical extraction ending in 2018; it is not evidence of current game coverage.",
        "- No category is reported as complete or VERIFIED solely because a file parsed successfully.",
        "",
    ])
    return "\n".join(parts).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--coverage", required=True)
    parser.add_argument("--collisions", required=True)
    parser.add_argument("--missing-refs", required=True)
    parser.add_argument("--asset-coverage", required=True)
    parser.add_argument("--asset-integrity", required=True)
    parser.add_argument("--missing-assets", required=True)
    parser.add_argument("--out-dir", default="docs/audit")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()
    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO,
                        format="%(levelname)s %(name)s: %(message)s")

    manifest = read(args.manifest, parser, "manifest")
    coverage = read(args.coverage, parser, "coverage")
    collisions = read(args.collisions, parser, "collisions")
    missing_refs = read(args.missing_refs, parser, "missing references")
    asset_coverage = read(args.asset_coverage, parser, "asset coverage")
    asset_integrity = read(args.asset_integrity, parser, "asset integrity")
    missing_assets = read(args.missing_assets, parser, "missing assets")

    os.makedirs(args.out_dir, exist_ok=True)
    inventory_md = build_inventory_markdown(manifest)
    audit_md = build_audit_markdown(args, manifest, coverage, collisions, missing_refs,
                                    asset_coverage, asset_integrity, missing_assets)
    with open(os.path.join(args.out_dir, "source-inventory.md"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(inventory_md)
    with open(os.path.join(args.out_dir, "audit-report.md"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(audit_md)
    LOG.info("Wrote source-inventory.md and audit-report.md to %s", args.out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
