#!/usr/bin/env python3
"""Generate the deterministic synthetic pixel atlas used by the Godot viewer.

The output is project-authored and contains no FFBE material. Re-running this
script must produce byte-identical output.
"""

from __future__ import annotations

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "game" / "assets" / "sprites" / "synthetic_pixel_atlas.png"

CELL = 32
COLUMNS = 4
ROWS = 4
WIDTH = CELL * COLUMNS
HEIGHT = CELL * ROWS


def _chunk(tag: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + tag
        + payload
        + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
    )


def _pixel(index: int, x: int, y: int) -> tuple[int, int, int, int]:
    """A simple deterministic 8-bit pixel motif with transparent corners."""
    if (x < 4 and y < 4) or (x >= CELL - 4 and y >= CELL - 4):
        return (0, 0, 0, 0)

    base = (
        (40 + index * 11) % 256,
        (90 + index * 17) % 256,
        (150 + index * 23) % 256,
        255,
    )
    if x % 8 == 0 or y % 8 == 0:
        return (base[0] // 2, base[1] // 2, base[2] // 2, 255)
    if 12 <= x <= 19 and 12 <= y <= 19:
        return (255, 236, 120, 255)
    return base


def build_png() -> bytes:
    rows: list[bytes] = []
    for y in range(HEIGHT):
        row = bytearray([0])  # PNG filter type: None
        for x in range(WIDTH):
            index = (y // CELL) * COLUMNS + (x // CELL)
            row.extend(_pixel(index, x % CELL, y % CELL))
        rows.append(bytes(row))

    ihdr = struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 6, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", ihdr)
        + _chunk(b"IDAT", zlib.compress(b"".join(rows), level=9))
        + _chunk(b"IEND", b"")
    )


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    data = build_png()
    OUTPUT.write_bytes(data)
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({len(data)} bytes, {WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()
