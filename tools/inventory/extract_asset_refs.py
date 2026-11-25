#!/usr/bin/env python3
"""Extract relative asset-path references from catalog JSON files.

This feeds ``validate_assets.py``. Fields to inspect and allowed extensions are
configured on the command line, so the tool is not tied to one catalog schema.
"""

from __future__ import annotations

import argparse
import logging
import os
import re
import sys
from typing import Any

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from audit_utils import iter_path_values, load_json, write_json  # noqa: E402

LOG = logging.getLogger("extract-asset-refs")
WINDOWS_PATH = re.compile(r"^[A-Za-z]:[\\/]|^\\\\")


def valid_asset_path(value: Any, extensions: set[str]) -> str | None:
    if not isinstance(value, str):
        return None
    path = value.strip().replace("\\", "/")
    if not path or WINDOWS_PATH.match(path) or path.startswith("/") or "://" in path:
        return None
    extension = os.path.splitext(path)[1].lower().lstrip(".")
    return path if extension in extensions else None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", action="append", required=True, help="Catalog JSON (repeatable)")
    parser.add_argument("--source-id", required=True)
    parser.add_argument("--field", action="append", required=True, help="Dotted field path (repeatable)")
    parser.add_argument("--extensions", default="png,jpg,jpeg,gif,csv,ssbp,bmb,zip")
    parser.add_argument("--output", required=True)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()
    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO,
                        format="%(levelname)s %(name)s: %(message)s")
    extensions = {item.strip().lower().lstrip(".") for item in args.extensions.split(",") if item.strip()}
    refs: list[dict[str, Any]] = []
    seen: set[tuple[str, str]] = set()

    for path in args.input:
        data, error = load_json(path)
        if error:
            LOG.error("Cannot read %s: %s", path, error)
            continue
        for field in args.field:
            for value in iter_path_values(data, field):
                asset_path = valid_asset_path(value, extensions)
                if not asset_path:
                    continue
                key = (path, asset_path)
                if key in seen:
                    continue
                seen.add(key)
                refs.append({
                    "source_id": args.source_id,
                    "catalog_path": os.path.basename(path),
                    "reference_field": field,
                    "asset_path": asset_path,
                })
    refs.sort(key=lambda item: (item["catalog_path"], item["asset_path"], item["reference_field"]))
    write_json(args.output, refs)
    LOG.info("Extracted %d asset references from %d catalogs", len(refs), len(args.input))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
