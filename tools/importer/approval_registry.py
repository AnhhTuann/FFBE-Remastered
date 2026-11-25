#!/usr/bin/env python3
"""Trusted local approval registry for the content importer.

The registry is deliberately separate from imported packs:

* it is loaded from the repository's ``data/import-approvals/`` directory by
  default, never from an input pack;
* every entry binds an approval to a source identity, an exact revision,
  canonical content hashes, a permitted use, an evidence class, a rights
  status, documented authorization evidence and expiry/revocation state;
* a registry entry records *documented authorization* only. It does not
  create, prove or transfer legal rights, and it never promotes recovered
  evidence to VERIFIED unless it also carries explicit verification evidence.

This module is standard-library only and never executes registry content.
"""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Iterable

REGISTRY_SCHEMA_VERSION = 1
DEFAULT_REGISTRY_DIR = "data/import-approvals"
DEFAULT_REGISTRY_FILENAME = "registry.json"

SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
APPROVAL_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*$")
SOURCE_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_./-]*$")
REVISION_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*$")
RELATIVE_NAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_./-]*$")

EVIDENCE_CLASSES = {
    "ORIGINAL_SOURCE", "COMMUNITY_RECOVERED", "COMMUNITY_MODIFIED",
    "UNVERIFIED", "SYNTHETIC_FIXTURE", "REMASTERED_DESIGN",
}
SAFE_EVIDENCE_CLASSES = {"SYNTHETIC_FIXTURE", "REMASTERED_DESIGN"}
RIGHTS_STATUSES = {
    "cleared_for_specified_use", "not_cleared", "unknown",
    "project-owned-test-data", "reference_only", "not_passed",
}
CLEARED_RIGHTS_STATUS = "cleared_for_specified_use"
VERIFICATION_STATUSES = {
    "VERIFIED", "RECOVERED", "PARTIAL", "UNVERIFIED", "UNAVAILABLE",
    "SYNTHETIC_FIXTURE", "REMASTERED_DESIGN",
}
SAFE_VERIFICATION_STATUSES = {
    "SYNTHETIC_FIXTURE", "REMASTERED_DESIGN", "UNVERIFIED",
    "RECOVERED", "PARTIAL", "UNAVAILABLE",
}
PROVENANCE_ORIGINS = {
    "synthetic_fixture", "project_original", "remastered_design",
    "original_source", "community_recovered", "community_modified",
    "unverified_source",
}
SYNTHETIC_PROVENANCE_ORIGINS = {
    "synthetic_fixture", "project_original", "remastered_design",
}
THIRD_PARTY_PROVENANCE_ORIGINS = {
    "original_source", "community_recovered", "community_modified",
    "unverified_source",
}
PERMITTED_USES = {
    "preview", "runtime_import", "local_research_only", "distribution",
}

# Restricted-source detection is intentionally broad: these tokens and exact
# audited revisions must never be treated as synthetic or self-clearing.
RESTRICTED_SOURCE_TOKENS = ("ffbe", "elvlin")
KNOWN_RESTRICTED_REVISIONS = {
    "f82d603c90ec799f539280267d3af7589c79f117",
    "ce7d98a6499bb8c2f6656f0698f60c30001a05b0",
    "b520e563cbc4364a07ee40331012340dc8aeb841",
    "65da3ca6b7924774c6c22dfbe397157c4a8966c4",
}

APPROVAL_REQUIRED_FIELDS = (
    "approval_id", "state", "source_id", "source_revision",
    "manifest_sha256", "file_sha256", "permitted_use", "evidence_class",
    "rights_status", "verification_status", "verification_evidence",
    "documented_authorization", "rights_basis", "expires_on", "revoked_on",
)


class RegistryError(Exception):
    """Raised for malformed or unreadable trusted registry data."""

    code = "invalid_registry"

    def __init__(self, message: str, *, code: str | None = None) -> None:
        super().__init__(message)
        self.code = code or self.code


def _issue(code: str, message: str, *, level: str = "error",
           field: str | None = None, rule: str | None = None,
           **extra: Any) -> dict[str, Any]:
    result: dict[str, Any] = {"code": code, "level": level, "message": message}
    if field is not None:
        result["field"] = field
    if rule is not None:
        result["rule"] = rule
    result.update(extra)
    return result


def _reject_constant(value: str) -> Any:
    raise ValueError(f"non-finite JSON number {value!r} is not allowed")


def _object_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key {key!r}")
        result[key] = value
    return result


def canonical_json_sha256(value: Any) -> str:
    """Hash a JSON value using the importer's canonical serialization."""
    payload = json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=False,
        allow_nan=False,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def bytes_sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_registry(data: bytes) -> Any:
    try:
        text = data.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise RegistryError(f"registry is not valid UTF-8: {exc}", code="invalid_json") from exc
    try:
        return json.loads(
            text, object_pairs_hook=_object_pairs, parse_constant=_reject_constant
        )
    except ValueError as exc:
        raise RegistryError(f"registry is not valid JSON: {exc}", code="invalid_json") from exc


def _valid_date(value: Any) -> bool:
    if not isinstance(value, str) or not DATE_RE.fullmatch(value):
        return False
    try:
        date.fromisoformat(value)
    except ValueError:
        return False
    return True


def _nonempty_strings(value: Any) -> bool:
    return (
        isinstance(value, list) and bool(value)
        and all(isinstance(item, str) and item.strip() for item in value)
    )


def validate_registry(value: Any) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Return structurally valid entries and deterministic validation issues."""
    if not isinstance(value, dict):
        return [], [_issue("invalid_registry_document", "registry must be a JSON object")]
    issues: list[dict[str, Any]] = []
    if value.get("schema_version") != REGISTRY_SCHEMA_VERSION:
        issues.append(_issue(
            "invalid_registry_schema",
            f"registry schema_version must be {REGISTRY_SCHEMA_VERSION}",
            field="schema_version",
        ))
    raw_entries = value.get("entries")
    if not isinstance(raw_entries, list):
        issues.append(_issue("invalid_registry_entries", "registry entries must be an array", field="entries"))
        return [], issues

    entries: list[dict[str, Any]] = []
    seen: set[str] = set()
    for position, raw in enumerate(raw_entries):
        where = f"entries[{position}]"
        if not isinstance(raw, dict):
            issues.append(_issue("invalid_approval_entry", f"{where} must be an object", field=where))
            continue
        local: list[dict[str, Any]] = []
        for key in APPROVAL_REQUIRED_FIELDS:
            if key not in raw:
                local.append(_issue(
                    "missing_approval_field", f"{where} is missing {key!r}", field=f"{where}.{key}",
                ))
        approval_id = raw.get("approval_id")
        if "approval_id" in raw:
            if not isinstance(approval_id, str) or not APPROVAL_ID_RE.fullmatch(approval_id):
                local.append(_issue(
                    "invalid_approval_id", f"{where} has unsafe approval_id {approval_id!r}",
                    field=f"{where}.approval_id",
                ))
            elif approval_id in seen:
                local.append(_issue(
                    "duplicate_approval_id", f"duplicate approval_id {approval_id!r}",
                    field=f"{where}.approval_id",
                ))
            else:
                seen.add(approval_id)
        if "state" in raw and raw["state"] not in ("active", "revoked"):
            local.append(_issue("invalid_approval_state", f"{where} has unknown state {raw['state']!r}", field=f"{where}.state"))
        for key in ("source_id", "source_revision"):
            if key not in raw:
                continue
            pattern = SOURCE_ID_RE if key == "source_id" else REVISION_RE
            value_in = raw[key]
            if not isinstance(value_in, str) or not pattern.fullmatch(value_in) or ".." in value_in:
                local.append(_issue("invalid_approval_identity", f"{where} has invalid {key} {value_in!r}", field=f"{where}.{key}"))
        if "manifest_sha256" in raw and (
            not isinstance(raw["manifest_sha256"], str)
            or not SHA256_RE.fullmatch(raw["manifest_sha256"])
        ):
            local.append(_issue("invalid_approval_hash", f"{where} has invalid manifest_sha256", field=f"{where}.manifest_sha256"))
        if "file_sha256" in raw:
            file_hashes = raw["file_sha256"]
            if not isinstance(file_hashes, dict):
                local.append(_issue("invalid_approval_hashes", f"{where}.file_sha256 must be an object", field=f"{where}.file_sha256"))
            else:
                for name, digest in sorted(file_hashes.items()):
                    if not isinstance(name, str) or not RELATIVE_NAME_RE.fullmatch(name) or ".." in name:
                        local.append(_issue("unsafe_approval_path", f"{where} has unsafe file path {name!r}", field=f"{where}.file_sha256"))
                    if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
                        local.append(_issue("invalid_approval_hash", f"{where} has invalid hash for {name!r}", field=f"{where}.file_sha256"))
        if "permitted_use" in raw:
            use = raw["permitted_use"]
            if not _nonempty_strings(use) or not set(use).issubset(PERMITTED_USES):
                local.append(_issue("invalid_permitted_use", f"{where} has invalid permitted_use", field=f"{where}.permitted_use"))
        if "evidence_class" in raw and raw["evidence_class"] not in EVIDENCE_CLASSES:
            local.append(_issue("invalid_evidence_class", f"{where} has unknown evidence_class {raw['evidence_class']!r}", field=f"{where}.evidence_class"))
        if "rights_status" in raw and raw["rights_status"] != CLEARED_RIGHTS_STATUS:
            local.append(_issue("invalid_approval_rights", f"{where} must record {CLEARED_RIGHTS_STATUS!r}", field=f"{where}.rights_status"))
        if "verification_status" in raw and raw["verification_status"] not in VERIFICATION_STATUSES:
            local.append(_issue("invalid_verification_status", f"{where} has unknown verification_status {raw['verification_status']!r}", field=f"{where}.verification_status"))
        for key in ("verification_evidence", "documented_authorization"):
            if key in raw and not _nonempty_strings(raw[key]) and (
                key == "documented_authorization" or raw.get("verification_status") == "VERIFIED"
            ):
                local.append(_issue("missing_authorization_evidence", f"{where} needs non-empty {key}", field=f"{where}.{key}"))
        if "rights_basis" in raw and (
            not isinstance(raw["rights_basis"], str) or not raw["rights_basis"].strip()
        ):
            local.append(_issue("invalid_rights_basis", f"{where} needs a rights_basis string", field=f"{where}.rights_basis"))
        for key in ("expires_on", "revoked_on"):
            if key in raw and raw[key] is not None and not _valid_date(raw[key]):
                local.append(_issue("invalid_approval_date", f"{where} has invalid {key}", field=f"{where}.{key}"))
        state = raw.get("state")
        revoked_on = raw.get("revoked_on")
        if state == "revoked" and not _valid_date(revoked_on):
            local.append(_issue("invalid_revocation", f"{where} state 'revoked' needs revoked_on date", field=f"{where}.revoked_on"))
        if state == "active" and revoked_on is not None:
            local.append(_issue("invalid_revocation", f"{where} active approval must have revoked_on null", field=f"{where}.revoked_on"))
        if not local:
            entries.append(raw)
        issues.extend(local)

    issues.sort(key=lambda item: (item.get("field", ""), item["code"], item["message"]))
    return entries, issues


@dataclass(frozen=True)
class ApprovalRegistry:
    entries: list[dict[str, Any]] = field(default_factory=list)
    issues: list[dict[str, Any]] = field(default_factory=list)
    path_label: str = DEFAULT_REGISTRY_FILENAME

    @property
    def blocking_issues(self) -> list[dict[str, Any]]:
        return [item for item in self.issues if item.get("level") == "error"]


def load_registry(path: Path) -> ApprovalRegistry:
    """Read the trusted registry; missing means no approvals, malformed is an error."""
    label = path.name
    if not path.exists():
        return ApprovalRegistry(
            issues=[_issue("registry_not_found", "approval registry not found; no approvals are available", level="warning")],
            path_label=label,
        )
    try:
        data = path.read_bytes()
    except OSError as exc:
        return ApprovalRegistry(
            issues=[_issue("registry_unreadable", f"cannot read approval registry: {exc}")],
            path_label=label,
        )
    try:
        value = parse_registry(data)
    except RegistryError as exc:
        return ApprovalRegistry(
            issues=[_issue(exc.code, f"cannot parse approval registry: {exc}")],
            path_label=label,
        )
    entries, issues = validate_registry(value)
    return ApprovalRegistry(entries=entries, issues=issues, path_label=label)


def is_restricted_source(*values: Any) -> bool:
    """Detect FFBE/Elvlin identities or known audited revisions conservatively."""
    for value in values:
        if not isinstance(value, str):
            continue
        lowered = value.lower()
        if any(token in lowered for token in RESTRICTED_SOURCE_TOKENS):
            return True
        if value in KNOWN_RESTRICTED_REVISIONS:
            return True
    return False


def _utc_today(today: str | date | None) -> date:
    if today is None:
        return datetime.now(timezone.utc).date()
    if isinstance(today, date):
        return today
    if isinstance(today, str) and _valid_date(today):
        return date.fromisoformat(today)
    raise ValueError(f"invalid audit date {today!r}; expected YYYY-MM-DD")


def evaluate_approval(*, entry: dict[str, Any], manifest: dict[str, Any],
                      sources: Iterable[Any], mode: str,
                      today: str | date | None = None) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Check every registry rule against one candidate entry."""
    audit_date = _utc_today(today)
    rules: list[dict[str, Any]] = []
    issues: list[dict[str, Any]] = []

    def check(rule: str, ok: bool, detail: str, *, field: str | None = None,
              code: str | None = None) -> None:
        rules.append({"rule": rule, "result": "pass" if ok else "fail", "detail": detail})
        if not ok:
            issues.append(_issue(
                code or "approval_rule_failed", detail, field=field, rule=rule,
            ))

    check(
        "registry.state_active", entry.get("state") == "active",
        f"approval state is {entry.get('state')!r}; expected 'active'",
        field="state", code="registry_entry_not_active",
    )
    revoked_on = entry.get("revoked_on")
    check(
        "registry.not_revoked", revoked_on is None,
        f"approval is revoked on {revoked_on}",
        field="revoked_on", code="registry_entry_revoked",
    )
    expires_on = entry.get("expires_on")
    check(
        "registry.not_expired", _valid_date(expires_on) and date.fromisoformat(expires_on) >= audit_date,
        f"approval expired on {expires_on}; audit date {audit_date.isoformat()}",
        field="expires_on", code="registry_entry_expired",
    )

    source_id = manifest.get("source_id")
    check(
        "registry.source_identity", isinstance(source_id, str) and source_id == entry.get("source_id"),
        f"manifest source_id {source_id!r} does not match approval {entry.get('source_id')!r}",
        field="source_id", code="approval_source_mismatch",
    )
    revision = manifest.get("source_revision")
    check(
        "registry.exact_revision", isinstance(revision, str) and revision == entry.get("source_revision"),
        f"manifest source_revision {revision!r} does not match approval {entry.get('source_revision')!r}",
        field="source_revision", code="approval_revision_mismatch",
    )
    evidence = manifest.get("evidence_class")
    check(
        "registry.evidence_class", evidence == entry.get("evidence_class"),
        f"manifest evidence_class {evidence!r} does not match approval {entry.get('evidence_class')!r}",
        field="evidence_class", code="approval_evidence_class_mismatch",
    )
    rights = manifest.get("rights_status")
    check(
        "registry.rights_status", rights == CLEARED_RIGHTS_STATUS == entry.get("rights_status"),
        f"manifest rights_status {rights!r} must be independently cleared for the approved use",
        field="rights_status", code="approval_rights_status_mismatch",
    )
    required_use = "runtime_import" if mode == "import" else "preview"
    permitted = entry.get("permitted_use", [])
    check(
        "registry.permitted_use", required_use in permitted,
        f"approval permits {sorted(permitted)} but mode {mode!r} requires {required_use!r}",
        field="permitted_use", code="approval_permitted_use_mismatch",
    )
    manifest_verification = manifest.get("verification_status")
    if manifest_verification is not None:
        check(
            "registry.verification_status",
            manifest_verification == entry.get("verification_status"),
            f"manifest verification_status {manifest_verification!r} does not match approval {entry.get('verification_status')!r}",
            field="verification_status", code="approval_verification_status_mismatch",
        )

    manifest_hash = canonical_json_sha256(manifest)
    check(
        "registry.manifest_sha256", manifest_hash == entry.get("manifest_sha256"),
        f"manifest sha256 {manifest_hash} does not match approved {entry.get('manifest_sha256')}",
        field="manifest_sha256", code="approval_manifest_hash_mismatch",
    )

    expected_files = entry.get("file_sha256", {})
    if not isinstance(expected_files, dict):
        expected_files = {}
    actual_files = {source.name: bytes_sha256(source.data) for source in sources}
    missing = sorted(set(expected_files) - set(actual_files))
    unexpected = sorted(set(actual_files) - set(expected_files))
    mismatch = sorted(
        name for name in set(expected_files) & set(actual_files)
        if expected_files[name] != actual_files[name]
    )
    check(
        "registry.files_present", not missing,
        f"approved files missing from pack: {missing}",
        field="file_sha256", code="approval_file_missing",
    )
    check(
        "registry.no_unexpected_files", not unexpected,
        f"unexpected files in pack: {unexpected}",
        field="file_sha256", code="approval_unexpected_file",
    )
    check(
        "registry.file_sha256", not mismatch,
        f"content hash mismatch for files: {mismatch}",
        field="file_sha256", code="approval_file_hash_mismatch",
    )

    authorization_evidence = entry.get("documented_authorization", [])
    restricted = is_restricted_source(
        source_id, revision, manifest.get("namespace", ""),
        manifest.get("provenance", {}).get("origin", "") if isinstance(manifest.get("provenance"), dict) else "",
    )
    check(
        "registry.documented_authorization",
        not restricted or _nonempty_strings(authorization_evidence),
        "restricted sources require documented authorization evidence in the registry",
        field="documented_authorization", code="approval_missing_documented_authorization",
    )
    return rules, issues


def find_approval(*, registry: ApprovalRegistry, manifest: dict[str, Any],
                  sources: Iterable[Any], mode: str,
                  today: str | date | None = None) -> tuple[dict[str, Any] | None, dict[str, Any]]:
    """Find an unambiguous approval and return diagnostics for every attempt."""
    attempts: list[dict[str, Any]] = []
    matching: list[tuple[dict[str, Any], list[dict[str, Any]]]] = []
    for entry in registry.entries:
        rules, issues = evaluate_approval(
            entry=entry, manifest=manifest, sources=sources, mode=mode, today=today,
        )
        attempts.append({
            "approval_id": entry.get("approval_id", ""),
            "source_id": entry.get("source_id", ""),
            "source_revision": entry.get("source_revision", ""),
            "rules": rules,
            "issues": issues,
            "allowed": not issues,
        })
        if not issues:
            matching.append((entry, rules))

    detail = {
        "attempts": attempts,
        "approval_count": len(registry.entries),
        "multiple_matches": len(matching) > 1,
    }
    if len(matching) == 1:
        return matching[0][0], detail
    return None, detail
