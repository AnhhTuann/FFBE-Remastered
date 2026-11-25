#!/usr/bin/env python3
"""Report localization coverage for the offline FFBE Remastered client.

The tool is deliberately dependency-free and deterministic: the same repository
state always produces byte-identical JSON. It scans ``game/**/*.gd`` for string
literals passed to ``L.t(...)`` or ``LocaleManager.t(...)``, compares those keys
with ``game/data/localization/{en,vi,ja}.json``, and checks placeholder parity,
Vietnamese diacritics, Japanese glyph coverage, and long-label risk.

Exit status is 0 only when there are no missing keys and no placeholder
mismatches. Unused keys and long labels are diagnostics, not blockers.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from pathlib import Path
from typing import Any

TOOL_VERSION = "1.0.0"
SCHEMA_VERSION = 1
LOCALES: tuple[str, ...] = ("en", "ja", "vi")
DEFAULT_LOCALE = "vi"
FALLBACK_LOCALE = "en"
DICTIONARY_DIR = Path("game/data/localization")
SOURCE_DIR = Path("game")
DEFAULT_OUTPUT = Path("data/validation/localization-coverage.json")
LONG_LABEL_THRESHOLD = 40

# Simple, intentional regexes: dynamic key expressions are reported as call
# sites but cannot be resolved without executing GDScript.
TRANSLATION_CALL_RE = re.compile(r"(?:\bL|\bLocaleManager)\s*\.\s*t\s*\(")
TRANSLATION_LITERAL_RE = re.compile(
    r"(?:\bL|\bLocaleManager)\s*\.\s*t\s*\(\s*(['\"])([^'\"\n]*)\1"
)
PLACEHOLDER_RE = re.compile(
    r"%(?:\([^)]+\))?[-+ #0]*\d*(?:\.\d+)?[hlL]?[diouxXeEfFgGcrs]"
    r"|\{[A-Za-z_][A-Za-z0-9_]*\}"
)
JAPANESE_GLYPH_RE = re.compile(
    r"[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]"
)


def repository_root() -> Path:
    """Return the repository root inferred from this script's location."""
    return Path(__file__).resolve().parents[2]


def extract_placeholders(text: str) -> tuple[str, ...]:
    """Return placeholders in source order, retaining duplicate tokens."""
    return tuple(PLACEHOLDER_RE.findall(text))


def has_vietnamese_diacritic(text: str) -> bool:
    """Detect Vietnamese diacritics, including precomposed forms and ``đ``."""
    if any(character in "đĐ" for character in text):
        return True
    decomposed = unicodedata.normalize("NFD", text)
    return any(unicodedata.combining(character) for character in decomposed)


def has_japanese_glyph(text: str) -> bool:
    """Detect kana, kanji, or other Japanese-script glyphs."""
    return JAPANESE_GLYPH_RE.search(text) is not None


def load_dictionary(root: Path, locale: str) -> tuple[dict[str, str], list[str]]:
    """Load one flat string dictionary, returning any structural problems."""
    path = root / DICTIONARY_DIR / f"{locale}.json"
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return {}, [f"{path.as_posix()}: {type(error).__name__}: {error}"]

    if not isinstance(raw, dict):
        return {}, [f"{path.as_posix()}: expected a flat JSON object"]

    clean: dict[str, str] = {}
    problems: list[str] = []
    for key, value in sorted(raw.items()):
        if not isinstance(key, str) or not isinstance(value, str):
            problems.append(f"{path.as_posix()}: non-string entry for {key!r}")
            continue
        clean[key] = value
    return clean, problems


def scan_sources(root: Path) -> dict[str, Any]:
    """Find literal translation keys requested by GDScript call sites."""
    source_root = root / SOURCE_DIR
    files = sorted(
        (path for path in source_root.rglob("*.gd") if path.is_file()),
        key=lambda path: path.relative_to(root).as_posix(),
    )
    literals: set[str] = set()
    call_sites = 0
    for path in files:
        text = path.read_text(encoding="utf-8", errors="replace")
        call_sites += len(TRANSLATION_CALL_RE.findall(text))
        literals.update(match.group(2) for match in TRANSLATION_LITERAL_RE.finditer(text))
    return {
        "gd_files_scanned": len(files),
        "gd_files": [path.relative_to(root).as_posix() for path in files],
        "translation_call_sites": call_sites,
        "literal_call_sites": sum(
            1
            for path in files
            for _ in TRANSLATION_LITERAL_RE.finditer(
                path.read_text(encoding="utf-8", errors="replace")
            )
        ),
        "literal_keys": sorted(literals),
    }


def build_report(root: Path) -> dict[str, Any]:
    """Build the deterministic coverage report for ``root``."""
    source = scan_sources(root)
    source_keys = set(source["literal_keys"])

    dictionaries: dict[str, dict[str, str]] = {}
    dictionary_errors: dict[str, list[str]] = {}
    for locale in LOCALES:
        dictionary, problems = load_dictionary(root, locale)
        dictionaries[locale] = dictionary
        if problems:
            dictionary_errors[locale] = problems

    union_keys = sorted(
        set().union(*(set(dictionary) for dictionary in dictionaries.values()), source_keys)
    )

    per_locale: dict[str, Any] = {}
    for locale in LOCALES:
        dictionary = dictionaries[locale]
        per_locale[locale] = {
            "dictionary_file": (DICTIONARY_DIR / f"{locale}.json").as_posix(),
            "key_count": len(dictionary),
            "missing_keys": [key for key in union_keys if key not in dictionary],
            "unused_keys": [key for key in sorted(dictionary) if key not in source_keys],
            "empty_value_keys": [key for key, value in sorted(dictionary.items()) if not value],
        }

    placeholder_mismatches: list[dict[str, Any]] = []
    for key in union_keys:
        signatures = {
            locale: extract_placeholders(dictionaries[locale][key])
            for locale in LOCALES
            if key in dictionaries[locale]
        }
        if len(set(signatures.values())) > 1:
            placeholder_mismatches.append(
                {
                    "key": key,
                    "expected_locale": DEFAULT_LOCALE,
                    "by_locale": {
                        locale: list(signatures[locale]) for locale in sorted(signatures)
                    },
                }
            )

    vi_dictionary = dictionaries[DEFAULT_LOCALE]
    vi_without = [
        key
        for key in sorted(vi_dictionary)
        if not has_vietnamese_diacritic(vi_dictionary[key])
    ]
    ja_dictionary = dictionaries["ja"]
    ja_without = [
        key
        for key in sorted(ja_dictionary)
        if not has_japanese_glyph(ja_dictionary[key])
    ]

    long_labels: dict[str, list[dict[str, Any]]] = {}
    for locale in LOCALES:
        long_labels[locale] = [
            {"key": key, "length": len(value), "value": value}
            for key, value in sorted(dictionaries[locale].items())
            if len(value) > LONG_LABEL_THRESHOLD
        ]

    missing_key_count = sum(len(item["missing_keys"]) for item in per_locale.values())
    placeholder_mismatch_count = len(placeholder_mismatches)
    status = "pass" if missing_key_count == 0 and placeholder_mismatch_count == 0 else "fail"

    report: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "tool_version": TOOL_VERSION,
        "status": status,
        "default_locale": DEFAULT_LOCALE,
        "fallback_locale": FALLBACK_LOCALE,
        "locales": list(LOCALES),
        "source_scan": source,
        "union_key_count": len(union_keys),
        "per_locale": per_locale,
        "dictionary_errors": dictionary_errors,
        "invalid_dictionary_count": len(dictionary_errors),
        "placeholder_mismatches": placeholder_mismatches,
        "vietnamese_diacritics": {
            "locale": DEFAULT_LOCALE,
            "strings_checked": len(vi_dictionary),
            "strings_with_diacritics": len(vi_dictionary) - len(vi_without),
            "coverage": round(
                1.0 - len(vi_without) / len(vi_dictionary), 4
            )
            if vi_dictionary
            else 0.0,
            "keys_without_diacritics": vi_without,
            "note": "Brand tokens such as NV, EX, TMR, STMR, LB, SLB, gil, UID and digits are expected without diacritics.",
        },
        "japanese_glyphs": {
            "locale": "ja",
            "strings_checked": len(ja_dictionary),
            "strings_with_japanese_glyphs": len(ja_dictionary) - len(ja_without),
            "coverage": round(
                1.0 - len(ja_without) / len(ja_dictionary), 4
            )
            if ja_dictionary
            else 0.0,
            "keys_without_japanese_glyphs": ja_without,
            "note": "Japanese values must contain kana or kanji, not romaji placeholders.",
        },
        "long_label_risk": {
            "threshold": LONG_LABEL_THRESHOLD,
            "total": sum(len(items) for items in long_labels.values()),
            "by_locale": long_labels,
        },
        "blocking": {
            "missing_key_count": missing_key_count,
            "placeholder_mismatch_count": placeholder_mismatch_count,
        },
    }
    return report


def render_report(report: dict[str, Any]) -> str:
    """Serialize a report with stable ordering and Unicode preserved."""
    return json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=repository_root(),
        help="Repository root (default: inferred from this script)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help=f"Report path (default: <root>/{DEFAULT_OUTPUT.as_posix()})",
    )
    args = parser.parse_args(argv)

    root = args.root.resolve()
    output = (args.output or root / DEFAULT_OUTPUT).resolve()
    report = build_report(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_report(report), encoding="utf-8")

    displayed_output = output.relative_to(root).as_posix() if output.is_relative_to(root) else str(output)
    print(f"status: {report['status']}")
    print(f"locales: {', '.join(LOCALES)}")
    print(f"union keys: {report['union_key_count']}")
    print(f"missing keys: {report['blocking']['missing_key_count']}")
    print(f"placeholder mismatches: {report['blocking']['placeholder_mismatch_count']}")
    print(f"long labels >{LONG_LABEL_THRESHOLD}: {report['long_label_risk']['total']}")
    print(f"report: {displayed_output}")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
