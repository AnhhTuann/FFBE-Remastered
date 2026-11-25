"""Small shared helpers for the FFBE Remastered audit tools.

This module deliberately has no third-party dependencies. Every helper is
deterministic so repeated runs produce byte-identical reports.
"""

from __future__ import annotations

import csv
import hashlib
import json
import os
import sys
from typing import Any, Iterator


VALID_REGIONS = ("GL", "JP")
STATUSES = ("VERIFIED", "RECOVERED", "PARTIAL", "UNVERIFIED", "UNAVAILABLE")


def sha256_file(path: str, chunk_size: int = 1024 * 1024) -> str:
    """Return the SHA-256 of a file, reading it in bounded chunks."""
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        while True:
            chunk = handle.read(chunk_size)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: str | None) -> tuple[Any, str | None]:
    """Load JSON. Returns (data, None) or (None, error_message)."""
    if not path:
        return None, "no path supplied"
    try:
        with open(path, "r", encoding="utf-8-sig") as handle:
            return json.load(handle), None
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        return None, f"{type(exc).__name__}: {exc}"


def write_json(path: str, payload: Any) -> None:
    """Write canonical, deterministic JSON."""
    os.makedirs(os.path.dirname(os.path.abspath(path)) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True, ensure_ascii=False)
        handle.write("\n")


def write_csv(path: str, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    """Write canonical CSV with a stable column order."""
    os.makedirs(os.path.dirname(os.path.abspath(path)) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore", lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})


def get_path(obj: Any, dotted: str) -> Any:
    """Resolve a dotted field path through dicts and lists.

    A blank path returns the object itself. ``[]`` segments traverse lists.
    """
    if not dotted:
        return obj
    current = obj
    for part in dotted.split("."):
        if part.endswith("[]"):
            part = part[:-2]
            if not isinstance(current, dict) or part not in current:
                return None
            current = current[part]
            if not isinstance(current, list):
                return None
            continue
        if isinstance(current, dict):
            if part not in current:
                return None
            current = current[part]
        elif isinstance(current, list) and part.isdigit():
            index = int(part)
            current = current[index] if index < len(current) else None
        else:
            return None
    return current


def iter_path_values(obj: Any, dotted: str) -> Iterator[Any]:
    """Yield every value at a dotted path, flattening intermediate lists."""
    if not dotted:
        yield obj
        return
    parts = dotted.split(".")

    def walk(node: Any, index: int) -> Iterator[Any]:
        if index >= len(parts):
            yield node
            return
        part = parts[index]
        if part.endswith("[]"):
            key = part[:-2]
            children = node.get(key) if isinstance(node, dict) else None
            if isinstance(children, list):
                for child in children:
                    yield from walk(child, index + 1)
        elif isinstance(node, dict):
            if part in node:
                yield from walk(node[part], index + 1)
        elif isinstance(node, list):
            for child in node:
                yield from walk(child, index)

    yield from walk(obj, 0)


def iter_records(data: Any, id_field: str) -> Iterator[tuple[str | None, dict[str, Any]]]:
    """Iterate (native_id, record) from a JSON object or list.

    Dict-shaped datasets use their keys as fallback IDs when the configured
    ``id_field`` is absent; this is recorded later as a partial record.
    """
    if isinstance(data, dict):
        for key, value in data.items():
            if not isinstance(value, dict):
                yield str(key), {"__value__": value}
                continue
            native_id = value.get(id_field, key)
            yield str(native_id), value
    elif isinstance(data, list):
        for index, value in enumerate(data):
            if not isinstance(value, dict):
                yield None, {"__value__": value, "__index__": index}
                continue
            yield str(value.get(id_field)), value


def composite_id(kind: str, region: str, native_id: str | None) -> str:
    """Build a region-aware identity. Native IDs are never assumed global."""
    return f"{kind}:{region}:{native_id}" if native_id is not None else f"{kind}:{region}:?"


def path_list(root: str) -> list[str]:
    """Return all regular file paths below root, relative to root, sorted."""
    found: list[str] = []
    for current, dirs, files in os.walk(root):
        dirs[:] = sorted(d for d in dirs if d not in (".git", "__pycache__"))
        for name in sorted(files):
            absolute = os.path.join(current, name)
            if os.path.isfile(absolute):
                found.append(os.path.relpath(absolute, root).replace(os.sep, "/"))
    return sorted(found)


def add_tools_to_path() -> None:
    """Allow ``python tools/.../script.py`` to import audit_utils."""
    tool_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    if tool_root not in sys.path:
        sys.path.insert(0, tool_root)
