# Prompt 05.1 final report — economy, summon, shop and crafting integrity hardening

**Development branch:** `phase-4-esper-summon-economy`\
**Prompt 05 checkpoint:** `59d521602c683756e6a5273e241192817f53372a`\
**Stacked PR base:** `phase-3-hardening` at `33aa0f697943ef0417444bff32510849a662b6f0`\
**PR:** [#8](https://github.com/AnhhTuann/FFBE-Remastered/pull/8) — `OPEN`, `DRAFT` at the start of this pass\
**Status:** implementation, validation and publication complete; owner approval is pending before any merge.

## A. Scope and boundary

Prompt 05.1 is a focused hardening pass on top of the already-published Prompt 05 work. It covers only:

- offline economy cap semantics, full elapsed-time consumption, timestamp anchoring and read-only previews;
- summon receipt validation/normalization, stable diagnostics and UI/engine guarantee alignment;
- shop receipt validation, definition/region/stock gates, unique item UIDs and failed-commit rollback;
- crafting output validation, explicit timestamps, idempotent claims/refunds, rollback and save/reload status;
- additive v4 save migration compatibility for v1/v2/v3 saves and preservation of existing v4 state;
- localization of the new user-facing receipt diagnostic and validation of `vi` / `en` / `ja`;
- regression tests, isolated headless validation, exports, Linux binary smoke, real GUI QA, repository review and publication on the existing branch.

Prompt 06 was not started. `main` was not changed. PR #8 was not merged, closed, rebased or retargeted. No force push, hard reset, `git clean`, destructive rebase, history rewrite, branch/tag deletion, save reset, original-FFBE data recovery, engine upgrade or unrelated feature work was performed.

No new gameplay data pack was introduced. The touched packs remain project-authored `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN` with `policy.rights_gate: not_passed`. The new localized diagnostic is a remastered string, not recovered FFBE copy.

## B. Baseline and branch integrity

The accepted pre-change baseline is the Prompt 05 head `59d521602c683756e6a5273e241192817f53372a`. Preflight confirmed the branch, clean tree, remote branch and PR #8 state. At preflight, `main` and `origin/main` were both `6232acab9fa75fafd8a7c9a2099a1c94c08fa51e`; `phase-3-hardening` and its remote were both `33aa0f697943ef0417444bff32510849a662b6f0`; the tag `checkpoint/prompt-05.1-economy-integrity` did not exist.

Baseline evidence (`/tmp/opencode/ffbe-logs/prompt-05.1/baseline/summary.txt`):

| Check | Baseline result |
|---|---|
| Godot import | exit `0` |
| Godot full runner | `3043 passed, 0 failed`, exit `0` |
| Godot negative control | deliberate failure, exit `1`, `3043 passed, 1 failed` |
| Python unittest discovery | `75 tests`, `OK`, exit `0` |
| Importer security suite | `22 tests`, `OK`, exit `0` |
| Localization validation | `status: pass`, `741` keys, `0` missing, `0` placeholder mismatches |
| Linux / Windows export | both exit `0` |
| Linux exported-binary smoke | exit `0` |
| DONE marker | recorded |

All final runs used an isolated profile under `/tmp/opencode/ffbe-profiles/prompt-05.1-final`; GUI captures used `/tmp/opencode/ffbe-profiles/prompt-05.1-captures`. No run used the owner's real `HOME` or `XDG_DATA_HOME`, and no run wrote a real user save.

## C. Offline economy and timestamp integrity

**Implemented behavior**

- `PlayerState.default_state(now_unix)`, `load_state(now_unix)` and `migrate_state(raw, now_unix)` accept explicit timestamps; explicit values take precedence over QA and wall-clock fallbacks.
- Fresh and migrated profiles receive `economy.last_settled_unix` anchored at creation/migration, preventing an epoch-zero save from claiming historical offline rewards.
- Existing positive v4 timestamps and v4 claim records are preserved; `_ensure_economy_anchor()` only fills missing/zero unclaimed anchors.
- `EconomySystem.status()` remains read-only and reports `pending_seconds`, `reward_seconds`, `elapsed_seconds`, `capped`, `consumed_until` and the claim key without mutating state.
- A capped away period pays at most `28800` reward seconds but consumes the entire elapsed interval on a successful settlement. The claim key and `last_settled_unix` therefore use the elapsed end, so repeating the same `now_unix` cannot mint another capped claim.
- Minimum-interval windows still consume no time; negative timestamps remain rejected.

**Evidence**

- `game/tests/phase3_economy_test_suite.gd::test_player_state_timestamp_contract` verifies explicit anchors for fresh, v1, v3 and preserved-v4 states, v1/v3 resource preservation, legacy reward/battle-progress preservation, save at `user://player_state_v3.json`, internal version `4` after reload and explicit zero-anchor survival.
- `test_economy_system` verifies read-only previews, minimum interval, cap `28800`, `elapsed_seconds=1000000`, `capped=true`, `consumed_until=1000000`, capped reward amounts, repeated capped claim rejection with unchanged fingerprint, a subsequent away session starting at the new timestamp and party-size modifiers.
- Final result: `3155 passed, 0 failed` (`/tmp/opencode/ffbe-logs/prompt-05.1/final/summary.txt`).

## D. Summon receipt and guarantee hardening

- `SummonSystem.MAX_RECEIPT_LENGTH := 128`; `normalize_receipt()` trims surrounding whitespace and rejects empty or oversized receipts.
- Invalid receipts return stable `ok=false`, `reason=invalid_receipt`, `locale_key=reason.invalid_receipt` with receipt length diagnostics before any banner lookup, cost check or charge.
- Claim keys, RNG seeds, stored claim records and history use the normalized receipt, so padded and unpadded variants cannot double-charge or double-grant. An exactly 128-character receipt is accepted.
- `guarantee_within` is reported alongside the diagnosis; `ContentRepository._validate_banners()` fails closed if `pity.threshold` and `guarantee.within` disagree.
- `game/scenes/phase3/summon.gd::_pity_counts()` now prefers `guarantee.within`, using `pity.threshold` only as a fallback, so the UI cannot promise a different draw count than the engine.
- Existing `test_summon_commit_rollback` still verifies full-state restoration and recovery after a failed save commit.

**Evidence:** `test_summon_receipt_validation`, `test_summon_commit_rollback`, the Python equality check `test_summon_pity_display_matches_engine_guarantee`, and the real GUI captures in section M. Final Godot result: `3155 passed, 0 failed`.

## E. Shop receipt, stock and rollback integrity

- `ShopSystem.MAX_RECEIPT_LENGTH := 128` and the same normalization policy as summon; invalid receipts return `invalid_receipt` before charging.
- Purchases now gate on a repository definition check and a region match between the shop and the purchased definition. Existing stock limits, quantities, flags, payment and receipt idempotency remain enforced.
- `refresh` is documented in `game/systems/shop_system.gd` as metadata only. No refresh action, timer, stock reset or cadence was invented. Python validation records the field as a string and explicitly does not infer behavior from it.
- Multi-quantity item grants produce distinct UIDs and preserve the shop region prefix, verified for the JP materia stock entry.
- Failed commits restore the whole state snapshot, including resources, inventory, claim ledger, stock usage and purchases; the same receipt succeeds after the injected fault is consumed.

**Evidence:** `test_shop_receipt_and_uid_integrity`, `test_shop_commit_rollback`, `test_shop_system`, Python `test_shop_stock_regions_match_shop_region`, and section M captures at all three required resolutions. Final result: `3155 passed, 0 failed`.

## F. Crafting validity, claims and rollback

- Recipe outputs are validated before payment and again before grant. Tampered job outputs referencing an unknown definition are rejected as `invalid_definition` with no state change.
- `status(now_unix)` and `claim(job_id, now_unix)` accept explicit timestamps; `claimed_at` uses the supplied time rather than an implicit wall clock.
- Inputs are deducted once via the existing claim-key ledger. Early claims, duplicate claims, cancelled-job claims and duplicate refunds remain rejected.
- Fault injection covers failed start, failed claim and failed refund commits; each failure restores the full fingerprint and leaves no partial grant, claim or refund record.
- `test_crafting_save_reload` saves and reloads a claimed job and a cancelled job, verifies both job statuses and both claim keys survive, and verifies neither action can be repeated after reload.

**Evidence:** `test_crafting_output_rollback`, `test_crafting_save_reload`, `test_crafting_system`, final Godot `3155 passed, 0 failed`.

## G. Esper/save compatibility and migration

- `PlayerState.PLAYER_STATE_PATH` remains `user://player_state_v3.json`; `PLAYER_STATE_VERSION` remains `4`. No new save format or filename was introduced.
- `_migrate_2_to_3()` now preserves v3-shaped fields already present in older saves instead of resetting resources, inventory, owned units, parties, reward claims, serial counters or profile selection.
- v1, v2 and v3 fixtures still migrate to internal version 4 and validate. Existing v4 economy timestamps and claims are preserved. `validate_state()` rejects negative economy anchors.
- Esper data and UI were not redesigned; the single Esper GUI capture in section M is a regression check on the additive v4 surface.

**Evidence:** `test_player_state_timestamp_contract`, the existing `phase3_test_suite.gd::test_save_v2_to_v4_migration` with explicit timestamp `5000`, and the full suite result `3155 passed, 0 failed`.

## H. Localization and translated diagnostics

- The new `reason.invalid_receipt` key was added to `en`, `ja` and `vi` with translations (`Invalid receipt`, `受領番号が無効です`, `Biên lai không hợp lệ`) and mapped in `game/data/phase3/localization_tokens.json`.
- `reason.region_mismatch` was added to the required locale-contract list; it resolves through the existing token manifest.
- Regenerated localization coverage: `status: pass`, union keys `742`, missing keys `0`, placeholder mismatches `0`, dynamic references `280`, dynamic reference errors `0`.
- `docs/localization/coverage-report.md` and Python expectations were updated to the intentional `742` / `305` mappings / `280` distinct-key baseline.
- Summon and shop scenes route result reasons through `LocaleManager.reason_label(...)`, so the new stable diagnostics are user-facing localized strings, not raw codes.

**Evidence:** `/tmp/opencode/ffbe-logs/prompt-05.1/final/summary.txt`, `python3 -m unittest discover -s tests` (`77 tests`, `OK`), and `en` / `ja` summon GUI captures in section M.

## I. Regression evidence and negative control

| Check | Result | Evidence |
|---|---|---|
| Godot import | exit `0` | `final/summary.txt`, `final/import.log` |
| Full Godot runner | `3155 passed, 0 failed`, exit `0` | `final/godot-full.log` |
| Negative control | `3155 passed, 1 failed`, exit `1` | `final/godot-negative.log`, `FFBE_TEST_NEGATIVE_CONTROL=1` |
| Python unittest discovery | `77 tests`, `OK`, exit `0` | `final/python.log` |
| Importer security suite | `22 tests`, `OK`, exit `0` | `final/importer.log` |
| Localization validator | `status: pass`, `742` keys, `0` missing, `0` placeholder mismatches, `280` dynamic references, `0` dynamic errors, exit `0` | `final/localization.log` |
| `git diff --check` | exit `0`, no output | captured after final review |

The three `Unicode parsing error ... Invalid unicode codepoint (400000)` lines in the import log are the previously root-caused Godot editor doc-cache warnings for the Escape keycode `4194304` (`0x400000`). Input bindings were intentionally left unchanged.

## J. Static Python and repository validation

New and updated static checks:

- `test_summon_pity_display_matches_engine_guarantee` asserts every banner has `pity.threshold == guarantee.within`.
- `test_shop_stock_regions_match_shop_region` asserts stock definition regions match their shop and records that `refresh` is metadata only.
- `test_phase3_localization.py` expects `742` keys, `305` dynamic mappings and `280` distinct dynamic keys, and requires `reason.invalid_receipt` plus `reason.region_mismatch` in the locale contract.
- `data/validation/localization-coverage.json` was regenerated by `tools/localization/coverage_report.py`, not hand-edited.

All 77 discovered Python tests passed. The importer security suite is run both inside discovery and separately; the separate run also passed 22/22.

## K. Headless regression matrix

Final isolated run (`/tmp/opencode/ffbe-logs/prompt-05.1/final/summary.txt`):

```text
import_exit=0
godot_full_exit=0
Results: 3155 passed, 0 failed
negative_exit=1
Results: 3155 passed, 1 failed
python_exit=0
Ran 77 tests in 2.392s
OK
importer_exit=0
Ran 22 tests in 0.168s
OK
localization_exit=0
status: pass
union keys: 742
missing keys: 0
placeholder mismatches: 0
dynamic references: 280
dynamic reference errors: 0
linux_export_exit=0
windows_export_exit=0
linux_smoke_exit=0
unicode_warning_count=3
DONE
```

The increase from the baseline `3043` assertions to `3155` comes from the added Prompt 05.1 regression cases and explicit timestamp/protection checks.

## L. Exports and runtime status

| Artifact | Result |
|---|---|
| Linux export | exit `0`, `/tmp/opencode/ffbe-logs/prompt-05.1/final/exports/linux-export.log` |
| Windows export | exit `0`, `/tmp/opencode/ffbe-logs/prompt-05.1/final/exports/windows-export.log` |
| Linux exported-binary smoke | exit `0`, `/tmp/opencode/ffbe-logs/prompt-05.1/final/exports/linux-smoke.log` |
| File types | recorded in `final/exports/file-types.log` |
| SHA-256 | recorded in `final/exports/sha256.log` |
| Windows runtime | **BLOCKED** — no Windows host is available; export success is not runtime verification |

## M. Real GUI QA

Capture tool: `tools/qa/capture_phase3.sh`. Output directory: `docs/qa/screenshots/prompt05.1/`. Runtime logs: `/tmp/opencode/ffbe-logs/prompt-05.1/captures/logs/`. Capture summary: `/tmp/opencode/ffbe-logs/prompt-05.1/captures/summary.txt`:

```text
capture_count=19
image_count=19
runtime_error_total=0
nonzero_runtime_error_files=0
resolutions=1024x640 1280x720 1920x1080
```

`1920x1080` captures use fullscreen because the available X display is exactly `1920x1080` and a decorated window cannot match that client size. Geometry and pixel statistics are recorded in each sidecar.

| Capture | Scene | Resolution | Locale | Pixels | Runtime errors |
|---|---|---|---|---:|---:|
| `prompt05.1-boot-capped-vi-1280x720` | boot | `1280x720` | `vi` | `1280x720 colors=210 stddev=0.0712129` | 0 |
| `prompt05.1-crafting-vi-1024x640` | `res://scenes/phase3/crafting.tscn` | `1024x640` | `vi` | `1024x640 colors=895 stddev=0.11945` | 0 |
| `prompt05.1-crafting-vi-1280x720` | `res://scenes/phase3/crafting.tscn` | `1280x720` | `vi` | `1280x720 colors=938 stddev=0.125414` | 0 |
| `prompt05.1-crafting-vi-1920x1080` | `res://scenes/phase3/crafting.tscn` | `1920x1080` | `vi` | `1920x1080 colors=1021 stddev=0.129814` | 0 |
| `prompt05.1-economy-vi-1024x640` | `res://scenes/phase3/economy_hub.tscn` | `1024x640` | `vi` | `1024x640 colors=653 stddev=0.11811` | 0 |
| `prompt05.1-economy-vi-1280x720` | `res://scenes/phase3/economy_hub.tscn` | `1280x720` | `vi` | `1280x720 colors=590 stddev=0.124214` | 0 |
| `prompt05.1-economy-vi-1920x1080` | `res://scenes/phase3/economy_hub.tscn` | `1920x1080` | `vi` | `1920x1080 colors=636 stddev=0.128094` | 0 |
| `prompt05.1-esper-vi-1280x720` | `res://scenes/phase3/esper_management.tscn` | `1280x720` | `vi` | `1280x720 colors=1339 stddev=0.136142` | 0 |
| `prompt05.1-menu-vi-1024x640` | `res://scenes/menu/main_menu.tscn` | `1024x640` | `vi` | `1024x640 colors=210 stddev=0.066945` | 0 |
| `prompt05.1-menu-vi-1280x720` | `res://scenes/menu/main_menu.tscn` | `1280x720` | `vi` | `1280x720 colors=210 stddev=0.0712129` | 0 |
| `prompt05.1-menu-vi-1920x1080` | `res://scenes/menu/main_menu.tscn` | `1920x1080` | `vi` | `1920x1080 colors=210 stddev=0.0726541` | 0 |
| `prompt05.1-shop-vi-1024x640` | `res://scenes/phase3/shop.tscn` | `1024x640` | `vi` | `1024x640 colors=656 stddev=0.0783723` | 0 |
| `prompt05.1-shop-vi-1280x720` | `res://scenes/phase3/shop.tscn` | `1280x720` | `vi` | `1280x720 colors=680 stddev=0.0819451` | 0 |
| `prompt05.1-shop-vi-1920x1080` | `res://scenes/phase3/shop.tscn` | `1920x1080` | `vi` | `1920x1080 colors=740 stddev=0.0880158` | 0 |
| `prompt05.1-summon-en-1280x720` | `res://scenes/phase3/summon.tscn` | `1280x720` | `en` | `1280x720 colors=640 stddev=0.142639` | 0 |
| `prompt05.1-summon-ja-1280x720` | `res://scenes/phase3/summon.tscn` | `1280x720` | `ja` | `1280x720 colors=512 stddev=0.129228` | 0 |
| `prompt05.1-summon-vi-1024x640` | `res://scenes/phase3/summon.tscn` | `1024x640` | `vi` | `1024x640 colors=631 stddev=0.134166` | 0 |
| `prompt05.1-summon-vi-1280x720` | `res://scenes/phase3/summon.tscn` | `1280x720` | `vi` | `1280x720 colors=693 stddev=0.145162` | 0 |
| `prompt05.1-summon-vi-1920x1080` | `res://scenes/phase3/summon.tscn` | `1920x1080` | `vi` | `1920x1080 colors=862 stddev=0.11426` | 0 |

These captures prove live window rendering, exact geometry and zero runtime error lines. They do not constitute subjective art-direction sign-off.

## N. Security, rights, size and preservation

Pre-publication repository review (`/tmp/opencode/ffbe-logs/prompt-05.1/final/security-audit.txt`):

| Check | Result |
|---|---|
| Credential/key candidates in tracked files | `0` |
| Executable/archive/temp/log/save candidates in tracked files | `0` |
| `data/import-approvals/registry.json` entries | `0` |
| `game/data/phase3/imported_manifest.json` active packs | `0`; `last_import: null` |
| Import policy | `allowed_evidence_classes: SYNTHETIC_FIXTURE, REMASTERED_DESIGN`; `allow_recovered_without_rights: false` |
| Rights gate on the five economy/esper/summon packs | `not_passed` on each; `source_data_imported: false` on each |
| Save-like tracked files | `4`: `player_state.gd`, `player_state.gd.uid`, `v1_save_slot_0.json`, `v2_player_state.json` — code or versioned fixtures, no runtime save |
| Tracked `game/build/` or `game/.godot/` entries | `0` each |
| Real-money purchase implementation | none; project scope documents explicitly exclude it |
| Restricted FFBE/Elvlin packs | none active or approved |

No protected asset was downloaded, imported or staged. No exported executable, temporary test log, runtime save or credential is being committed. The 19 screenshot pairs are intentional QA evidence generated from the isolated profile.

## O. Known limitations and non-verified items

- Windows runtime execution: **BLOCKED** on this Linux host. Only export success and file-type evidence are available.
- Subjective visual/art-direction approval from screenshots: **NOT VERIFIED**. The captures verify geometry, rendering statistics and zero runtime error lines only.
- Original FFBE banners, rates, guarantees, shop inventories, recipe timings and historical economy values were not recovered. All values remain synthetic remaster designs.
- No new save format, save reset or guessed original FFBE value was introduced.
- The three Unicode import warnings remain benign Godot editor doc-cache warnings from the Escape keycode; bindings were intentionally unchanged.
- Original online services, real-money purchases and protected source assets remain outside project scope.

## P. Publication evidence

- Reviewed the staged diff before commit. `git diff --cached --check` returned exit `0` with no output.
- Implementation commit: `bb428c5bca9aeaed5c14b611fe8c656e9b51afae` — `fix(prompt05.1): harden economy, receipts and save integrity`.
- Published with a normal push: `git push origin phase-4-esper-summon-economy`, reported `59d5216..bb428c5`.
- One docs-only follow-up commit on the same branch records this publication evidence; no amend, rebase, force push or history rewrite was used.
- Independent post-push verification after the implementation commit: local HEAD and `origin/phase-4-esper-summon-economy` were both `bb428c5bca9aeaed5c14b611fe8c656e9b51afae`. After the evidence commit, local and remote branch were re-read and matched at the final HEAD.
- GitHub PR #8 was re-read after publication: `state: OPEN`, `isDraft: true`, `baseRefName: phase-3-hardening`, `baseRefOid: 33aa0f697943ef0417444bff32510849a662b6f0`, `headRefName: phase-4-esper-summon-economy`, URL `https://github.com/AnhhTuann/FFBE-Remastered/pull/8`. The PR was not merged, closed or retargeted.
- `origin/main` remained `6232acab9fa75fafd8a7c9a2099a1c94c08fa51e`; `origin/phase-3-hardening` remained `33aa0f697943ef0417444bff32510849a662b6f0`.
- The tag `checkpoint/prompt-05.1-economy-integrity` was confirmed absent before creation, then created as an annotated tag at the final branch HEAD. No existing tag was replaced or deleted.
- Final tracked-file count: `696`; no executable, archive, runtime save, credential or temporary test log was staged.

## Q. Final status

Implementation and validation are complete and green. All Prompt 05.1 hardening requirements covered by this host are satisfied; Windows runtime remains explicitly blocked rather than reported as passing. Prompt 06 remains unstarted and owner approval is required before any merge.

## Definition of Done — 38 items

| # | Item | Status | Evidence / caveat |
|---:|---|---|---|
| 1 | Existing Prompt 05 branch and base preserved | PASS | `phase-4-esper-summon-economy`, base `phase-3-hardening`, PR #8 unchanged |
| 2 | Pre-change baseline reproduced | PASS | `baseline/summary.txt`: `3043` Godot, `75` Python, `22` importer, `741` locale keys |
| 3 | No Prompt 06 work started | PASS | scope limited to Prompt 05.1 files and tests |
| 4 | Explicit timestamp contract added | PASS | `test_player_state_timestamp_contract`, final Godot `3155/0` |
| 5 | Fresh/migrated save timestamp anchoring | PASS | fresh, v1, v3 and preserved-v4 checks in section C |
| 6 | Economy cap is at most eight hours | PASS | `pending_seconds=28800`, `capped=true` in `test_economy_system` |
| 7 | Full elapsed interval consumed on capped settlement | PASS | `consumed_until=1000000`, `last_settled_unix=1000000` |
| 8 | Repeated capped claim rejected without mutation | PASS | `already_claimed`, unchanged fingerprint |
| 9 | Economy `status()` read-only | PASS | fingerprint unchanged before/after status calls |
| 10 | Resources/inventory/rewards/battle progress preserved | PASS | v1/v3 migration assertions and `_fingerprint()` protection |
| 11 | Save path/version contract unchanged | PASS | `user://player_state_v3.json`, internal version `4` |
| 12 | Additive v4 migration preserved | PASS | existing v4 timestamp, claim and resources preserved |
| 13 | v1/v2/v3 compatibility remains green | PASS | explicit migration tests, `3155/0` |
| 14 | Summon empty/whitespace/oversized receipts rejected | PASS | `test_summon_receipt_validation`, stable `invalid_receipt` |
| 15 | Receipts normalized for keys, RNG and storage | PASS | padded receipt accepted once, unpadded duplicate rejected |
| 16 | No duplicate summon charge/grant | PASS | `already_claimed`, unchanged fingerprint |
| 17 | UI pity display aligned with engine guarantee | PASS | repository equality check and UI preference for `guarantee.within` |
| 18 | Shop empty/whitespace/oversized receipts rejected | PASS | `test_shop_receipt_and_uid_integrity` |
| 19 | Shop stock limits and definition/region gates enforced | PASS | `test_shop_system`, Python region check |
| 20 | Shop unique item UIDs and JP region preserved | PASS | two distinct `owned:JP:600004:` UIDs |
| 21 | Shop failed commit fully rolled back | PASS | `test_shop_commit_rollback`, full fingerprint restored |
| 22 | `refresh` documented as metadata-only | PASS | system comment and Python metadata assertion; no refresh feature |
| 23 | Crafting invalid outputs rejected before charge/grant | PASS | `test_crafting_output_rollback`, `invalid_definition` |
| 24 | Crafting inputs deducted once; early/double/cancel claims rejected | PASS | `test_crafting_system`, `test_crafting_save_reload` |
| 25 | Crafting start/claim/refund commits roll back fully | PASS | three fault-injection branches restore full fingerprint |
| 26 | Crafting job/claim status survives save/reload | PASS | claimed/cancelled statuses and claim keys reloaded; no repeats |
| 27 | Localization `vi`/`en`/`ja` parity | PASS | `742` keys each, `0` missing, `0` placeholder mismatches |
| 28 | New diagnostics translated and mapped | PASS | `reason.invalid_receipt` in three locales and token manifest; `reason.region_mismatch` contract |
| 29 | Full Godot regression and negative control | PASS | `3155/0`, exit `0`; negative `3155/1`, exit `1` |
| 30 | Python/importer/localization suites | PASS | `77`, `22`, validator `status: pass` |
| 31 | Linux/Windows exports and Linux smoke | PASS | all exit `0`; file types and hashes logged |
| 32 | GUI QA at three required resolutions | PASS | 19 captures, 19 sidecars, `0` runtime error lines |
| 33 | Security/rights/size review | PASS | zero credentials, zero active packs, rights gate `not_passed` |
| 34 | Isolated profiles only; no real saves touched | PASS | dedicated `/tmp/opencode/ffbe-profiles/prompt-05.1-*` homes |
| 35 | Windows runtime execution | BLOCKED | no Windows host; export success is not runtime verification |
| 36 | Diff reviewed, `git diff --check` clean | PASS | no output, exit `0` |
| 37 | Commit, normal push, PR #8 and tag verification | PASS | implementation commit `bb428c5`, normal push, PR #8 `OPEN`/`DRAFT` with unchanged base, annotated checkpoint tag |
| 38 | Final report delivered; Prompt 06 not started | PASS | this document and unchanged branch boundary |
