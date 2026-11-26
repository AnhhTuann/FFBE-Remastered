# Prompt 05 final report — Esper, Summon and synthetic economy foundations

**Development branch:** `phase-4-esper-summon-economy`\
**Base checkpoint:** `33aa0f697943ef0417444bff32510849a662b6f0`\
**Stacked PR base:** `phase-3-hardening`\
**Previous checkpoint:** `checkpoint/prompt-04.6-foundation-hardening`\
**Status:** implementation and validation complete; publication in progress.

## A. Scope and boundary

Prompt 05 covers the authorized Phase 3/4 correction and foundation work only:

- battle-run identity, independent/QA RNG seeds, reward buckets, one-time/repeatable/mission rewards, idempotent settlement and transactional persistence;
- ActionQueue execution-time eligibility and resource limits;
- Leader Skills, per-unit Vision Cards and explicit invalid-party diagnostics;
- synthetic Esper progression/battle/UI, summon definitions/RNG/transactions/UI, offline economy and farming policy, shop and crafting foundations;
- additive v4 save migration, one Economy hub entry in the main menu, and `vi` / `en` / `ja` localization;
- full regression, real desktop GUI QA, exports, security/rights/size review, stacked draft PR and checkpoint tag.

Prompt 06 was not started. `main` was not changed. No merge, force push, hard reset, `git clean`, destructive rebase, restricted-asset import, FFBE/Elvlin pack download, or real-money purchase system was performed.

All new gameplay data is project-authored `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN`. Original FFBE banner names, rates, guarantees, historical pools, recipe timings and shop inventories remain honestly labeled unknown; no original values are claimed.

## B. Baseline and branch integrity

The verified baseline is `33aa0f697943ef0417444bff32510849a662b6f0`, the head of `phase-3-hardening` and PR #7. The Prompt 05 branch was created directly from that commit; `origin/main` remained at `6232acab9fa75fafd8a7c9a2099a1c94c08fa51e` throughout implementation and validation.

Baseline reproduction used an isolated `HOME` / `XDG_DATA_HOME` profile and recorded:

| Check | Baseline result |
|---|---|
| Godot full runner | `2153 passed, 0 failed`, exit `0` |
| Godot negative control | deliberate failure, exit `1` |
| Python unittest discovery | `61 tests OK`, exit `0` |
| Importer security suite | `22 tests OK`, exit `0` |
| Localization coverage | `status: pass`, `495` keys, `0` missing, `0` placeholder mismatches |
| Phase 2 subset | `224 passed, 0 failed` |
| Linux export | exit `0` |
| Windows export | exit `0` |
| Linux exported-binary smoke | exit `0` |

The three `Unicode parsing error ... Invalid unicode codepoint (400000)` editor-cache warnings were root-caused to the Escape keycode `4194304` (`0x400000`) in `project.godot`; a minimal project with that single action reproduced them, while an empty project produced zero. They are benign Godot 4.7 editor documentation-cache warnings and are not data corruption or runtime errors. Evidence: `/tmp/opencode/ffbe-logs/prompt-05/unicode-probe/README.md`.

## C. Mandatory gameplay corrections

| Correction | Delivered behavior and evidence |
|---|---|
| Battle-run identity | `BattleManager` accepts/stores `run_id`; `BattleResult`, battle UI snapshots and `SaveManager.record_battle_result()` carry it. Legacy results still use a stable fallback fingerprint. Covered by `battle_test_suite.gd` and `phase3_test_suite.gd`. |
| Independent / QA RNG seeds | Default seeds use monotonic clock plus a static counter; `FFBE_QA_SEED` is honored only with `FFBE_QA_MODE=1` and reports `seed_source = qa_deterministic`. QA/independent seeds are separated from run IDs. |
| One-time / repeatable / mission reward buckets | `reward_resolver.gd` separates `repeat`, `first_clear`, and `missions` with canonical `battle|run|`, `battle|once|`, `battle|first|` and `battle|mission|` keys. Tests cover a first clear followed by a repeat run and mission claims. |
| Idempotent settlement | `PlayerState.claim_battle_reward()` computes all keys, rejects duplicates, and grants buckets independently; `SaveManager` skips duplicate `processed_runs`; economy, summon, shop and crafting use namespaced receipt keys. |
| Transactional persistence and rollback | `claim_battle_reward()` snapshots the whole state and restores it on failed `rewards` commit. `SaveManager.fail_next_atomic_write()` provides fault injection; tests verify no partial reward, summon, shop or crafting grants. |
| ActionQueue eligibility / resource limits | Queue-time MP/item/ability/LB reservations plus execution-time actor, status, target and use-limit checks; cancelled actions release reserved uses. Pre-hit cancellation is exercised in `battle_test_suite.gd`. |
| Leader Skills | `build_resolver.gd` reads the owned leader definition, validates category/stat, preserves localized labels, and suppresses duplicate leader IDs. |
| Vision Cards | Explicit precedence: unit-equipped > party per-unit assignment > legacy party card. Shared-card checks and `build.error.vision_*` diagnostics prevent double-counting and silent fallback. |
| Invalid-party errors | `resolve_party()` emits slot-tagged stable locale keys for empty slots, duplicates, unknown instances and per-unit restriction failures; party UI disables launch, and BattleScene blocks invalid parties outside QA. |

All nine corrections are exercised by the final `3043 passed, 0 failed` Godot runner.

## D. Esper foundation

- Three synthetic esper definitions in `game/data/phase3/espers.json`, each marked `SYNTHETIC_FIXTURE` with `REMASTERED_DESIGN` labels and `not_passed` rights gate.
- `game/systems/esper_system.gd` exposes `definitions`, `definition`, `owned`, `unlock`, `set_active`, `clear_active`, `status_for` and `add_sp`.
- `set_active()` is idempotent for the current party assignment and no longer consumes a one-time reward claim; `clear_active()` makes reassignment explicit.
- `add_sp()` is a repeatable paid progression sink with bounded purchase history instead of a permanently blocking claim key.
- `game/scenes/phase3/esper_management.tscn/.gd` lists definitions, ownership, unlock cost, synthetic stats, active status, activation and clear actions.
- Tests verify unknown/region-mismatched/unaffordable inputs, unlock claims, activation idempotency, clearing, link limits, SP caps, repeat SP purchases and synthetic stat evidence.

## E. Summon foundation

- Three synthetic banners in `game/data/phase3/summon_banners.json`; no original FFBE banner, rate, guarantee or historical pool is claimed.
- `game/systems/summon_system.gd` derives draws from banner ID, seed, receipt and a synthetic pity counter; receipts are explicit idempotency keys.
- `grant_unit()` now returns an empty ID when its save commit fails. `summon()` restores the complete snapshot, retries the restored commit and returns `grant_failed`; `test_summon_commit_rollback` verifies currency, inventory, claims and subsequent recovery.
- UI receipts include a monotonic tick component so a frozen QA clock cannot collide when a scene is re-entered.
- Tests verify banner/cost getters, seeded determinism, receipt idempotency, synthetic pity guarantees, JP receipts, bounded history, insufficient resources and commit rollback.

## F. Offline economy and farming policy

- `game/data/phase3/offline_economy_rules.json` defines capped windows, minimum intervals and synthetic party-size modifiers.
- `game/core/content_repository.gd` now stores and exposes the declared `default_rule_id`; `EconomySystem._window()` honors it instead of silently choosing the alphabetically first rule.
- `status()` is read-only; `settle()` uses explicit `now_unix`, namespaced `offline|<start>|<end>` claim keys and transactional resource grants.
- Tests verify negative timestamps, minimum-interval clamping, preview immutability, cap math, party modifiers, settlement idempotency and E2E reload persistence.

## G. Shop and crafting foundations

- Synthetic shops define per-stock limits, costs, requirements and receipts; `ShopSystem.buy()` enforces quantity, flags, limits, payments and idempotent receipts.
- Synthetic crafting recipes define requirements, inputs, outputs and durations; `CraftingSystem` exposes `start`, `status`, `settle`, `claim` and `cancel` with namespaced job/claim keys.
- Tests verify invalid IDs/quantities, flags, limits, insufficient resources, duplicate receipts, duration gating, claim idempotency, cancellation/refund behavior and JP recipe resource outputs.
- All shop and crafting values are remaster designs, not recovered FFBE inventories or recipes.

## H. Save migration and transactional integrity

- `PlayerState` remains on `user://player_state_v3.json` for backward compatibility but writes in-file version `4`.
- `_migrate_3_to_4()` duplicates legacy state and backfills `reward_claims`, `mission_progress`, `battle_runs`, `espers`, `summon`, `economy`, `shops` and `crafting`; legacy `claimed_rewards` and `battle_progress` are preserved under canonical/careful mappings.
- Version safety rejects newer saves with `save.error.newer`; v1/v2/v3 fixtures migrate forward and validate.
- `set_locale()` now restores the prior profile and propagates `commit("profile")` errors rather than discarding them.
- Tests cover v2→v4 migration, newer-save refusal, stable error text, reward rollback, and an explicit save/reload pass in `test_end_to_end_flow`.

## I. Localization

Localization expanded from `495` to `741` keys per locale. The dynamic token manifest expanded from `223` mappings / `211` keys to `304` mappings / `279` distinct keys across `26` categories. All three locales have identical key sets, identical placeholders, zero missing dynamic keys and zero manifest errors. A source-scan reconciliation confirms that every literal `t()` key used by GDScript exists in `en`, `ja` and `vi`. The final report generator and hardcoded Python expectations were updated to these intentional baselines.

## J. Real GUI QA

Full capture table and sidecars are in [docs/qa/prompt05-visual-review.md](prompt05-visual-review.md).

- 19 real Godot window captures; 19 matching metadata sidecars.
- Required resolutions: `1024x640`, `1280x720`, `1920x1080`.
- Locales captured: `vi`, `en`, `ja`.
- Screens covered: boot/offline summary, main menu, Economy hub, Esper management, summon, shop, crafting and battle.
- Runtime error lines across all captures: `0`; geometry and pixel statistics recorded per capture.
- `1920x1080` captures use fullscreen because the available X display is exactly `1920x1080` and a window with decorations cannot fit the exact client size.

## K. End-to-end gameplay coverage

`game/tests/phase3_economy_test_suite.gd::test_end_to_end_flow` performs one continuous pass:

1. synthetic battle result with `run_id`, repeat reward, first-clear reward and mission reward;
2. duplicate settlement returns `already_claimed`;
3. offline economy settlement from an explicit timestamp;
4. shop purchase with a unique receipt;
5. crafting start → settle → claim;
6. seeded summon with a unique receipt;
7. `save()` → `load_state()` and verification that all five namespaced ledgers plus the summoned unit survive.

The separate `hardening_ui_flow_test_suite.gd::test_party_battle_and_rewards` covers real scene transitions through party selection, battle, result and rewards.

## L. Regression, negative control and static tests

Final isolated validation (`/tmp/opencode/ffbe-logs/prompt-05/final/summary.txt`):

| Check | Result |
|---|---|
| Godot import | exit `0`, no parse/runtime errors |
| Godot full runner | `3043 passed, 0 failed`, exit `0` |
| Godot negative control | `3043 passed, 1 failed`, exit `1`; deliberate `FFBE_TEST_NEGATIVE_CONTROL` failure |
| Python unittest discovery | `75 tests OK`, exit `0` |
| Importer security suite | `22 tests OK`, exit `0` |
| Localization coverage | `status: pass`, `741` keys, `0` missing, `0` placeholder mismatches, `279` dynamic refs |
| `git diff --check` | exit `0` |

The remaining ten `ERROR:` lines in the positive Godot log are intentional negative-fixture diagnostics from invalid economy packs/identities; they are assertions, not failures.

## M. Export and runtime status

| Artifact | Result |
|---|---|
| Linux export | exit `0` |
| Windows export | exit `0` |
| Linux binary type | `ELF 64-bit LSB executable, x86-64`, stripped |
| Windows binary type | `PE32+ executable for MS Windows 5.02 (GUI), x86-64` |
| Linux SHA-256 | `d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63` |
| Windows SHA-256 | `06d6853a83a61a758a1e8d14a31672dd45aaf7a379478223e2c5cae05ed3d704` |
| Linux exported-binary smoke | exit `0`; booted to PlayerState v4 with 6 synthetic units |
| Windows runtime | `NOT RUN` — no Windows host is available; export success is not runtime verification |

## N. Security, rights, size and preservation

- 583 tracked files; 200 MB excluding `.git`.
- No credential/key candidates or executable/archive candidates in tracked files.
- `data/import-approvals/registry.json` entries: empty.
- `data/manifests/imported-manifest.json` active packs: empty; `source_data_imported: false`.
- All five new economy packs carry `SYNTHETIC_FIXTURE`, `REMASTERED_DESIGN`, `policy.rights_gate: not_passed` and per-record `provenance.rights_gate: not_passed`; the runtime gate is fail-closed when `policy` is absent.
- Tracked save-like files are intentional versioned fixtures (`v1_save_slot_0.json`, `v2_player_state.json`) plus source code; no runtime player save is tracked.
- `game/.godot/` and `game/build/` are ignored/untracked; no templates or exported executables are staged.
- All Godot/Python runs used isolated `HOME` / `XDG_DATA_HOME` profiles; owner saves were not touched.

## O. Known limitations

- Original FFBE rules, banners, rates, guarantees, historical pools, recipe timings and shop inventories were not independently recovered; all delivered values are synthetic remaster designs.
- Windows runtime was not executed on this Linux host.
- Captured screenshots prove live window rendering and zero runtime error lines; they do not constitute subjective art-direction sign-off.
- Boot/offline QA environment variables are not gated by `FFBE_QA_MODE`; they are documented test hooks without production defaults.
- The three Unicode warnings remain benign Godot 4.7 editor doc-cache warnings from the Escape keycode; input bindings were intentionally left unchanged.
- Rights gate remains `not_passed`; no protected content is importable or present in the distributable build.

## P. Publication evidence

Publication is being performed with this checkpoint. The implementation commit, annotated tag `checkpoint/prompt-05-esper-summon-economy`, stacked draft PR against `phase-3-hardening`, and independent remote verification are being recorded in the follow-up documentation-only commit on this same branch. No `main` update, merge, force push, hard reset or destructive rebase is part of publication.

## Q. Final status

Implementation and validation are complete and green. All mandatory corrections, synthetic economy foundations, migration, localization, GUI QA, exports and security/rights review are satisfied. Publication verification is the only remaining gate; Prompt 06 remains unstarted and owner approval is required before any merge.

## Definition of Done — 28 items

| # | Item | Status | Evidence / caveat |
|---:|---|---|---|
| 1 | Branch created from verified Phase 3 checkpoint, not `main` | PASS | `33aa0f6` baseline; `main` unchanged |
| 2 | Baseline reproduced before implementation | PASS | `2153` Godot, `61` Python, `22` importer, `495` locale keys |
| 3 | Battle-run identity implemented | PASS | `run_id` propagated through manager, result, UI and saves |
| 4 | Independent/QA RNG seeds implemented | PASS | `seed_source`, QA-gated fixed seed |
| 5 | One-time/repeatable/mission reward buckets implemented | PASS | RewardResolver + canonical PlayerState claim keys |
| 6 | Idempotent settlement implemented | PASS | namespaced claim ledger and duplicate detection |
| 7 | Transactional reward persistence with rollback | PASS | whole-state snapshot restore on failed commit |
| 8 | ActionQueue eligibility/resource limits implemented | PASS | queue reservations and execution-time guards |
| 9 | Leader Skills implemented | PASS | build resolver and tests |
| 10 | Vision Cards implemented | PASS | per-unit assignment, legacy fallback, diagnostics |
| 11 | Invalid-party errors explicit | PASS | stable diagnostic keys and no silent fallback |
| 12 | Esper progression/battle/UI implemented | PASS | synthetic data, system, scene, locale keys, clear action |
| 13 | Summon definitions/RNG/transactions/UI implemented | PASS | synthetic banners, seeded draws, receipts, rollback test |
| 14 | Offline economy and farming policy implemented | PASS | caps, intervals, default rule, party modifiers, claims |
| 15 | Shop foundation implemented | PASS | synthetic shops, limits, receipts |
| 16 | Crafting foundation implemented | PASS | jobs, duration, settle/claim/cancel receipts |
| 17 | Additive v4 save migration implemented | PASS | legacy fields preserved, new sections backfilled |
| 18 | Localization complete for `vi` / `en` / `ja` | PASS | `741` keys, `304` mappings, zero missing |
| 19 | GUI QA at required desktop resolutions | PASS | 19 real captures and zero runtime error sidecars |
| 20 | Full Godot regression passes | PASS | `3043 passed, 0 failed`, exit `0` |
| 21 | Negative control fails as intended | PASS | deliberate failure, exit `1` |
| 22 | Python static/importer/localization tests pass | PASS | `75`, `22`, `11` tests respectively |
| 23 | End-to-end gameplay coverage passes | PASS | `test_end_to_end_flow` and UI battle/reward flow |
| 24 | Linux and Windows exports produced | PASS | both exit `0`; file types verified |
| 25 | Linux exported-binary smoke passes | PASS | exit `0`, PlayerState v4 boot |
| 26 | Security/rights/size review passes | PASS | no secrets, protected assets, runtime saves or staged executables |
| 27 | Stacked draft PR, tag and remote verification complete | PENDING | publication in progress on this branch |
| 28 | Final report delivered; Prompt 06 not started | PASS | this document and branch boundary |
