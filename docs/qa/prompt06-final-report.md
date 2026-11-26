# Prompt 06 final report — synthetic world, exploration, story and quests

**Development branch:** `phase-5-world-exploration-story`\
**Branch point / PR #9 base:** `phase-4-esper-summon-economy` at `d66cd4397d5b842cedfe38b83ff21aec58e74efb`\
**Stacked PR:** #9, base `phase-4-esper-summon-economy`, head `phase-5-world-exploration-story` (draft; owner approval pending)\
**Prior PR:** #8 remains `OPEN`, `DRAFT`, base `phase-3-hardening`, head `phase-4-esper-summon-economy`; it was not modified\
**Rights gate:** `not_passed`\
**Status:** implementation and host-verifiable validation complete; publication evidence is recorded below; owner approval is pending.

## A. Scope and boundary

Prompt 06 delivers a synthetic world/exploration/story vertical slice: a World Map, a keyboard/mouse explorable area, NPC dialogue with choices, a two-quest chain, one-time treasure, unlock-gated travel, and a battle-return path that preserves location, encounter and quest identity. All content is project-authored `SYNTHETIC_FIXTURE` or `REMASTERED_DESIGN`; no original FFBE story, map, art, portrait, music, text or source pack was imported or represented.

Explicitly outside this pass: Prompt 07, original story restoration, new protected assets, real-money purchases, hosted services, credentials, runtime saves in Git, engine upgrades, and any change to `main`, PR #8 or published Prompt 05/05.1 history. No force push, hard reset, `git clean`, destructive rebase, history rewrite, tag/branch deletion or save reset was performed.

The changes are confined to the new world scenes/scripts/data, the additive world portion of the existing v4 save, the existing battle result return path, the main-menu entry, localization, validation, tools and documentation.

## B. Baseline and branch integrity

The accepted pre-change baseline is Prompt 05.1 head `d66cd4397d5b842cedfe38b83ff21aec58e74efb`. Preflight verified the local branch, the remote branch, the clean starting tree and PR state. `main` and `origin/main` remained `6232acab9fa75fafd8a7c9a2099a1c94c08fa51e`. The tag `checkpoint/prompt-06-world-exploration-story` was absent before creation.

Baseline evidence (`/tmp/opencode/ffbe-logs/prompt06/baseline/summary.txt`):

| Check | Baseline result |
|---|---|
| Godot import | exit `0` |
| Full Godot runner | `3155 passed, 0 failed`, exit `0` |
| Godot negative control | deliberate failure, exit `1`, `3155 passed, 1 failed` |
| Python unittest discovery | `77 tests`, `OK`, exit `0` |
| Importer security suite | `22 tests`, `OK`, exit `0` |
| Localization validation | `status: pass`, `742` keys, `0` missing, `0` placeholder mismatches |
| Linux / Windows export | both exit `0` |
| Linux exported-binary smoke | exit `0` |

All final validation used isolated profiles under `/tmp/opencode/ffbe-profiles/prompt-06-*`. GUI captures used a fresh temporary profile per capture. No command read or wrote the owner's real save.

## C. Source and rights audit

`docs/audit/prompt06-world-story-source-audit.md` records the pre-implementation audit. No lawfully usable recovered FFBE map, story or dialogue pack was available, so the world was designed from scratch. Every pack declares `fixture_marker: SYNTHETIC_FIXTURE`, `policy.rights_gate: not_passed`, `policy.source_data_imported: false` and `policy.evidence_class: REMASTERED_DESIGN`; every record declares `verification_status: REMASTERED_DESIGN` with project-authored provenance.

No GL/JP equivalence is implied. All world IDs use the GL namespace and compact `loc:` location form; the repository canonicalizes `loc:` to `location` for kind validation without changing stable IDs. No restricted FFBE or Elvlin pack is active or approved in `data/import-approvals/registry.json` or `game/data/phase3/imported_manifest.json`.

## D. World data and catalog

Six packs are registered in `game/data/content_catalog.json` and loaded by `game/core/content_repository.gd`: regions, locations, location connections, interactables, dialogues and quests. Content loading is fail-closed on missing, malformed or policy-invalid data.

The synthetic world contains one region (`region:GL:1001@vale`), three locations (`loc:GL:1101@haven`, `loc:GL:1102@meadow`, `loc:GL:1103@spire`), two travel connections, nine interactables, two dialogue graphs and two quests. References are checked against existing battle encounters and existing synthetic resource IDs. Rewards use only validated item/fragment resources.

`tests/test_prompt06_world_data.py` statically verifies schema version, policy, ID shape, provenance, graph references, interactable contracts, dialogue effects, quest objectives/rewards, localization coverage and the absence of restricted-source phrases.

## E. Additive save state and migration

The save path remains `user://player_state_v3.json` and the top-level format remains version 4. `PlayerState.default_world_state()` adds an internal world-state version 1 section for current location, discovery/unlocks, quests, flags, dialogue choices, interactions, opened treasures, one-time encounter defeats and the last battle result. `_ensure_world_state()` backfills missing fields for v1, v2, v3 and v4 saves without resetting resources, units, inventory, claimed rewards, battle runs, economy, shops, crafting, summoning or Espers.

`SaveManager.backup_for_migration()` writes `player_state_v3.json.mig.bak` before the first committed world mutation of an older save. Future top-level versions are refused rather than downgraded. `PlayerState.transact_world()` stages a snapshot, commits via the existing writer and restores in-memory state if the commit fails. `game/tests/prompt06_world_test_suite.gd` covers the v1/v2/v3/v4 matrix, backup creation, future-version refusal and write rollback.

## F. World Map and exploration

`world_map.tscn` draws a project-authored map surface with location markers, connection edges, selection state, locked/unlocked indicators, a localized detail panel, a quest journal button and travel into an exploration area. `world_map_marker_area.gd` contains no protected map art; it draws synthetic shapes.

`exploration_area.tscn` hosts a `Control` playfield, player marker, interaction buttons, controls/help labels, a pause panel and the reusable `dialogue_panel.tscn`. Movement and interaction are authored in a 1280×720 design space and mapped to the real viewport, so 1024×640, 1280×720 and 1920×1080 use the same logical positions, obstacles and click targets.

Controls: WASD/arrows move; mouse click sets a clamped finite target; E/Space interacts or advances dialogue; Enter confirms a choice; Escape opens/closes pause, closes dialogue or returns from pause to the World Map. Obstacles reject both keyboard and mouse movement, verified by `ExplorationController` tests.

## G. Dialogue, quests and treasure

`DialogueRepository` provides keyed lines, conditional lines, choices and effects. `DialogueManager` resolves quest-status conditions and applies `flag`, `quest_accept`, `quest_event` and `unlock_location` effects only after a choice is selected. `DialoguePanel` is presentation-only and resolves all text through `LocaleManager`. The keeper dialogue accepts the oath quest; the scout dialogue has conditional intro/active/done lines.

`QuestManager` accepts quests with prerequisite gates, initializes progress from facts already present in the world state, records the supported event vocabulary, completes objectives atomically, settles rewards once and unlocks locations. The oath quest unlocks the meadow; the lantern quest requires talk, visit, treasure, battle, collect and prerequisite-quest objectives, and unlocks the spire.

Treasure uses `one_time` interaction and `world|treasure|<id>` claim keys. Repeated interaction, reload or scene re-entry cannot claim it twice. No dialogue or quest text claims to restore an original FFBE story.

## H. Battle integration and identity

An encounter trigger writes location, encounter, return-scene and trigger identity into `WorldContext`, then starts the existing `BattleScene`. `BattleScene` consumes the context, applies the encounter override, keeps the return path and emits a result snapshot. `InteractionController.on_battle_result()` accepts that snapshot only for a matching identity, calls `QuestManager.record_event()` for a victory and leaves defeat without progress or reward.

`WorldContext` stores metadata on the persistent SceneTree root under a namespaced prefix instead of adding/removing a child node. This removes the Godot "parent node is busy" errors encountered when a scene changed during `_ready()`. QA battle-transition scenarios defer the scene change to the next idle frame. Retry uses a new battle `run_id`; existing battle reward prefixes (`battle|run|`, `battle|once|`, `battle|first|`, `battle|mission|`) remain unchanged and are separate from world claim keys.

## I. Localization

`vi` remains the default locale, with `en` and `ja` supported. World labels, prompts, dialogue lines, quest text and the two new battle-result statuses (`world.explore.battle_victory`, `world.explore.battle_defeat`) are localization keys. The world scenes and dialogue panel reconnect on `locale_changed` for live switching. `FFBE_QA_LOCALE` is a QA-only starting-locale override and does not write the saved locale.

`data/validation/localization-coverage.json` was regenerated by `tools/localization/coverage_report.py`: `829` union keys, `0` missing, `0` placeholder mismatches, `45` world data keys, `280` dynamic references and `0` dynamic reference errors. `docs/localization/coverage-report.md` and the Python key-count expectation were updated to match.

## J. Regression evidence and negative control

| Check | Result | Evidence |
|---|---|---|
| Godot import | exit `0` | `final/import.log` |
| Full Godot runner | `3521 passed, 0 failed`, exit `0` | `final/godot-full.log` |
| Negative control | `3521 passed, 1 failed`, exit `1` | `final/godot-negative.log`, `FFBE_TEST_NEGATIVE_CONTROL=1` |
| Python unittest discovery | `95 tests`, `OK`, exit `0` | `final/python.log` |
| Importer security suite | `22 tests`, `OK`, exit `0` | `final/importer.log` |
| Localization validator | `status: pass`, `829` keys, `0` missing, `0` placeholder mismatches, `45` world keys, `280` dynamic references, `0` dynamic errors, exit `0` | `final/localization.log` |
| `git diff --check` | reviewed after final diff | publication evidence |

Expected negative-validation `ERROR:` lines in the Godot logs come from deliberate fixture tests for invalid economy/esper packs and shutdown resource notices; they are not runtime GUI errors. The GUI capture harness counts `SCRIPT ERROR`, `Parse Error` and `ERROR:` lines separately and requires zero for every Prompt 06 capture.

## K. Static Python and repository validation

`tests/test_prompt06_world_data.py` adds ten static world-contract tests. `tests/test_phase3_qa_tools.py` adds seven Prompt 06 QA-tool tests covering the 72-capture matrix, missing-capture detection, runtime-error rejection, missing scenario metadata, report rendering and the isolated-profile capture wrapper. `tests/test_phase3_localization.py` was updated to the regenerated `829`-key baseline.

The world data validator checks the compact `loc:` prefix by canonical kind normalization rather than renaming stable IDs. All newly added JSON keys are present in all three locale dictionaries. No forbidden source phrase or JP-region world record is present.

## L. Headless regression matrix

Final isolated run (`/tmp/opencode/ffbe-logs/prompt06/final/summary.txt`):

```text
import_exit=0
godot_full_exit=0
Results: 3521 passed, 0 failed
negative_exit=1
Results: 3521 passed, 1 failed
python_exit=0
Ran 95 tests in 1.415s
OK
importer_exit=0
Ran 22 tests in 0.229s
OK
localization_exit=0
status: pass
union keys: 829
world data keys: 45
missing keys: 0
placeholder mismatches: 0
dynamic references: 280
dynamic reference errors: 0
linux_export_exit=0
windows_export_exit=0
linux_smoke_exit=0
capture_sidecars=72
capture_runtime_error_total=0
DONE
```

The increase from the baseline `3155` assertions comes from the Prompt 06 world suite, the v1–v4 normalization test and explicit scene/context checks. Python discovery increased from `77` to `95` tests through the ten static world-contract tests and seven QA-tool tests.

## M. Exports and runtime status

| Artifact | Result |
|---|---|
| Linux release export | exit `0`, ELF64 x86-64 executable, `final/exports/linux-export.log` |
| Windows release export | exit `0`, PE32+ x86-64 executable, `final/exports/windows-export.log` |
| Linux exported-binary smoke | exit `0`, `final/exports/linux-smoke.log` |
| File types and SHA-256 | `final/exports/file-types.log`, `final/exports/sha256.log` |
| Windows runtime | **BLOCKED / NOT RUN** — no Windows host is available; export success is not runtime verification |

Export templates were discovered through a read-only symlink from the isolated Godot data directory to the existing local template installation; no template was downloaded or modified.

## N. Real GUI QA

Capture tool: `tools/qa/capture_prompt06.sh`, which delegates to the live-window `tools/qa/capture_phase3.sh` with a fresh isolated profile per capture. Report generator: `tools/qa/prompt06_visual_report.py`. Output directory: `docs/qa/screenshots/prompt06/`. The required eight scenarios × three resolutions × three locales are:

- World Map, selected location, hub exploration, NPC dialogue, quest journal, treasure interaction, battle transition and quest completion;
- `1024x640`, `1280x720`, `1920x1080`;
- `vi`, `en`, `ja`.

At `1920x1080` the wrapper uses fullscreen because the available X display cannot fit a decorated client window of that size. Every PNG has a sidecar containing scene, scenario, resolution, locale, geometry, ImageMagick pixel statistics and runtime error count. The generator rejects any missing matrix cell or nonzero error line. The derived report is [docs/qa/prompt06-visual-review.md](prompt06-visual-review.md).

Seventy-two sidecars were generated and zero runtime error lines were recorded across all of them. These captures prove live rendering at the requested sizes and locales; they do not establish subjective art-direction approval.

## O. Security, rights, size and preservation

Pre-publication repository review is recorded in `/tmp/opencode/ffbe-logs/prompt06/final/security-audit.txt`. It checks credentials, executables, archives, logs, saves, temp files, restricted packs, import approvals, the active imported manifest and tracked build/cache directories. The intended staged set contains source, synthetic JSON, isolated GUI evidence and documentation only.

No runtime save, exported binary, temporary debug script, credential or protected asset is staged. The GUI PNG/TXT pairs are intentional QA evidence. No original or recovered FFBE/Elvlin pack was added to public Git.

## P. Reproducibility and evidence locations

- Development logs: `/tmp/opencode/ffbe-logs/prompt06/dev-summary.txt`, `godot-current.log`, `import-current.log`.
- Baseline: `/tmp/opencode/ffbe-logs/prompt06/baseline/summary.txt`.
- Final validation: `/tmp/opencode/ffbe-logs/prompt06/final/summary.txt` and sibling logs.
- GUI capture log: `/tmp/opencode/ffbe-logs/prompt06/capture-matrix.log`; per-capture logs under `/tmp/ffbe-phase3-qa/`.
- Isolated profiles: `/tmp/opencode/ffbe-profiles/prompt-06-dev`, `prompt-06-final`, `prompt-06-qa-runs`.
- Static documentation: `docs/audit/prompt06-world-story-source-audit.md`, `docs/architecture/world-exploration.md`, `docs/data-dictionary/world-story-schema.md`, this report and the visual review.

## Q. Known limitations and non-verified items

- Windows runtime execution: **NOT RUN / BLOCKED** on this Linux host. Windows export success only proves that a PE32+ binary was produced.
- Subjective visual, readability and art-direction approval: **NOT VERIFIED**. Automated captures verify geometry, pixel variation and zero runtime error lines only.
- The world is a synthetic demonstration, not a restoration of original FFBE geography, story, names or quest text.
- Battle-transition captures show the encounter-trigger transition into battle, not a full battle-to-victory playthrough; reward idempotency and defeat isolation are covered by headless tests.
- The three `Unicode parsing error ... 400000` lines in Godot import/export logs are previously root-caused editor doc-cache warnings for the Escape keycode; input bindings were intentionally unchanged.
- Original online services, real-money purchases and protected source assets remain outside project scope.

## R. Prompt preservation and regression

The existing v4 save contract, battle reward ledger, economy/summon/shop/crafting/Espers systems and main-menu entry points remain intact. The Main Menu gains a World entry; no prior button was removed. BattleScene consumes optional world context only when present, so non-world battles still start and return normally. Prompt 05/05.1 tests remain in the full suite and are green. `main`, PR #8 and the published Prompt 05/05.1 commits were not touched.

## S. Review and publication evidence

- Reviewed the staged diff before commit. `git diff --cached --check` returned exit `0` with no output.
- Security review (`/tmp/opencode/ffbe-logs/prompt06/final/security-audit.txt`): `207` staged files, `0` credential filename/text hits, `0` executable or archive candidates, `0` runtime save candidates, `0` temporary log candidates, `0` registry entries, `0` active imported packs and `last_import: null`. The `72` `.txt` sidecars are intentional GUI evidence containing geometry, pixel statistics, locale and runtime-error metadata.
- Implementation commit: `6d22904d0922b2530097930502f80f99c7fbe006` — `feat(prompt06): add synthetic world exploration and story slice`.
- Published with a normal push: `git push origin phase-5-world-exploration-story`, reported as a new remote branch. One docs-only follow-up commit on the same branch records this publication evidence; no amend, rebase, force push or history rewrite was used.
- Independent post-push verification after the implementation commit: local HEAD and `origin/phase-5-world-exploration-story` were both `6d22904d0922b2530097930502f80f99c7fbe006`. After the evidence commit, local and remote branch were re-read and matched at the final HEAD.
- GitHub PR #9 was re-read after publication: `state: OPEN`, `isDraft: true`, `baseRefName: phase-4-esper-summon-economy`, `baseRefOid: d66cd4397d5b842cedfe38b83ff21aec58e74efb`, `headRefName: phase-5-world-exploration-story`, URL `https://github.com/AnhhTuann/FFBE-Remastered/pull/9`. The PR was not merged, closed or retargeted.
- GitHub PR #8 was re-read and remained `OPEN`, `DRAFT`, base `phase-3-hardening`, head `phase-4-esper-summon-economy` at `d66cd4397d5b842cedfe38b83ff21aec58e74efb`. It was not modified.
- `origin/main` remained `6232acab9fa75fafd8a7c9a2099a1c94c08fa51e`; `origin/phase-3-hardening` remained `33aa0f697943ef0417444bff32510849a662b6f0`; `origin/phase-4-esper-summon-economy` remained `d66cd4397d5b842cedfe38b83ff21aec58e74efb`.
- The tag `checkpoint/prompt-06-world-exploration-story` was confirmed absent before creation, then created as an annotated tag at the final branch HEAD after the docs-only evidence commit. No existing tag was replaced or deleted.

## T. Final status

Implementation is complete. All host-verifiable validation gates are green; Windows runtime and subjective visual approval remain explicitly non-verified rather than reported as passing. The branch is published as draft PR #9 for owner review. Prompt 07 has not been started and must not begin before owner approval.

## Definition of Done — 32 items

| # | Item | Status | Evidence / caveat |
|---:|---|---|---|
| 1 | Branch created from Prompt 05.1 head | PASS | `phase-5-world-exploration-story` at `d66cd439...`; PR #9 base recorded |
| 2 | `main` and PR #8 preserved | PASS | `main` at `6232aca...`; PR #8 `OPEN`/`DRAFT`, unchanged base/head |
| 3 | Rights gate remains `not_passed` | PASS | all six world packs and audit document |
| 4 | No restricted FFBE/Elvlin/source material | PASS | audit, static phrase scan, import manifests |
| 5 | Synthetic provenance on every world record | PASS | `test_stable_ids_and_provenance` |
| 6 | Six world packs registered and fail-closed | PASS | catalog and `ContentRepository` tests |
| 7 | Stable regional IDs and `loc:` normalization | PASS | repository `_canonical_kind()`, Python ID checks |
| 8 | World Map scene present and functional | PASS | `world_map.tscn`, GUI matrix, headless scene test |
| 9 | Location selection and travel | PASS | `test_world_map_scene`, selected-location captures |
| 10 | Locked location gate | PASS | quest unlock requirements and unlock tests |
| 11 | Exploration area scene present | PASS | `exploration_area.tscn`, hub captures |
| 12 | WASD/arrow movement | PASS | `test_exploration_controller` |
| 13 | Mouse/keyboard interaction support | PASS | controller and scene tests, design-space mapping |
| 14 | Obstacles and finite mouse targets | PASS | `test_exploration_controller` |
| 15 | Escape pause/return and Enter confirm | PASS | exploration input handlers and pause scenario |
| 16 | Dialogue panel scene and keyed text | PASS | `dialogue_panel.tscn`, `DialoguePanel` tests |
| 17 | Dialogue choices and effects | PASS | `test_dialogue_manager`, keeper/scout graph tests |
| 18 | Quest journal and two-quest chain | PASS | `test_quest_manager`, journal captures |
| 19 | Treasure one-time claim | PASS | `test_interaction_controller`, treasure captures |
| 20 | World Map → exploration → battle context | PASS | `test_battle_result_identity`, battle-transition captures |
| 21 | Battle result returns to exploration | PASS | `_world_return_context()` and result-path test |
| 22 | Defeat never completes objectives | PASS | `test_battle_result_identity` |
| 23 | Retry/reload cannot duplicate world rewards | PASS | claim-key tests, treasure and quest tests |
| 24 | Save path and v4 format preserved | PASS | `user://player_state_v3.json`, version contract tests |
| 25 | v1/v2/v3/v4 normalization, backup, refusal, rollback | PASS | `test_version_matrix_normalization`, migration/rollback tests |
| 26 | `vi`/`en`/`ja` parity and live switching | PASS | `829` keys, `0` missing, GUI locale matrix |
| 27 | No hardcoded world user-facing strings | PASS | scene text fields empty; locale key scan |
| 28 | Godot full suite and negative control | PASS | `3521/0` exit `0`; `3521/1` exit `1` |
| 29 | Python, importer and localization suites | PASS | `95`, `22`, validator `pass` with `829` keys |
| 30 | Linux/Windows export and Linux smoke | PASS | all exit `0`; file types and hashes logged |
| 31 | GUI matrix at three resolutions and locales | PASS | 72 PNG/sidecar pairs, `0` runtime error lines; visual review generator |
| 32 | Docs, diff, commit, push, draft PR #9, tag | PASS | section S evidence; implementation commit `6d22904`, normal push, PR #9 `OPEN`/`DRAFT`, annotated checkpoint tag |
