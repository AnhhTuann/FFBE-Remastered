# Prompt 07 final report — Event Center foundation

**Date:** 2026-11-26
**Branch:** `phase-6-event-center-collaboration`
**Stacked PR:** [#10](https://github.com/AnhhTuann/FFBE-Remastered/pull/10) — `OPEN`, `DRAFT`, base `phase-5-world-exploration-story`
**Engine:** Godot 4.7.2 stable; project root `game/`
**Rights gate:** `not_passed`. Every runtime event record is `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN`.

## 1. Scope and outcome

Prompt 07 adds an offline, data-driven Event Center foundation. It does **not** restore original FFBE events and does not start Prompt 08. No protected FFBE/Elvlin character, art, music, dialogue, logo, banner rate, guarantee, historical pool or real-money purchase was introduced.

Delivered capabilities:

- Six synthetic events and eight stages in `game/data/events/events.json`, registered as `events` in `game/data/content_catalog.json`.
- Stable region-aware IDs (`event:<GL|JP>:<native>@<form>`, `stage:<GL|JP>:<native>@<form>`), category/type, localized keys, GL/JP schedules, permanent and scheduled availability, unlocks, boss encounters, replay/archive policy, missions, currency, shop and banner references, and provenance/rights metadata.
- `EventSchedule` owns all availability states — `Upcoming`, `Active`, `Ended`, `Archived`, `Permanent`, `Replayable` — through an injectable clock. Gameplay tests never read the OS clock.
- `EventRepository` is read-only over the validated fixture pack; `EventStateService` owns staged progression, idempotent claims and transactions.
- Additive `events` section in the existing v4 `user://player_state_v3.json`. Top-level format stays v4; v1–v4 data is preserved; future section versions are refused; failed writes roll back and keep the pending result for the existing Retry path.
- Event battles reuse `BattleScene`, `WorldContext` and the existing reward ledger. Event contexts carry `event_id`, `stage_id`, `region`, `encounter_id` and `return_scene`, and omit `trigger_id` so world settlement cannot be entered accidentally.
- Event Center UI: overview cards, category and status filters, details, art panels with explicit synthetic placeholder captions, stages, first-clear/repeat rewards, currency, missions, shop, archive/replay, collaboration fixture and summon-banner navigation.
- Entry points from the main menu and economy hub; summon consumes an Event Center return context once.
- `vi`, `en`, `ja` dictionaries with live switching and persisted locale. All visible Event Center copy uses localization keys.

## 2. Integration decisions

Existing systems were audited before implementation; no parallel reward, battle, save or locale system was created.

| Area | Reused integration |
|---|---|
| Save | `PlayerState.transaction("events", ...)`, existing atomic writes, migration backup and pending-result retry. `PLAYER_STATE_VERSION` remains `4`. |
| Rewards | Existing `_stage_world_claim()` and canonical `world|event|<kind>|<identity>` keys, e.g. `world|event|mission|event:GL:980001@stargarden|clear_gate`. |
| Battle | Existing `BattleScene` result recording with a dedicated `settle_event_battle()` branch before world settlement. |
| Navigation | `WorldContext.META_KEYS` whitelist plus the existing `return_scene` mechanism. |
| Content | Existing `ContentRepository` fixture gate, record validation and catalog paths. |
| Summon/economy | Existing synthetic banner and shop packs referenced by ID only. |
| UI/locale | Existing `LocaleManager`, `Control` containers, anchors, autowrap and scroll containers. |

Architecture details are in [docs/architecture/event-center.md](../architecture/event-center.md) and the record contract in [docs/data-dictionary/event-schema.md](../data-dictionary/event-schema.md).

## 3. Skills used

Loaded project-local skills: `ffbe-godot-foundation`, `ffbe-battle-engine`, `save-systems`, `rpg`, `ffbe-project-quality`, `godot-gdscript-headless-testing`, `godot-export`, `ffbe-source-audit`, `ffbe-asset-restoration`. No event-system skill exists in `.agents/skills`; the closest project skills were audited and applied. Upstream skill guidance was checked against the pinned Godot 4.7.2 API before use.

## 4. Fresh verification

All commands below were run on the final implementation tree. Logs are retained in `/tmp/opencode/ffbe-logs/prompt-07/`. Focused, full, negative-control, export and smoke runs used isolated `/tmp/opencode/ffbe-profiles/prompt-07-*` profiles.

| Check | Command / path | Result |
|---|---|---|
| Godot import | `godot --headless --editor --quit --path game --user-dir /tmp/opencode/ffbe-profiles/prompt-07-import-final` | exit `0`; `0` `SCRIPT ERROR`/`Parse Error`; `import-final.log` |
| Focused Prompt 07 suite | `godot --headless --path game --script /tmp/opencode/ffbe-profiles/prompt-07-focused/focused_runner.gd --user-dir /tmp/opencode/ffbe-profiles/prompt-07-focused-final` | `205 passed, 0 failed`, exit `0`; `focused-final.log` |
| Full Godot suite | `godot --headless --path game --script res://tests/test_runner.gd --user-dir /tmp/opencode/ffbe-profiles/prompt-07-full-final` | `4051 passed, 0 failed`, exit `0`; `full-suite-final.log` |
| Negative control | same full suite with `FFBE_TEST_NEGATIVE_CONTROL=1`, profile `prompt-07-negative-final` | `4051 passed, 1 failed`, exit `1`; `negative-control-final.log` |
| Python discovery | `python3 -m unittest discover -s tests -v` | `115 tests`, `OK`, exit `0`; `python-discovery-final.log` |
| Importer security | `python3 -m unittest tests.test_phase3_importer -v` | `22 tests`, `OK`, exit `0`; `importer-security-final.log` |
| World data + QA tools | `python3 -m unittest tests.test_prompt06_world_data tests.test_phase3_qa_tools -v` | `40 tests`, `OK`, exit `0`; `world-qa-final.log` |
| Localization | `python3 tools/localization/coverage_report.py` | `status: pass`, `917` keys per locale, `33` event data keys, `0` missing, `0` placeholder mismatch, `280` dynamic references, `0` dynamic error, exit `0`; `localization-final.log` |
| Visual QA report | `python3 tools/qa/prompt07_visual_report.py` | `156` PNG/sidecar pairs, complete matrix, `0` runtime error lines, no blank captures, exit `0`; `visual-report-final2.log` |
| Linux export | `godot --headless --path game --export-release "Linux" build/linux/FFBE-Remastered.x86_64` | exit `0`, ELF64 x86-64; `export-linux.log` |
| Windows export | `godot --headless --path game --export-release "Windows Desktop" build/windows/FFBE-Remastered.exe` | exit `0`, PE32+ x86-64; `export-windows.log` |
| Linux smoke | `./FFBE-Remastered.x86_64 --headless --quit-after 300` in isolated profile | exit `0`, no `SCRIPT ERROR`/`Parse Error`/`ERROR:`; `smoke-linux.log` |
| Diff check | `git diff --check` and `git diff --cached --check` | exit `0` both times |

Expected noise: the negative control intentionally emits one failure; the full suite contains warning lines from existing fault-injection fixtures and engine resource cleanup. Unicode font-cache warnings in Godot import/export are pre-existing engine noise, not project parse errors.

## 5. Visual QA

See [docs/qa/prompt07-visual-review.md](prompt07-visual-review.md). The generated report and its 156 sidecars record:

- 13 scenarios: overview, active, upcoming, ended, categories, detail, stages, rewards, shop, summon, archive, replay, collaboration.
- 4 resolutions: `1024x640`, `1280x720`, `1920x1080`, `720x1280`.
- 3 locales: `vi`, `en`, `ja`.
- Fixed injected clock `1740000000`, isolated profile per capture, `0` runtime error lines.
- ImageMagick geometry and pixel statistics; the generator rejects blank or near-blank frames.

Portrait captures temporarily switched the X display to a `720x1280` mode because that window cannot fit the `1920x1080` desktop, then restored `1920x1080`. Metadata confirms exact geometry. These are real Godot window captures, not mockups or composited images.

Subjective art-direction, readability and final visual approval remain **NOT VERIFIED** by automation and require owner inspection of the retained PNGs. No protected art, logo or character was used.

## 6. Rights and security audit

- Event pack policy: `rights_gate: not_passed`, `source_data_imported: false`, `evidence_class: REMASTERED_DESIGN`, `verification_status: REMASTERED_DESIGN`.
- Collaboration guest is an original synthetic reference with a rights gate; no copyrighted collaboration character, dialogue, art or music.
- Summon references point to existing synthetic banners; no invented FFBE rates, guarantees, pools or history and no real-money purchase.
- Static test rejects protected-name terms, asset extensions (`png/jpg/mp3/ogg`) and URLs in the event pack.
- No credentials, private keys, archives, local saves, player profiles or build executables were added to Git. `game/build/` remains ignored.

## 7. Git checkpoint and publication

- Implementation commit: `a147ba93cf866101b56092631516595ac9d4ecdb` — `feat(events): add offline event center foundation`.
- Documentation/evidence commit: the commit containing this report and the retained screenshots.
- Annotated tag: `checkpoint/prompt-07-event-center`, tag object `00256f7d8ccf02b0d606f101da24b5a00b9aa567`, target `a147ba93cf866101b56092631516595ac9d4ecdb`.
- Only `phase-6-event-center-collaboration` was pushed normally; no force push, hard reset, destructive rebase, `git clean`, auto-merge or `main` modification.
- PR #10 is a stacked draft against `phase-5-world-exploration-story`; PR #9 and PR #8 remain open drafts and untouched.

## 8. Remaining blockers / next step

- Windows runtime: **BLOCKED / NOT RUN** on this Linux host; successful export is not runtime proof.
- Subjective visual approval: **NOT VERIFIED** until the owner inspects the retained PNGs.
- Prompt 08 is **not started**. Wait for owner approval of this checkpoint before any further milestone.
