#!/usr/bin/env python3
"""Generate the Prompt 05 visual-review table from real screenshot metadata.

The sidecars are written by tools/qa/capture_phase3.sh from live Godot windows.
This tool never creates or edits screenshots; it only summarises captured
geometry, pixel statistics and runtime error counts.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from phase3_visual_report import read_captures as _read_captures, repository_root

DEFAULT_CAPTURE_DIR = "docs/qa/screenshots/prompt05"


def read_captures(
    root: Path, captures_dir: str = DEFAULT_CAPTURE_DIR
) -> list[dict[str, str]]:
    """Read Prompt 05 sidecars using the Prompt 05 directory by default."""
    return _read_captures(root, captures_dir)


def render(captures: list[dict[str, str]], image_dir: str = DEFAULT_CAPTURE_DIR) -> str:
    resolutions = sorted({item["resolution"] for item in captures})
    locales = sorted({item["locale"] for item in captures})
    errors = sum(int(item["runtime_error_lines"]) for item in captures)
    lines = [
        "# Prompt 05 visual review",
        "",
        "**Capture tool:** `tools/qa/capture_phase3.sh`\\",
        "**Report generator:** `tools/qa/prompt05_visual_report.py`",
        "",
        "All images below are real captures from running Godot windows. The harness",
        "records window geometry, ImageMagick pixel statistics and runtime error counts",
        "in a `.txt` sidecar next to each PNG. Automated checks validate real-window",
        "geometry, metadata presence and recorded runtime error counts. Pixel statistics",
        "are recorded for review but are not threshold-gated; subjective visual sign-off",
        "remains a human QA task.",
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
        png = f"`{image_dir.rstrip('/')}/{item['name']}.png`"
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
            "NAME=prompt05-esper-vi-1280x720 \\",
            "  SCENE=res://scenes/phase3/esper_management.tscn RES=1280x720 LOCALE=vi \\",
            "  QA_SHOT_DIR=docs/qa/screenshots/prompt05 \\",
            "  ./tools/qa/capture_phase3.sh",
            "python3 tools/qa/prompt05_visual_report.py",
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
    root = repository_root()
    captures = read_captures(root, DEFAULT_CAPTURE_DIR)
    output = root / "docs/qa/prompt05-visual-review.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render(captures), encoding="utf-8")
    print(f"captures: {len(captures)}")
    print(f"output: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
