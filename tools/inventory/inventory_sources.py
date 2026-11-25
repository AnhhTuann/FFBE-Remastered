#!/usr/bin/env python3
"""Inventory a source tree (or Git tree listing) and update the source manifest.

The tool never assumes a source layout: category rules and audit notes are
supplied as JSON configuration. Files that were not checked out can still be
counted from ``git ls-tree -r -l`` output; their SHA-256 stays null and is
reported as METADATA_ONLY.

Example:
  python3 tools/inventory/inventory_sources.py \
    --root /path/to/source --git-tree /path/to/ls-tree.txt \
    --metadata /path/to/github-api.json --audit-meta /path/to/audit-meta.json \
    --category-map tools/inventory/category-map.json \
    --inventory-out data/manifests/source-b-inventory.json \
    --manifest data/manifests/source-manifest.json \
    --manifest-csv data/manifests/source-manifest.csv
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from typing import Any

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from audit_utils import load_json, path_list, sha256_file, write_csv, write_json  # noqa: E402

TOOL_VERSION = "1.0.0"
LOG = logging.getLogger("inventory")


def parse_git_tree(path: str) -> dict[str, dict[str, Any]]:
    """Parse tab-separated output of ``git ls-tree -r -l HEAD``."""
    files: dict[str, dict[str, Any]] = {}
    with open(path, "r", encoding="utf-8") as handle:
        for line in handle:
            if "\t" not in line:
                continue
            meta, relpath = line.rstrip("\n").split("\t", 1)
            parts = meta.split()
            if len(parts) < 4 or parts[1] != "blob":
                continue
            files[relpath] = {
                "path": relpath,
                "category": None,
                "extension": os.path.splitext(relpath)[1].lower().lstrip(".") or "(none)",
                "size_bytes": int(parts[3]),
                "sha256": None,
                "evidence": "git-tree",
                "status": "METADATA_ONLY",
            }
    return files


def load_rules(path: str | None) -> list[tuple[str, str]]:
    if not path:
        return []
    data, error = load_json(path)
    if error or not isinstance(data, dict):
        LOG.warning("Could not read category map %s: %s", path, error)
        return []
    return [(str(rule.get("prefix", "")), str(rule.get("category", "other")))
            for rule in data.get("rules", []) if isinstance(rule, dict)]


def categorize(relpath: str, rules: list[tuple[str, str]]) -> str:
    for prefix, category in rules:
        if relpath.startswith(prefix):
            return category
    return relpath.split("/", 1)[0] if "/" in relpath else "root"


def build_inventory(args: argparse.Namespace) -> dict[str, Any]:
    rules = load_rules(args.category_map)
    tree_files: dict[str, dict[str, Any]] = {}
    if args.git_tree:
        tree_files = parse_git_tree(args.git_tree)
        LOG.info("Read %d entries from Git tree listing", len(tree_files))
    files: dict[str, dict[str, Any]] = dict(tree_files) if args.include_tree_files else {}

    root_files = path_list(args.root) if os.path.isdir(args.root) else []
    for relpath in root_files:
        absolute = os.path.join(args.root, relpath)
        size = os.path.getsize(absolute)
        hashed = False
        sha: str | None = None
        if args.hash_all or (0 <= args.max_hash_bytes and size <= args.max_hash_bytes):
            try:
                sha = sha256_file(absolute)
                hashed = True
            except OSError as exc:
                LOG.warning("Could not hash %s: %s", relpath, exc)
        files[relpath] = {
            "path": relpath,
            "category": categorize(relpath, rules),
            "extension": os.path.splitext(relpath)[1].lower().lstrip(".") or "(none)",
            "size_bytes": size,
            "sha256": sha,
            "evidence": "worktree",
            "status": "HASHED" if hashed else "METADATA_ONLY",
        }
    LOG.info("Inventoried %d files from worktree", len(root_files))

    # Statistics always cover the complete tree; per-file rows are emitted only
    # for materialized files unless --include-tree-files is requested.
    all_records = dict(tree_files)
    all_records.update(files)
    for record in all_records.values():
        if record["category"] is None:
            record["category"] = categorize(record["path"], rules)
    ordered = [files[key] for key in sorted(files)]

    categories: dict[str, dict[str, int]] = {}
    extensions: dict[str, dict[str, int]] = {}
    for record in all_records.values():
        for bucket, key in ((categories, record["category"]), (extensions, record["extension"])):
            entry = bucket.setdefault(key, {"files": 0, "bytes": 0})
            entry["files"] += 1
            entry["bytes"] += record["size_bytes"]

    metadata, error = load_json(args.metadata)
    if error or not isinstance(metadata, dict):
        LOG.warning("Metadata file unreadable (%s); using CLI identifiers", error)
        metadata = {}
    audit, audit_error = load_json(args.audit_meta) if args.audit_meta else ({}, None)
    if audit_error or not isinstance(audit, dict):
        LOG.warning("Audit metadata unreadable: %s", audit_error)
        audit = {}

    source_id = str(audit.get("source_id") or metadata.get("full_name") or os.path.basename(args.root))
    return {
        "tool": "inventory_sources.py",
        "tool_version": TOOL_VERSION,
        "source_id": source_id,
        "revision": args.revision,
        "root_label": os.path.basename(os.path.normpath(args.root)),
        "git_tree_listing": os.path.basename(args.git_tree) if args.git_tree else None,
        "file_count": len(all_records),
        "total_bytes": sum(record["size_bytes"] for record in all_records.values()),
        "hashed_file_count": sum(1 for record in all_records.values() if record["sha256"]),
        "emitted_file_rows": len(ordered),
        "tree_metadata_only_files": len(tree_files) - sum(1 for key in tree_files if key in files),
        "categories": categories,
        "extensions": extensions,
        "files": ordered,
        "github_metadata": metadata,
        "audit_metadata": audit,
    }


def update_manifest(path: str, entry: dict[str, Any], csv_path: str) -> None:
    manifest: dict[str, Any] = {"tool_version": TOOL_VERSION, "sources": []}
    if os.path.exists(path):
        existing, error = load_json(path)
        if existing is not None and isinstance(existing, dict) and not error:
            manifest = existing
        else:
            LOG.warning("Replacing unreadable manifest %s", path)
    sources = manifest.setdefault("sources", [])
    replaced = False
    for index, item in enumerate(sources):
        if item.get("source_id") == entry["source_id"]:
            sources[index] = entry
            replaced = True
            break
    if not replaced:
        sources.append(entry)
    sources.sort(key=lambda item: str(item.get("source_id", "")))
    manifest["tool_version"] = TOOL_VERSION
    write_json(path, manifest)

    columns = [
        "source_id", "name", "repository_url", "source_type", "region_coverage",
        "current_branch", "commit_sha", "commit_date", "last_update", "license",
        "redistribution_restrictions", "file_count", "total_size_bytes",
        "confidence", "provenance", "branches", "limitations",
    ]
    rows = []
    for source in sources:
        row = {key: source.get(key, "") for key in columns}
        for key in ("limitations", "missing_or_inaccessible", "available_data_categories"):
            if isinstance(row.get(key), list):
                row[key] = "; ".join(str(item) for item in row[key])
        if isinstance(row.get("branches"), list):
            row["branches"] = "; ".join(
                f"{item.get('branch', '')}@{item.get('commit_sha', '')}"
                for item in row["branches"] if isinstance(item, dict)
            )
        rows.append(row)
    write_csv(csv_path, rows, columns)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", required=True, help="Local source checkout directory")
    parser.add_argument("--git-tree", help="Optional git ls-tree -r -l HEAD text file")
    parser.add_argument("--metadata", help="JSON with verified GitHub API metadata")
    parser.add_argument("--audit-meta", help="JSON with manually verified audit notes")
    parser.add_argument("--category-map", help="JSON with prefix -> category rules")
    parser.add_argument("--revision", required=True, help="Exact commit SHA of the inspected revision")
    parser.add_argument("--inventory-out", required=True, help="Per-source inventory JSON path")
    parser.add_argument("--manifest", help="Source manifest JSON to update")
    parser.add_argument("--manifest-csv", help="Source manifest CSV to update")
    parser.add_argument("--include-tree-files", action="store_true",
                        help="Emit a per-file row for every Git tree entry (large)")
    parser.add_argument("--hash-all", action="store_true", help="Hash every checked-out file")
    parser.add_argument("--max-hash-bytes", type=int, default=2_000_000,
                        help="Maximum checked-out file size to hash (default: 2000000; -1 with --hash-all)")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO,
                        format="%(levelname)s %(name)s: %(message)s")
    if args.manifest and not args.manifest_csv:
        parser.error("--manifest-csv is required with --manifest")

    inventory = build_inventory(args)
    write_json(args.inventory_out, inventory)
    LOG.info("Wrote inventory for %s (%d files, %d bytes)",
             inventory["source_id"], inventory["file_count"], inventory["total_bytes"])

    if args.manifest:
        audit = inventory["audit_metadata"]
        metadata = inventory["github_metadata"]
        entry = {
            "source_id": inventory["source_id"],
            "name": audit.get("name", metadata.get("full_name", inventory["source_id"])),
            "repository_url": audit.get("repository_url", metadata.get("html_url", "")),
            "source_type": audit.get("source_type", "public repository"),
            "region_coverage": audit.get("region_coverage", "UNVERIFIED"),
            "current_branch": audit.get("current_branch", metadata.get("default_branch", "")),
            "commit_sha": args.revision,
            "commit_date": audit.get("commit_date", ""),
            "last_update": audit.get("last_update", metadata.get("pushed_at", "")),
            "license": audit.get("license", "NO LICENSE FILE"),
            "redistribution_restrictions": audit.get("redistribution_restrictions", "UNVERIFIED"),
            "provenance": audit.get("provenance", "UNVERIFIED"),
            "branches": audit.get("branches", []),
            "available_data_categories": audit.get("available_data_categories", []),
            "file_count": inventory["file_count"],
            "total_size_bytes": inventory["total_bytes"],
            "hashed_file_count": inventory["hashed_file_count"],
            "missing_or_inaccessible": audit.get("missing_or_inaccessible", []),
            "confidence": audit.get("confidence", "UNVERIFIED"),
            "limitations": audit.get("limitations", []),
            "inventory_path": os.path.basename(args.inventory_out),
            "inventory_tool_version": TOOL_VERSION,
        }
        update_manifest(args.manifest, entry, args.manifest_csv)
        LOG.info("Updated source manifest: %s", args.manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
