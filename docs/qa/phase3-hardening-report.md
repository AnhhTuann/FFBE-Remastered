# Prompt 04.6 final report — Phase 3 foundation hardening

**Branch:** `phase-3-hardening`  
**Verified baseline:** `b7be6719151a3062ab29ce8cb7b65e32b01f7ec0`  
**Implementation commits:** `44c5b57f1cf6b0a46467e3496e094394c2b72c9a`, `62030c412855f9cf551ee52574cab296f9e9ed05`, `47d7ad2a9d0b5f33c2cf25c55fb8220634f507ec`  
**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf` (unchanged)  
**Status:** Prompt 04.6 remediation complete. Prompt 05 was **not** started.

---

## A. Scope and boundary

Prompt 04.6 hardened the existing Phase 3 foundation only: importer admission
security, player-facing localization, battle-screen layout, representative UI
interaction tests, QA tooling, export status, and publication evidence. No new
gameplay phase was implemented and no original FFBE asset, archive, APK, raw
dataset, protected sprite/audio, credential, or owner save was added to Git.

The rights gate remains `not_passed`. Elvlin data remains supplementary evidence
only. The local approval registry has zero entries and explicitly no FFBE or
Elvlin approval. All active gameplay fixtures remain project-authored
`SYNTHETIC_FIXTURE` content.

## B. Baseline and branch integrity

The branch was created directly from the verified Phase 3 documentation tip
`b7be6719151a3062ab29ce8cb7b65e32b01f7ec0`, not from `main`. Before work began,
the local branch, `origin/phase-3-character-progression`, and the remote branch
SHA all matched. No force push, hard reset, `git clean`, destructive rebase,
automatic merge, or change to `main` occurred. `main` remained at
`6232acab9fa75fafd8a7c9a2099a1c94c08fa51e`.

The documented baseline was reproduced before implementation: import exit `0`,
Godot `1412 passed, 0 failed`, Python `45 tests OK`, baseline subset
`224 passed, 0 failed`, localization `294` keys with zero missing/mismatch, and
PCK smoke exit `0`.

## C. Importer security

`tools/importer/import_content.py` and the new `tools/importer/approval_registry.py`
implement a fail-closed admission path. The registry is trusted repository-local
state with no CLI override; an input pack cannot grant itself permission.

Registry entries bind exact source identity, revision, canonical manifest hash,
every file hash, permitted use, evidence class, rights status, verification
status, documented authorization, expiry and revocation. Strict allowlists reject
unknown or malformed provenance, evidence, rights, and verification statuses.
Self-declared `cleared_for_specified_use` is rejected without an exact independent
registry authorization. No status is silently promoted to `VERIFIED`; a
`VERIFIED` claim requires an explicit registry entry with documented evidence.
FFBE and Elvlin remain restricted. Imports remain transactional with rollback,
and dry runs name the exact rule that accepted or rejected a candidate.

Evidence: `data/import-approvals/registry.json` (zero entries),
`docs/architecture/importer-security.md`, `docs/audit/safe-import-plan.md`, and
22 passing importer tests including 11 adversarial cases. The registry records
documented authorization only; it does not establish legal rights.

## D. Localization

Localization now uses 495 keys in each of `vi`, `en`, and `ja`, with zero missing
keys, zero placeholder mismatches, zero empty values, and zero invalid
dictionaries. Vietnamese remains default, English remains fallback, and Japanese
remains selectable through the existing live-switching and persistence path.

The new `game/data/phase3/localization_tokens.json` manifest maps 223 stable
internal identifiers across 22 categories to 211 distinct dictionary keys, with
zero manifest errors. Evidence prose, verification/mechanic labels, stat, slot,
region, category, resource and reason codes, viewer clip/unit labels, synthetic
ability names, and party validation messages now resolve through `LocaleManager`
while stable IDs remain unchanged. Developer diagnostics are explicitly marked
rather than presented as player-facing copy.

The previous 237 static-unused diagnostic count is now 230 per locale because
manifest-backed dynamic keys are correctly counted as referenced; valid keys
were not deleted. There are 66 long labels over 40 characters (`en` 25, `ja` 16,
`vi` 25), mainly localized evidence prose; these are layout diagnostics, not
translation failures. Vietnamese diacritic coverage is `471/495` (`0.9515`);
the remainder are intentional token-only values. Japanese glyph coverage is
`495/495`.

`FFBE_QA_LOCALE` remains a capture-only starting-locale override and does not
write settings. Evidence: `docs/qa/phase3-hardening-localization-notes.md`,
`docs/localization/coverage-report.md`, `docs/localization/glossary.md`,
`docs/localization/translation-guide.md`, and
`data/validation/localization-coverage.json`.

## E. Battle UI layout

Owner-reported defects were reproduced with headless geometry probes before
being fixed: party row overflow at width 1280, oversized/stretchy combatant
cards, clipped localized names, sprites overlapping text, an empty companion
slot consuming battlefield space, weak battlefield/debug separation, and long
localized labels inflating minimum widths.

`game/scenes/battle/battle_scene.gd` now uses a full-rect vertical layout with an
expanding battlefield and content-sized command panel; centered enemy/party
rows; fixed `130x168` card budgets; a `64 px` sprite host with uniform scaling;
ellipsis/clipping plus full-name tooltips; fixed-width character buttons; and a
separated QA/debug footer. Result and pause overlays remain at the root and no
longer inflate their own height. Public methods, signals, QA hooks, and
synthetic sprite labeling were preserved. No `.tscn` change was required.

The new 214-assertion layout suite checks logical geometry and long-label cases
at `1024x640`, `1280x720`, and `1920x1080`.

## F. UI interaction tests

`game/tests/hardening_ui_flow_test_suite.gd` drives real Godot controls and real
scene navigation through boot/menu, locale switching and persistence, menu and
Phase 3 navigation, collection search and details, upgrade, equipment and
materia, Vision Cards, party composition, battle ability selection and victory,
reward persistence, save reload, and save migrations including newer-save
refusal. State, settings, locale, environment and `user://` files are snapshotted
and restored; only synthetic fixture IDs are used.

The suite uses Godot signals and `InputEventAction` rather than OS-level input
injection. Battle resolution calls `_on_tick()` instead of waiting on wall-clock
timers. These limits are documented rather than presented as full manual QA.

## G. Saves and offline integrity

Save version behavior remains intact: battle progress stays format 2, player
state stays format 3, and v1→v2→v3 migration plus newer-save refusal are covered
by the new UI-flow suite. The test runner now also clears
`user://player_state_v3.json` along with the existing settings, battle-progress
and slot files, which removed a state-leak found when the negative control was
converted into a final test entry. A copy of the pre-existing QA state was kept
outside Git before testing. No player save file is tracked.

## H. Regression and negative control

| Check | Result |
|---|---|
| Godot import | exit `0` |
| Full Godot suite | `2153 passed, 0 failed`, exit `0` |
| Negative control | `2153 passed, 1 failed`, exit `1`; only the deliberate failure |
| Baseline subset | `224 passed, 0 failed`, exit `0` |
| Python suite | `61 tests`, `OK`, exit `0` |
| Localization report | `status: pass`, `495` union keys |
| Visual report | `30` captures, `0` runtime error lines |
| Diff check | `git diff --check` exit `0` |

Three pre-existing `Unicode parsing error ... (400000)` warnings still appear
during import while Godot scans older binary files; import still exits `0`. Full
command and log details are in `docs/qa/phase3-hardening-test-report.md`.

## I. Real GUI QA

`tools/qa/capture_phase3.sh` was hardened with strict `NAME`, `RES`, and
`LOCALE` validation and an optional isolated capture directory. It captured 30
new real PNGs from live Godot windows into `docs/qa/screenshots/hardening/`,
preserving the original 123 Phase 3 captures unchanged.

The new captures cover battle with the abilities scenario and boss encounter at
`1024x640`, `1280x720`, and `1920x1080` in `vi`, `en`, and `ja`, plus details,
equipment, Vision Card, collection, viewer, settings, and menu at `1280x720` in
all three locales. Every sidecar records scene, resolution, locale, scenario,
freeze frame, window geometry, pixel statistics, fullscreen flag and
`runtime_error_lines=0`. The report generator validates real-window geometry and
metadata. Evidence: `docs/qa/phase3-hardening-visual-review.md`.

Pixel statistics and geometry prove that windows rendered with zero recorded
runtime errors; they do not establish subjective readability. This model could
not visually inspect the PNGs, so subjective visual sign-off is **not** claimed.
Five older Phase 3 sidecars still lack a `fullscreen` field; they were not
rewritten with invented historical metadata.

## J. Export and runtime status

Official version-matched `4.7.2.stable` export templates were verified by
SHA-256 and SHA-512 from the official release and installed locally. No engine
upgrade or substituted template was used. Linux and Windows release exports both
exited `0`, producing an ELF64 executable and a PE32+ executable. The Linux
executable smoke-run exited `0` with zero error lines. Windows launch and Windows
runtime remain `NOT RUN` because this host is Linux. Details:
`docs/qa/phase3-hardening-export-report.md`.

## K. Security, size, rights, and preservation

The publishable scope scan covered 580 files / `19,568,725` bytes and found zero
secret-pattern hits, zero protected archive/executable extensions, zero tracked
export templates or build outputs, and no machine-specific absolute paths in
changed or new text files. The only save-like file in Git scope is the existing
synthetic fixture `game/data/save_fixtures/v1_save_slot_0.json`. `.git` is about
`14 MB`; the working tree excluding ignored build outputs is about `22 MB`.

All nine Agent Skills remain present (12 tracked skill files).
`FEATURE_MASTER_LIST.md` was preserved unchanged. PRs #1–#6 remain open/unmerged
and their commits were not altered. No protected assets, credentials, local
saves, or executables were committed.

## L. Known limitations

- Rights gate remains `not_passed`; no original FFBE or Elvlin content was imported.
- Complete lawful final-era GL/JP source truth, exact banners/rates/guarantees,
  story, event and dialogue coverage remain incomplete; `event_encounters.json`
  exceeded the 20 MB fetch cap.
- 230 keys remain static-scan diagnostics, and 66 long labels require subjective
  layout review; neither was treated as a translation failure.
- Windows launch and runtime were not run on this Linux host.
- Subjective visual sign-off of captured screens is not claimed.
- Prompt 05 was not started.

## M. Definition of Done — 17 items

| # | Item | Status | Evidence / caveat |
|---:|---|---|---|
| 1 | Branch created from verified Phase 3 checkpoint, not `main` | PASS | `b7be671` baseline; ancestry verified; `main` unchanged |
| 2 | Baseline reproduced before hardening | PASS | `1412` Godot, `45` Python, `224` baseline subset, `294` locale keys |
| 3 | Importer approval registry independent of untrusted packs | PASS | `data/import-approvals/registry.json`, zero entries, no CLI override |
| 4 | Self-declared rights clearance and `VERIFIED` claims rejected without independent evidence | PASS | 11 adversarial importer tests; strict allowlists |
| 5 | Importer hash/schema validation, transaction rollback, dry-run rule diagnostics | PASS | `docs/architecture/importer-security.md`, 22 importer tests |
| 6 | Player-facing dynamic labels localized with stable internal IDs | PASS | 495 keys/locale, 223 dynamic mappings, zero missing/mismatch |
| 7 | Vietnamese default with live `en`/`ja` switching and persisted preference | PASS | Locale report and UI-flow suite |
| 8 | Dynamic-key coverage and synthetic ability labels accounted for | PASS | `localization_tokens.json`, zero manifest errors |
| 9 | Owner-reported battle layout defects reproduced and fixed | PASS | Geometry probes, 214-assertion layout suite |
| 10 | Keyboard/mouse-representative UI interaction flows automated with isolated synthetic saves | PASS | UI-flow suite; Godot signals and `InputEventAction` |
| 11 | Save migration, reload, reward persistence and newer-save refusal preserved | PASS | UI-flow suite and full runner |
| 12 | Full regression and negative control pass with accurate counts | PASS | `2153/0`; negative `2153/1`; baseline `224/0`; Python `61 OK` |
| 13 | Real GUI captures added with metadata and zero runtime errors | PASS | 30 new captures; original 123 preserved; subjective sign-off not claimed |
| 14 | Official version-matched export templates verified without engine upgrade | PASS | SHA-256/SHA-512 verified; four desktop templates present |
| 15 | Linux and Windows release exports generated; Linux smoke-tested | PASS | Both exports exit `0`; Linux smoke exit `0`; Windows runtime `NOT RUN` |
| 16 | Security, rights, size, skills, and feature-list preservation reviewed | PASS | 580 files scanned; zero secrets/protected assets; nine skills retained |
| 17 | Focused commits, explicit branch push, checkpoint tag, stacked PR, and final report | PASS | Publication evidence recorded in final handoff; no merge into `main` |
