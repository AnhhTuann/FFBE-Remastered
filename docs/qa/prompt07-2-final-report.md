# Prompt 07.2 final QA report — Event Center visual redesign

**Status:** PASS.
**Branch:** `phase-6.2-event-center-visual-redesign`.
**Baseline:** `e1da3eccf663a882a09de7a33d5823bf00939ef3` (Prompt 07.1 HEAD).
**Engine:** Godot 4.7.2 stable; project root `game/`.
**Rights gate:** `not_passed`. All Event Center artwork is project-authored procedural geometry; no FFBE UI, character art, music, dialogue, banner or historical summon data was introduced.

## 1. Outcome summary

| Item | Status |
|---|---|
| Event Center visual redesign | PASS |
| Reusable procedural UI components | PASS |
| Responsive 1024×640 / 1280×720 / 1920×1080 / 720×1280 | PASS |
| Localization parity (`vi`, `en`, `ja`) | PASS |
| Gameplay service preservation | PASS |
| Fresh 180-capture matrix | PASS |
| Godot import / focused / full / negative control | PASS |
| Python discovery / importer security / world + QA tooling | PASS |
| Linux / Windows export and Linux smoke | PASS |
| Security and protected-asset audit | PASS |
| Windows runtime execution | NOT RUN (Linux host) |
| Subjective human visual approval | NOT VERIFIED |
| Stage-region validation concern | Separate gameplay issue, not in this presentation scope |

## 2. Scope and preservation

This was a presentation-only redesign. `EventRepository`, `EventSchedule`, `EventStateService`, `EventUnlockEvaluator`, `PlayerState`, save format v4, `WorldContext`, mission progression, repeatable-cycle claims, atomic reward transactions, GL/JP support, battle settlement and Event Center return navigation were preserved.

Prompt 07 and Prompt 07.1 reports and the original 180 screenshots remain untouched. New evidence uses `docs/qa/screenshots/prompt07-2/` and `docs/qa/prompt07-2-visual-review.md`.

## 3. Implemented visual changes

Detailed design decisions are in [docs/architecture/event-center-visual-design.md](../architecture/event-center-visual-design.md).

- Midnight navy layered background with gold/cyan ornament, drawn with Godot primitives.
- Designed header with localized title/subtitle, GL/JP selector, back navigation and currency summary.
- Scrollable status/category filters with explicit selected and focus states.
- Designed event cards with deterministic procedural fantasy artwork, category, availability badge, schedule and selected highlight.
- Hero detail section with large procedural art, status, region, schedule, currency and main action.
- Designed stage, mission, shop and summon cards with distinct locked/available/completed/repeatable states.
- Progress bars, restrained hover/selection/progress transitions and reduced-motion support.

## 4. Validation evidence

All logs are under `/tmp/opencode/ffbe-logs/prompt-07.2/`. Fresh isolated profiles under `/tmp/opencode/ffbe-profiles/prompt-07.2-*` were used. Commands are shown from the worktree root unless noted.

| Check | Command / log | Exit | Result |
|---|---|---:|---|
| Godot import | `godot --headless --editor --quit --path game --user-dir /tmp/opencode/ffbe-profiles/prompt-07.2-final-import-3` → `import/final-import-3.log` | 0 | 0 `SCRIPT ERROR`, `Parse Error` or `ERROR:` lines |
| Focused Event Center suite | `godot --headless --path game --script /tmp/opencode/ffbe-logs/prompt-07.2/focused/prompt07_focused_runner.gd --user-dir /tmp/opencode/ffbe-profiles/prompt-07.2-focused-final-3` → `focused/final-focused-3.log` | 0 | `PROMPT07_FOCUSED passed=503 failed=0 suite_ok=true` |
| Full Godot suite | `godot --headless --path game --script res://tests/test_runner.gd --user-dir /tmp/opencode/ffbe-profiles/prompt-07.2-full-final-3` → `full/final-full-3.log` | 0 | `Results: 4395 passed, 0 failed` |
| Negative control | `FFBE_TEST_NEGATIVE_CONTROL=1 godot --headless --path game --script res://tests/test_runner.gd --user-dir /tmp/opencode/ffbe-profiles/prompt-07.2-negative-final-3` → `negative/final-negative-3.log` | 1 | Expected: `ERROR: FAIL FFBE_TEST_NEGATIVE_CONTROL deliberate failure: expected true`; `Results: 4395 passed, 1 failed` |
| Python discovery | `python3 -m unittest discover -s tests -v` → `python/final-discovery-3.log` | 0 | `Ran 133 tests`, `OK` |
| Importer security | `python3 -m unittest tests.test_phase3_importer -v` → `security/final-importer-recheck.log` | 0 | `Ran 22 tests`, `OK` |
| Localization generator | `python3 tools/localization/coverage_report.py --root . --output data/validation/localization-coverage.json` → `localization/final-coverage-recheck.log` | 0 | `status: pass`; 940 union keys, 45 world keys, 33 event keys, 0 missing, 0 placeholder mismatches, 291 dynamic references, 0 dynamic errors |
| Localization unit tests | `python3 -m unittest tests.test_phase3_localization -v` → `localization/final-unit-recheck.log` | 0 | `Ran 13 tests`, `OK` |
| World + QA tooling | `python3 -m unittest tests.test_prompt06_world_data tests.test_phase3_qa_tools -v` → `world/final-world-qa-3.log` | 0 | `Ran 55 tests`, `OK` |
| 180-capture QA | `tools/qa/capture_prompt07_2.sh` over 15 scenarios × 4 resolutions × 3 locales with a 10-second settle plus the Event Center post-layout `QA_READY` marker → `qa/final-capture-loop.log`; `python3 tools/qa/prompt07_2_visual_report.py` → `qa/final-visual.log` | 0 | Loop `captured=180 failed=0`; report `captures: 180`; 360 sidecar/PNG files, readiness marker in all Event Center sidecars, 0 runtime error lines, 0 blank-frame rejections, 0 byte-identical PNGs; summon uses the JP banner fixture and replay uses the ended collaboration fixture; display restored to 1920×1080 |
| Linux export | `cd game && godot --headless --path . --export-release "Linux" build/linux/FFBE-Remastered.x86_64 --user-dir /tmp/opencode/ffbe-profiles/prompt-07.2-export-linux-final` → `linux-export/final-export.log` | 0 | ELF 64-bit executable produced |
| Windows export | `cd game && godot --headless --path . --export-release "Windows Desktop" build/windows/FFBE-Remastered.exe --user-dir /tmp/opencode/ffbe-profiles/prompt-07.2-export-windows-final` → `windows-export/final-export.log` | 0 | PE32+ Windows executable produced; runtime NOT RUN |
| Linux smoke | `HOME=/tmp/opencode/ffbe-profiles/prompt-07.2-smoke-final/home XDG_DATA_HOME=... XDG_CONFIG_HOME=... ./build/linux/FFBE-Remastered.x86_64 --headless --quit-after 300` → `linux-smoke/final-smoke.log` | 0 | Clean startup; 0 `SCRIPT ERROR` / `ERROR:` lines |
| Diff check | `git diff --check` → `diff/final-diff-check.log` | 0 | No whitespace errors |
| Security/rights audit | `security/audit-staged.sh /tmp/opencode/ffbe-worktrees/prompt07.2` → `security/final-security-rights.log` | 0 | 387 staged files; no forbidden binaries/archives, no secret patterns, no protected terms in event data; `not_passed` / `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN` retained; 6 events / 8 stages; 360 historical + 360 new capture files |

The negative-control exit code of 1 is intentional: it proves the full runner returns non-zero when a deliberate failure is injected.

## 5. Rights and repository safety

- Rights gate remains `not_passed`; all event content remains `SYNTHETIC_FIXTURE` / `REMASTERED_DESIGN`.
- Procedural artwork is generated in GDScript from region-aware IDs and category accents; no downloaded or protected image was added.
- Visible labels use localized dynamic display-name mappings; no raw banner ID, claim key, event-currency ID, purchase rate, guarantee or historical pool is rendered.
- No real-money purchase, summon rate, banner, guarantee, historical pool or FFBE character identity was introduced.
- Final staged-file, binary, secret and protected-content scan results are recorded in `security/final-security-rights.log`.

## 6. Limitations

- Windows runtime testing is NOT RUN on this Linux host; a Windows export is not runtime proof.
- Subjective visual approval of the 180 retained captures is a human review item; automated verification proves capture integrity only.
- Corrupted-save and process-termination recovery remain outside this presentation-only phase.
- The previously identified stage-region validation concern remains a separate gameplay issue; this redesign does not alter it.
