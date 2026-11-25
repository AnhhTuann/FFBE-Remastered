"""Static, engine-independent checks for the Phase 1 Godot foundation."""

from __future__ import annotations

import importlib.util
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


class Phase1FoundationTest(unittest.TestCase):
    def test_project_settings_match_pinned_foundation(self) -> None:
        text = (GAME / "project.godot").read_text(encoding="utf-8")
        self.assertIn('config/name="FFBE Remastered"', text)
        self.assertIn("window/size/viewport_width=1280", text)
        self.assertIn("window/size/viewport_height=720", text)
        self.assertIn("textures/canvas_textures/default_texture_filter=0", text)
        self.assertIn('renderer/rendering_method="gl_compatibility"', text)
        self.assertIn("qa/test_viewport_width=1920", text)

    def test_content_catalog_and_fixtures_are_synthetic(self) -> None:
        catalog = _json(GAME / "data/content_catalog.json")
        self.assertEqual(catalog["fixture_marker"], "SYNTHETIC_FIXTURE")
        for relative in catalog["files"].values():
            path = GAME / relative.removeprefix("res://")
            self.assertTrue(path.is_file(), path)

        units = _json(GAME / "data/units.json")
        self.assertEqual(units["fixture_marker"], "SYNTHETIC_FIXTURE")
        ids = [unit["id"] for unit in units["units"]]
        self.assertEqual(len(ids), len(set(ids)))
        for unit in units["units"]:
            self.assertEqual(unit["verification_status"], "SYNTHETIC_FIXTURE")
            self.assertEqual(unit["id"], f"{unit['kind']}:{unit['region']}:{unit['native_id']}@{unit['form']}")
            self.assertTrue(unit["provenance"])
            self.assertTrue(unit["asset_refs"]["atlas"].startswith("res://"))

        gl = {unit["native_id"] for unit in units["units"] if unit["region"] == "GL"}
        jp = {unit["native_id"] for unit in units["units"] if unit["region"] == "JP"}
        self.assertIn("900001", gl & jp)

    def test_animation_metadata_is_valid(self) -> None:
        data = _json(GAME / "data/animations.json")
        atlas = data["atlas"]
        width, height = atlas["width"], atlas["height"]
        self.assertEqual(data["fixture_marker"], "SYNTHETIC_FIXTURE")

        total_clips = 0
        for clips in data["clips"].values():
            for name, clip in clips.items():
                total_clips += 1
                self.assertIsInstance(clip["loop"], bool, name)
                self.assertGreater(clip["speed"], 0, name)
                frame_ids = [frame["frame_id"] for frame in clip["frames"]]
                self.assertEqual(len(frame_ids), len(set(frame_ids)), name)
                for frame in clip["frames"]:
                    x, y, frame_width, frame_height = frame["rect"]
                    self.assertGreater(frame_width, 0)
                    self.assertGreater(frame_height, 0)
                    self.assertLessEqual(x + frame_width, width)
                    self.assertLessEqual(y + frame_height, height)
                    self.assertEqual(len(frame["offset"]), 2)
                    self.assertTrue(all(0.0 <= value <= 1.0 for value in frame["origin"]))
                    self.assertGreater(frame["duration"], 0)
        self.assertEqual(total_clips, 12)

    def test_synthetic_atlas_is_deterministic_and_has_alpha(self) -> None:
        spec = importlib.util.spec_from_file_location(
            "generate_synthetic_assets",
            ROOT / "tools/fixtures/generate_synthetic_assets.py",
        )
        self.assertIsNotNone(spec)
        module = importlib.util.module_from_spec(spec)
        assert spec and spec.loader
        spec.loader.exec_module(module)

        atlas = (GAME / "assets/sprites/synthetic_pixel_atlas.png").read_bytes()
        self.assertEqual(atlas, module.build_png())
        self.assertEqual(atlas[:8], b"\x89PNG\r\n\x1a\n")
        self.assertEqual(atlas[25], 6)  # RGBA colour type
        self.assertEqual((int.from_bytes(atlas[16:20]), int.from_bytes(atlas[20:24])), (128, 128))

    def test_scenes_reference_existing_scripts_and_nodes(self) -> None:
        script_to_scene = {
            "boot.gd": "game/scenes/boot/boot.tscn",
            "main_menu.gd": "game/scenes/menu/main_menu.tscn",
            "settings.gd": "game/scenes/settings/settings.tscn",
            "character_viewer.gd": "game/scenes/viewer/character_viewer.tscn",
        }
        for script_name, scene_relative in script_to_scene.items():
            scripts = list((GAME / "scenes").rglob(script_name))
            self.assertEqual(len(scripts), 1, script_name)
            script = scripts[0]
            scene = ROOT / scene_relative
            scene_text = scene.read_text(encoding="utf-8")
            self.assertIn(script.relative_to(GAME).as_posix(), scene_text)
            for node_path in re.findall(r"\$([A-Za-z][A-Za-z0-9_/]+)", script.read_text(encoding="utf-8")):
                leaf = node_path.split("/")[-1]
                self.assertIn(f'node name="{leaf}"', scene_text, f"{script.name}: {node_path}")

    def test_export_presets_cover_both_desktop_targets(self) -> None:
        text = (GAME / "export_presets.cfg").read_text(encoding="utf-8")
        self.assertIn('name="Windows Desktop"', text)
        self.assertIn('platform="Windows Desktop"', text)
        self.assertIn('name="Linux"', text)
        self.assertIn('platform="Linux"', text)
        self.assertIn('include_filter="*.json, *.png, *.svg, *.import"', text)

    def test_restricted_assets_are_absent_from_game(self) -> None:
        forbidden = {".cpk", ".apk", ".zip", ".dat", ".bmb", ".m3r", ".ssbp", ".tpz"}
        found = [path.relative_to(ROOT).as_posix() for path in GAME.rglob("*") if path.suffix.lower() in forbidden]
        self.assertEqual(found, [])

    def test_unresolved_reference_classification_matches_report(self) -> None:
        report = _json(ROOT / "data/validation/missing-references.json")
        classification = _json(ROOT / "data/validation/unresolved-reference-classification.json")
        self.assertEqual(report["total_missing_references"], 651)
        self.assertEqual(classification["source_reference_count"], 651)
        self.assertEqual(sum(classification["by_field"].values()), 651)
        self.assertEqual(sum(classification["by_region"].values()), 651)
        self.assertEqual(sum(classification["by_field_and_region"].values()), 651)
        self.assertEqual(sum(classification["resolved_target_by_declared_type"].values()), 651)
        self.assertEqual(classification["unresolved_after_declared_catalog_check"], 0)
        self.assertTrue(classification["no_source_record_modified"])

    def test_supplemental_manifest_records_revision_and_rights(self) -> None:
        manifest = _json(ROOT / "data/manifests/supplemental-sources.json")
        self.assertEqual(manifest["status"], "supplemental_evidence_only")
        self.assertGreaterEqual(len(manifest["sources"]), 9)
        self.assertEqual(manifest["rights_gate"]["status"], "not_passed")
        for source in manifest["sources"]:
            self.assertTrue(source["url"].startswith("https://github.com/"))
            self.assertEqual(len(source["revision"]), 40)
            self.assertTrue(source["date"])
            self.assertIn("licensing", source)
            self.assertIn("limitations", source)
            self.assertIn("differences_from_phase0", source)

    def test_required_documentation_exists(self) -> None:
        required = [
            "docs/audit/supplemental-source-discovery.md",
            "docs/audit/unresolved-reference-classification.md",
            "docs/audit/animation-frame-validation-note.md",
            "docs/architecture/environment-and-engine.md",
            "docs/decisions/0001-godot-engine-and-renderer.md",
            "docs/decisions/0002-runtime-content-storage.md",
            "docs/decisions/0003-regional-identity.md",
            "docs/decisions/0004-asset-storage-and-packaging.md",
            "docs/decisions/0005-save-format-and-versioning.md",
            "docs/decisions/0006-ui-scaling.md",
            "docs/qa/test-report.md",
            "docs/qa/visual-review.md",
            "docs/qa/export-report.md",
            "docs/qa/phase1-final-report.md",
            "game/README.md",
        ]
        for relative in required:
            self.assertTrue((ROOT / relative).is_file(), relative)


if __name__ == "__main__":
    unittest.main()
