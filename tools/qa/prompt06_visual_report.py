#!/usr/bin/env python3
"""Generate the Prompt 06 visual-review report from real screenshot metadata.

Sidecars are written by tools/qa/capture_prompt06.sh, which delegates to the
existing live-window capture harness. This tool never creates screenshots; it
validates the required scenario/resolution/locale matrix and summarises the
recorded geometry, pixel statistics and runtime error counts.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from phase3_visual_report import read_captures as _read_captures, repository_root

SCHEMA_VERSION = 1
DEFAULT_CAPTURE_DIR = "docs/qa/screenshots/prompt06"
DEFAULT_OUTPUT = "docs/qa/prompt06-visual-review.md"
REQUIRED_SCENARIOS = (
    "world_map",
    "selected",
    "hub",
    "haven_npc",
    "haven_npc_choice",
    "journal",
    "meadow_chest",
    "meadow_battle",
    "quest_complete_journal",
    "battle_victory",
    "battle_defeat",
    "battle_retry",
    "battle_return",
)
REQUIRED_RESOLUTIONS = ("1024x640", "1280x720", "1920x1080")
REQUIRED_LOCALES = ("vi", "en", "ja")

SCENARIO_LABELS = {
    "world_map": "World Map",
    "selected": "World Map selected location",
    "hub": "Hub exploration",
    "haven_npc": "NPC dialogue",
    "haven_npc_choice": "NPC dialogue choice page",
    "journal": "Quest journal",
    "meadow_chest": "Treasure interaction",
    "meadow_battle": "Battle transition",
    "quest_complete_journal": "Quest completion",
    "battle_victory": "Battle victory",
    "battle_defeat": "Battle defeat",
    "battle_retry": "Battle Retry available",
    "battle_return": "Battle return state",
}


def read_captures(
    root: Path, captures_dir: str = DEFAULT_CAPTURE_DIR
) -> list[dict[str, str]]:
    """Read Prompt 06 sidecars, rejecting ones without a scenario field."""
    captures = _read_captures(root, captures_dir)
    for item in captures:
        if not item.get("scenario"):
            raise ValueError(f"{item['name']}: missing scenario metadata")
    return captures


def validate_matrix(captures: list[dict[str, str]]) -> None:
    """Require the documented scenario x resolution x locale evidence matrix."""
    actual = {
        (item["scenario"], item["resolution"], item["locale"])
        for item in captures
    }
    missing = [
        f"{scenario}/{resolution}/{locale}"
        for scenario in REQUIRED_SCENARIOS
        for resolution in REQUIRED_RESOLUTIONS
        for locale in REQUIRED_LOCALES
        if (scenario, resolution, locale) not in actual
    ]
    if missing:
        raise ValueError("missing Prompt 06 captures: " + ", ".join(missing))
    errors = [
        item["name"]
        for item in captures
        if int(item["runtime_error_lines"]) != 0
    ]
    if errors:
        raise ValueError("runtime error lines in: " + ", ".join(errors))


def render(captures: list[dict[str, str]], image_dir: str = DEFAULT_CAPTURE_DIR) -> str:
    validate_matrix(captures)
    resolutions = list(REQUIRED_RESOLUTIONS)
    locales = list(REQUIRED_LOCALES)
    errors = sum(int(item["runtime_error_lines"]) for item in captures)
    lines = [
        "# Prompt 06 world exploration visual review",
        "",
        f"**Schema version:** {SCHEMA_VERSION}",
        "**Capture tool:** `tools/qa/capture_prompt06.sh`",
        "**Report generator:** `tools/qa/prompt06_visual_report.py`",
        "",
        "All images below are real captures from running Godot windows. Each capture uses a",
        "fresh isolated `user://` profile, so no owner save is read or modified. The harness",
        "records window geometry, ImageMagick pixel statistics and runtime error counts in a",
        "`.txt` sidecar next to each PNG. This report validates the complete scenario ×",
        "resolution × locale matrix and requires zero runtime error lines. Pixel statistics",
        "are recorded for review but are not threshold-gated; subjective visual sign-off",
        "remains a human QA task.",
        "",
        f"- Captures: {len(captures)}",
        f"- Scenarios: {len(REQUIRED_SCENARIOS)}",
        f"- Resolutions: {', '.join(resolutions)}",
        f"- Locales: {', '.join(locales)}",
        f"- Runtime error lines across all captures: {errors}",
        "",
        "## Coverage matrix",
        "",
        "| Scenario | Resolutions | Locales | Captures |",
        "|---|---|---|---:|",
    ]
    for scenario in REQUIRED_SCENARIOS:
        rows = [item for item in captures if item["scenario"] == scenario]
        lines.append(
            f"| {SCENARIO_LABELS[scenario]} | {', '.join(resolutions)} | "
            f"{', '.join(locales)} | {len(rows)} |"
        )
    lines.extend(
        [
            "",
            "## Captures",
            "",
            "| Screenshot | Scenario | Scene | Resolution | Locale | Geometry | Pixels | Errors |",
            "|---|---|---|---|---|---|---|---:|",
        ]
    )
    ordered = sorted(
        captures,
        key=lambda item: (
            REQUIRED_SCENARIOS.index(item["scenario"])
            if item["scenario"] in REQUIRED_SCENARIOS
            else len(REQUIRED_SCENARIOS),
            resolutions.index(item["resolution"])
            if item["resolution"] in resolutions
            else len(resolutions),
            locales.index(item["locale"])
            if item["locale"] in locales
            else len(locales),
            item["name"],
        ),
    )
    for item in ordered:
        png = f"`{image_dir.rstrip('/')}/{item['name']}.png`"
        label = SCENARIO_LABELS.get(item["scenario"], item["scenario"])
        geometry = item["geometry"].replace("WINDOW=", "window=")
        lines.append(
            f"| {png} | {label} | `{item['scene']}` | {item['resolution']} | "
            f"`{item['locale']}` | {geometry} | `{item['pixels']}` | "
            f"{item['runtime_error_lines']} |"
        )
    lines.extend(
        [
            "",
            "## Reproduction",
            "",
            "Every capture is reproducible with a real display and the pinned Godot binary:",
            "",
            "```sh",
            "NAME=prompt06-world_map-vi-1280x720 \\",
            "  SCENE=res://scenes/world/world_map.tscn RES=1280x720 LOCALE=vi \\\n",
            "  ./tools/qa/capture_prompt06.sh",
            "python3 tools/qa/prompt06_visual_report.py",
            "```",
            "",
            "Set `SCENARIO` to one of the thirteen required scenarios: `world_map`, `selected`,",
            "`hub`, `haven_npc`, `haven_npc_choice`, `journal`, `meadow_chest`, `meadow_battle`,",
            "`quest_complete_journal`, `battle_victory`, `battle_defeat`, `battle_retry`, or",
            "`battle_return`. Battle result captures enable `FFBE_QA_MODE` and pass the same",
            "world trigger/location/return context used by exploration. `FULLSCREEN=1` and",
            "`WAIT_SECONDS` are also accepted by the shared capture harness. `FFBE_QA_LOCALE`",
            "is a QA-only starting-locale override and does not write player settings.",
            "",
            "## Limitations",
            "",
            "- Distinct pixel statistics and zero error lines prove renders occurred; they",
            "  do not prove subjective layout quality or text readability.",
            "- Fullscreen 1920×1080 captures are taken at `(0,0)` when `FULLSCREEN=1`;",
            "  windowed captures include desktop decoration offsets recorded in metadata.",
            "- `meadow_battle` is a transition capture. `battle_victory`, `battle_defeat`,",
            "  `battle_retry` and `battle_return` run a full synthetic battle with world",
            "  settlement in an isolated profile; `battle_return` then navigates back to the",
            "  exploration area with the settled result.",
            "- Geometry, pixel statistics and error lines are evidence that rendering and",
            "  navigation occurred; Retry visibility and choice-page layout still need human",
            "  visual inspection of the retained PNGs.",
            "- No mockups or composited images are used.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=repository_root())
    parser.add_argument(
        "--captures-dir",
        type=str,
        default=DEFAULT_CAPTURE_DIR,
        help="Capture directory relative to --root",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Markdown output (default: docs/qa/prompt06-visual-review.md)",
    )
    args = parser.parse_args()
    root = args.root.resolve()
    captures_dir = args.captures_dir.rstrip("/")
    output = (args.output or root / DEFAULT_OUTPUT).resolve()
    captures = read_captures(root, captures_dir)
    validate_matrix(captures)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render(captures, captures_dir), encoding="utf-8")
    print(f"captures: {len(captures)}")
    print(f"output: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
