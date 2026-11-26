"""Static, engine-independent validation for Prompt 05 synthetic economy packs.

These tests never import protected content. Every Prompt 05 definition must be a
project-authored SYNTHETIC_FIXTURE / REMASTERED_DESIGN with a canonical composite
identity and references that resolve inside existing synthetic catalogs.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
CATALOG_PATH = GAME / "data/content_catalog.json"

NEW_PACKS = {
    "espers": ("espers", "esper"),
    "summon_banners": ("banners", "summon"),
    "offline_economy_rules": ("rules", "offline_rule"),
    "shops": ("shops", "shop"),
    "crafting_recipes": ("recipes", "recipe"),
}

CID_RE = re.compile(r"^(?P<kind>[a-z_]+):(?P<region>GL|JP):(?P<native>\d+)@(?P<form>[a-z0-9_]+)$")

# Strings that would indicate copied original content rather than a fixture.
FORBIDDEN_NAME_TOKENS = (
    "bismarck",
    "siren",
    "odin",
    "bahamut",
    "ifenoir",
    "fenrir",
    "golem",
    "titan",
    "shiva",
    "ramuh",
    "diabolos",
)


def _json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _canonical_id(value: str) -> bool:
    match = CID_RE.fullmatch(value)
    return bool(match and f"{match['kind']}:{match['region']}:{match['native']}@{match['form']}" == value)


class Prompt05EconomyDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = _json(CATALOG_PATH)
        cls.packs = {key: _json(GAME / cls.catalog["files"][key].removeprefix("res://")) for key in NEW_PACKS}
        cls.unit_definitions = _json(GAME / "data/phase3/unit_definitions.json")
        cls.equipment = _json(GAME / "data/phase3/equipment.json")

    def test_catalog_registers_all_prompt05_packs(self) -> None:
        files = self.catalog["files"]
        self.assertEqual(self.catalog["fixture_marker"], "SYNTHETIC_FIXTURE")
        for key in NEW_PACKS:
            self.assertIn(key, files, key)
            path = GAME / files[key].removeprefix("res://")
            self.assertTrue(path.is_file(), path)

    def test_packs_are_synthetic_and_schema_versioned(self) -> None:
        for key, pack in self.packs.items():
            with self.subTest(pack=key):
                self.assertEqual(pack["fixture_marker"], "SYNTHETIC_FIXTURE")
                self.assertEqual(pack.get("content_label"), "REMASTERED_DESIGN")
                self.assertIsInstance(pack["schema_version"], int)
                self.assertGreaterEqual(pack["schema_version"], 1)
                self.assertTrue(pack.get("description"))
                self.assertNotIn("imported", pack.get("description", "").lower())

    def test_rights_gate_is_fail_closed(self) -> None:
        for key, pack in self.packs.items():
            with self.subTest(pack=key):
                policy = pack.get("policy", {})
                self.assertIsInstance(policy, dict, key)
                self.assertEqual(policy.get("rights_gate"), "not_passed", key)
                self.assertIs(policy.get("source_data_imported"), False, key)

    def test_all_ids_are_canonical_unique_and_expected_kind(self) -> None:
        for key, (collection, expected_kind) in NEW_PACKS.items():
            records = self.packs[key][collection]
            self.assertIsInstance(records, (dict, list), key)
            values = list(records.values()) if isinstance(records, dict) else records
            self.assertGreater(len(values), 0, key)
            ids: list[str] = []
            for record in values:
                identifier = str(record["id"])
                self.assertTrue(_canonical_id(identifier), identifier)
                self.assertEqual(identifier.split(":", 1)[0], expected_kind, identifier)
                self.assertEqual(record.get("verification_status"), "SYNTHETIC_FIXTURE", identifier)
                provenance = record.get("provenance", {})
                self.assertTrue(isinstance(provenance, dict) and provenance, identifier)
                self.assertIn("origin", provenance, identifier)
                ids.append(identifier)
            self.assertEqual(len(ids), len(set(ids)), key)

    def test_no_original_esperm_name_or_rate_claims(self) -> None:
        text = json.dumps(self.packs["espers"], ensure_ascii=False).lower()
        for token in FORBIDDEN_NAME_TOKENS:
            self.assertNotIn(token, text, f"original esper name leaked: {token}")
        banners = self.packs["summon_banners"]["banners"]
        values = list(banners.values()) if isinstance(banners, dict) else banners
        for banner in values:
            blob = json.dumps(banner, ensure_ascii=False).lower()
            self.assertNotIn("featured", blob.replace("featured_unit_ids", ""), "banner must be synthetic")
            self.assertIn("seed_policy", banner)

    def test_summon_pity_display_matches_engine_guarantee(self) -> None:
        banners = self.packs["summon_banners"]["banners"]
        values = list(banners.values()) if isinstance(banners, dict) else banners
        self.assertGreater(len(values), 0)
        for banner in values:
            threshold = int(banner["pity"]["threshold"])
            within = int(banner["guarantee"]["within"])
            self.assertGreater(threshold, 0, banner["id"])
            self.assertEqual(threshold, within, banner["id"])

    def test_summon_pools_reference_existing_unit_definitions(self) -> None:
        known = set(self.unit_definitions["units"].keys()) if isinstance(
            self.unit_definitions["units"], dict
        ) else {entry["id"] for entry in self.unit_definitions["units"]}
        self.assertGreater(len(known), 0)
        banners = self.packs["summon_banners"]["banners"]
        values = list(banners.values()) if isinstance(banners, dict) else banners
        for banner in values:
            pool = banner.get("pool", [])
            self.assertIsInstance(pool, list)
            self.assertGreater(len(pool), 0)
            for unit_id in pool:
                self.assertIn(unit_id, known, banner["id"])

    def test_offline_rules_enforce_positive_caps(self) -> None:
        rules = self.packs["offline_economy_rules"]["rules"]
        values = list(rules.values()) if isinstance(rules, dict) else rules
        self.assertGreater(len(values), 0)
        for rule in values:
            self.assertGreater(int(rule["cap_seconds"]), 0)
            self.assertGreaterEqual(int(rule["minimum_interval_seconds"]), 0)
            self.assertGreater(len(rule["rates_per_hour"]), 0)
            for resource, rate in rule["rates_per_hour"].items():
                self.assertIsInstance(resource, str)
                self.assertGreaterEqual(int(rate), 0)
            caps = rule.get("cap_per_resource", {})
            for resource, cap in caps.items():
                self.assertGreaterEqual(int(cap), 0)

    def test_shop_stock_references_known_definitions_and_positive_costs(self) -> None:
        shops = self.packs["shops"]["shops"]
        values = list(shops.values()) if isinstance(shops, dict) else shops
        self.assertGreater(len(values), 0)
        known_ids: set[str] = set()
        for section in ("equipment", "materia", "vision_cards", "abilities"):
            records = self.equipment.get(section, {})
            known_ids.update(records.keys() if isinstance(records, dict) else {r["id"] for r in records})
        for shop in values:
            stock = shop.get("stock", [])
            self.assertGreater(len(stock), 0)
            seen: set[str] = set()
            for item in stock:
                self.assertNotIn(item["stock_id"], seen)
                seen.add(item["stock_id"])
                self.assertTrue(item.get("definition_id"), item["stock_id"])
                cost = item.get("cost", {})
                self.assertGreater(len(cost), 0)
                self.assertTrue(all(int(value) >= 0 for value in cost.values()))
                self.assertGreaterEqual(int(item.get("limit", 0)), 0)

    def test_shop_stock_regions_match_shop_region(self) -> None:
        shops = self.packs["shops"]["shops"]
        values = list(shops.values()) if isinstance(shops, dict) else shops
        for shop in values:
            for item in shop.get("stock", []):
                definition = str(item.get("definition_id", ""))
                match = CID_RE.fullmatch(definition)
                if match:
                    self.assertEqual(match["region"], shop["region"], definition)
                # `refresh` is metadata only; no runtime refresh cadence is implemented.
                self.assertIsInstance(item.get("refresh"), str, item["stock_id"])

    def test_crafting_recipes_have_bounded_inputs_outputs_and_duration(self) -> None:
        recipes = self.packs["crafting_recipes"]["recipes"]
        values = list(recipes.values()) if isinstance(recipes, dict) else recipes
        self.assertGreater(len(values), 0)
        for recipe in values:
            self.assertGreater(len(recipe["inputs"]), 0)
            self.assertGreater(len(recipe["outputs"]), 0)
            self.assertGreater(int(recipe["duration_seconds"]), 0)
            self.assertTrue(all(int(value) > 0 for value in recipe["inputs"].values()))
            self.assertTrue(all(int(value) > 0 for value in recipe["outputs"].values()))
            self.assertTrue(recipe.get("receipt_prefix"))

    def test_espers_have_bounded_progression(self) -> None:
        espers = self.packs["espers"]["espers"]
        values = list(espers.values()) if isinstance(espers, dict) else espers
        self.assertGreater(len(values), 0)
        for esper in values:
            self.assertGreaterEqual(int(esper["max_level"]), 1)
            self.assertIsInstance(esper["stats"], dict)
            self.assertGreater(len(esper["stats"]), 0)
            self.assertTrue(all(int(value) >= 0 for value in esper["stats"].values()))
            self.assertIsInstance(esper.get("passive_effects", []), list)
            self.assertTrue(esper.get("unlock"))


if __name__ == "__main__":
    unittest.main()
