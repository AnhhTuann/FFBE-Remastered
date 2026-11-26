"""Static data-contract tests for the Prompt 07 synthetic Event Center packs.

Gameplay, persistence, navigation and UI behaviour are covered by the isolated
headless GDScript suite. These tests inspect repository JSON only and never
require network access, owner saves or protected source data.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
EVENTS_PATH = GAME / "data" / "events" / "events.json"
CATALOG_PATH = GAME / "data" / "content_catalog.json"
BATTLES_PATH = GAME / "data" / "battles.json"
SHOPS_PATH = GAME / "data" / "phase3" / "shops.json"
SUMMON_PATH = GAME / "data" / "phase3" / "summon_banners.json"
DICT_DIR = GAME / "data" / "localization"
PLAYER_STATE_PATH = GAME / "core" / "player_state.gd"
LOCALES = ("vi", "en", "ja")

ID_RE = re.compile(r"^(?P<kind>[a-z_]+):(?P<region>GL|JP):(?P<native>\d+)@(?P<form>[a-z0-9_]+)$")
PROTECTED_TERMS = (
    "fina", "rain", "lasswell", "charlotte", "elvlin", "cleome",
    "dawn warrior", "circle", "warrior of light",
)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def parse_id(identifier: str, kind: str) -> dict[str, str]:
    match = ID_RE.match(identifier)
    if match is None or match.group("kind") != kind:
        raise AssertionError(f"{identifier!r} is not a valid {kind} identity")
    return match.groupdict()


class Prompt07EventDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.events_pack = load_json(EVENTS_PATH)
        cls.catalog = load_json(CATALOG_PATH)
        cls.battles = load_json(BATTLES_PATH)
        cls.shops = load_json(SHOPS_PATH)
        cls.banners = load_json(SUMMON_PATH)
        cls.dictionaries = {locale: load_json(DICT_DIR / f"{locale}.json") for locale in LOCALES}
        cls.events = cls.events_pack["events"]
        cls.stages = cls.events_pack["stages"]
        cls.event_by_id = {event["id"]: event for event in cls.events}
        cls.stage_by_id = {stage["id"]: stage for stage in cls.stages}
        cls.shop_by_id = {shop["id"]: shop for shop in cls.shops["shops"]}
        cls.banner_by_id = {banner["id"]: banner for banner in cls.banners["banners"]}

    def test_catalog_registration_and_fixture_policy(self) -> None:
        self.assertEqual(self.catalog.get("fixture_marker"), "SYNTHETIC_FIXTURE")
        self.assertEqual(self.catalog["files"].get("events"), "res://data/events/events.json")
        self.assertEqual(self.events_pack.get("schema_version"), 1)
        self.assertEqual(self.events_pack.get("fixture_marker"), "SYNTHETIC_FIXTURE")
        policy = self.events_pack["policy"]
        self.assertEqual(policy["rights_gate"], "not_passed")
        self.assertFalse(policy["source_data_imported"])
        self.assertEqual(policy["evidence_class"], "REMASTERED_DESIGN")
        self.assertEqual(len(self.events), 6)
        self.assertEqual(len(self.stages), 8)

    def test_stable_region_aware_identities(self) -> None:
        all_ids = [event["id"] for event in self.events] + [stage["id"] for stage in self.stages]
        self.assertEqual(len(all_ids), len(set(all_ids)))
        for event in self.events:
            parts = parse_id(event["id"], "event")
            self.assertEqual(event["kind"], "event")
            self.assertEqual(event["region"], parts["region"])
            self.assertEqual(event["native_id"], parts["native"])
            self.assertEqual(event["form"], parts["form"])
            self.assertTrue(event["id"].startswith(f"event:{parts['region']}:"))
            for region in event["regions"]:
                self.assertIn(region, ("GL", "JP"))
        for stage in self.stages:
            parts = parse_id(stage["id"], "stage")
            self.assertEqual(stage["kind"], "event_stage")
            self.assertEqual(stage["region"], parts["region"])
            self.assertEqual(stage["native_id"], parts["native"])
            self.assertEqual(stage["form"], parts["form"])
            event_parts = parse_id(stage["event_id"], "event")
            self.assertEqual(event_parts["region"], parts["region"])

    def test_event_contract_fields(self) -> None:
        for event in self.events:
            for field in (
                "name_key", "description_key", "regions", "availability", "unlock",
                "stage_ids", "event_currency", "shop_ref", "banner_ref",
                "boss_encounter", "replay_policy", "missions", "shop", "art",
                "guests", "provenance", "verification_status",
            ):
                self.assertIn(field, event, f"{event['id']}: {field}")
            self.assertIn(event["category"], (
                "story", "seasonal", "collaboration", "challenge", "limited", "permanent"
            ))
            self.assertTrue(event["type"])
            self.assertIn(event["availability"]["mode"], ("scheduled", "permanent"))
            self.assertEqual(event["unlock"]["kind"], "none")
            self.assertEqual(event["verification_status"], "REMASTERED_DESIGN")
            provenance = event["provenance"]
            self.assertEqual(provenance["evidence"], "REMASTERED_DESIGN")
            self.assertEqual(provenance["rights_gate"], "not_passed")
            self.assertEqual(provenance["source"], "project_authored")
            replay = event["replay_policy"]
            self.assertIsInstance(replay["archive_after_end"], bool)
            self.assertIsInstance(replay["replay_enabled"], bool)
            self.assertIsInstance(replay["keep_rewards_on_replay"], bool)

    def test_schedules_and_region_configuration(self) -> None:
        for event in self.events:
            mode = event["availability"]["mode"]
            self.assertTrue(event["regions"], event["id"])
            for region, config in event["regions"].items():
                start = int(config["start_unix"])
                end = int(config["end_unix"])
                if mode == "permanent":
                    self.assertEqual((start, end), (0, 0), event["id"])
                else:
                    self.assertGreater(end, start, f"{event['id']}:{region}")
                self.assertEqual(config["stage_ids"], [], f"{event['id']}:{region}")
        story = self.event_by_id["event:GL:980001@stargarden"]
        future = self.event_by_id["event:JP:980005@future"]
        permanent = self.event_by_id["event:GL:980006@evergreen"]
        self.assertEqual(story["regions"]["GL"]["start_unix"], 1700000000)
        self.assertEqual(story["regions"]["GL"]["end_unix"], 1800000000)
        self.assertGreater(future["regions"]["JP"]["start_unix"], permanent["regions"]["GL"]["end_unix"])
        self.assertFalse(future["replay_policy"]["replay_enabled"])

    def test_stages_rewards_currency_and_unlocks(self) -> None:
        for stage in self.stages:
            event = self.event_by_id[stage["event_id"]]
            self.assertIn(stage["id"], event["stage_ids"])
            self.assertEqual(stage["region"], event["region"])
            self.assertIn(stage["encounter_id"], self.battles["encounters"])
            self.assertEqual(
                self.battles["encounters"][stage["encounter_id"]]["fixture_marker"],
                "SYNTHETIC_FIXTURE",
            )
            self.assertGreaterEqual(int(stage["order"]), 0)
            self.assertGreaterEqual(int(stage["completion_target"]), 1)
            for prerequisite in stage["unlock_after"]:
                self.assertIn(prerequisite, event["stage_ids"])
            for reward_field in ("first_clear_reward", "repeat_reward"):
                reward = stage[reward_field]
                self.assertGreater(int(reward["gil"]), 0, f"{stage['id']}: {reward_field}")
                for item_id in reward["items"]:
                    self.assertIn(item_id, self.battles["items"], f"{stage['id']}: {item_id}")
            currency = stage["currency"]
            self.assertEqual(currency["id"], event["event_currency"])
            self.assertGreater(int(currency["amount"]), 0)
            self.assertFalse(stage["reward_policy"]["one_time"])
            self.assertTrue(stage["reward_policy"]["repeatable"])
            self.assertEqual(stage["verification_status"], "REMASTERED_DESIGN")
            self.assertEqual(stage["provenance"]["rights_gate"], "not_passed")
        for event in self.events:
            self.assertIn(event["boss_encounter"], self.battles["encounters"])
            for stage_id in event["stage_ids"]:
                self.assertIn(stage_id, self.stage_by_id)

    def test_missions_shop_and_banner_references(self) -> None:
        for event in self.events:
            mission_ids: set[str] = set()
            for mission in event["missions"]:
                self.assertNotIn(mission["id"], mission_ids)
                mission_ids.add(mission["id"])
                self.assertGreaterEqual(int(mission["target"]), 1)
                self.assertIsInstance(mission["repeatable"], bool)
                self.assertGreaterEqual(int(mission["reward"]["gil"]), 0)
            shop_ref = event["shop_ref"]
            if shop_ref:
                self.assertEqual(shop_ref, event["shop"]["id"])
                self.assertIn(shop_ref, self.shop_by_id)
                shop = self.shop_by_id[shop_ref]
                self.assertEqual(shop["provenance"]["rights_gate"], "not_passed")
                self.assertEqual(self.shops["policy"]["rights_gate"], "not_passed")
                self.assertFalse(self.shops["policy"]["source_data_imported"])
                stock_ids = {item["stock_id"] for item in shop["stock"]}
                for item in event["shop"]["items"]:
                    self.assertIn(item["id"], stock_ids)
                    self.assertEqual(item["currency"], event["event_currency"])
                    self.assertGreater(int(item["cost"]), 0)
                    self.assertEqual(item["shop_id"], shop_ref)
                    for reward_item in item["reward"]["items"]:
                        self.assertIn(reward_item, self.battles["items"])
            else:
                self.assertEqual(event["shop"]["id"], "")
                self.assertEqual(event["shop"]["items"], [])
            banner_ref = event["banner_ref"]
            if banner_ref:
                self.assertIn(banner_ref, self.banner_by_id)
                banner = self.banner_by_id[banner_ref]
                self.assertEqual(banner["provenance"]["rights_gate"], "not_passed")
                self.assertEqual(self.banners["policy"]["rights_gate"], "not_passed")
                self.assertFalse(self.banners["policy"]["source_data_imported"])
                self.assertIn("SYNTHETIC_FIXTURE", self.banners["rate_notice"])
                self.assertEqual(banner["region"], event["region"])
            for region, config in event["regions"].items():
                if config.get("banner_ref"):
                    self.assertIn(config["banner_ref"], self.banner_by_id)

    def test_localization_keys_and_collaboration_safety(self) -> None:
        key_fields: set[str] = set()
        for event in self.events:
            key_fields.update((
                event["name_key"], event["description_key"], event["art"]["label_key"]
            ))
            key_fields.update(mission["key"] for mission in event["missions"])
            for guest in event["guests"]:
                key_fields.update((guest["name_key"], guest["role_key"]))
                self.assertEqual(guest["rights_gate"], "not_passed")
                parse_id(guest["id"], "guest")
        for stage in self.stages:
            key_fields.add(stage["name_key"])
        for key in key_fields:
            self.assertTrue("." in key, key)
            for locale in LOCALES:
                self.assertIn(key, self.dictionaries[locale], f"{locale}: {key}")
                self.assertTrue(self.dictionaries[locale][key])

        raw_text = EVENTS_PATH.read_text(encoding="utf-8").lower()
        for term in PROTECTED_TERMS:
            self.assertIsNone(re.search(r"\b" + re.escape(term) + r"\b", raw_text), term)
        for forbidden in (".png", ".jpg", ".mp3", ".ogg", "http://", "https://"):
            self.assertNotIn(forbidden, raw_text, forbidden)
        collab = self.event_by_id["event:GL:980003@lumenguest"]
        self.assertEqual(collab["category"], "collaboration")
        self.assertEqual(len(collab["guests"]), 1)
        self.assertEqual(collab["provenance"]["rights_gate"], "not_passed")
        self.assertIn("synthetic", self.dictionaries["en"][collab["guests"][0]["role_key"]].lower())

    def test_save_section_is_additive_without_version_bump(self) -> None:
        source = PLAYER_STATE_PATH.read_text(encoding="utf-8")
        self.assertIn('const PLAYER_STATE_VERSION := 4', source)
        for field in (
            "processed_runs", "first_clears", "completions", "currency",
            "mission_progress", "claims", "last_result",
        ):
            self.assertIn(f'"{field}"', source)
        self.assertIn("settle_event_battle", source)
        self.assertIn("SAVE_STATUS_READ_ONLY_FUTURE_VERSION", source)


if __name__ == "__main__":
    unittest.main()
