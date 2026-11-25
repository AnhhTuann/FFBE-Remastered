# Importer security architecture — Prompt 04.6

**Status:** foundational hardening; no gameplay or original-content import is enabled by this document.

This note describes the fail-closed gate implemented by
`tools/importer/import_content.py` and `tools/importer/approval_registry.py`.
The public registration file is `data/import-approvals/registry.json`.

## 1. Trust boundary

An input pack is untrusted data. It may be a directory or ZIP, and it may
contain manifests, approval-shaped JSON, asset paths and arbitrary text. None of
that data can grant permission. The approval registry is trusted local state,
loaded by default from the repository-relative path
`data/import-approvals/registry.json`, derived from the tool's own repository
location. The CLI deliberately has no `--registry` override; a Python caller
may supply a registry path only as explicit trusted configuration.

The shipped registry has zero approvals. In particular it contains no FFBE or
Elvlin approval. Registry entries record a *documented authorization decision*
for a specific source and revision. They do not establish legal rights, do not
replace a license review, and do not make a public archive redistributable.

## 2. Registry entry contract

Each entry binds all of the following:

| Field | Purpose |
|---|---|
| `approval_id` | Stable, unique identifier for the authorization record. |
| `state`, `revoked_on`, `expires_on` | Active/expired/revocation semantics. An expired or revoked entry cannot authorize an import. |
| `source_id`, `source_revision` | Exact source identity and exact revision; no fuzzy matching. |
| `manifest_sha256`, `file_sha256` | Canonical SHA-256 of the manifest and every approved pack file. Extra or missing files fail closed. |
| `permitted_use` | Allowlist of uses; a real import requires `runtime_import`, a dry-run requires `preview` or `runtime_import`. |
| `evidence_class`, `rights_status` | Must match the pack and use the strict allowlists. Only `cleared_for_specified_use` can grant third-party clearance. |
| `verification_status`, `verification_evidence` | A `VERIFIED` claim needs explicit status plus non-empty documented evidence; otherwise third-party records stay `UNVERIFIED`/recovered. |
| `documented_authorization`, `rights_basis` | Human-auditable evidence references for the authorization decision, not a rights grant by themselves. |

Malformed registry structure blocks the import, including synthetic fixtures.
A missing registry means "no approvals", not "allow".

## 3. Status allowlists

* Evidence class: `ORIGINAL_SOURCE`, `COMMUNITY_RECOVERED`,
  `COMMUNITY_MODIFIED`, `UNVERIFIED`, `SYNTHETIC_FIXTURE`,
  `REMASTERED_DESIGN`.
* Self-admitting evidence classes: `SYNTHETIC_FIXTURE`, `REMASTERED_DESIGN`.
* Rights status: `cleared_for_specified_use`, `not_cleared`, `unknown`,
  `project-owned-test-data`, `reference_only`, `not_passed`.
* Verification status: `VERIFIED`, `RECOVERED`, `PARTIAL`, `UNVERIFIED`,
  `UNAVAILABLE`, `SYNTHETIC_FIXTURE`, `REMASTERED_DESIGN`.
* Provenance origins: `synthetic_fixture`, `project_original`,
  `remastered_design`, `original_source`, `community_recovered`,
  `community_modified`, `unverified_source`.
* Synthetic evidence must use a synthetic origin and a synthetic verification
  status. Third-party evidence cannot use a synthetic origin.

There is no status promotion path based on parsing, loading, or successful
dry-run. The project has zero VERIFIED recovered records; all `VERIFIED` claims
are rejected unless the registry explicitly authorizes that status with
documented evidence. The default safe result for third-party content is
`UNVERIFIED` or another recovered/partial label.

## 4. Pack and file validation

* ZIP and directory inputs are scanned without extraction or execution.
  Absolute paths, drive prefixes, backslashes, `..`, symlinks, executable
  extensions, oversized files and compression bombs are rejected.
* Manifest shape, schema version, pack ID, region, status strings and declared
  `content_hashes` are validated using strict rules and duplicate-key-safe JSON
  parsing.
* A pack may declare file hashes for integrity, but declared hashes never
  authorize content. For registry-authorized packs, the registry's exact
  manifest and file hashes are authoritative.
* Regions remain GL/JP namespaced; composite IDs and reference kinds are still
  validated per record.

## 5. Transactional behavior and diagnostics

An import is staged, then written to the normalized index, generated pack,
journal and backups. Any exception restores the prior state and writes a failure
report. Rollback is journal-backed and refuses to delete modified generated
files whose hash no longer matches.

Dry-run reports include an `authorization` block with the registry path, source
identity, revision, decision, approval ID, content hashes, every rule result,
and every candidate approval attempt. Rejection diagnostics name the exact
failed rule (for example `registry.manifest_sha256`, `registry.not_expired`,
`registry.clearance_not_self_declared` or `verification_status_unauthorized`).

## 6. Adversarial coverage

`tests/test_phase3_importer.py` covers forged pack-level approval metadata,
self-declared clearance, registry hash mismatches, modified packs, expired and
revoked entries, malformed registries, invalid statuses, restricted FFBE/Elvlin
sources, unauthorized and authorized `VERIFIED` claims, unsafe declared hash
paths, and rollback after a simulated partial failure. The original eleven
importer tests remain in place and pass unchanged.

## 7. Remaining limitations

* The registry records documented authorization, not legal rights. License and
  distribution review remains a human gate before original or third-party
  content is included in a build.
* The importer does not fetch sources, execute archives, or verify legal
  ownership. It only enforces locally recorded evidence and hashes.
* No original FFBE or Elvlin data is imported by Prompt 04.6; all active test
  content remains synthetic.
