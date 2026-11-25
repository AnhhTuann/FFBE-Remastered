"""Automated tests for the Phase 0 audit tooling.

All fixtures are synthetic. No copyrighted game data or asset is used.
Run with: python3 -m unittest discover -s tests -v
"""

from __future__ import annotations

import csv
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(ROOT, "tools")
FIXTURES = os.path.join(ROOT, "tests", "data")
ASSETS = os.path.join(ROOT, "tests", "assets")
sys.path.insert(0, TOOLS)

from audit_utils import load_json, sha256_file, write_csv  # noqa: E402


def run_script(script: str, *arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, os.path.join(TOOLS, script), *arguments],
        capture_output=True, text=True, check=False,
    )


class AuditToolTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.work = self.temp.name

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write(self, relative: str, payload: str) -> str:
        path = os.path.join(self.work, relative)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(payload)
        return path

    def test_valid_json_parsing(self) -> None:
        data, error = load_json(os.path.join(FIXTURES, "valid.json"))
        self.assertIsNone(error)
        self.assertEqual(data["1"]["name"], "Alpha")

    def test_invalid_json_handling(self) -> None:
        data, error = load_json(os.path.join(FIXTURES, "invalid.json"))
        self.assertIsNone(data)
        self.assertIsNotNone(error)
        self.assertIn("JSONDecodeError", error)

    def test_csv_parsing(self) -> None:
        out = os.path.join(self.work, "rows.csv")
        write_csv(out, [{"id": "1", "status": "RECOVERED"}], ["id", "status"])
        with open(out, encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(rows, [{"id": "1", "status": "RECOVERED"}])

    def _validate(self, name: str, gl: dict, jp: dict) -> tuple[dict, dict, dict]:
        self.write(f"{name}/gl/unit.json", json.dumps(gl))
        self.write(f"{name}/jp/unit.json", json.dumps(jp))
        self.write(f"{name}/gl/item.json", json.dumps({"99": {"id": 99, "name": "Potion"}}))
        self.write(f"{name}/jp/item.json", json.dumps({"99": {"id": 99, "name": "Potion"}}))
        coverage = os.path.join(self.work, f"{name}-coverage.json")
        collisions = os.path.join(self.work, f"{name}-collisions.json")
        refs = os.path.join(self.work, f"{name}-refs.json")
        result = run_script(
            "validate/validate_data.py",
            "--spec", os.path.join(FIXTURES, "spec.json"),
            "--root", f"GL={os.path.join(self.work, name)}",
            "--root", f"JP={os.path.join(self.work, name)}",
            "--revision", "fixture=test-sha",
            "--coverage-out", coverage,
            "--csv-out", os.path.join(self.work, f"{name}-coverage.csv"),
            "--collisions-out", collisions,
            "--refs-out", refs,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return (load_json(coverage)[0], load_json(collisions)[0], load_json(refs)[0])

    def test_duplicate_id_detection(self) -> None:
        coverage, _, _ = self._validate(
            "duplicates",
            {"a": {"id": 1, "name": "Alpha"}, "b": {"id": 1, "name": "Duplicate Alpha"}},
            {"a": {"id": 1, "name": "Alpha"}, "b": {"id": 2, "name": "Beta"}},
        )
        unit_rows = [row for row in coverage["regions"]["GL"]
                     if row["key"] == "units" and row["region"] == "GL"]
        self.assertEqual(unit_rows[0]["duplicate_records"], 1)

    def test_global_japan_id_collision_detection(self) -> None:
        _, collisions, _ = self._validate(
            "collisions",
            {"7": {"id": 7, "name": "Alpha", "lb": {"id": 999}}},
            {"7": {"id": 7, "name": "Beta", "lb": {"id": 999}}},
        )
        types = [entry["type"] for entry in collisions["collisions"]]
        self.assertIn("same_native_id_different_regional_names", types)

    def test_missing_reference_detection(self) -> None:
        _, _, refs = self._validate(
            "refs",
            {"7": {"id": 7, "name": "Alpha", "lb": {"id": 999}}},
            {"7": {"id": 7, "name": "Alpha", "lb": {"id": 999}}},
        )
        self.assertEqual(refs["total_missing_references"], 2)
        self.assertEqual(refs["missing_references"][0]["missing_id"], "999")

    def test_asset_inventory_and_checksum(self) -> None:
        source = os.path.join(self.work, "source")
        os.makedirs(os.path.join(source, "unit_icons"), exist_ok=True)
        shutil.copy(os.path.join(ASSETS, "sample.png"), os.path.join(source, "unit_icons", "sample.png"))
        inventory = os.path.join(self.work, "inventory.json")
        result = run_script(
            "inventory/inventory_sources.py",
            "--root", source, "--revision", "test-sha",
            "--hash-all", "--inventory-out", inventory,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        data, _ = load_json(inventory)
        self.assertEqual(data["file_count"], 1)
        self.assertEqual(data["files"][0]["category"], "unit_icons")
        with open(os.path.join(ASSETS, "sample.png"), "rb") as handle:
            expected = hashlib.sha256(handle.read()).hexdigest()
        self.assertEqual(data["files"][0]["sha256"], expected)

    def test_sha256_calculation(self) -> None:
        path = os.path.join(ASSETS, "sample.png")
        with open(path, "rb") as handle:
            expected = hashlib.sha256(handle.read()).hexdigest()
        self.assertEqual(sha256_file(path), expected)

    def test_report_generation(self) -> None:
        manifest = {
            "sources": [{
                "source_id": "fixture", "commit_sha": "abc", "region_coverage": "GL+JP",
                "file_count": 2, "total_size_bytes": 20, "license": "none",
                "redistribution_restrictions": "review", "confidence": "HIGH",
                "available_data_categories": ["units"], "missing_or_inaccessible": [], "limitations": [],
            }],
        }
        paths = {
            "manifest": os.path.join(self.work, "manifest.json"),
            "coverage": os.path.join(self.work, "coverage.json"),
            "collisions": os.path.join(self.work, "collisions.json"),
            "missing-refs": os.path.join(self.work, "refs.json"),
            "asset-coverage": os.path.join(self.work, "asset-coverage.json"),
            "asset-integrity": os.path.join(self.work, "asset-integrity.json"),
            "missing-assets": os.path.join(self.work, "missing-assets.json"),
        }
        payloads = {
            "manifest": manifest,
            "coverage": {"regions": {"GL": [], "JP": []}},
            "collisions": {"total_collisions": 0, "collisions": []},
            "missing-refs": {"total_missing_references": 0, "missing_references": []},
            "asset-coverage": {"file_count": 0, "total_bytes": 0, "categories": {}, "animation_csv": {}},
            "asset-integrity": {},
            "missing-assets": {"references_checked": 0, "missing_asset_count": 0},
        }
        for key, path in paths.items():
            with open(path, "w", encoding="utf-8") as handle:
                json.dump(payloads[key], handle)
        out = os.path.join(self.work, "docs")
        result = run_script(
            "reports/build_reports.py",
            "--manifest", paths["manifest"], "--coverage", paths["coverage"],
            "--collisions", paths["collisions"], "--missing-refs", paths["missing-refs"],
            "--asset-coverage", paths["asset-coverage"], "--asset-integrity", paths["asset-integrity"],
            "--missing-assets", paths["missing-assets"], "--out-dir", out,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        with open(os.path.join(out, "audit-report.md"), encoding="utf-8") as handle:
            text = handle.read()
        self.assertIn("Phase 0", text)
        self.assertIn("Global structured-data coverage", text)
        self.assertTrue(os.path.isfile(os.path.join(out, "source-inventory.md")))

    def test_repeatable_audit_output(self) -> None:
        outputs = []
        for name in ("run-one", "run-two"):
            coverage, collisions, refs = self._validate(
                name,
                {"7": {"id": 7, "name": "Alpha", "lb": {"id": 999}}},
                {"7": {"id": 7, "name": "Beta", "lb": {"id": 999}}},
            )
            outputs.append((coverage, collisions, refs))
        self.assertEqual(outputs[0], outputs[1])


if __name__ == "__main__":
    unittest.main()
