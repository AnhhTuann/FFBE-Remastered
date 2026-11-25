#!/usr/bin/env python3
"""Generate the Phase 3 visual-review table from real screenshot metadata.

The sidecars are written by tools/qa/capture_phase3.sh from live Godot windows.
This tool never creates or edits screenshots; it only summarises captured
geometry, pixel statistics and runtime error counts.
"""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 1
REQUIRED_FIELDS = (
    "name",
    "scene",
    "resolution",
    "locale",
    "geometry",
    "pixels",
    "runtime_error_lines",
)


def repository_root() -> Path:
    return Path(__file__).resolve().parents[2]


def read_captures(root: Path) -> list[dict[str, str]]:
    directory = root / "docs/qa/screenshots/phase3"
    captures: list[dict[str, str]] = []
    for path in sorted(directory.glob("*.txt")):
        values: dict[str, str] = {}
        for line in path.read_text(encoding="utf-8").splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                values[key] = value
        missing = [field for field in REQUIRED_FIELDS if field not in values]
        if missing:
            raise ValueError(f"{path.name}: missing metadata {missing}")
        width, height = values["resolution"].split("x", 1)
        geometry = values["geometry"]
        actual_width = _geometry_value(geometry, "WIDTH")
        actual_height = _geometry_value(geometry, "HEIGHT")
        if (actual_width, actual_height) != (width, height):
            raise ValueError(
                f"{path.name}: geometry {actual_width}x{actual_height} "
                f"does not match requested {values['resolution']}"
            )
        if values.get("fullscreen") == "1" and _geometry_value(geometry, "Y") != "0":
            raise ValueError(f"{path.name}: fullscreen capture is not at Y=0")
        captures.append(values)
    return captures


def _geometry_value(geometry: str, key: str) -> str:
    """Read one KEY=value token from xdotool's shell-style geometry string."""
    for token in geometry.split():
        if token.startswith(f"{key}="):
            return token.split("=", 1)[1]
    return ""


def render(captures: list[dict[str, str]]) -> str:
    resolutions = sorted({item["resolution"] for item in captures})
    locales = sorted({item["locale"] for item in captures})
    errors = sum(int(item["runtime_error_lines"]) for item in captures)
    lines = [
        "# Phase 3 visual review",
        "",
        f"**Schema version:** {SCHEMA_VERSION}  ",
        "**Capture tool:** `tools/qa/capture_phase3.sh`  ",
        "**Report generator:** `tools/qa/phase3_visual_report.py`",
        "",
        "All images below are real captures from running Godot windows. The harness",
        "records window geometry, ImageMagick pixel statistics and runtime error counts",
        "in a `.txt` sidecar next to each PNG. This report does not claim subjective",
        "visual quality: the model cannot inspect PNG pixel content directly.",
        "",
        f"- Captures: {len(captures)}",
        f"- Resolutions: {', '.join(resolutions)}",
        f"- Locales: {', '.join(locales)}",
        f"- Runtime error lines across all captures: {errors}",
        "",
        "## Captures",
        "",
        "| Screenshot | Scene | Resolution | Locale | Geometry | Pixel statistics | Errors |",
        "|---|---|---|---|---|---|---:|",
    ]
    for item in captures:
        png = f"`docs/qa/screenshots/phase3/{item['name']}.png`"
        geometry = item["geometry"].replace("WINDOW=", "window=")
        lines.append(
            f"| {png} | `{item['scene']}` | {item['resolution']} | `{item['locale']}` | "
            f"{geometry} | `{item['pixels']}` | {item['runtime_error_lines']} |"
        )
    lines.extend(
        [
            "",
            "## Reproduction",
            "",
            "Each capture is reproducible with the same environment and scene. Example:",
            "",
            "```sh",
            "NAME=phase3-main-menu-vi-1280x720 \\",
            "  SCENE=res://scenes/menu/main_menu.tscn RES=1280x720 LOCALE=vi \\",
            "  ./tools/qa/capture_phase3.sh",
            "python3 tools/qa/phase3_visual_report.py",
            "```",
            "",
            "Optional capture variables: `SCENARIO`, `INSTANCE_ID`, `PARTY_ID`,",
            "`ENCOUNTER`, `SEED`, `FREEZE_FRAME`, `FULLSCREEN=1`, and `WAIT_SECONDS`.",
            "`FFBE_QA_LOCALE` is a QA-only starting-locale override and does not write",
            "player settings; normal locale switching remains available in Settings.",
            "",
            "## Limitations",
            "",
            "- Distinct pixel statistics and zero error lines prove renders occurred; they",
            "  do not prove subjective layout quality or text readability.",
            "- Fullscreen 1920×1080 captures are taken at `(0,0)` when `FULLSCREEN=1`;",
            "  windowed captures include desktop decoration offsets recorded in metadata.",
            "- No mockups or composited images are used.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=repository_root())
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Markdown output (default: docs/qa/phase3-visual-review.md)",
    )
    args = parser.parse_args()
    root = args.root.resolve()
    output = (args.output or root / "docs/qa/phase3-visual-review.md").resolve()
    captures = read_captures(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render(captures), encoding="utf-8")
    print(f"captures: {len(captures)}")
    print(f"output: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
