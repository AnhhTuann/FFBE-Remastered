#!/usr/bin/env python3
"""Generate the Prompt 07 Event Center visual-review report from real captures.

Sidecars are written by tools/qa/capture_prompt07.sh, which delegates to the
existing live-window capture harness. This tool never creates screenshots; it
validates the required scenario x resolution x locale matrix and summarises the
recorded geometry, pixel statistics and runtime error counts.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from phase3_visual_report import read_captures as _read_captures, repository_root

SCHEMA_VERSION = 1
DEFAULT_CAPTURE_DIR = "docs/qa/screenshots/prompt07"
DEFAULT_OUTPUT = "docs/qa/prompt07-visual-review.md"
REQUIRED_SCENARIOS = (
    "overview",
    "active",
    "upcoming",
    "ended",
    "categories",
    "detail",
    "stages",
    "rewards",
    "shop",
    "summon",
    "archive",
    "replay",
    "collaboration",
    "event_battle",
    "event_battle_return",
)
BATTLE_SCENARIOS = ("event_battle", "event_battle_return")
REQUIRED_RESOLUTIONS = ("1024x640", "1280x720", "1920x1080", "720x1280")
REQUIRED_LOCALES = ("vi", "en", "ja")

SCENARIO_LABELS = {
    "overview": "Overview and cards",
    "active": "Active filter",
    "upcoming": "Upcoming filter",
    "ended": "Ended filter",
    "categories": "Category filter",
    "detail": "Event details",
    "stages": "Stage selection",
    "rewards": "First-clear and repeat rewards",
    "shop": "Event currency and shop",
    "summon": "Summon-banner navigation",
    "archive": "Archive filter",
    "replay": "Replay archive",
    "collaboration": "Synthetic collaboration fixture",
    "event_battle": "Event battle",
    "event_battle_return": "Battle return to Event Center",
}


def read_captures(
    root: Path, captures_dir: str = DEFAULT_CAPTURE_DIR
) -> list[dict[str, str]]:
    """Read Prompt 07 sidecars, rejecting ones without a scenario field."""
    captures = _read_captures(root, captures_dir)
    for item in captures:
        if not item.get("scenario"):
            raise ValueError(f"{item['name']}: missing scenario metadata")
        if not item.get("event_center_view"):
            raise ValueError(f"{item['name']}: missing event center view metadata")
        if item["scenario"] != item["event_center_view"]:
            raise ValueError(f"{item['name']}: scenario/view metadata mismatch")
        if not item.get("event_now_unix"):
            raise ValueError(f"{item['name']}: missing injected clock metadata")
        if item["scenario"] in BATTLE_SCENARIOS:
            if "battle_scene.tscn" not in item.get("scene", ""):
                raise ValueError(f"{item['name']}: event battle must use the battle scene")
            if item.get("qa_mode") != "1":
                raise ValueError(f"{item['name']}: missing QA mode metadata")
            if not item.get("event_stage_id"):
                raise ValueError(f"{item['name']}: missing event stage metadata")
            if "event_center.tscn" not in item.get("return_scene", ""):
                raise ValueError(f"{item['name']}: battle must return to Event Center")
    return captures


def _pixel_stddev(item: dict[str, str]) -> float:
    """Read ImageMagick's stddev value from a capture's pixel summary."""
    match = re.search(r"stddev=([0-9.eE+-]+)", item.get("pixels", ""))
    if match is None:
        raise ValueError(f"{item['name']}: missing pixel stddev")
    try:
        return float(match.group(1))
    except ValueError as exc:
        raise ValueError(f"{item['name']}: invalid pixel stddev") from exc


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
        raise ValueError("missing Prompt 07 captures: " + ", ".join(missing))
    errors = [
        item["name"]
        for item in captures
        if int(item["runtime_error_lines"]) != 0
    ]
    if errors:
        raise ValueError("runtime error lines in: " + ", ".join(errors))
    blank = [item["name"] for item in captures if _pixel_stddev(item) <= 0.01]
    if blank:
        raise ValueError("blank or near-blank captures: " + ", ".join(blank))


def render(captures: list[dict[str, str]], image_dir: str = DEFAULT_CAPTURE_DIR) -> str:
    validate_matrix(captures)
    resolutions = list(REQUIRED_RESOLUTIONS)
    locales = list(REQUIRED_LOCALES)
    errors = sum(int(item["runtime_error_lines"]) for item in captures)
    lines = [
        "# Prompt 07 Event Center visual review",
        "",
        f"**Schema version:** {SCHEMA_VERSION}",
        "**Capture tool:** `tools/qa/capture_prompt07.sh`",
        "**Report generator:** `tools/qa/prompt07_visual_report.py`",
        "",
        "All images below are real captures from running Godot windows. Each capture uses a",
        "fresh isolated `user://` profile and the injected clock `1740000000`, so no owner",
        "save is read or modified and scheduled states are deterministic. The harness records",
        "window geometry, ImageMagick pixel statistics and runtime error counts in a `.txt`",
        "sidecar next to each PNG. This report validates the complete scenario × resolution ×",
        "locale matrix, requires zero runtime error lines, and rejects blank or near-blank",
        "captures by inspecting ImageMagick pixel variance. Pixel statistics are recorded",
        "for review but are not an art-direction threshold; subjective visual sign-off remains",
        "a human QA task. All card art is an explicitly labelled synthetic placeholder panel.",
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
            "| Screenshot | Scenario | Scene | Resolution | Locale | Clock | Geometry | Pixels | Errors |",
            "|---|---|---|---|---|---|---|---|---:|",
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
            f"`{item['locale']}` | `{item['event_now_unix']}` | {geometry} | "
            f"`{item['pixels']}` | {item['runtime_error_lines']} |"
        )
    lines.extend(
        [
            "",
            "## Reproduction",
            "",
            "Every capture is reproducible with a real display and the pinned Godot binary:",
            "",
            "```sh",
            "NAME=prompt07-overview-vi-1280x720 \\",
            "  SCENE=res://scenes/event/event_center.tscn RES=1280x720 LOCALE=vi \\",
            "  SCENARIO=overview ./tools/qa/capture_prompt07.sh",
            "python3 tools/qa/prompt07_visual_report.py",
            "```",
            "",
            "Set `SCENARIO` to one of the fifteen required scenarios: `overview`, `active`,",
            "`upcoming`, `ended`, `categories`, `detail`, `stages`, `rewards`, `shop`, `summon`,",
            "`archive`, `replay`, `collaboration`, `event_battle`, or `event_battle_return`. The",
            "wrapper converts it to `FFBE_QA_EVENT_CENTER_VIEW`, injects",
            "`FFBE_QA_EVENT_NOW_UNIX=1740000000` and selects a synthetic event ID where needed.",
            "Battle scenarios launch `res://scenes/battle/battle_scene.tscn` with QA mode and an",
            "event stage context; `event_battle_return` runs the real settlement and navigates back",
            "to the Event Center. `FULLSCREEN=1` and `WAIT_SECONDS` are accepted by the shared",
            "capture harness. `FFBE_QA_LOCALE` is a QA-only starting-locale override and does not",
            "write player settings.",
            "",
            "## Limitations",
            "",
            "- Distinct pixel statistics and zero error lines prove renders occurred; they",
            "  do not prove subjective layout quality or text readability.",
            "- Fullscreen 1920×1080 captures are taken at `(0,0)` when `FULLSCREEN=1`;",
            "  windowed captures include desktop decoration offsets recorded in metadata.",
            "- 720×1280 captures exercise the portrait layout profile; the other three",
            "  resolutions exercise the landscape profile. Because a 720×1280 window cannot fit",
            "  the 1920×1080 desktop, those captures temporarily switched the X display to a",
            "  720×1280 mode and restored 1920×1080 afterwards; geometry metadata confirms it.",
            "- The generator parses each sidecar's pixel standard deviation and rejects blank",
            "  frames, but does not claim readability or art-direction approval.",
            "- Rewards, shop and summon captures scroll an existing rendered detail section",
            "  into view; they do not compose or mock UI.",
            "- Event battle captures use a QA-only context seed when the battle scene is launched",
            "  directly. Normal gameplay receives the same context from Event Center through",
            "  `WorldContext`; no gameplay branch is activated by the QA environment.",
            "- No mockups or composited images are used, and no protected art, logo, music,",
            "  dialogue or collaboration character appears in the captured scene.",
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
        help="Markdown output (default: docs/qa/prompt07-visual-review.md)",
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
