"""Static and CLI tests for the Phase 3 localization dictionaries and tooling."""

from __future__ import annotations

import importlib.util
import json
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DICT_DIR = ROOT / "game/data/localization"
REPORT_PATH = ROOT / "data/validation/localization-coverage.json"
TOOL_PATH = ROOT / "tools/localization/coverage_report.py"
TOKEN_MANIFEST_PATH = ROOT / "game/data/phase3/localization_tokens.json"
LOCALES = ("en", "ja", "vi")
EXPECTED_KEY_COUNT = 917
EXPECTED_WORLD_DATA_KEY_COUNT = 45
EXPECTED_EVENT_DATA_KEY_COUNT = 33
EXPECTED_DYNAMIC_MAPPING_COUNT = 305
EXPECTED_DYNAMIC_KEY_COUNT = 280

VI_TERMS = (
    "Nhân vật",
    "Đội hình",
    "Trang bị",
    "Kho đồ",
    "Thức tỉnh",
    "Cường hóa",
    "Triệu hồi",
    "Kỹ năng",
    "Kỹ năng bị động",
    "Chuỗi liên kích",
    "Kháng nguyên tố",
    "Mảnh nhân vật",
    "Chiến thắng",
    "Thất bại",
)
JA_TERMS = (
    "キャラクター",
    "編成",
    "装備",
    "覚醒",
    "強化",
    "召喚",
    "アビリティ",
    "パッシブ",
    "チェイン",
    "属性耐性",
    "欠片",
    "勝利",
    "敗北",
    "ギル",
)
LOCKED_TOKENS = ("NV", "EX", "TMR", "STMR", "LB", "SLB", "gil")

PLACEHOLDER_SAMPLES = {
    "settings.path": ("{path}",),
    "settings.locale_changed": ("{locale}",),
    "collection.copy_count": ("{count}",),
    "upgrade.gain_exp": ("{amount}",),
    "upgrade.level_cap": ("{cap}",),
    "awakening.star": ("{star}",),
    "party.slot": ("{slot}",),
    "party.build_summary": ("{count}",),
    "battle.turn": ("{turn}",),
    "party.error.empty_slot": ("{slot}",),
    "party.error.duplicate": ("{id}",),
}


def _load_module() -> Any:
    spec = importlib.util.spec_from_file_location("coverage_report", TOOL_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_fixture(root: Path, dictionaries: dict[str, dict[str, str]], gd_text: str = "") -> None:
    dictionary_dir = root / "game/data/localization"
    dictionary_dir.mkdir(parents=True, exist_ok=True)
    for locale, payload in dictionaries.items():
        (dictionary_dir / f"{locale}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    if gd_text:
        script = root / "game/scenes/fixture.gd"
        script.parent.mkdir(parents=True, exist_ok=True)
        script.write_text(gd_text, encoding="utf-8")


def _run_cli(root: Path, output: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(TOOL_PATH), "--root", str(root), "--output", str(output)],
        capture_output=True,
        text=True,
        check=False,
    )


class Phase3LocalizationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tool = _load_module()
        cls.dictionaries = {locale: _json(DICT_DIR / f"{locale}.json") for locale in LOCALES}
        cls.token_manifest = _json(TOKEN_MANIFEST_PATH)
        cls.report = _json(REPORT_PATH)

    def test_dictionary_contract_and_key_parity(self) -> None:
        key_sets = []
        for locale in LOCALES:
            dictionary = self.dictionaries[locale]
            self.assertIsInstance(dictionary, dict, locale)
            self.assertEqual(len(dictionary), EXPECTED_KEY_COUNT, locale)
            self.assertEqual(list(dictionary), sorted(dictionary), locale)
            for key, value in dictionary.items():
                self.assertIsInstance(key, str, f"{locale}: {key!r}")
                self.assertIsInstance(value, str, f"{locale}: {key}")
                self.assertTrue(value, f"{locale}: {key}")
            key_sets.append(set(dictionary))

        self.assertEqual(key_sets[0], key_sets[1])
        self.assertEqual(key_sets[1], key_sets[2])
        for key in (
            "app.title",
            "common.victory",
            "menu.collection",
            "details.fragments",
            "battle.chain",
            "upgrade.title",
            "awakening.title",
            "party.title",
            "passive.vanguard.name",
            "vision.synthetic_arcane.name",
        ):
            self.assertIn(key, key_sets[0], key)

    def test_placeholder_parity(self) -> None:
        extract = self.tool.extract_placeholders
        for key in sorted(self.dictionaries["en"]):
            signatures = {
                locale: extract(self.dictionaries[locale][key]) for locale in LOCALES
            }
            self.assertEqual(len(set(signatures.values())), 1, f"{key}: {signatures}")

        for key, expected in PLACEHOLDER_SAMPLES.items():
            for locale in LOCALES:
                self.assertEqual(
                    extract(self.dictionaries[locale][key]), expected, f"{locale}: {key}"
                )

    def test_vietnamese_diacritics_and_required_terms(self) -> None:
        vi = self.dictionaries["vi"]
        with_diacritics = sum(
            1 for value in vi.values() if self.tool.has_vietnamese_diacritic(value)
        )
        self.assertGreaterEqual(with_diacritics / len(vi), 0.9)
        text = "\n".join(vi.values())
        for term in VI_TERMS:
            self.assertIn(term, text, term)
        for token in LOCKED_TOKENS:
            self.assertIn(token, text, token)
        self.assertRegex(vi["common.uid"], r"^\D")
        self.assertIn("{turn}", vi["battle.turn"])

    def test_japanese_glyphs(self) -> None:
        ja = self.dictionaries["ja"]
        for key, value in ja.items():
            self.assertTrue(self.tool.has_japanese_glyph(value), f"{key}: {value}")
        text = "\n".join(ja.values())
        for term in JA_TERMS:
            self.assertIn(term, text, term)
        self.assertIn("（", ja["details.tmr"])
        self.assertIn("（", ja["battle.limit"])
        for key, value in ja.items():
            self.assertFalse(value.isascii(), f"{key}: romaji-only placeholder")

    def test_dynamic_token_manifest(self) -> None:
        manifest = self.token_manifest
        self.assertEqual(manifest["fixture_marker"], "SYNTHETIC_FIXTURE")
        categories = manifest["categories"]
        self.assertIsInstance(categories, dict)
        mappings = [value for value in categories.values() if isinstance(value, dict)]
        mapping_count = sum(len(mapping) for mapping in mappings)
        self.assertEqual(mapping_count, EXPECTED_DYNAMIC_MAPPING_COUNT)

        dynamic_keys = {key for mapping in mappings for key in mapping.values()}
        self.assertEqual(len(dynamic_keys), EXPECTED_DYNAMIC_KEY_COUNT)
        for locale in LOCALES:
            missing = sorted(key for key in dynamic_keys if key not in self.dictionaries[locale])
            self.assertEqual(missing, [], locale)

        dynamic = self.report["dynamic_references"]
        self.assertEqual(dynamic["manifest_file"], "game/data/phase3/localization_tokens.json")
        self.assertEqual(dynamic["mapping_count"], EXPECTED_DYNAMIC_MAPPING_COUNT)
        self.assertEqual(dynamic["reference_count"], EXPECTED_DYNAMIC_KEY_COUNT)
        self.assertEqual(dynamic["manifest_errors"], [])
        self.assertEqual(dynamic["missing_keys"], [])
        self.assertEqual(self.report["blocking"]["dynamic_reference_error_count"], 0)
        for locale in LOCALES:
            unused = set(self.report["per_locale"][locale]["unused_keys"])
            self.assertEqual(unused & dynamic_keys, set(), locale)

    def test_hardening_keys_and_translated_search(self) -> None:
        expected_keys = (
            "common.diagnostic",
            "common.failed",
            "reason.already_claimed",
            "reason.invalid_receipt",
            "reason.region_mismatch",
            "reason.insufficient_resources",
            "verification.synthetic_fixture",
            "mechanic.name.brave_shift",
            "evidence.note.brave_shift",
            "code.stat.hp",
            "code.slot.weapon",
            "code.region.gl",
            "resource.gil",
            "resource.trust_moogle",
            "unit.synthetic.astra_gl.name",
            "viewer.clip.idle",
            "viewer.clip.victory",
            "ability.synthetic.starlight_slash.name",
        )
        for locale in LOCALES:
            for key in expected_keys:
                self.assertIn(key, self.dictionaries[locale], f"{locale}: {key}")

        self.assertEqual(self.dictionaries["en"]["code.stat.hp"], "HP")
        self.assertIn("Vũ khí", self.dictionaries["vi"]["code.slot.weapon"])
        self.assertIn("武器", self.dictionaries["ja"]["code.slot.weapon"])
        self.assertIn("Technical", self.dictionaries["en"]["common.diagnostic"])
        self.assertIn("{slot}", self.dictionaries["vi"]["party.error.empty_slot"])
        self.assertIn("（", self.dictionaries["ja"]["code.region.gl"])

        manager = (ROOT / "game/core/locale_manager.gd").read_text(encoding="utf-8")
        for helper in (
            "func token(", "func has_token(", "func identified(",
            "func diagnostic_text(", "func filter_value_label(",
            "func reason_label(", "func mechanic_note(", "func unit_name(",
        ):
            self.assertIn(helper, manager, helper)

        collection = (ROOT / "game/scenes/phase3/collection.gd").read_text(encoding="utf-8")
        self.assertIn("LocaleManager.filter_value_label(key, value)", collection)
        self.assertIn("LocaleManager.region_label(region).to_lower()", collection)
        self.assertIn("LocaleManager.category_label(value).to_lower()", collection)

        owned_scenes = list((ROOT / "game/scenes/phase3").glob("*.gd")) + [
            ROOT / "game/scenes/viewer/character_viewer.gd"
        ]
        for path in owned_scenes:
            text = path.read_text(encoding="utf-8")
            self.assertNotIn("LocaleManager.t(text)", text, path.as_posix())

    def test_glossary_and_guide_documentation(self) -> None:
        glossary = (ROOT / "docs/localization/glossary.md").read_text(encoding="utf-8")
        guide = (ROOT / "docs/localization/translation-guide.md").read_text(encoding="utf-8")
        coverage_doc = (ROOT / "docs/localization/coverage-report.md").read_text(encoding="utf-8")

        for term in VI_TERMS:
            self.assertIn(term, glossary, term)
        for token in LOCKED_TOKENS:
            self.assertIn(token, glossary, token)
        self.assertIn("SYNTHETIC_FIXTURE", glossary)
        self.assertIn("python3 tools/localization/coverage_report.py", guide)
        self.assertIn("python3 -m unittest tests.test_phase3_localization -v", guide)
        self.assertIn("vi is the default locale", guide.lower().replace("`vi`", "vi"))
        self.assertIn("localization_tokens.json", guide)
        self.assertIn("developer diagnostic", guide.lower())
        self.assertNotIn("translation is complete", guide.lower())
        notes = (ROOT / "docs/qa/phase3-hardening-localization-notes.md").read_text(encoding="utf-8")
        self.assertIn("dynamic-reference", notes.lower())
        self.assertIn("Prompt 05", notes)
        self.assertIn("SYNTHETIC_FIXTURE", notes)

        report = self.report
        self.assertIn("`pass`", coverage_doc)
        self.assertIn(str(report["union_key_count"]), coverage_doc)
        self.assertIn(f"`{report['vietnamese_diacritics']['coverage']}`", coverage_doc)
        self.assertIn(f"`{report['japanese_glyphs']['coverage']}`", coverage_doc)
        self.assertIn("coverage_report.py", coverage_doc)

    def test_world_data_key_scan(self) -> None:
        scan = self.report["world_data_scan"]
        self.assertEqual(scan["data_files_scanned"], 6)
        for name in (
            "dialogues.json", "interactables.json", "location_connections.json",
            "locations.json", "quests.json", "regions.json",
        ):
            self.assertIn(f"game/data/world/{name}", scan["data_files"])
        self.assertEqual(len(scan["literal_keys"]), EXPECTED_WORLD_DATA_KEY_COUNT)
        self.assertEqual(scan["literal_keys"], sorted(scan["literal_keys"]))
        for key in (
            "dialogue.scout.line2",
            "quest.oath.title",
            "world.location.haven.name",
            "world.prompt.open",
        ):
            self.assertIn(key, scan["literal_keys"])
        for locale in LOCALES:
            missing = [key for key in scan["literal_keys"] if key not in self.dictionaries[locale]]
            self.assertEqual(missing, [], locale)
            self.assertEqual(self.report["per_locale"][locale]["missing_keys"], [])

    def test_event_data_key_scan(self) -> None:
        scan = self.report["event_data_scan"]
        self.assertEqual(scan["data_files_scanned"], 1)
        self.assertEqual(scan["data_files"], ["game/data/events/events.json"])
        self.assertEqual(len(scan["literal_keys"]), EXPECTED_EVENT_DATA_KEY_COUNT)
        self.assertEqual(scan["literal_keys"], sorted(scan["literal_keys"]))
        for key in (
            "event.stargarden.name",
            "event.mission.clear_gate",
            "event.stage.gate",
            "event.art.stargarden",
            "event.guest.lumen.name",
            "event.stage.training",
        ):
            self.assertIn(key, scan["literal_keys"])
        for locale in LOCALES:
            missing = [key for key in scan["literal_keys"] if key not in self.dictionaries[locale]]
            self.assertEqual(missing, [], locale)
            self.assertEqual(self.report["per_locale"][locale]["missing_keys"], [])

    def test_generated_report_matches_tool_serialization(self) -> None:
        report = self.report
        self.assertEqual(report["schema_version"], self.tool.SCHEMA_VERSION)
        self.assertEqual(report["tool_version"], self.tool.TOOL_VERSION)
        self.assertEqual(report["status"], "pass")
        self.assertEqual(report["blocking"]["missing_key_count"], 0)
        self.assertEqual(report["blocking"]["placeholder_mismatch_count"], 0)
        self.assertEqual(report["union_key_count"], EXPECTED_KEY_COUNT)
        self.assertEqual(report["blocking"]["dynamic_reference_error_count"], 0)
        self.assertEqual(report["placeholder_mismatches"], [])
        self.assertGreaterEqual(report["vietnamese_diacritics"]["coverage"], 0.9)
        self.assertEqual(report["japanese_glyphs"]["coverage"], 1.0)
        for locale in LOCALES:
            detail = report["per_locale"][locale]
            self.assertEqual(detail["key_count"], EXPECTED_KEY_COUNT)
            self.assertEqual(detail["missing_keys"], [])
            self.assertEqual(detail["missing_keys"], sorted(detail["missing_keys"]))
            self.assertEqual(detail["unused_keys"], sorted(detail["unused_keys"]))
        text = REPORT_PATH.read_text(encoding="utf-8")
        self.assertEqual(text, self.tool.render_report(report))

    def test_cli_exit_codes_and_source_scan(self) -> None:
        base = {
            locale: {"app.title": "Title", "common.back": "Back"} for locale in LOCALES
        }
        gd_text = 'L.t("app.title")\nLocaleManager.t( \'common.back\' )\n'

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = root / "report.json"
            _write_fixture(root, base, gd_text)

            result = _run_cli(root, output)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("status: pass", result.stdout)
            report = _json(output)
            self.assertEqual(report["source_scan"]["literal_keys"], ["app.title", "common.back"])
            self.assertEqual(report["source_scan"]["translation_call_sites"], 2)
            self.assertEqual(report["per_locale"]["ja"]["unused_keys"], [])

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = root / "report.json"
            missing = {locale: dict(values) for locale, values in base.items()}
            del missing["ja"]["common.back"]
            _write_fixture(root, missing, gd_text)

            result = _run_cli(root, output)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn("status: fail", result.stdout)
            report = _json(output)
            self.assertGreater(report["blocking"]["missing_key_count"], 0)
            self.assertIn("common.back", report["per_locale"]["ja"]["missing_keys"])

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = root / "report.json"
            mismatched = {locale: dict(values) for locale, values in base.items()}
            mismatched["ja"]["common.back"] = "戻る %d"
            _write_fixture(root, mismatched, gd_text)

            result = _run_cli(root, output)
            self.assertEqual(result.returncode, 1, result.stderr)
            report = _json(output)
            self.assertEqual(report["blocking"]["missing_key_count"], 0)
            self.assertEqual(report["blocking"]["placeholder_mismatch_count"], 1)
            self.assertEqual(report["placeholder_mismatches"][0]["key"], "common.back")

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = root / "report.json"
            _write_fixture(root, base, gd_text + 'L.t("menu.unknown")\n')

            result = _run_cli(root, output)
            self.assertEqual(result.returncode, 1, result.stderr)
            report = _json(output)
            for locale in LOCALES:
                self.assertIn("menu.unknown", report["per_locale"][locale]["missing_keys"])

    def test_cli_dynamic_manifest_evidence(self) -> None:
        dictionaries = {
            locale: {"app.title": "Title", "code.region.gl": "GL"} for locale in LOCALES
        }
        manifest = {
            "schema_version": 1,
            "categories": {"region": {"GL": "code.region.gl"}},
        }
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = root / "report.json"
            _write_fixture(root, dictionaries, 'L.t("app.title")\n')
            token_dir = root / "game/data/phase3"
            token_dir.mkdir(parents=True, exist_ok=True)
            (token_dir / "localization_tokens.json").write_text(
                json.dumps(manifest, ensure_ascii=False), encoding="utf-8"
            )

            result = _run_cli(root, output)
            self.assertEqual(result.returncode, 0, result.stderr)
            report = _json(output)
            self.assertEqual(report["dynamic_references"]["reference_count"], 1)
            self.assertEqual(report["dynamic_references"]["mapping_count"], 1)
            self.assertEqual(report["per_locale"]["en"]["unused_keys"], [])
            self.assertEqual(report["blocking"]["dynamic_reference_error_count"], 0)

            (token_dir / "localization_tokens.json").write_text(
                '{invalid json', encoding="utf-8"
            )
            result = _run_cli(root, output)
            self.assertEqual(result.returncode, 1, result.stderr)
            report = _json(output)
            self.assertEqual(report["status"], "fail")
            self.assertEqual(report["blocking"]["dynamic_reference_error_count"], 1)
            self.assertTrue(report["dynamic_references"]["manifest_errors"])

    def test_report_is_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            dictionaries = {
                locale: {
                    "app.title": "Title",
                    "common.back": "Back %s",
                    "settings.path": "Path: {path}",
                }
                for locale in LOCALES
            }
            dictionaries["ja"]["common.back"] = "戻る %s"
            dictionaries["vi"]["common.back"] = "Quay lại %s"
            _write_fixture(
                root,
                dictionaries,
                'L.t("app.title")\nLocaleManager.t("common.back")\n',
            )

            first = root / "first.json"
            second = root / "second.json"
            self.assertEqual(_run_cli(root, first).returncode, 0)
            self.assertEqual(_run_cli(root, second).returncode, 0)
            first_bytes = first.read_bytes()
            second_bytes = second.read_bytes()
            self.assertEqual(first_bytes, second_bytes)
            self.assertEqual(
                first_bytes.decode("utf-8"), self.tool.render_report(_json(first))
            )

            built_once = self.tool.render_report(self.tool.build_report(root))
            built_twice = self.tool.render_report(self.tool.build_report(root))
            self.assertEqual(built_once, built_twice)
            self.assertEqual(built_once.encode("utf-8"), first_bytes)


if __name__ == "__main__":
    unittest.main()
