# Test report — Phase 1 Godot foundation

**Date:** 2026-11-25
**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`
**Branch:** `phase-1-godot-foundation`
**Scope:** technical foundation and Character Viewer only. No battle gameplay is implemented.

## 1. Commands and results

| Command | Result | Exit |
|---|---|---:|
| `godot --headless --path game --import` | Completed; no `SCRIPT ERROR` or `ERROR:` lines after fixes | 0 |
| `godot --headless --path game --script res://tests/test_runner.gd` | `Results: 74 passed, 0 failed` | 0 |
| Negative control: inject `unit_count` expectation `77`, rerun runner, restore file | `Results: 73 passed, 1 failed`; `ERROR: FAIL unit count: expected 77, got 4` | 1 |
| `python3 -m unittest discover -s tests -v` | `Ran 20 tests`, `OK` | 0 |

Logs are kept under `/tmp/opencode/ffbe-logs/` on this machine:

- `import.log`, `import-after-fixes.log`
- `gdscript-tests-final.log`, `gdscript-tests-negative-final.log`
- `python-tests-final.log`, `python-tests-final-2.log`

## 2. GDScript coverage

The `SceneTree` runner counts every assertion and explicitly calls `quit(1 if failed > 0 else 0)`. Bare `assert()`, `push_error()` alone, or Godot's default exit code are **not** trusted to fail CI.

Checked areas:

- project name, 1280×720 viewport, nearest texture filter, Compatibility renderer, input actions, all four scenes exist;
- `ContentRepository` loads 4 synthetic units, 3 GL / 1 JP, with `SYNTHETIC_FIXTURE` marker;
- composite identity distinguishes `unit:GL:900001@base` from `unit:JP:900001@base`;
- all 12 synthetic clips validate; out-of-bounds and zero-duration examples fail validation;
- repeated and non-monotonic frame IDs are accepted as hold/oscillation metadata;
- viewer scene: unit list, region filter, clip switch, playback toggle/restart, loop flag and visible diagnostic for a missing animation;
- synthetic atlas loads at 128×128;
- save round-trip, backup recovery from a deliberately corrupted primary, `1 → 2` migration, newer-version refusal, settings persistence;
- export presets contain Windows Desktop and Linux entries and include JSON assets.

The two `WARNING:` lines in the passing run are expected: one is the deliberate corrupt-primary recovery test, the other is the deliberate newer-version refusal test. No parser or unexpected runtime errors remain.

## 3. Parser/runtime errors found and corrected

| Finding | Fix |
|---|---|
| `Function "pop()" not found in base Dictionary` in `save_manager.gd` during import | Replaced `profile.pop("selected_unit")` with assignment plus `erase()` |
| `Identifier not found: ContentRepository` when `--script` compiled `test_runner.gd` | Resolve autoloads by node path at runtime instead of by global identifier |
| `Invalid operands 'Vector2' and 'Vector2i'` in atlas size assertion | Compare `Texture2D.get_size()` with `Vector2(128, 128)` |
| `Cannot find member "strip_suffix" in base "String"` in the viewer at runtime | Replaced with `substr(0, maxi(length - 1, 0))` |
| Validator rejected repeated frame IDs although hold/oscillation is documented as valid | Removed the repeated-ID diagnostic and added a `hold_oscillation` fixture plus acceptance test |
| Viewer `@onready` fields were null when instantiated from a `SceneTree` script | Invoke `_ready()` explicitly before assertions; free the node before the next frame |

After each fix the project was re-imported and both suites rerun. The final import and test logs contain no unexpected `SCRIPT ERROR` or `ERROR:` entries.

## 4. Python coverage

The 10 original Phase 0 audit tests still pass unchanged. Ten new engine-independent tests check project settings, synthetic fixtures, composite IDs, animation metadata, atlas determinism and RGBA format, scene/script/node-path consistency, export presets, absence of restricted archive formats, unresolved-reference classification totals, supplemental-source manifest fields, and required documentation.

## 5. Limitations

- No battle, damage, chaining, LB, AI, or progression logic is tested because none is implemented.
- No protected FFBE data or asset was used in any test.
- Windows and Linux executable exports were attempted and failed because export templates are absent; see `export-report.md`.
- A local save write/read round-trip was tested in-process. Quit-and-relaunch persistence is not claimed.
