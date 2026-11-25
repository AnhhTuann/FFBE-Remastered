#!/usr/bin/env python3
"""Generate asset coverage, integrity and missing-asset reports.

Input is a deterministic inventory produced by ``inventory_sources.py`` and,
optionally, a JSON list of asset references extracted from catalogs. Image
headers are read directly from worktree files when available; source files are
never converted or modified.

Example:
  python3 tools/validate/validate_assets.py \
    --inventory data/manifests/source-a-inventory.json \
    --references /path/to/catalog-asset-refs.json \
    --coverage-out data/validation/asset-coverage.json \
    --integrity-out data/validation/asset-integrity.json \
    --missing-out data/validation/missing-assets.json
"""

from __future__ import annotations

import argparse
import collections
import csv
import json
import logging
import os
import struct
import sys
from typing import Any

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from audit_utils import load_json, write_json  # noqa: E402

TOOL_VERSION = "1.0.0"
LOG = logging.getLogger("validate-assets")
IMAGE_EXTENSIONS = {"png", "gif", "jpg", "jpeg", "bmp", "webp"}


def image_header(path: str) -> tuple[int | None, int | None, bool, str | None]:
    """Read dimensions/alpha from common headers without decoding the image."""
    try:
        with open(path, "rb") as handle:
            signature = handle.read(32)
            if signature.startswith(b"\x89PNG\r\n\x1a\n"):
                if len(signature) < 26 or signature[12:16] != b"IHDR":
                    return None, None, False, "PNG header missing IHDR"
                width, height, depth, color_type = struct.unpack(">IIBB", signature[16:26])
                return width, height, color_type in (4, 6), None
            if signature.startswith((b"GIF87a", b"GIF89a")):
                width, height = struct.unpack("<HH", signature[6:10])
                packed = signature[10] if len(signature) > 10 else 0
                has_gct = bool(packed & 0x80)
                if has_gct:
                    handle.seek(13 + 3 * (2 << (packed & 0x07)))
                alpha = False
                while True:
                    block = handle.read(1)
                    if not block:
                        break
                    if block == b"\x21" and handle.read(1) == b"\xf9":
                        handle.read(1)
                        flags = handle.read(1)
                        if flags and flags[0] & 0x01:
                            alpha = True
                        break
                    if block == b",":
                        break
                return width, height, alpha, None
            if signature.startswith(b"\xff\xd8"):
                handle.seek(2)
                while True:
                    marker = handle.read(1)
                    if not marker:
                        return None, None, False, "JPEG SOF marker not found"
                    if marker != b"\xff":
                        continue
                    code = handle.read(1)
                    while code == b"\xff":
                        code = handle.read(1)
                    if not code or code in (b"\x00", b"\x01") or 0xD0 <= code[0] <= 0xD9:
                        continue
                    length_data = handle.read(2)
                    if len(length_data) < 2:
                        break
                    length = struct.unpack(">H", length_data)[0]
                    if code[0] in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
                        payload = handle.read(5)
                        if len(payload) < 5:
                            break
                        height, width = struct.unpack(">HH", payload[1:5])
                        return width, height, False, None
                    handle.seek(length - 2, os.SEEK_CUR)
                return None, None, False, "JPEG dimensions unavailable"
            if signature.startswith(b"BM") and len(signature) >= 26:
                width, height = struct.unpack("<ii", signature[18:26])
                return abs(width), abs(height), False, None
        return None, None, False, "Unsupported header"
    except (OSError, struct.error) as exc:
        return None, None, False, f"Unreadable: {type(exc).__name__}"


def analyze_csv(path: str) -> dict[str, Any]:
    """Basic animation frame-data checks on an accessible CSV."""
    result: dict[str, Any] = {"rows": 0, "frame_ids": [], "invalid_rows": 0, "error": None}
    try:
        with open(path, "r", encoding="utf-8-sig", errors="replace", newline="") as handle:
            for line in csv.reader(handle):
                if not line or all(not cell.strip() for cell in line):
                    continue
                result["rows"] += 1
                try:
                    result["frame_ids"].append(int(line[0]))
                except (ValueError, IndexError):
                    result["invalid_rows"] += 1
    except OSError as exc:
        result["error"] = f"{type(exc).__name__}: {exc}"
    frame_ids = result.pop("frame_ids")
    result["first_frame_id"] = frame_ids[0] if frame_ids else None
    result["last_frame_id"] = frame_ids[-1] if frame_ids else None
    result["non_decreasing"] = bool(frame_ids) and all(
        current <= following for current, following in zip(frame_ids, frame_ids[1:])
    )
    result["starts_at_zero"] = bool(frame_ids) and frame_ids[0] == 0
    result["duplicate_frame_ids"] = len(frame_ids) - len(set(frame_ids))
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--inventory", action="append", required=True, help="Inventory JSON (repeatable)")
    parser.add_argument("--references", help="JSON list of catalog asset references")
    parser.add_argument("--coverage-out", required=True)
    parser.add_argument("--integrity-out", required=True)
    parser.add_argument("--missing-out", required=True)
    parser.add_argument("--max-header-reads", type=int, default=500,
                        help="Maximum image headers to read from the worktree")
    parser.add_argument("--max-animation-reads", type=int, default=200,
                        help="Maximum CSV frame tables to inspect from the worktree")
    parser.add_argument("--max-examples", type=int, default=50)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO,
                        format="%(levelname)s %(name)s: %(message)s")
    files: dict[str, dict[str, Any]] = {}
    roots: dict[str, str] = {}
    for path in args.inventory:
        data, error = load_json(path)
        if error or not isinstance(data, dict):
            parser.error(f"Could not load inventory {path}: {error}")
        roots[data.get("source_id", path)] = data.get("root", "")
        for item in data.get("files", []):
            key = f"{data.get('source_id')}::{item['path']}"
            files[key] = dict(item, source_id=data.get("source_id"))
    LOG.info("Loaded %d files from %d inventories", len(files), len(args.inventory))

    coverage: dict[str, dict[str, Any]] = collections.defaultdict(
        lambda: {"files": 0, "bytes": 0, "hashed_files": 0, "formats": collections.Counter()})
    hash_groups: dict[str, list[str]] = collections.defaultdict(list)
    integrity_examples: list[dict[str, Any]] = []
    broken: list[dict[str, Any]] = []
    unsupported: list[str] = []
    image_stats: dict[str, dict[str, Any]] = collections.defaultdict(
        lambda: {"checked": 0, "with_dimensions": 0, "alpha": 0, "errors": 0})
    animation_stats: dict[str, Any] = {
        "csv_files": 0, "sequence_csv_candidates": 0, "checked": 0, "rows": 0,
        "non_decreasing": 0, "not_non_decreasing": 0, "starts_at_zero": 0,
        "invalid_rows": 0, "duplicate_frame_ids": 0, "errors": [], "examples": [],
    }

    image_reads = 0
    animation_reads = 0
    for key, item in sorted(files.items()):
        category = item.get("category") or "other"
        extension = item.get("extension") or "(none)"
        bucket = coverage[category]
        bucket["files"] += 1
        bucket["bytes"] += item.get("size_bytes", 0)
        bucket["formats"][extension] += 1
        sha = item.get("sha256")
        if sha:
            bucket["hashed_files"] += 1
            hash_groups[sha].append(key)
        if item.get("size_bytes", 0) <= 0:
            broken.append({"path": key, "reason": "zero-length or missing size"})
        if extension not in {"csv", "png", "gif", "jpg", "jpeg", "ssbp", "bmb", "m3r", "bin",
                             "json", "py", "md", "txt", "zip", "fnt", "plist", "(none)"}:
            unsupported.append(key)
        root = roots.get(item.get("source_id"), "")
        absolute = os.path.join(root, item["path"]) if root else ""
        if extension in IMAGE_EXTENSIONS and absolute and os.path.isfile(absolute) and image_reads < args.max_header_reads:
            image_reads += 1
            width, height, alpha, error = image_header(absolute)
            stat = image_stats[extension]
            stat["checked"] += 1
            if error:
                stat["errors"] += 1
                if len(integrity_examples) < args.max_examples:
                    integrity_examples.append({"path": key, "issue": error})
            else:
                stat["with_dimensions"] += 1
                stat["alpha"] += int(alpha)
        is_sequence_csv = (extension == "csv" and "_cgs_" in os.path.basename(item["path"])
                           and ("animation-metadata" in category or "regional-unit-bundles" in category))
        if extension == "csv":
            animation_stats["csv_files"] += 1
        if is_sequence_csv:
            animation_stats["sequence_csv_candidates"] += 1
        if is_sequence_csv and absolute and os.path.isfile(absolute) and animation_reads < args.max_animation_reads:
            animation_reads += 1
            result = analyze_csv(absolute)
            animation_stats["checked"] += 1
            animation_stats["rows"] += result["rows"]
            animation_stats["invalid_rows"] += result["invalid_rows"]
            animation_stats["duplicate_frame_ids"] += result["duplicate_frame_ids"]
            animation_stats["non_decreasing"] += int(result["non_decreasing"])
            animation_stats["not_non_decreasing"] += int(not result["non_decreasing"])
            animation_stats["starts_at_zero"] += int(result["starts_at_zero"])
            if result["error"]:
                animation_stats["errors"].append({"path": key, "error": result["error"]})
            elif (not result["non_decreasing"] or result["invalid_rows"]) and len(animation_stats["examples"]) < args.max_examples:
                animation_stats["examples"].append({"path": key, **result})

    duplicates = {sha: paths for sha, paths in hash_groups.items() if len(paths) > 1}
    duplicate_examples = [
        {"sha256": sha, "count": len(paths), "paths": paths[:args.max_examples]}
        for sha, paths in sorted(duplicates.items(), key=lambda pair: -len(pair[1]))[:args.max_examples]
    ]

    known_paths = {item["path"] for item in files.values()}
    reference_rows: list[dict[str, Any]] = []
    reference_count = 0
    if args.references:
        refs, error = load_json(args.references)
        if error or not isinstance(refs, list):
            parser.error(f"Could not load references: {error}")
        reference_count = len(refs)
        for ref in refs:
            asset_path = str(ref.get("asset_path", ""))
            if asset_path in known_paths:
                continue
            reference_rows.append({
                "source_id": ref.get("source_id"),
                "identity": ref.get("identity"),
                "reference_field": ref.get("reference_field"),
                "asset_path": asset_path,
                "status": "UNAVAILABLE",
            })

    coverage_out = {
        "tool": "validate_assets.py", "tool_version": TOOL_VERSION,
        "inventory_count": len(args.inventory), "file_count": len(files),
        "total_bytes": sum(item.get("size_bytes", 0) for item in files.values()),
        "categories": {
            name: {
                "files": bucket["files"], "bytes": bucket["bytes"],
                "hashed_files": bucket["hashed_files"],
                "formats": dict(sorted(bucket["formats"].items())),
            } for name, bucket in sorted(coverage.items())
        },
        "image_header_sampling": dict(sorted(image_stats.items())),
        "animation_csv": animation_stats,
    }
    integrity_out = {
        "tool": "validate_assets.py", "tool_version": TOOL_VERSION,
        "files_with_checksum": sum(1 for item in files.values() if item.get("sha256")),
        "metadata_only_files": sum(1 for item in files.values() if not item.get("sha256")),
        "duplicate_hash_groups": len(duplicates),
        "duplicate_files": sum(len(paths) for paths in duplicates.values()),
        "duplicate_examples": duplicate_examples,
        "zero_length_files": len(broken),
        "zero_length_examples": broken[:args.max_examples],
        "unsupported_format_count": len(unsupported),
        "unsupported_format_examples": unsupported[:args.max_examples],
        "image_header_examples": integrity_examples,
        "policy": "SHA-256 is null when only Git tree metadata was available. No source file was converted.",
    }
    missing_out = {
        "tool": "validate_assets.py", "tool_version": TOOL_VERSION,
        "references_checked": reference_count,
        "missing_asset_count": len(reference_rows),
        "missing_assets": reference_rows[:2000],
        "truncated": len(reference_rows) > 2000,
    }
    write_json(args.coverage_out, coverage_out)
    write_json(args.integrity_out, integrity_out)
    write_json(args.missing_out, missing_out)
    LOG.info("Asset reports written: %d files, %d duplicate groups, %d missing references",
             len(files), len(duplicates), len(reference_rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
