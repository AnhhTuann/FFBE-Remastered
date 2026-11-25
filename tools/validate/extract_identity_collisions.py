#!/usr/bin/env python3
"""Extract documented GL/JP identity collisions from a region-aware unit master.

This converts source-provided identity evidence into the same collision schema
used by ``validate_data.py``. It does not decide which identity is correct.
"""

from __future__ import annotations

import argparse
import collections
import logging
import os
import sys
from typing import Any

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from audit_utils import load_json, write_json  # noqa: E402

LOG = logging.getLogger("identity-collisions")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--unit-master", required=True)
    parser.add_argument("--source-id", required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--report-path", action="append", default=[],
                        help="Source report path supporting the mapping (repeatable)")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")

    data, error = load_json(args.unit_master)
    if error or not isinstance(data, dict):
        parser.error(f"Could not read unit master: {error}")
    units = data.get("units", [])
    by_native: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
    for unit in units:
        if unit.get("identity_status") != "regional_collision":
            continue
        for identity in unit.get("identities", []):
            server = identity.get("server")
            native = str(identity.get("original_id", ""))
            if server in ("GL", "JP") and native:
                by_native[native].append({
                    "identity": f"unit:{server}:{native}",
                    "master_id": unit.get("master_id"),
                    "name": identity.get("name") or identity.get("raw_name"),
                    "raw_name": identity.get("raw_name"),
                    "unit_source_sha256": identity.get("series_provenance", {}).get("unit_source_sha256"),
                    "game_id": identity.get("game_id"),
                })

    collisions: list[dict[str, Any]] = []
    for native_id, entries in sorted(by_native.items()):
        gl = [item for item in entries if item["identity"].startswith("unit:GL:")]
        jp = [item for item in entries if item["identity"].startswith("unit:JP:")]
        if not gl or not jp:
            continue
        gl_names = {str(item["name"]) for item in gl}
        jp_names = {str(item["name"]) for item in jp}
        if gl_names == jp_names:
            continue
        source_path = os.path.basename(args.unit_master)
        evidence = [{
            "source_id": args.source_id,
            "revision": args.revision,
            "path": f"catalog/{source_path}",
            "identity": item["identity"],
            "master_id": item["master_id"],
            "name": item["name"],
            "raw_name": item["raw_name"],
            "unit_source_sha256": item["unit_source_sha256"],
            "game_id": item["game_id"],
        } for item in gl + jp]
        for report_path in args.report_path:
            evidence.append({
                "source_id": args.source_id,
                "revision": args.revision,
                "path": report_path,
                "role": "upstream_validation_report",
            })
        collisions.append({
            "type": "same_native_id_different_regional_names",
            "entity_type": "unit",
            "native_id": native_id,
            "identities": [item["identity"] for item in gl + jp],
            "gl_names": sorted(gl_names),
            "jp_names": sorted(jp_names),
            "evidence": evidence,
            "action": "kept_separate",
        })

    write_json(args.output, {
        "tool": "extract_identity_collisions.py",
        "source_id": args.source_id,
        "revision": args.revision,
        "total_collisions": len(collisions),
        "collisions": collisions,
    })
    LOG.info("Extracted %d region-collision groups from %s", len(collisions), args.unit_master)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
