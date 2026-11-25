"""Self-contained tests for the safe Phase 3 local content importer."""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from typing import Any

from tools.importer import import_content as importer

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "importer" / "import_content.py"


def canonical_sha(value: Any) -> str:
    payload = json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def record(record_id: str = "unit:GL:900101@base", **overrides: Any) -> dict[str, Any]:
    kind = overrides.get("kind", record_id.split(":", 1)[0])
    result: dict[str, Any] = {
        "id": record_id,
        "kind": kind,
        "region": record_id.split(":", 2)[1],
        "verification_status": "SYNTHETIC_FIXTURE",
        "schema_version": 1,
        "name": "Fixture Hero",
        "provenance": {
            "origin": "synthetic_fixture",
            "source": "tests/test_phase3_importer.py",
            "license": "project-owned test data",
        },
    }
    result.update(overrides)
    return result


def manifest(records: list[dict[str, Any]], **overrides: Any) -> dict[str, Any]:
    result: dict[str, Any] = {
        "schema_version": 1,
        "pack_id": "synthetic-demo",
        "namespace": "phase3-fixtures",
        "region": "GL",
        "source_revision": "local-test-revision",
        "source_version": "1.0.0",
        "rights_status": "project-owned-test-data",
        "evidence_class": "SYNTHETIC_FIXTURE",
        "records": records,
    }
    result.update(overrides)
    return result


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, sort_keys=True, indent=2) + "\n", encoding="utf-8")


class Phase3ImporterTest(unittest.TestCase):
    def new_root(self) -> Path:
        temp = tempfile.TemporaryDirectory(prefix="ffbe-phase3-root-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        for name in ("raw", "staging", "normalized", "assets", "packs", "reports"):
            (root / "content-local" / name).mkdir(parents=True, exist_ok=True)
        return root

    def input_dir(self, label: str, pack: dict[str, Any]) -> Path:
        temp = tempfile.TemporaryDirectory(prefix=f"ffbe-phase3-{label}-")
        self.addCleanup(temp.cleanup)
        path = Path(temp.name) / "pack"
        path.mkdir()
        write_json(path / "manifest.json", pack)
        return path

    def input_zip(self, label: str, entries: dict[str, Any | bytes]) -> Path:
        temp = tempfile.TemporaryDirectory(prefix=f"ffbe-phase3-{label}-")
        self.addCleanup(temp.cleanup)
        path = Path(temp.name) / "pack.zip"
        with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_STORED) as archive:
            for name, value in entries.items():
                data = value if isinstance(value, bytes) else json.dumps(value).encode("utf-8")
                archive.writestr(name, data)
        return path

    def asset(self, root: Path, relative: str, data: bytes = b"synthetic-asset") -> Path:
        path = root / "content-local" / "assets" / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return path

    def assert_no_import_state(self, root: Path, *, allow_log: bool = False) -> None:
        self.assertFalse((root / "content-local/normalized/index.json").exists())
        self.assertEqual(list((root / "content-local/normalized").glob("*.json")), [])
        self.assertEqual(list((root / "content-local/packs").glob("*.json")), [])
        self.assertFalse((root / "content-local/reports/import-journal.json").exists())
        if not allow_log:
            self.assertFalse((root / "content-local/reports/import.log").exists())

    def test_valid_synthetic_dry_run(self) -> None:
        root = self.new_root()
        self.asset(root, "sprites/hero.png", b"synthetic-png")
        ability = record("ability:GL:900101@fixture", kind="ability", name="Fixture Skill")
        hero = record(abilities=[ability["id"]], asset_refs=["sprites/hero.png"])
        input_path = self.input_dir("valid", manifest([hero, ability]))

        report = importer.preview_import(
            input_path, root, report_path=root / "preview.json"
        )

        self.assertEqual(report["result"], "ok")
        self.assertEqual(report["counts"], {
            "discovered": 1, "parsed": 2, "valid": 2, "blocked": 0,
            "duplicates": 0, "conflicts": 0, "unresolved": 0, "asset_refs": 1,
        })
        self.assertEqual(report["unresolved"], [])
        self.assertEqual(report["asset_refs"][0]["path"], "content-local/assets/sprites/hero.png")
        self.assertEqual(
            report["asset_refs"][0]["sha256"], hashlib.sha256(b"synthetic-png").hexdigest()
        )
        log_lines = (root / "content-local/reports/import.log").read_text().splitlines()
        self.assertEqual(json.loads(log_lines[-1])["mode"], "preview")
        self.assertEqual(json.loads(log_lines[-1])["result"], "ok")
        self.assert_no_import_state(root, allow_log=True)

    def test_rights_blocked_recovered_manifest_writes_no_content_state(self) -> None:
        root = self.new_root()
        input_path = self.input_dir(
            "blocked",
            manifest(
                [record()],
                evidence_class="ORIGINAL_SOURCE",
                rights_status="unknown",
            ),
        )
        report_path = root / "blocked-report.json"

        with self.assertRaises(importer.ValidationError) as caught:
            importer.preview_import(input_path, root, report_path=report_path)

        report = caught.exception.report
        self.assertEqual(report["result"], "blocked")
        self.assertEqual(report["counts"]["blocked"], 1)
        self.assertEqual(report["counts"]["valid"], 0)
        self.assertEqual(report["diagnostics"][0]["code"], "rights_blocked")
        self.assertEqual(json.loads(report_path.read_text(encoding="utf-8"))["result"], "blocked")
        self.assert_no_import_state(root)

        quiet_root = self.new_root()
        quiet_input = self.input_dir(
            "blocked-quiet",
            manifest(
                [record()],
                evidence_class="COMMUNITY_MODIFIED",
                rights_status="unknown",
            ),
        )
        with self.assertRaises(importer.ValidationError):
            importer.import_pack(quiet_input, quiet_root)
        self.assertEqual(list((quiet_root / "content-local/reports").iterdir()), [])
        self.assert_no_import_state(quiet_root)

    def test_invalid_id_and_region_are_diagnosed_per_record(self) -> None:
        root = self.new_root()
        bad_id = self.input_dir("bad-id", manifest([record("unit:GL:bad id@base")]))
        bad_region = self.input_dir(
            "bad-region", manifest([record("unit:JP:900101@base", region="JP")])
        )

        with self.assertRaises(importer.ValidationError) as caught:
            importer.preview_import(bad_id, root, report_path=root / "bad-id.json")
        self.assertIn(
            "invalid_id",
            [item["code"] for item in caught.exception.report["diagnostics"]],
        )

        with self.assertRaises(importer.ValidationError) as caught:
            importer.preview_import(bad_region, root, report_path=root / "bad-region.json")
        codes = [item["code"] for item in caught.exception.report["diagnostics"]]
        self.assertIn("id_region_mismatch", codes)
        self.assertIn("record_region_mismatch", codes)
        self.assert_no_import_state(root)

    def test_duplicate_id_inside_pack_is_rejected(self) -> None:
        root = self.new_root()
        duplicate = record(name="Different fixture content")
        input_path = self.input_dir("duplicate", manifest([record(), duplicate]))

        with self.assertRaises(importer.ValidationError) as caught:
            importer.preview_import(input_path, root, report_path=root / "duplicate.json")

        report = caught.exception.report
        self.assertEqual(report["counts"]["duplicates"], 1)
        self.assertIn(
            "duplicate_in_pack_conflict",
            [item["code"] for item in report["diagnostics"]],
        )
        self.assert_no_import_state(root)

    def test_conflict_against_existing_normalized_index_is_rejected(self) -> None:
        root = self.new_root()
        record_id = "unit:GL:900101@base"
        index_path = root / "content-local/normalized/index.json"
        original_index = {
            "schema_version": 1,
            "packs": {"prior-pack": {
                "record_ids": [record_id],
                "record_sha256": {record_id: canonical_sha(record(name="Old content"))},
            }},
        }
        write_json(index_path, original_index)
        before = index_path.read_bytes()
        input_path = self.input_dir("conflict", manifest([record(name="New content")]))

        with self.assertRaises(importer.ValidationError) as caught:
            importer.preview_import(input_path, root, report_path=root / "conflict.json")

        report = caught.exception.report
        self.assertEqual(report["counts"]["conflicts"], 1)
        self.assertIn("conflict", [item["code"] for item in report["diagnostics"]])
        self.assertEqual(index_path.read_bytes(), before)
        self.assertEqual(list((root / "content-local/packs").glob("*.json")), [])

    def test_zip_traversal_is_rejected(self) -> None:
        root = self.new_root()
        zip_path = self.input_zip("traversal", {
            "manifest.json": manifest([record()]),
            "../evil.json": {"not": "allowed"},
        })

        with self.assertRaises(importer.SafetyError) as caught:
            importer.preview_import(zip_path, root, report_path=root / "traversal.json")

        self.assertEqual(caught.exception.code, "path_traversal")
        self.assertIn("traversal", str(caught.exception).lower())
        self.assert_no_import_state(root)

    def test_zip_executable_and_oversized_files_are_rejected(self) -> None:
        root = self.new_root()
        executable_zip = self.input_zip("executable", {
            "manifest.json": manifest([record()]),
            "install.sh": b"#!/bin/sh\necho unsafe\n",
        })
        with self.assertRaises(importer.SafetyError) as caught:
            importer.preview_import(executable_zip, root)
        self.assertEqual(caught.exception.code, "restricted_extension")

        oversized_zip = self.input_zip("oversized", {
            "manifest.json": manifest([record()]),
            "big.json": b"x" * (importer.MAX_FILE_BYTES + 1),
        })
        with self.assertRaises(importer.SafetyError) as caught:
            importer.preview_import(oversized_zip, root)
        self.assertEqual(caught.exception.code, "file_too_large")
        self.assert_no_import_state(root)

    def test_asset_refs_are_validated_and_hashed(self) -> None:
        root = self.new_root()
        self.asset(root, "sprites/hero.png", b"asset-bytes")
        bad_asset_record = record(asset_refs=[
            "sprites/hero.png", "../secret.png", "payload.py", "missing.png",
        ])
        input_path = self.input_dir("assets", manifest([bad_asset_record]))

        with self.assertRaises(importer.ValidationError) as caught:
            importer.preview_import(input_path, root, report_path=root / "assets.json")

        report = caught.exception.report
        codes = [item["code"] for item in report["diagnostics"]]
        self.assertIn("unsafe_asset_path", codes)
        self.assertIn("restricted_asset_extension", codes)
        self.assertIn("asset_not_found", codes)
        self.assertEqual(report["counts"]["asset_refs"], 1)
        self.assertEqual(report["asset_refs"][0]["sha256"], hashlib.sha256(b"asset-bytes").hexdigest())
        self.assertEqual(report["asset_refs"][0]["size_bytes"], len(b"asset-bytes"))
        self.assertEqual(report["records"][0]["status"], "invalid")
        self.assertEqual(list((root / "content-local/normalized").glob("*.json")), [])

    def test_transactional_import_and_rollback(self) -> None:
        root = self.new_root()
        self.asset(root, "sprites/hero.png", b"asset-bytes")
        ability = record("ability:GL:900101@fixture", kind="ability")
        hero = record(abilities=[ability["id"]], asset_refs=["sprites/hero.png"])
        input_path = self.input_dir("transaction", manifest([hero, ability]))
        index_path = root / "content-local/normalized/index.json"
        journal_path = root / "content-local/reports/import-journal.json"
        original_index = b'{"packs": {}, "schema_version": 1}\n'
        original_journal = b'{"entries": [], "packs": {}, "schema_version": 1}\n'
        index_path.write_bytes(original_index)
        journal_path.write_bytes(original_journal)

        imported = importer.import_pack(
            input_path, root, report_path=root / "imported.json"
        )
        self.assertEqual(imported["result"], "imported")
        normalized = root / "content-local/normalized/synthetic-demo.json"
        packaged = root / "content-local/packs/synthetic-demo.json"
        self.assertTrue(normalized.is_file())
        self.assertTrue(packaged.is_file())
        self.assertEqual(normalized.read_bytes(), packaged.read_bytes())
        self.assertIn("synthetic-demo", json.loads(index_path.read_text())["packs"])
        self.assertIn("synthetic-demo", json.loads(journal_path.read_text())["packs"])
        self.assertEqual(Path(str(index_path) + ".bak").read_bytes(), original_index)
        self.assertEqual(Path(str(journal_path) + ".bak").read_bytes(), original_journal)
        self.assertEqual(
            len((root / "content-local/reports/import.log").read_text().splitlines()), 1
        )
        self.assertNotIn("import.sh", str(list((root / "content-local/staging").iterdir())))

        rolled_back = importer.rollback_pack(
            "synthetic-demo", root, report_path=root / "rolled-back.json"
        )
        self.assertEqual(rolled_back["result"], "rolled_back")
        self.assertFalse(normalized.exists())
        self.assertFalse(packaged.exists())
        self.assertNotIn(
            "synthetic-demo", json.loads(index_path.read_text())["packs"]
        )
        self.assertNotIn(
            "synthetic-demo", json.loads(journal_path.read_text())["packs"]
        )

        second = importer.rollback_pack(
            "synthetic-demo", root, report_path=root / "noop.json"
        )
        self.assertEqual(second["result"], "noop")
        self.assertEqual(
            len((root / "content-local/reports/import.log").read_text().splitlines()), 3
        )

    def test_reports_are_deterministic_and_sorted(self) -> None:
        root = self.new_root()
        input_path = self.input_dir(
            "deterministic", manifest([record(), record("ability:GL:900101@fixture", kind="ability")])
        )
        first_path = root / "first.json"
        second_path = root / "second.json"
        importer.preview_import(input_path, root, report_path=first_path)
        importer.preview_import(input_path, root, report_path=second_path)

        first_bytes = first_path.read_bytes()
        self.assertEqual(first_bytes, second_path.read_bytes())
        report = json.loads(first_bytes)
        self.assertEqual(list(report.keys()), sorted(report.keys()))
        self.assertEqual(list(report["counts"].keys()), sorted(report["counts"].keys()))
        self.assertNotIn("timestamp", report)

    def test_cli_exits_nonzero_on_blocked_input(self) -> None:
        root = self.new_root()
        input_path = self.input_dir(
            "cli-blocked",
            manifest(
                [record()], evidence_class="COMMUNITY_RECOVERED", rights_status="unknown"
            ),
        )
        report_path = root / "cli-blocked.json"
        completed = subprocess.run(
            [sys.executable, str(SCRIPT), "--input", str(input_path),
             "--root", str(root), "--report", str(report_path)],
            capture_output=True, text=True, check=False,
        )

        self.assertEqual(completed.returncode, 2, completed.stderr)
        self.assertIn("blocked", (completed.stdout + completed.stderr).lower())
        self.assertEqual(json.loads(report_path.read_text())["result"], "blocked")
        self.assert_no_import_state(root)


if __name__ == "__main__":
    unittest.main()
