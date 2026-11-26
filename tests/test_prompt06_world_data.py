"""Static data-contract tests for the Prompt 06 synthetic world packs.

These tests inspect repository JSON only. Gameplay, persistence and scene
behaviour are covered by the isolated headless GDScript suite.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
WORLD_DIR = GAME / "data" / "world"
CATALOG_PATH = GAME / "data" / "content_catalog.json"
BATTLES_PATH = GAME / "data" / "battles.json"
COVERAGE_PATH = ROOT / "data" / "validation" / "localization-coverage.json"
AUDIT_PATH = ROOT / "docs" / "audit" / "prompt06-world-story-source-audit.md"
LOCALES = ("vi", "en", "ja")

PACK_SECTIONS = {
    "regions.json": ("world_regions", "regions", "region"),
    "locations.json": ("world_locations", "locations", "location"),
    "location_connections.json": ("world_connections", "connections", "connection"),
    "interactables.json": (
        "world_interactables", "interactables",
        {"npc", "treasure", "encounter_trigger", "exit"},
    ),
    "dialogues.json": ("world_dialogues", "dialogues", "dialogue"),
    "quests.json": ("world_quests", "quests", "quest"),
}

ID_PATTERN = re.compile(
    r"^(region|loc|connection|npc|treasure|encounter_trigger|exit|dialogue|quest)"
    r":(GL|JP):\d+@[a-z0-9_]+$"
)
TOKEN_PATTERN = re.compile(r"^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$")
RESOURCE_ID_PATTERN = re.compile(r"^(fragment|item|material):(GL|JP):\d+@[a-z0-9_]+$")

REQUIRED_PATHS = (
    "game/scenes/world/world_map.tscn",
    "game/scenes/world/exploration_area.tscn",
    "game/scenes/world/dialogue_panel.tscn",
    "game/world/exploration_controller.gd",
    "game/world/exploration_area.gd",
    "game/world/interaction_controller.gd",
    "game/world/dialogue_manager.gd",
    "game/world/dialogue_repository.gd",
    "game/world/quest_manager.gd",
    "game/world/quest_repository.gd",
    "game/data/world/dialogues.json",
    "game/data/world/quests.json",
    "docs/architecture/world-exploration.md",
    "docs/data-dictionary/world-story-schema.md",
    "docs/qa/prompt06-visual-review.md",
    "docs/qa/prompt06-final-report.md",
)


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


class Prompt06WorldDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.packs = {name: load_json(WORLD_DIR / name) for name in PACK_SECTIONS}
        cls.battles = load_json(BATTLES_PATH)
        cls.catalog = load_json(CATALOG_PATH)

    def records(self, filename: str) -> list[dict[str, Any]]:
        _, section, _ = PACK_SECTIONS[filename]
        return self.packs[filename][section]

    def test_required_files_exist(self) -> None:
        for relative in REQUIRED_PATHS:
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_catalog_registers_every_world_pack(self) -> None:
        files: dict[str, str] = self.catalog["files"]
        for filename, (catalog_key, _, _) in PACK_SECTIONS.items():
            self.assertEqual(files[catalog_key], f"res://data/world/{filename}")
            self.assertTrue((GAME / "data" / "world" / filename).is_file(), filename)

    def test_pack_policy_is_synthetic_and_rights_gated(self) -> None:
        for filename, pack in self.packs.items():
            with self.subTest(pack=filename):
                self.assertEqual(pack["schema_version"], 1)
                self.assertEqual(pack["fixture_marker"], "SYNTHETIC_FIXTURE")
                policy = pack["policy"]
                self.assertEqual(policy["rights_gate"], "not_passed")
                self.assertFalse(policy["source_data_imported"])
                self.assertEqual(policy["evidence_class"], "REMASTERED_DESIGN")

    def test_stable_ids_and_provenance(self) -> None:
        seen: set[str] = set()
        for filename, (_, _, expected_kind) in PACK_SECTIONS.items():
            for record in self.records(filename):
                with self.subTest(record=record.get("id")):
                    identifier = record["id"]
                    self.assertRegex(identifier, ID_PATTERN)
                    self.assertNotIn(identifier, seen)
                    seen.add(identifier)
                    prefix, region, native, form = re.split(r"[:@]", identifier)
                    if isinstance(expected_kind, set):
                        self.assertIn(prefix, expected_kind)
                    else:
                        expected_prefix = "loc" if expected_kind == "location" else expected_kind
                        self.assertEqual(prefix, expected_prefix)
                    self.assertEqual(region, "GL")
                    self.assertEqual(record["kind"], expected_kind if isinstance(expected_kind, str) else prefix)
                    self.assertEqual(record["region"], region)
                    self.assertEqual(record["native_id"], native)
                    self.assertEqual(record["form"], form)
                    self.assertEqual(record["verification_status"], "REMASTERED_DESIGN")
                    provenance = record["provenance"]
                    self.assertEqual(provenance["origin"], "remastered_design")
                    self.assertEqual(provenance["source"], "prompt06-synthetic-world")
                    self.assertEqual(provenance["license"], "project-authored")
                    self.assertEqual(provenance["rights_gate"], "not_passed")

    def test_region_and_connection_graph(self) -> None:
        regions = {record["id"]: record for record in self.records("regions.json")}
        locations = {record["id"]: record for record in self.records("locations.json")}
        connections = self.records("location_connections.json")
        quest_ids = {record["id"] for record in self.records("quests.json")}
        encounters = self.battles["encounters"]

        self.assertEqual(len(regions), 1)
        self.assertEqual(len(locations), 3)
        self.assertEqual(len(connections), 2)
        for region in regions.values():
            self.assertIn(region["start_location"], locations)
            self.assertTrue(TOKEN_PATTERN.match(region["name_key"]))
            self.assertTrue(TOKEN_PATTERN.match(region["description_key"]))
            self.assertTrue(region["background_ref"])
        for identifier, location in locations.items():
            with self.subTest(location=identifier):
                self.assertIn(location["region_id"], regions)
                self.assertIn(location["location_kind"], {"town", "field", "dungeon", "boss"})
                self.assertTrue(TOKEN_PATTERN.match(location["name_key"]))
                self.assertTrue(TOKEN_PATTERN.match(location["description_key"]))
                self.assertTrue(location["background_ref"])
                self.assertTrue(0.0 <= location["map_position"]["x"] <= 1.0)
                self.assertTrue(0.0 <= location["map_position"]["y"] <= 1.0)
                for quest in location["unlock_requirements"].get("quests", []):
                    self.assertIn(quest, quest_ids)
                if location["encounter_id"]:
                    self.assertIn(location["encounter_id"], encounters)

        pairs = {
            frozenset((connection["from"], connection["to"])): connection
            for connection in connections
        }
        self.assertEqual(len(pairs), 2)
        self.assertIn(frozenset(("loc:GL:1101@haven", "loc:GL:1102@meadow")), pairs)
        self.assertIn(frozenset(("loc:GL:1102@meadow", "loc:GL:1103@spire")), pairs)
        self.assertNotIn(frozenset(("loc:GL:1101@haven", "loc:GL:1103@spire")), pairs)
        for connection in connections:
            self.assertNotEqual(connection["from"], connection["to"])
            self.assertIn(connection["from"], locations)
            self.assertIn(connection["to"], locations)
            required = connection["requirement"]["location_id"]
            self.assertIn(required, locations)

    def test_interactable_contracts(self) -> None:
        locations = {record["id"] for record in self.records("locations.json")}
        dialogues = {record["id"] for record in self.records("dialogues.json")}
        encounters = self.battles["encounters"]
        items = self.battles["items"]
        interactables = self.records("interactables.json")
        self.assertEqual(len(interactables), 9)
        for record in interactables:
            with self.subTest(interactable=record["id"]):
                self.assertIn(record["area_id"], locations)
                self.assertIn(record["kind"], {"npc", "treasure", "encounter_trigger", "exit"})
                self.assertIn(record["interaction_policy"], {"one_time", "repeatable"})
                self.assertTrue(TOKEN_PATTERN.match(record["name_key"]))
                self.assertTrue(TOKEN_PATTERN.match(record["prompt_key"]))
                self.assertTrue(0 <= record["position"]["x"] <= 1280)
                self.assertTrue(0 <= record["position"]["y"] <= 720)
                self.assertGreater(record["radius"], 0)
                if record["kind"] == "npc":
                    self.assertIn(record["dialogue_id"], dialogues)
                elif record["kind"] == "treasure":
                    self.assertEqual(record["interaction_policy"], "one_time")
                    self.assertGreater(record["reward"]["gil"], 0)
                    for item in record["reward"]["items"]:
                        self.assertRegex(item, RESOURCE_ID_PATTERN)
                        self.assertTrue(item in items or item.startswith("fragment:GL:"))
                elif record["kind"] == "encounter_trigger":
                    self.assertIn(record["encounter_id"], encounters)
                else:
                    destination = record["destination"]
                    self.assertTrue(destination == "world_map" or destination in locations)
        chest = next(record for record in interactables if record["id"] == "treasure:GL:4101@meadow")
        self.assertEqual(chest["reward"]["gil"], 150)
        self.assertEqual(chest["reward"]["items"], ["fragment:GL:910101@base"])

    def test_dialogue_graphs_and_consequences(self) -> None:
        quest_ids = {record["id"] for record in self.records("quests.json")}
        dialogues = self.records("dialogues.json")
        self.assertEqual(len(dialogues), 2)
        for dialogue in dialogues:
            with self.subTest(dialogue=dialogue["id"]):
                node_ids = [node["id"] for node in dialogue["nodes"]]
                self.assertEqual(len(node_ids), len(set(node_ids)))
                self.assertIn(dialogue["start_node"], node_ids)
                self.assertTrue(TOKEN_PATTERN.match(dialogue["speaker_key"]))
                self.assertTrue(dialogue["portrait_ref"])
                for node in dialogue["nodes"]:
                    for line in node["lines"]:
                        key = line["key"] if isinstance(line, dict) else line
                        self.assertTrue(TOKEN_PATTERN.match(key), key)
                        if isinstance(line, dict) and "when" in line:
                            self.assertIn(line["when"]["quest_id"], quest_ids)
                    for choice in node["choices"]:
                        self.assertTrue(TOKEN_PATTERN.match(choice["label_key"]))
                        if "when" in choice:
                            self.assertIn(choice["when"]["quest_id"], quest_ids)
                        for effect in choice["effects"]:
                            self.assertIn(effect["type"], {
                                "flag", "quest_accept", "quest_event", "unlock_location"
                            })
                            if effect["type"] == "quest_accept":
                                self.assertIn(effect["quest_id"], quest_ids)
        keeper = next(record for record in dialogues if record["id"] == "dialogue:GL:2101@keeper")
        intro = next(node for node in keeper["nodes"] if node["id"] == "intro")
        accept = next(choice for choice in intro["choices"] if choice["id"] == "accept_oath")
        effects = accept["effects"]
        self.assertIn({"type": "quest_accept", "quest_id": "quest:GL:3100@oath"}, effects)
        self.assertIn({
            "type": "quest_event",
            "event": {"type": "talk_to", "target": "npc:GL:2101@keeper", "count": 1},
        }, effects)
        scout = next(record for record in dialogues if record["id"] == "dialogue:GL:2102@scout")
        scout_lines = scout["nodes"][0]["lines"]
        self.assertEqual(
            {line["key"] for line in scout_lines if isinstance(line, dict)},
            {"dialogue.scout.active", "dialogue.scout.intro", "dialogue.scout.done"},
        )

    def test_quest_graph_and_rewards(self) -> None:
        quests = self.records("quests.json")
        quest_ids = {record["id"] for record in quests}
        locations = {record["id"] for record in self.records("locations.json")}
        interactables = {record["id"] for record in self.records("interactables.json")}
        encounters = self.battles["encounters"]
        items = self.battles["items"]
        self.assertEqual(len(quests), 2)
        for quest in quests:
            with self.subTest(quest=quest["id"]):
                self.assertTrue(TOKEN_PATTERN.match(quest["name_key"]))
                self.assertTrue(TOKEN_PATTERN.match(quest["description_key"]))
                for prerequisite in quest["prerequisites"].get("quests", []):
                    self.assertIn(prerequisite, quest_ids)
                objective_ids = [objective["id"] for objective in quest["objectives"]]
                self.assertEqual(len(objective_ids), len(set(objective_ids)))
                for objective in quest["objectives"]:
                    self.assertTrue(TOKEN_PATTERN.match(objective["description_key"]))
                    self.assertGreaterEqual(objective["count"], 1)
                    target = objective["target"]
                    objective_type = objective["type"]
                    if objective_type == "talk_to":
                        self.assertIn(target, interactables)
                    elif objective_type == "visit_location":
                        self.assertIn(target, locations)
                    elif objective_type == "defeat_encounter":
                        self.assertIn(target, encounters)
                    elif objective_type == "open_treasure":
                        self.assertIn(target, interactables)
                    elif objective_type == "collect":
                        self.assertRegex(target, RESOURCE_ID_PATTERN)
                    elif objective_type == "complete_quest":
                        self.assertIn(target, quest_ids)
                    else:
                        self.fail(f"unknown objective type {objective_type}")
                self.assertGreater(quest["rewards"]["gil"], 0)
                for item in quest["rewards"]["items"]:
                    self.assertIn(item, items)
                for unlock in quest["unlocks"]:
                    self.assertIn(unlock, locations)

    def test_localization_keys_cover_world_data(self) -> None:
        report = load_json(COVERAGE_PATH)
        keys = report["world_data_scan"]["literal_keys"]
        self.assertGreater(len(keys), 0)
        self.assertEqual(keys, sorted(keys))
        for locale in LOCALES:
            dictionary = load_json(ROOT / "game" / "data" / "localization" / f"{locale}.json")
            for key in keys:
                self.assertIn(key, dictionary, (locale, key))
                self.assertTrue(dictionary[key], (locale, key))
        for key in ("dialogue.scout.line2", "quest.oath.title", "world.prompt.open"):
            self.assertIn(key, keys)

    def test_no_restricted_source_material(self) -> None:
        forbidden = ("final fantasy", "square enix", "protected story", "copyright")
        for path in sorted(WORLD_DIR.glob("*.json")):
            text = path.read_text(encoding="utf-8").lower()
            for phrase in forbidden:
                self.assertNotIn(phrase, text, (path.name, phrase))
            self.assertNotIn('"region": "JP"', text, path.name)
        self.assertTrue(AUDIT_PATH.is_file())
        audit = AUDIT_PATH.read_text(encoding="utf-8").lower()
        self.assertIn("not_passed", audit)
        self.assertIn("synthetic", audit)


if __name__ == "__main__":
    unittest.main()
