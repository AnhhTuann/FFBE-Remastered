"""Tests for the deterministic Phase 3 visual-review metadata tool."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TOOL_PATH = ROOT / "tools/qa/phase3_visual_report.py"


def _load_module() -> Any:
    spec = importlib.util.spec_from_file_location("phase3_visual_report", TOOL_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class Phase3QaToolsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool = _load_module()

    @staticmethod
    def _capture(name: str, **overrides: str) -> str:
        values = {
            "name": name,
            "scene": "res://scenes/menu/main_menu.tscn",
            "resolution": "1280x720",
            "locale": "vi",
            "geometry": "WINDOW=1 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0",
            "pixels": "1280x720 colors=210 stddev=0.06",
            "runtime_error_lines": "0",
        }
        values.update(overrides)
        return "\n".join(f"{key}={value}" for key, value in values.items()) + "\n"

    def test_reads_sorted_capture_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "docs/qa/screenshots/phase3"
            directory.mkdir(parents=True)
            (directory / "b.txt").write_text(
                self._capture("b", locale="ja"), encoding="utf-8"
            )
            (directory / "a.txt").write_text(self._capture("a"), encoding="utf-8")
            captures = self.tool.read_captures(root)
            self.assertEqual([item["name"] for item in captures], ["a", "b"])

    def test_rejects_incomplete_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "docs/qa/screenshots/phase3"
            directory.mkdir(parents=True)
            (directory / "broken.txt").write_text("name=broken\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                self.tool.read_captures(root)

    def test_rejects_geometry_that_does_not_match_request(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "docs/qa/screenshots/phase3"
            directory.mkdir(parents=True)
            (directory / "wrong.txt").write_text(
                self._capture(
                    "wrong",
                    geometry="WINDOW=1 X=0 Y=70 WIDTH=1920 HEIGHT=950 SCREEN=0",
                ),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                self.tool.read_captures(root)

    def test_rejects_fullscreen_capture_not_at_origin(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "docs/qa/screenshots/phase3"
            directory.mkdir(parents=True)
            (directory / "offset.txt").write_text(
                self._capture(
                    "offset",
                    fullscreen="1",
                    geometry="WINDOW=1 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0",
                ),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                self.tool.read_captures(root)

    def test_render_summarises_real_metadata_only(self) -> None:
        rendered = self.tool.render(
            [
                {
                    "name": "phase3-main-menu-vi-1280x720",
                    "scene": "res://scenes/menu/main_menu.tscn",
                    "resolution": "1280x720",
                    "locale": "vi",
                    "geometry": "WINDOW=1 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0",
                    "pixels": "1280x720 colors=210 stddev=0.06",
                    "runtime_error_lines": "0",
                }
            ]
        )
        self.assertIn("Captures: 1", rendered)
        self.assertIn("`vi`", rendered)
        self.assertIn("1280x720", rendered)
        self.assertIn("docs/qa/screenshots/phase3/phase3-main-menu-vi-1280x720.png", rendered)
        self.assertIn("Runtime error lines across all captures: 0", rendered)
        self.assertIn("subjective visual sign-off", rendered)

    def test_cli_writes_deterministic_report(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "docs/qa/screenshots/phase3"
            directory.mkdir(parents=True)
            (directory / "a.txt").write_text(self._capture("a"), encoding="utf-8")
            output = root / "review.md"
            first = subprocess.run(
                [sys.executable, str(TOOL_PATH), "--root", str(root), "--output", str(output)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(first.returncode, 0, first.stderr)
            self.assertIn("captures: 1", first.stdout)
            initial = output.read_text(encoding="utf-8")
            second = subprocess.run(
                [sys.executable, str(TOOL_PATH), "--root", str(root), "--output", str(output)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertEqual(output.read_text(encoding="utf-8"), initial)


if __name__ == "__main__":
    unittest.main()
