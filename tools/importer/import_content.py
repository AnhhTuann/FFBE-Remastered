#!/usr/bin/env python3
"""Validate and import local FFBE-style content packs without executing inputs.

The importer is deliberately conservative:

* Python standard library only, no network access and no ``eval``/``exec``.
* ZIP and JSON data are untrusted: names, sizes and compression ratios are
  checked before any member is read; executable member names and symlinks are
  rejected; ZIP members are never extracted to disk.
* Recovered original/community data is not imported unless rights were
  explicitly cleared. Synthetic and newly designed fixtures stay distinct.
* Reports are deterministic JSON (sorted keys, no timestamps). Timestamps are
  used only for staging directory names and the JSONL import log.

Example:
    python3 tools/importer/import_content.py --input /path/to/pack.zip --dry-run
    python3 tools/importer/import_content.py --input /path/to/pack.zip
    python3 tools/importer/import_content.py --rollback my-pack
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import re
import shutil
import stat
import sys
import uuid
import zipfile
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any, Iterable, Iterator

TOOL_VERSION = "1.0.0"
SCHEMA_VERSION = 1

MAX_FILE_BYTES = 20 * 1024 * 1024
MAX_ARCHIVE_BYTES = 512 * 1024 * 1024
MAX_COMPRESSION_RATIO = 200

RESTRICTED_EXTENSIONS = {
    ".py", ".sh", ".exe", ".dll", ".so", ".bat", ".cmd", ".apk", ".jar",
}
REGIONS = {"GL", "JP"}
EVIDENCE_CLASSES = {
    "ORIGINAL_SOURCE", "COMMUNITY_RECOVERED", "COMMUNITY_MODIFIED",
    "UNVERIFIED", "SYNTHETIC_FIXTURE", "REMASTERED_DESIGN",
}
SAFE_EVIDENCE_CLASSES = {"SYNTHETIC_FIXTURE", "REMASTERED_DESIGN"}
CLEARED_RIGHTS_STATUS = "cleared_for_specified_use"

KINDS = (
    "unit", "ability", "equip", "materia", "vision_card", "item",
    "encounter", "enemy", "leader_skill", "ability_awakening",
)
KIND_PATTERN = "|".join(re.escape(kind) for kind in KINDS)
STRICT_ID_RE = re.compile(
    rf"^(?:{KIND_PATTERN}):(?:GL|JP):[A-Za-z0-9_.-]+@[a-z0-9_-]+$"
)
COMPOSITE_ID_RE = re.compile(
    rf"(?<![A-Za-z0-9_.:-])(?:{KIND_PATTERN}):(?:GL|JP):[A-Za-z0-9_.-]+@[a-z0-9_-]+(?![A-Za-z0-9_.:-])"
)
PACK_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*$")
DRIVE_RE = re.compile(r"^[A-Za-z]:")

# Expected kind prefixes for typed reference fields. "refs" and "requires"
# are intentionally broad; the other fields have obvious domain contexts.
REFERENCE_FIELD_KINDS: dict[str, set[str]] = {
    "refs": set(KINDS),
    "requires": set(KINDS),
    "asset_refs": set(),
    "abilities": {"ability", "ability_awakening", "leader_skill"},
    "equipment": {"equip"},
    "passives": {"materia", "ability"},
}
ASSET_KEY_NAMES = {"path", "ref", "asset", "file", "relative_path", "src"}
ASSET_METADATA_KEYS = {"sha256", "hash", "checksum", "size", "size_bytes"}
REQUIRED_PROVENANCE_KEYS = ("origin", "source", "license")
REQUIRED_RECORD_FIELDS = ("id", "kind", "region", "verification_status", "provenance")
REQUIRED_MANIFEST_FIELDS = (
    "schema_version", "pack_id", "namespace", "region", "source_revision",
    "source_version", "rights_status", "evidence_class", "records",
)

STATUS_PRIORITY = {
    "valid": 0,
    "duplicate_identical": 1,
    "unresolved": 2,
    "invalid": 3,
    "conflict": 4,
}


class ImporterError(Exception):
    """Base error with a stable machine-readable code."""

    code = "internal_error"

    def __init__(self, message: str, *, code: str | None = None,
                 report: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.code = code or self.code
        self.report = report


class ValidationError(ImporterError):
    """Untrusted input failed validation; no content state is changed."""

    code = "validation_error"


class SafetyError(ValidationError):
    """Untrusted input failed an archive/path safety check."""

    code = "unsafe_input"


@dataclass(frozen=True)
class SourceFile:
    name: str
    data: bytes


@dataclass
class Analysis:
    report: dict[str, Any]
    manifest: dict[str, Any] | None
    sources: list[SourceFile]
    blocking: bool
    importable_records: list[dict[str, Any]] = field(default_factory=list)
    pack_bytes: bytes | None = None


@dataclass
class Snapshot:
    files: dict[Path, bytes | None] = field(default_factory=dict)
    directories: list[Path] = field(default_factory=list)

    @classmethod
    def capture(cls, *, files: Iterable[Path], directories: Iterable[Path]) -> "Snapshot":
        return cls(
            files={path: path.read_bytes() if path.is_file() else None for path in files},
            directories=[path for path in directories if path.exists()],
        )

    def restore(self) -> None:
        for directory in self.directories:
            if directory.exists():
                shutil.rmtree(directory)
        for path, original in self.files.items():
            if original is None:
                if path.is_file():
                    path.unlink()
            else:
                _atomic_write(path, original)


# ---------------------------------------------------------------------------
# Small deterministic helpers


def _utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")


def _json_bytes(value: Any) -> bytes:
    text = json.dumps(value, sort_keys=True, indent=2, ensure_ascii=False, allow_nan=False)
    return (text + "\n").encode("utf-8")


def _reject_json_constant(value: str) -> Any:
    raise ValueError(f"non-finite JSON number {value!r} is not allowed")


def _object_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key {key!r}")
        result[key] = value
    return result


def _json_loads(data: bytes, *, label: str = "JSON") -> Any:
    try:
        text = data.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise ValidationError(f"{label} is not valid UTF-8: {exc}", code="invalid_json") from exc
    try:
        return json.loads(
            text, object_pairs_hook=_object_pairs, parse_constant=_reject_json_constant
        )
    except ValueError as exc:
        raise ValidationError(f"{label} is not valid JSON: {exc}", code="invalid_json") from exc


def _canonical_sha256(value: Any) -> str:
    payload = json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def _file_sha256(path: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
            size += len(chunk)
    return digest.hexdigest(), size


def _atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(f".{path.name}.{uuid.uuid4().hex}.tmp")
    try:
        with temp.open("wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp, path)
    finally:
        if temp.exists():
            temp.unlink()


def _write_report(report: dict[str, Any], path: Path) -> Path:
    _atomic_write(path, _json_bytes(report))
    return path


def _backup_file(path: Path) -> None:
    if path.is_file():
        _atomic_write(Path(str(path) + ".bak"), path.read_bytes())


def _append_log(root: Path, entry: dict[str, Any]) -> None:
    path = _content_paths(root)["reports"] / "import.log"
    path.parent.mkdir(parents=True, exist_ok=True)
    line = json.dumps(entry, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(line + "\n")


def _root(root: Path | str | None) -> Path:
    if root is None:
        return Path(__file__).resolve().parents[2]
    return Path(root).expanduser().resolve()


def _rooted(root: Path, value: Path | str) -> Path:
    path = Path(value).expanduser()
    return path if path.is_absolute() else (root / path)


def _content_paths(root: Path) -> dict[str, Path]:
    base = root / "content-local"
    return {
        "base": base,
        "raw": base / "raw",
        "staging": base / "staging",
        "normalized": base / "normalized",
        "assets": base / "assets",
        "packs": base / "packs",
        "reports": base / "reports",
        "index": base / "normalized" / "index.json",
        "journal": base / "reports" / "import-journal.json",
        "log": base / "reports" / "import.log",
    }


def _ensure_layout(root: Path) -> dict[str, Path]:
    paths = _content_paths(root)
    for key in ("raw", "staging", "normalized", "assets", "packs", "reports", "data"):
        target = paths["base"] / key if key == "data" else paths[key]
        target.mkdir(parents=True, exist_ok=True)
    return paths


def _default_report_path(root: Path, mode: str, pack_id: str) -> Path:
    safe_id = pack_id if PACK_ID_RE.fullmatch(pack_id) else "unknown"
    return _content_paths(root)["reports"] / f"{mode}-{safe_id}-{_utc_stamp()}.json"


def _issue(code: str, message: str, *, level: str = "error",
           record_index: int | None = None, record_id: str | None = None,
           field: str | None = None, **extra: Any) -> dict[str, Any]:
    result: dict[str, Any] = {"code": code, "level": level, "message": message}
    if record_index is not None:
        result["record_index"] = record_index
    if record_id is not None:
        result["record_id"] = record_id
    if field is not None:
        result["field"] = field
    result.update(extra)
    return result


def _issue_key(issue: dict[str, Any]) -> tuple[Any, ...]:
    return (
        issue.get("record_index", -1), str(issue.get("record_id", "")),
        str(issue.get("field", "")), issue["code"], issue["message"],
    )


def _record_key(record: dict[str, Any]) -> tuple[Any, ...]:
    return (str(record.get("id", "")), int(record.get("index", -1)))


def _counts() -> dict[str, int]:
    return {
        "discovered": 0, "parsed": 0, "valid": 0, "blocked": 0,
        "duplicates": 0, "conflicts": 0, "unresolved": 0, "asset_refs": 0,
    }


def _raise_status(record: dict[str, Any], status: str) -> None:
    current = record.get("status", "valid")
    if STATUS_PRIORITY[status] > STATUS_PRIORITY[current]:
        record["status"] = status


# ---------------------------------------------------------------------------
# Untrusted input discovery and archive safety


def _safe_relative_name(name: str) -> str:
    if not isinstance(name, str) or not name:
        raise SafetyError("empty entry name in input", code="unsafe_name")
    if "\x00" in name:
        raise SafetyError(f"NUL byte in entry name {name!r}", code="unsafe_name")
    if "\\" in name:
        raise SafetyError(f"backslash path separator in entry name {name!r}", code="unsafe_path")
    if name.startswith("/") or PurePosixPath(name).is_absolute():
        raise SafetyError(f"absolute path rejected: {name!r}", code="absolute_path")
    if DRIVE_RE.match(name):
        raise SafetyError(f"drive-prefixed path rejected: {name!r}", code="drive_path")
    parts = name.split("/")
    if any(part in ("", ".", "..") for part in parts):
        raise SafetyError(
            f"path traversal or unsafe component in {name!r}", code="path_traversal"
        )
    return "/".join(parts)


def _check_file_allowed(name: str, size: int) -> None:
    suffix = PurePosixPath(name).suffix.lower()
    if suffix in RESTRICTED_EXTENSIONS:
        raise SafetyError(
            f"restricted executable extension {suffix!r} in {name!r}",
            code="restricted_extension",
        )
    if size > MAX_FILE_BYTES:
        raise SafetyError(
            f"file too large: {name!r} is {size} bytes (limit {MAX_FILE_BYTES})",
            code="file_too_large",
        )


def load_input(input_path: Path | str, root: Path | str | None = None) -> list[SourceFile]:
    """Read a directory or ZIP without extracting or executing any input."""
    path = _rooted(_root(root), input_path)
    if not path.exists():
        raise ValidationError(f"input not found: {path.name!r}", code="input_not_found")

    sources: list[SourceFile] = []
    if path.is_dir():
        for directory, dirs, files in os.walk(path, followlinks=False):
            dirs.sort()
            files.sort()
            for dirname in list(dirs):
                if (Path(directory) / dirname).is_symlink():
                    raise SafetyError(
                        f"symlink directory rejected: {dirname!r}", code="symlink_entry"
                    )
            for filename in files:
                file_path = Path(directory) / filename
                if file_path.is_symlink():
                    raise SafetyError(
                        f"symlink file rejected: {filename!r}", code="symlink_entry"
                    )
                name = _safe_relative_name(file_path.relative_to(path).as_posix())
                size = file_path.stat().st_size
                _check_file_allowed(name, size)
                sources.append(SourceFile(name, file_path.read_bytes()))
        sources.sort(key=lambda source: source.name)
        return sources

    if not path.is_file() or path.suffix.lower() != ".zip":
        raise ValidationError(
            "input must be a directory or a .zip file", code="unsupported_input"
        )

    archive_size = path.stat().st_size
    if archive_size > MAX_ARCHIVE_BYTES:
        raise SafetyError(
            f"archive too large: {archive_size} bytes (limit {MAX_ARCHIVE_BYTES})",
            code="archive_too_large",
        )
    try:
        with zipfile.ZipFile(path) as archive:
            infos = archive.infolist()
            entries: list[tuple[zipfile.ZipInfo, str]] = []
            total_uncompressed = 0
            total_compressed = 0
            for info in infos:
                if info.is_dir():
                    continue
                name = _safe_relative_name(info.filename)
                mode = (info.external_attr >> 16) & 0o170000
                if stat.S_ISLNK(mode):
                    raise SafetyError(
                        f"symlink ZIP entry rejected: {name!r}", code="symlink_entry"
                    )
                _check_file_allowed(name, info.file_size)
                ratio = info.file_size / max(info.compress_size, 1)
                if ratio > MAX_COMPRESSION_RATIO:
                    raise SafetyError(
                        f"compression ratio {ratio:.1f}:1 rejected for {name!r} "
                        f"(limit {MAX_COMPRESSION_RATIO}:1)",
                        code="compression_ratio",
                    )
                total_uncompressed += info.file_size
                total_compressed += info.compress_size
                entries.append((info, name))

            if total_uncompressed > MAX_ARCHIVE_BYTES or total_compressed > MAX_ARCHIVE_BYTES:
                raise SafetyError(
                    f"archive contents exceed {MAX_ARCHIVE_BYTES} bytes",
                    code="archive_too_large",
                )
            if total_uncompressed / max(total_compressed, 1) > MAX_COMPRESSION_RATIO:
                raise SafetyError(
                    "archive-wide compression ratio exceeds 200:1", code="compression_ratio"
                )

            for info, name in entries:
                try:
                    data = archive.read(info)
                except (RuntimeError, zipfile.BadZipFile, NotImplementedError, OSError) as exc:
                    raise SafetyError(
                        f"cannot safely read ZIP entry {name!r}: {exc}", code="unreadable_entry"
                    ) from exc
                if len(data) > MAX_FILE_BYTES:
                    raise SafetyError(
                        f"expanded ZIP entry too large: {name!r}", code="file_too_large"
                    )
                sources.append(SourceFile(name, data))
    except zipfile.BadZipFile as exc:
        raise ValidationError(f"invalid ZIP archive: {exc}", code="invalid_zip") from exc
    sources.sort(key=lambda source: source.name)
    return sources


def _find_manifest(sources: list[SourceFile]) -> tuple[str, dict[str, Any]]:
    candidates: list[tuple[str, dict[str, Any]]] = []
    for source in sources:
        if PurePosixPath(source.name).suffix.lower() != ".json":
            continue
        value = _json_loads(source.data, label=f"JSON entry {source.name!r}")
        if isinstance(value, dict) and "records" in value and "schema_version" in value:
            candidates.append((source.name, value))
    if not candidates:
        raise ValidationError(
            "no manifest JSON object with schema_version and records was found",
            code="manifest_not_found",
        )
    candidates.sort(
        key=lambda item: (
            0 if PurePosixPath(item[0]).name == "manifest.json" else 1,
            item[0].count("/"), item[0],
        )
    )
    return candidates[0]


def _validate_manifest_shape(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    problems: list[dict[str, Any]] = []
    for key in REQUIRED_MANIFEST_FIELDS:
        if key not in manifest:
            problems.append(_issue("missing_manifest_field", f"missing manifest field {key!r}", field=key))
    if "schema_version" in manifest and (
        isinstance(manifest["schema_version"], bool) or manifest["schema_version"] != SCHEMA_VERSION
    ):
        problems.append(_issue("unsupported_schema_version", f"schema_version must be {SCHEMA_VERSION}", field="schema_version"))
    pack_id = manifest.get("pack_id")
    if "pack_id" in manifest and (
        not isinstance(pack_id, str) or not PACK_ID_RE.fullmatch(pack_id) or ".." in pack_id
    ):
        problems.append(_issue("invalid_pack_id", f"unsafe pack_id {pack_id!r}", field="pack_id"))
    for key in ("namespace", "source_revision", "source_version", "rights_status", "evidence_class"):
        if key in manifest and (not isinstance(manifest[key], str) or not manifest[key].strip()):
            problems.append(_issue("invalid_manifest_field", f"{key} must be a non-empty string", field=key))
    if "region" in manifest and manifest["region"] not in REGIONS:
        problems.append(_issue("invalid_region", f"region must be GL or JP, got {manifest['region']!r}", field="region"))
    if "evidence_class" in manifest and manifest["evidence_class"] not in EVIDENCE_CLASSES:
        problems.append(_issue("invalid_evidence_class", f"unknown evidence_class {manifest['evidence_class']!r}", field="evidence_class"))
    if "records" in manifest and not isinstance(manifest["records"], list):
        problems.append(_issue("invalid_records", "records must be an array", field="records"))
    if "asset_refs" in manifest and not isinstance(manifest["asset_refs"], (dict, list, str)):
        problems.append(_issue("invalid_asset_refs", "asset_refs must be a string, array or object", field="asset_refs"))
    return problems


def _rights_allowed(manifest: dict[str, Any]) -> bool:
    evidence = manifest.get("evidence_class")
    rights = manifest.get("rights_status")
    return evidence in SAFE_EVIDENCE_CLASSES or rights == CLEARED_RIGHTS_STATUS


def _build_report(*, mode: str, input_label: str, manifest: dict[str, Any] | None,
                  counts: dict[str, int], issues: list[dict[str, Any]],
                  records: list[dict[str, Any]], unresolved: list[dict[str, Any]],
                  asset_refs: list[dict[str, Any]], result: str,
                  error: dict[str, str] | None = None, **extra: Any) -> dict[str, Any]:
    report: dict[str, Any] = {
        "tool_version": TOOL_VERSION,
        "schema_version": SCHEMA_VERSION,
        "mode": mode,
        "result": result,
        "input": input_label,
        "pack_id": manifest.get("pack_id", "") if manifest and isinstance(manifest.get("pack_id"), str) else "",
        "namespace": manifest.get("namespace", "") if manifest and isinstance(manifest.get("namespace"), str) else "",
        "region": manifest.get("region", "") if manifest and isinstance(manifest.get("region"), str) else "",
        "evidence_class": manifest.get("evidence_class", "") if manifest and isinstance(manifest.get("evidence_class"), str) else "",
        "rights_status": manifest.get("rights_status", "") if manifest and isinstance(manifest.get("rights_status"), str) else "",
        "counts": counts,
        "diagnostics": sorted(issues, key=_issue_key),
        "records": sorted(records, key=_record_key),
        "unresolved": sorted(
            unresolved,
            key=lambda item: (str(item.get("record_id", "")), str(item.get("field", "")), item.get("target_id", "")),
        ),
        "asset_refs": sorted(asset_refs, key=lambda item: (item.get("path", ""), item.get("referenced_by", ""))),
    }
    if error is not None:
        report["error"] = error
    report.update(extra)
    return report


def _empty_analysis_report(mode: str, input_label: str, manifest: dict[str, Any] | None,
                           counts: dict[str, int], issues: list[dict[str, Any]],
                           result: str = "blocked") -> dict[str, Any]:
    return _build_report(
        mode=mode, input_label=input_label, manifest=manifest, counts=counts,
        issues=issues, records=[], unresolved=[], asset_refs=[], result=result,
    )


# ---------------------------------------------------------------------------
# Record, reference and asset validation


def _iter_strings(value: Any) -> Iterator[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for key in sorted(value, key=str):
            yield from _iter_strings(value[key])
    elif isinstance(value, (list, tuple)):
        for item in value:
            yield from _iter_strings(item)


def _iter_asset_strings(value: Any) -> Iterator[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for key in sorted(value, key=str):
            if key in ASSET_METADATA_KEYS:
                continue
            yield from _iter_asset_strings(value[key])
    elif isinstance(value, (list, tuple)):
        for item in value:
            yield from _iter_asset_strings(item)


def _validate_asset_ref(value: str, assets_root: Path, *, referenced_by: str,
                        field: str, record_index: int | None) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    issues: list[dict[str, Any]] = []
    prefix = "content-local/assets/"
    relative = value[len(prefix):] if value.startswith(prefix) else value
    if STRICT_ID_RE.fullmatch(value) or COMPOSITE_ID_RE.fullmatch(value):
        issues.append(_issue(
            "invalid_asset_ref", "asset_ref must be a relative file path, not a composite ID",
            record_index=record_index, record_id=referenced_by or None, field=field, ref=value,
        ))
        return {}, issues
    if not relative or not relative.strip():
        issues.append(_issue(
            "invalid_asset_ref", "asset_ref must be a non-empty relative path",
            record_index=record_index, record_id=referenced_by or None, field=field, ref=value,
        ))
        return {}, issues
    if "\\" in relative or DRIVE_RE.match(relative) or relative.startswith("/") or PurePosixPath(relative).is_absolute():
        issues.append(_issue(
            "unsafe_asset_path", f"unsafe asset path {value!r}",
            record_index=record_index, record_id=referenced_by or None, field=field, ref=value,
        ))
        return {}, issues
    parts = relative.split("/")
    if any(part in ("", ".", "..") for part in parts):
        issues.append(_issue(
            "unsafe_asset_path", f"asset path escapes content-local/assets: {value!r}",
            record_index=record_index, record_id=referenced_by or None, field=field, ref=value,
        ))
        return {}, issues
    if PurePosixPath(relative).suffix.lower() in RESTRICTED_EXTENSIONS:
        issues.append(_issue(
            "restricted_asset_extension", f"restricted asset extension in {value!r}",
            record_index=record_index, record_id=referenced_by or None, field=field, ref=value,
        ))
        return {}, issues

    root_resolved = assets_root.resolve()
    candidate = assets_root.joinpath(*parts)
    current = assets_root
    for part in parts:
        current = current / part
        if current.is_symlink():
            issues.append(_issue(
                "unsafe_asset_path", f"symlink in asset path {value!r}",
                record_index=record_index, record_id=referenced_by or None, field=field, ref=value,
            ))
            return {}, issues
    if not candidate.resolve().is_relative_to(root_resolved):
        issues.append(_issue(
            "unsafe_asset_path", f"asset path resolves outside content-local/assets: {value!r}",
            record_index=record_index, record_id=referenced_by or None, field=field, ref=value,
        ))
        return {}, issues
    if not candidate.is_file():
        issues.append(_issue(
            "asset_not_found", f"asset file does not exist: content-local/assets/{relative}",
            record_index=record_index, record_id=referenced_by or None, field=field, ref=value,
        ))
        return {}, issues

    sha256, size = _file_sha256(candidate)
    return {
        "path": f"content-local/assets/{relative}",
        "ref": value,
        "sha256": sha256,
        "size_bytes": size,
        "referenced_by": referenced_by,
        "field": field,
    }, issues


def _read_index(root: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    path = _content_paths(root)["index"]
    if not path.exists():
        return {"schema_version": SCHEMA_VERSION, "packs": {}}, []
    value = _json_loads(path.read_bytes(), label="normalized index")
    if not isinstance(value, dict) or not isinstance(value.get("packs", {}), dict):
        raise ValidationError("normalized index has invalid shape", code="invalid_index")
    value.setdefault("schema_version", SCHEMA_VERSION)
    value.setdefault("packs", {})
    return value, []


def _index_record_map(index: dict[str, Any]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for pack_id, entry in sorted(index.get("packs", {}).items()):
        if not isinstance(entry, dict):
            continue
        hashes = entry.get("record_sha256", {})
        ids = entry.get("record_ids", [])
        if isinstance(hashes, dict):
            for record_id, digest in hashes.items():
                result.setdefault(str(record_id), {"sha256": str(digest), "pack_id": str(pack_id)})
        if isinstance(ids, list):
            for record_id in ids:
                result.setdefault(str(record_id), {"sha256": None, "pack_id": str(pack_id)})
    return result


def analyze_input(input_path: Path | str, root: Path | str | None = None,
                  *, mode: str = "preview") -> Analysis:
    """Load, safety-check and validate an input without changing content state."""
    resolved_root = _root(root)
    sources = load_input(input_path, resolved_root)
    input_label = Path(input_path).name
    counts = _counts()
    counts["discovered"] = len(sources)

    manifest_name, manifest = _find_manifest(sources)
    issues: list[dict[str, Any]] = []
    shape_problems = _validate_manifest_shape(manifest)
    issues.extend(shape_problems)
    records_in = manifest.get("records") if isinstance(manifest.get("records"), list) else []
    counts["parsed"] = len(records_in)

    if shape_problems:
        report = _empty_analysis_report(
            mode, input_label, manifest, counts, issues, "blocked"
        )
        report["manifest"] = manifest_name
        return Analysis(report, manifest, sources, True)

    if not _rights_allowed(manifest):
        issues.append(_issue(
            "rights_blocked",
            "import blocked: evidence_class is not synthetic/designed and rights_status is not "
            f"{CLEARED_RIGHTS_STATUS!r}",
            field="rights_status", evidence_class=manifest.get("evidence_class"),
        ))
        counts["blocked"] = len(records_in)
        report = _empty_analysis_report(
            mode, input_label, manifest, counts, issues, "blocked"
        )
        report["manifest"] = manifest_name
        return Analysis(report, manifest, sources, True)

    paths = _content_paths(resolved_root)
    try:
        index, index_issues = _read_index(resolved_root)
    except ValidationError as exc:
        issues.append(_issue(exc.code, str(exc), field="index.json"))
        index = {"schema_version": SCHEMA_VERSION, "packs": {}}
        index_issues = []
    issues.extend(index_issues)
    existing_ids = _index_record_map(index)
    known_ids = set(existing_ids)

    prepared: list[dict[str, Any]] = []
    seen_in_pack: dict[str, dict[str, Any]] = {}
    for index_number, raw in enumerate(records_in):
        local_issues: list[dict[str, Any]] = []
        if not isinstance(raw, dict):
            local_issues.append(_issue(
                "record_not_object", f"record {index_number} is not a JSON object",
                record_index=index_number,
            ))
            prepared.append({
                "index": index_number, "id": "", "record": {}, "sha256": "",
                "status": "invalid", "issues": local_issues, "unresolved": [],
                "duplicate_in_pack": False,
            })
            continue

        record = copy.deepcopy(raw)
        if "schema_version" not in record:
            record["schema_version"] = manifest["schema_version"]
        elif record["schema_version"] != SCHEMA_VERSION:
            local_issues.append(_issue(
                "unsupported_schema_version", "record schema_version must be 1",
                record_index=index_number, record_id=str(record.get("id", "")), field="schema_version",
            ))
        for key in REQUIRED_RECORD_FIELDS:
            if key not in record:
                local_issues.append(_issue(
                    "missing_record_field", f"missing record field {key!r}",
                    record_index=index_number, record_id=str(record.get("id", "")), field=key,
                ))
                continue
            value = record[key]
            if key == "provenance":
                if not isinstance(value, dict) or not value or any(
                    not isinstance(value.get(name), str) or not value[name].strip()
                    for name in REQUIRED_PROVENANCE_KEYS
                ):
                    local_issues.append(_issue(
                        "invalid_provenance",
                        "provenance must be a non-empty dict with origin, source and license strings",
                        record_index=index_number, record_id=str(record.get("id", "")), field=key,
                    ))
            elif not isinstance(value, str) or not value.strip():
                local_issues.append(_issue(
                    "invalid_record_field", f"{key} must be a non-empty string",
                    record_index=index_number, record_id=str(record.get("id", "")), field=key,
                ))

        record_id = record.get("id") if isinstance(record.get("id"), str) else ""
        kind = record.get("kind") if isinstance(record.get("kind"), str) else ""
        if record_id:
            if not STRICT_ID_RE.fullmatch(record_id):
                local_issues.append(_issue(
                    "invalid_id", f"invalid composite ID {record_id!r}",
                    record_index=index_number, record_id=record_id, field="id",
                ))
            else:
                prefix = record_id.split(":", 1)[0]
                if kind and kind != prefix:
                    local_issues.append(_issue(
                        "kind_id_mismatch", f"kind {kind!r} does not match ID prefix {prefix!r}",
                        record_index=index_number, record_id=record_id, field="kind",
                    ))
                record_region = record_id.split(":", 2)[1]
                if record_region != manifest["region"]:
                    local_issues.append(_issue(
                        "id_region_mismatch",
                        f"record region {record_region!r} does not match manifest region "
                        f"{manifest['region']!r}",
                        record_index=index_number, record_id=record_id, field="id",
                    ))
        if isinstance(record.get("region"), str) and record["region"] != manifest["region"]:
            local_issues.append(_issue(
                "record_region_mismatch",
                f"record field region {record['region']!r} does not match manifest region "
                f"{manifest['region']!r}",
                record_index=index_number, record_id=record_id, field="region",
            ))
        if kind and kind not in KINDS:
            local_issues.append(_issue(
                "invalid_kind", f"unknown record kind {kind!r}",
                record_index=index_number, record_id=record_id, field="kind",
            ))

        canonical = _canonical_sha256(record)
        status = "invalid" if local_issues else "valid"
        known_ids.add(record_id)
        duplicate_in_pack = False
        if record_id and status == "valid":
            if record_id in seen_in_pack:
                duplicate_in_pack = True
                status = "duplicate_identical" if seen_in_pack[record_id]["sha256"] == canonical else "conflict"
                code = "duplicate_in_pack_identical" if status == "duplicate_identical" else "duplicate_in_pack_conflict"
                local_issues.append(_issue(
                    code, f"duplicate ID inside pack: {record_id}",
                    record_index=index_number, record_id=record_id, field="id",
                ))
            else:
                seen_in_pack[record_id] = {"sha256": canonical, "index": index_number}

        prepared.append({
            "index": index_number, "id": record_id, "record": record,
            "sha256": canonical, "status": status, "issues": local_issues,
            "unresolved": [], "duplicate_in_pack": duplicate_in_pack,
        })

    # Existing normalized state: identical IDs are reported and skipped;
    # conflicting content is a hard validation error and never overwrites.
    for item in prepared:
        record_id = item["id"]
        if not record_id:
            continue
        previous = existing_ids.get(record_id)
        if previous is None:
            continue
        if previous["sha256"] == item["sha256"]:
            item["issues"].append(_issue(
                "duplicate_identical",
                f"record already present with identical content in pack {previous['pack_id']!r}",
                record_index=item["index"], record_id=record_id, field="id", level="info",
                existing_pack_id=previous["pack_id"], sha256=item["sha256"],
            ))
            _raise_status(item, "duplicate_identical")
        else:
            item["issues"].append(_issue(
                "conflict",
                f"record conflicts with existing content in pack {previous['pack_id']!r}",
                record_index=item["index"], record_id=record_id, field="id",
                existing_pack_id=previous["pack_id"], sha256=item["sha256"],
                existing_sha256=previous["sha256"],
            ))
            _raise_status(item, "conflict")

    # Typed references. Unknown targets are listed explicitly and never
    # counted as valid, even when the record otherwise passes schema checks.
    unresolved_seen: dict[tuple[str, str, str], dict[str, Any]] = {}
    for item in prepared:
        record = item["record"]
        if not isinstance(record, dict):
            continue
        for field_name, allowed_kinds in REFERENCE_FIELD_KINDS.items():
            if field_name not in record:
                continue
            for value in _iter_strings(record[field_name]):
                for match in COMPOSITE_ID_RE.finditer(value):
                    target = match.group(0)
                    prefix = target.split(":", 1)[0]
                    kind_problem = bool(allowed_kinds) and prefix not in allowed_kinds
                    if kind_problem:
                        item["issues"].append(_issue(
                            "reference_kind_mismatch",
                            f"field {field_name!r} expects {sorted(allowed_kinds)} but found {prefix!r}",
                            record_index=item["index"], record_id=item["id"], field=field_name,
                            target_id=target,
                        ))
                        _raise_status(item, "invalid")
                    if target not in known_ids:
                        key = (item["id"], field_name, target)
                        unresolved_seen.setdefault(key, {
                            "record_id": item["id"], "field": field_name,
                            "target_id": target, "kind": prefix,
                        })
                        item["unresolved"].append(target)
                        item["issues"].append(_issue(
                            "unresolved_reference",
                            f"unresolved reference {target!r} in field {field_name!r}",
                            record_index=item["index"], record_id=item["id"], field=field_name,
                            target_id=target,
                        ))
                        _raise_status(item, "unresolved")
    for item in prepared:
        item["unresolved"] = sorted(set(item["unresolved"]))

    # Asset references: record hashes and byte sizes, never copy files.
    asset_seen: dict[str, dict[str, Any]] = {}
    asset_ref_sources: list[tuple[str | None, int | None, str, str]] = []
    if "asset_refs" in manifest:
        for value in _iter_asset_strings(manifest["asset_refs"]):
            asset_ref_sources.append((None, None, "manifest.asset_refs", value))
    for item in prepared:
        record = item["record"]
        if isinstance(record, dict) and "asset_refs" in record:
            for value in _iter_asset_strings(record["asset_refs"]):
                asset_ref_sources.append((item["id"], item["index"], "asset_refs", value))

    for record_id, record_index, asset_field, value in asset_ref_sources:
        metadata, asset_issues = _validate_asset_ref(
            value, paths["assets"], referenced_by=record_id or "", field=asset_field,
            record_index=record_index,
        )
        if asset_issues:
            issues.extend(asset_issues)
            if record_id:
                for item in prepared:
                    if item["id"] == record_id and item["index"] == record_index:
                        item["issues"].extend(asset_issues)
                        _raise_status(item, "invalid")
                        break
            continue
        path = metadata["path"]
        if path in asset_seen:
            referenced = asset_seen[path]["referenced_by"]
            if record_id and record_id not in referenced:
                asset_seen[path]["referenced_by"] = f"{referenced},{record_id}"
            continue
        asset_seen[path] = metadata

    # Re-import of an already indexed pack is allowed only when every record
    # is an identical duplicate (a no-op); otherwise it is a conflict.
    pack_id = manifest["pack_id"]
    importable = [item["record"] for item in prepared if item["status"] == "valid"]
    if pack_id in index.get("packs", {}) and importable:
        issues.append(_issue(
            "pack_id_conflict",
            f"pack {pack_id!r} is already present in the normalized index",
            field="pack_id",
        ))
    for generated in (
        paths["normalized"] / f"{pack_id}.json", paths["packs"] / f"{pack_id}.json"
    ):
        if generated.exists() and pack_id not in index.get("packs", {}):
            issues.append(_issue(
                "existing_pack_file",
                f"unindexed pack file already exists: {generated.relative_to(resolved_root).as_posix()}",
                field="pack_id",
            ))

    counts["valid"] = sum(1 for item in prepared if item["status"] == "valid")
    counts["duplicates"] = sum(
        1 for item in prepared
        if item["status"] == "duplicate_identical" or item.get("duplicate_in_pack")
    )
    counts["conflicts"] = sum(1 for item in prepared if item["status"] == "conflict")
    counts["unresolved"] = len(unresolved_seen)
    counts["asset_refs"] = len(asset_seen)

    for item in prepared:
        issues.extend(item["issues"])
    issues.sort(key=_issue_key)
    blocking = any(issue["level"] == "error" for issue in issues)
    records = [{
        "id": item["id"],
        "index": item["index"],
        "kind": item["record"].get("kind", "") if isinstance(item["record"], dict) else "",
        "status": item["status"],
        "sha256": item["sha256"],
        "unresolved": item["unresolved"],
        "diagnostics": sorted(item["issues"], key=_issue_key),
    } for item in prepared]

    pack_payload: dict[str, Any] | None = None
    if not blocking:
        pack_payload = {
            "schema_version": SCHEMA_VERSION,
            "pack_id": pack_id,
            "namespace": manifest["namespace"],
            "region": manifest["region"],
            "source_revision": manifest["source_revision"],
            "source_version": manifest["source_version"],
            "evidence_class": manifest["evidence_class"],
            "rights_status": manifest["rights_status"],
            "importer_version": TOOL_VERSION,
            "records": sorted(importable, key=lambda record: str(record.get("id", ""))),
            "record_sha256": {
                item["id"]: item["sha256"] for item in prepared if item["status"] == "valid"
            },
            "asset_refs": list(asset_seen.values()),
        }

    report = _build_report(
        mode=mode, input_label=input_label, manifest=manifest, counts=counts,
        issues=issues, records=records,
        unresolved=list(unresolved_seen.values()), asset_refs=list(asset_seen.values()),
        result="ok" if not blocking else "blocked",
        manifest_name=manifest_name,
        pack_sha256=_canonical_sha256(pack_payload) if pack_payload else "",
    )
    return Analysis(
        report=report, manifest=manifest, sources=sources, blocking=blocking,
        importable_records=importable,
        pack_bytes=_json_bytes(pack_payload) if pack_payload else None,
    )


def _finish_report(analysis: Analysis, *, report_path: Path | None,
                   root: Path, mode: str) -> Path:
    target = report_path or _default_report_path(root, mode, analysis.report.get("pack_id", "unknown"))
    _write_report(analysis.report, target)
    return target


def _log_entry(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "timestamp": _utc_stamp(),
        "pack_id": report.get("pack_id", ""),
        "mode": report.get("mode", ""),
        "counts": report.get("counts", _counts()),
        "result": report.get("result", ""),
    }


def preview_import(input_path: Path | str, root: Path | str | None = None,
                   *, report_path: Path | str | None = None) -> dict[str, Any]:
    """Dry-run: validate and write a deterministic report, changing no content state."""
    resolved_root = _root(root)
    target = _rooted(resolved_root, report_path) if report_path is not None else None
    analysis = analyze_input(input_path, resolved_root, mode="preview")
    if analysis.blocking:
        if target is not None:
            _write_report(analysis.report, target)
        raise ValidationError(
            "preview found validation/blocked errors",
            code=analysis.report.get("diagnostics", [{}])[0].get("code", "validation_error"),
            report=analysis.report,
        )
    _finish_report(analysis, report_path=target, root=resolved_root, mode="preview")
    _append_log(resolved_root, _log_entry(analysis.report))
    return analysis.report


def import_pack(input_path: Path | str, root: Path | str | None = None,
                *, report_path: Path | str | None = None) -> dict[str, Any]:
    """Transactionally import a validated pack into content-local."""
    resolved_root = _root(root)
    target = _rooted(resolved_root, report_path) if report_path is not None else None
    analysis = analyze_input(input_path, resolved_root, mode="import")
    if analysis.blocking:
        if target is not None:
            _write_report(analysis.report, target)
        raise ValidationError(
            "import blocked by validation",
            code=analysis.report.get("diagnostics", [{}])[0].get("code", "validation_error"),
            report=analysis.report,
        )

    manifest = analysis.manifest
    assert manifest is not None
    pack_id = str(manifest["pack_id"])
    paths = _ensure_layout(resolved_root)
    index, _ = _read_index(resolved_root)
    journal, _ = _read_journal(resolved_root)
    normalized_file = paths["normalized"] / f"{pack_id}.json"
    pack_copy = paths["packs"] / f"{pack_id}.json"
    staging_dir = paths["staging"] / f"{pack_id}-{_utc_stamp()}"
    suffix = 0
    while staging_dir.exists():
        suffix += 1
        staging_dir = paths["staging"] / f"{pack_id}-{_utc_stamp()}-{suffix}"
    staging_pack = staging_dir / f"{pack_id}.json"

    if not analysis.importable_records:
        analysis.report["result"] = "duplicate_identical"
        _finish_report(analysis, report_path=target, root=resolved_root, mode="import")
        _append_log(resolved_root, _log_entry(analysis.report))
        return analysis.report

    assert analysis.pack_bytes is not None
    pack_sha256 = hashlib.sha256(analysis.pack_bytes).hexdigest()
    previous_entry = copy.deepcopy(index.get("packs", {}).get(pack_id))
    snapshot = Snapshot.capture(
        files=[
            paths["index"], Path(str(paths["index"]) + ".bak"),
            paths["journal"], Path(str(paths["journal"]) + ".bak"),
            normalized_file, pack_copy,
        ],
        directories=[staging_dir],
    )
    try:
        staging_dir.mkdir(parents=True, exist_ok=False)
        _atomic_write(staging_pack, analysis.pack_bytes)
        _atomic_write(
            staging_dir / "report.json",
            _json_bytes({**analysis.report, "result": "staged"}),
        )
        os.replace(staging_pack, normalized_file)
        _atomic_write(pack_copy, analysis.pack_bytes)

        updated_index = copy.deepcopy(index)
        updated_index["schema_version"] = SCHEMA_VERSION
        updated_index.setdefault("packs", {})[pack_id] = {
            "pack_file": f"content-local/normalized/{pack_id}.json",
            "pack_copy": f"content-local/packs/{pack_id}.json",
            "namespace": manifest["namespace"],
            "region": manifest["region"],
            "source_revision": manifest["source_revision"],
            "source_version": manifest["source_version"],
            "evidence_class": manifest["evidence_class"],
            "rights_status": manifest["rights_status"],
            "record_ids": sorted(
                item["id"] for item in analysis.report["records"] if item["status"] == "valid"
            ),
            "record_sha256": {
                record["id"]: record["sha256"] for record in sorted(
                    (item for item in analysis.report["records"] if item["status"] == "valid"),
                    key=lambda item: item["id"],
                )
            },
            "asset_refs": analysis.report["asset_refs"],
            "pack_sha256": pack_sha256,
        }
        _backup_file(paths["index"])
        _atomic_write(paths["index"], _json_bytes(updated_index))

        entry = {
            "timestamp": _utc_stamp(),
            "action": "import",
            "pack_id": pack_id,
            "result": "imported",
            "counts": analysis.report["counts"],
            "pack_sha256": pack_sha256,
            "record_ids": updated_index["packs"][pack_id]["record_ids"],
            "pack_files": [
                f"content-local/normalized/{pack_id}.json",
                f"content-local/packs/{pack_id}.json",
            ],
            "snapshot": previous_entry,
        }
        updated_journal = copy.deepcopy(journal)
        updated_journal["schema_version"] = SCHEMA_VERSION
        updated_journal.setdefault("entries", []).append(entry)
        updated_journal.setdefault("packs", {})[pack_id] = entry
        _backup_file(paths["journal"])
        _atomic_write(paths["journal"], _json_bytes(updated_journal))

        analysis.report["result"] = "imported"
        analysis.report["staging_dir"] = staging_dir.relative_to(resolved_root).as_posix()
        analysis.report["pack_sha256"] = pack_sha256
        _finish_report(analysis, report_path=target, root=resolved_root, mode="import")
        _append_log(resolved_root, _log_entry(analysis.report))
        return analysis.report
    except Exception as exc:
        snapshot.restore()
        failure = copy.deepcopy(analysis.report)
        failure["result"] = "failure"
        failure["error"] = {
            "code": getattr(exc, "code", "internal_error"),
            "message": str(exc),
        }
        failure_target = target or _default_report_path(resolved_root, "failure", pack_id)
        try:
            _write_report(failure, failure_target)
        except OSError:
            pass
        try:
            _append_log(resolved_root, _log_entry(failure))
        except OSError:
            pass
        if isinstance(exc, ImporterError):
            raise
        raise ImporterError(
            f"transactional import failed and was rolled back: {exc}",
            code="internal_error", report=failure,
        ) from exc


def _read_journal(root: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    path = _content_paths(root)["journal"]
    if not path.exists():
        return {"schema_version": SCHEMA_VERSION, "entries": [], "packs": {}}, []
    value = _json_loads(path.read_bytes(), label="import journal")
    if not isinstance(value, dict) or not isinstance(value.get("entries", []), list) or not isinstance(value.get("packs", {}), dict):
        raise ValidationError("import journal has invalid shape", code="invalid_journal")
    value.setdefault("schema_version", SCHEMA_VERSION)
    value.setdefault("entries", [])
    value.setdefault("packs", {})
    return value, []


def _safe_generated_file(root: Path, relative: str, pack_id: str) -> Path:
    relative = _safe_relative_name(relative)
    if "/" not in relative:
        raise SafetyError(
            f"journal references an unexpected file for pack {pack_id!r}: {relative!r}",
            code="unsafe_journal_path",
        )
    parent, name = relative.rsplit("/", 1)
    if parent not in ("content-local/normalized", "content-local/packs") or name != f"{pack_id}.json":
        raise SafetyError(
            f"journal references an unexpected file for pack {pack_id!r}: {relative!r}",
            code="unsafe_journal_path",
        )
    return root / relative


def rollback_pack(pack_id: Path | str, root: Path | str | None = None,
                  *, report_path: Path | str | None = None) -> dict[str, Any]:
    """Remove a previously imported pack using the journal snapshot."""
    resolved_root = _root(root)
    identifier = str(pack_id)
    target = _rooted(resolved_root, report_path) if report_path is not None else None
    if not PACK_ID_RE.fullmatch(identifier) or ".." in identifier:
        raise ValidationError(f"unsafe pack_id {identifier!r}", code="invalid_pack_id")
    paths = _content_paths(resolved_root)
    index, _ = _read_index(resolved_root)
    journal, _ = _read_journal(resolved_root)
    entry = journal.get("packs", {}).get(identifier)
    in_index = identifier in index.get("packs", {})
    if entry is None and not in_index:
        report = _build_report(
            mode="rollback", input_label=identifier, manifest=None, counts=_counts(),
            issues=[], records=[], unresolved=[], asset_refs=[], result="noop",
            pack_id=identifier,
        )
        _write_report(report, target or _default_report_path(resolved_root, "rollback-noop", identifier))
        _append_log(resolved_root, _log_entry(report))
        return report

    snapshot_entry = entry.get("snapshot") if isinstance(entry, dict) else None
    relative_files = entry.get("pack_files", []) if isinstance(entry, dict) else []
    if not isinstance(relative_files, list):
        relative_files = []
    files = [
        _safe_generated_file(resolved_root, str(relative), identifier)
        for relative in relative_files
    ]
    if not files:
        files = [
            paths["normalized"] / f"{identifier}.json",
            paths["packs"] / f"{identifier}.json",
        ]

    expected_sha = entry.get("pack_sha256") if isinstance(entry, dict) else None
    issues: list[dict[str, Any]] = []
    if expected_sha and isinstance(expected_sha, str):
        for path in files:
            if path.is_file() and _file_sha256(path)[0] != expected_sha:
                issues.append(_issue(
                    "pack_hash_mismatch",
                    f"refusing to delete modified generated file {path.name!r}",
                    field="pack_files",
                ))

    snapshot = Snapshot.capture(
        files=[
            paths["index"], Path(str(paths["index"]) + ".bak"),
            paths["journal"], Path(str(paths["journal"]) + ".bak"),
            *files,
        ],
        directories=[],
    )
    if issues:
        report = _build_report(
            mode="rollback", input_label=identifier, manifest=None, counts=_counts(),
            issues=issues, records=[], unresolved=[], asset_refs=[], result="blocked",
            pack_id=identifier,
        )
        _write_report(report, target or _default_report_path(resolved_root, "rollback-failure", identifier))
        raise ValidationError("rollback blocked by safety checks", code=issues[0]["code"], report=report)

    try:
        for path in files:
            if path.is_file():
                path.unlink()
        updated_index = copy.deepcopy(index)
        if snapshot_entry is not None:
            updated_index.setdefault("packs", {})[identifier] = snapshot_entry
        else:
            updated_index.get("packs", {}).pop(identifier, None)
        _backup_file(paths["index"])
        _atomic_write(paths["index"], _json_bytes(updated_index))

        updated_journal = copy.deepcopy(journal)
        updated_journal.get("packs", {}).pop(identifier, None)
        updated_journal.setdefault("entries", []).append({
            "timestamp": _utc_stamp(),
            "action": "rollback",
            "pack_id": identifier,
            "result": "rolled_back",
            "removed_files": [path.relative_to(resolved_root).as_posix() for path in files],
            "snapshot_restored": snapshot_entry is not None,
        })
        _backup_file(paths["journal"])
        _atomic_write(paths["journal"], _json_bytes(updated_journal))

        report = _build_report(
            mode="rollback", input_label=identifier, manifest=None, counts=_counts(),
            issues=[], records=[], unresolved=[], asset_refs=[], result="rolled_back",
            pack_id=identifier,
            removed_files=[path.relative_to(resolved_root).as_posix() for path in files],
            snapshot_restored=snapshot_entry is not None,
        )
        _write_report(report, target or _default_report_path(resolved_root, "rollback", identifier))
        _append_log(resolved_root, _log_entry(report))
        return report
    except Exception as exc:
        snapshot.restore()
        failure = _build_report(
            mode="rollback", input_label=identifier, manifest=None, counts=_counts(),
            issues=[_issue(getattr(exc, "code", "internal_error"), str(exc))],
            records=[], unresolved=[], asset_refs=[], result="failure", pack_id=identifier,
            error={"code": getattr(exc, "code", "internal_error"), "message": str(exc)},
        )
        try:
            _write_report(failure, target or _default_report_path(resolved_root, "rollback-failure", identifier))
            _append_log(resolved_root, _log_entry(failure))
        except OSError:
            pass
        if isinstance(exc, ImporterError):
            raise
        raise ImporterError(
            f"rollback failed and was restored: {exc}", code="internal_error", report=failure,
        ) from exc


# ---------------------------------------------------------------------------
# CLI


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--input", help="directory or ZIP input containing a manifest")
    source.add_argument("--rollback", metavar="PACK_ID", help="roll back an imported pack")
    parser.add_argument("--dry-run", action="store_true", help="validate and preview only")
    parser.add_argument("--report", help="report path (relative to --root unless absolute)")
    parser.add_argument("--root", help="repository root (defaults to the repository containing this tool)")
    return parser


def _print_summary(report: dict[str, Any], *, stream: Any) -> None:
    counts = report.get("counts", {})
    print(
        "{mode}: {result} pack={pack} discovered={discovered} parsed={parsed} "
        "valid={valid} blocked={blocked} duplicates={duplicates} conflicts={conflicts} "
        "unresolved={unresolved} asset_refs={asset_refs}".format(
            mode=report.get("mode", "?"), result=report.get("result", "?"),
            pack=report.get("pack_id", "") or "-",
            **{key: counts.get(key, 0) for key in _counts()},
        ),
        file=stream,
    )
    error = report.get("error")
    if error:
        print(f"error[{error.get('code', 'error')}]: {error.get('message', '')}", file=stream)
    elif report.get("result") == "blocked":
        diagnostics = report.get("diagnostics", [])
        if diagnostics:
            print(
                f"error[{diagnostics[0].get('code', 'validation_error')}]: "
                f"{diagnostics[0].get('message', '')}",
                file=stream,
            )


def main(argv: list[str] | None = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    if args.rollback and args.dry_run:
        parser.error("--dry-run cannot be combined with --rollback")
    root = _root(args.root)
    report_path = _rooted(root, args.report) if args.report else None
    try:
        if args.rollback:
            report = rollback_pack(args.rollback, root, report_path=report_path)
        elif args.dry_run:
            report = preview_import(args.input, root, report_path=report_path)
        else:
            report = import_pack(args.input, root, report_path=report_path)
        _print_summary(report, stream=sys.stdout)
        return 0
    except ImporterError as exc:
        if exc.report is not None and report_path is not None:
            try:
                _write_report(exc.report, report_path)
            except OSError:
                pass
        _print_summary(exc.report or {
            "mode": "import", "result": "blocked", "pack_id": "", "counts": _counts(),
            "diagnostics": [{"code": exc.code, "message": str(exc)}],
        }, stream=sys.stderr)
        return 2 if isinstance(exc, ValidationError) else 3
    except Exception as exc:  # pragma: no cover - defensive CLI boundary
        print(f"internal error[{type(exc).__name__}]: {exc}", file=sys.stderr)
        return 3


if __name__ == "__main__":
    raise SystemExit(main())
