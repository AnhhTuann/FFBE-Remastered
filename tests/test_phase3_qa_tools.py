"""Tests for the deterministic Phase 3 visual-review metadata tool."""

from __future__ import annotations

import importlib.util
import os
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

    def test_reads_alternate_capture_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "docs/qa/screenshots/hardening"
            directory.mkdir(parents=True)
            (directory / "hardening.txt").write_text(
                self._capture("hardening"), encoding="utf-8"
            )
            captures = self.tool.read_captures(
                root, "docs/qa/screenshots/hardening"
            )
            rendered = self.tool.render(
                captures, "docs/qa/screenshots/hardening"
            )
            self.assertEqual([item["name"] for item in captures], ["hardening"])
            self.assertIn(
                "docs/qa/screenshots/hardening/hardening.png", rendered
            )

    def test_capture_script_rejects_unsafe_arguments(self) -> None:
        script = ROOT / "tools/qa/capture_phase3.sh"
        cases = [
            {"NAME": "../escape", "RES": "1280x720", "LOCALE": "vi"},
            {"NAME": "safe", "RES": "1280x720;rm", "LOCALE": "vi"},
            {"NAME": "safe", "RES": "1280x720", "LOCALE": "fr"},
        ]
        for overrides in cases:
            env = os.environ.copy()
            env.update(overrides)
            env["SCENE"] = "boot"
            result = subprocess.run(
                ["bash", str(script)], env=env, capture_output=True, text=True, check=False
            )
            self.assertEqual(result.returncode, 2, result.stderr)
            self.assertFalse((ROOT / "escape.png").exists())

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


class Prompt05QaToolsTest(unittest.TestCase):
    """Prompt 05 reuses the Phase 3 sidecar format with its own output path."""

    @classmethod
    def setUpClass(cls) -> None:
        tool_path = ROOT / "tools/qa/prompt05_visual_report.py"
        spec = importlib.util.spec_from_file_location("prompt05_visual_report", tool_path)
        assert spec is not None and spec.loader is not None
        cls.tool = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.tool)

    def test_default_capture_directory(self) -> None:
        self.assertEqual(self.tool.DEFAULT_CAPTURE_DIR, "docs/qa/screenshots/prompt05")

    def test_render_summarises_prompt05_metadata(self) -> None:
        rendered = self.tool.render(
            [
                {
                    "name": "prompt05-economy-vi-1280x720",
                    "scene": "res://scenes/phase3/economy_hub.tscn",
                    "resolution": "1280x720",
                    "locale": "vi",
                    "geometry": "WINDOW=1 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0",
                    "pixels": "1280x720 colors=210 stddev=0.06",
                    "runtime_error_lines": "0",
                }
            ]
        )
        self.assertIn("# Prompt 05 visual review", rendered)
        self.assertIn("Captures: 1", rendered)
        self.assertIn("`vi`", rendered)
        self.assertIn(
            "docs/qa/screenshots/prompt05/prompt05-economy-vi-1280x720.png", rendered
        )
        self.assertIn("Runtime error lines across all captures: 0", rendered)

    def test_reads_alternate_prompt05_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "docs/qa/screenshots/prompt05"
            directory.mkdir(parents=True)
            sidecar = Phase3QaToolsTest._capture("prompt05-a")
            (directory / "a.txt").write_text(sidecar, encoding="utf-8")
            captures = self.tool.read_captures(root)
            self.assertEqual([item["name"] for item in captures], ["prompt05-a"])

    def test_capture_script_passes_prompt05_economy_env(self) -> None:
        script = (ROOT / "tools/qa/capture_phase3.sh").read_text(encoding="utf-8")
        self.assertIn("FFBE_QA_OFFLINE_SECONDS=", script)
        self.assertIn("FFBE_QA_NOW_UNIX=", script)
        self.assertIn("offline_seconds=", script)
        self.assertIn("now_unix=", script)


class Prompt06QaToolsTest(unittest.TestCase):
    """Prompt 06 requires a complete real-window capture matrix."""

    @classmethod
    def setUpClass(cls) -> None:
        tool_path = ROOT / "tools/qa/prompt06_visual_report.py"
        spec = importlib.util.spec_from_file_location("prompt06_visual_report", tool_path)
        assert spec is not None and spec.loader is not None
        cls.tool = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.tool)

    @staticmethod
    def _capture(scenario: str, resolution: str, locale: str, errors: str = "0") -> dict[str, str]:
        return {
            "name": f"prompt06-{scenario}-{locale}-{resolution}",
            "scene": "res://scenes/world/world_map.tscn",
            "resolution": resolution,
            "locale": locale,
            "scenario": scenario,
            "geometry": "WINDOW=1 X=0 Y=70 WIDTH=1280 HEIGHT=720 SCREEN=0",
            "pixels": "1280x720 colors=210 stddev=0.06",
            "runtime_error_lines": errors,
        }

    def _full_matrix(self) -> list[dict[str, str]]:
        return [
            self._capture(scenario, resolution, locale)
            for scenario in self.tool.REQUIRED_SCENARIOS
            for resolution in self.tool.REQUIRED_RESOLUTIONS
            for locale in self.tool.REQUIRED_LOCALES
        ]

    def test_default_paths_and_matrix_size(self) -> None:
        self.assertEqual(self.tool.DEFAULT_CAPTURE_DIR, "docs/qa/screenshots/prompt06")
        self.assertEqual(self.tool.DEFAULT_OUTPUT, "docs/qa/prompt06-visual-review.md")
        self.assertEqual(len(self._full_matrix()), 117)

    def test_validate_matrix_accepts_complete_clean_matrix(self) -> None:
        self.tool.validate_matrix(self._full_matrix())

    def test_validate_matrix_rejects_missing_capture(self) -> None:
        captures = self._full_matrix()[1:]
        with self.assertRaisesRegex(ValueError, "missing Prompt 06 captures"):
            self.tool.validate_matrix(captures)

    def test_validate_matrix_rejects_runtime_errors(self) -> None:
        captures = self._full_matrix()
        captures[0]["runtime_error_lines"] = "2"
        with self.assertRaisesRegex(ValueError, "runtime error lines"):
            self.tool.validate_matrix(captures)

    def test_read_rejects_sidecar_without_scenario(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "docs/qa/screenshots/prompt06"
            directory.mkdir(parents=True)
            (directory / "broken.txt").write_text(
                Phase3QaToolsTest._capture("broken"), encoding="utf-8"
            )
            with self.assertRaisesRegex(ValueError, "missing scenario metadata"):
                self.tool.read_captures(root)

    def test_render_summarises_prompt06_metadata(self) -> None:
        rendered = self.tool.render(self._full_matrix())
        self.assertIn("# Prompt 06 world exploration visual review", rendered)
        self.assertIn("Captures: 117", rendered)
        self.assertIn("World Map selected location", rendered)
        self.assertIn("Runtime error lines across all captures: 0", rendered)
        self.assertIn("subjective visual sign-off", rendered)

    def test_capture_wrapper_allow_lists_scenarios(self) -> None:
        script = (ROOT / "tools/qa/capture_prompt06.sh").read_text(encoding="utf-8")
        for scenario in self.tool.REQUIRED_SCENARIOS:
            self.assertIn(scenario, script)
        self.assertIn("QA_PROFILE_ROOT", script)
        self.assertIn("rm -rf -- \"$PROFILE\"", script)

    def test_capture_wrapper_seeds_real_world_battle_context(self) -> None:
        script = (ROOT / "tools/qa/capture_prompt06.sh").read_text(encoding="utf-8")
        self.assertIn("export FFBE_QA_MODE=1", script)
        self.assertIn("battle_victory)", script)
        self.assertIn("encounter:GL:950002@boss", script)
        self.assertIn("encounter_trigger:GL:5102@spire", script)
        self.assertIn("battle_defeat|battle_retry|battle_return)", script)
        self.assertIn("encounter:GL:950001@skirmish", script)
        self.assertIn("encounter_trigger:GL:5101@meadow", script)
        self.assertIn("FFBE_QA_RETURN_SCENE", script)


if __name__ == "__main__":
    unittest.main()
