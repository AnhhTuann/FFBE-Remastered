# Prompt 04.6 localization hardening notes

**Scope:** Phase 3 UI and tooling hardening only. Prompt 05 is **not** started, no gameplay
features are added, and no original FFBE story or skill translations are fabricated. All
copy referenced here is project-authored `SYNTHETIC_FIXTURE` content.

## 1. What changed

- `game/data/localization/{en,vi,ja}.json`: 201 new keys in each locale (495 total per
  locale), covering evidence notes, verification and mechanic labels, stat/slot/region/role/
  element/category/rarity codes, synthetic resources, viewer clip and unit names, synthetic
  ability names, reason codes, and localized party validation messages.
- `game/data/phase3/localization_tokens.json`: new dynamic-reference manifest. Stable
  identifiers remain byte-for-byte unchanged in data and OptionButton metadata; each maps to
  a locale key. 22 categories, 223 mappings, 211 distinct keys.
- `game/core/locale_manager.gd`: manifest loading plus `token`, `has_token`, `identified`,
  `diagnostic_text`, and typed helper wrappers. `label_for` now resolves known resource,
  unit, and ability identifiers before falling back to raw data.
- `game/scenes/phase3/*.gd` and `game/scenes/viewer/character_viewer.gd`: raw evidence prose,
  status codes, mechanic labels/notes, stat and resource IDs, equipment slots, filters,
  regions, clips, unit names, ability names, and validation reasons now resolve through
  `LocaleManager`. Unknown raw messages are marked explicitly as developer diagnostics
  (`common.diagnostic`) rather than presented as UI copy.
- `game/scenes/phase3/collection.gd`: filter labels and search haystack use localized labels
  as well as stable IDs, so translated Vietnamese and Japanese searches work without
  changing stored identifiers.
- `tools/localization/coverage_report.py`: tool version 1.1.0, schema version 2. Adds
  dynamic manifest validation, counts manifest-backed keys as referenced, and blocks on
  malformed or missing dynamic references.
- `tests/test_phase3_localization.py`: updated counts and new tests for the manifest,
  hardening keys, dynamic CLI evidence, placeholders, accents, glyphs, and translated
  search wiring.
- `docs/localization/coverage-report.md`, `docs/localization/translation-guide.md`,
  `docs/localization/glossary.md`: refreshed from generated evidence and the new contract.

All seven entries in `game/data/phase3/advanced_abilities.json` already had `name_key`; no
original ability text was invented. No new `name_key` fields were required in owned Phase 3
fixtures; the remaining unkeyed display names live in unowned files and are handled through
the dynamic manifest instead.

## 2. Measured results

| Check | Result |
|---|---|
| Keys per locale | 495 (`en`, `ja`, `vi`) |
| Union keys | 495 |
| Missing keys | 0 |
| Placeholder mismatches | 0 |
| Empty values / invalid dictionaries | 0 |
| Dynamic mappings / distinct keys | 223 / 211 |
| Dynamic manifest errors | 0 |
| Static scan | 50 files, 106 calls, 93 literal calls, 59 literal keys |
| Unused keys (diagnostic, after dynamic evidence) | 230 per locale |
| Vietnamese diacritics | 471 / 495 (`0.9515`) |
| Japanese glyphs | 495 / 495 (`1.0`) |
| Long labels over 40 characters | 66 (`en` 25, `ja` 16, `vi` 25) |

The 24 Vietnamese strings without diacritics are intentional brand/token-only values (`NV`,
`EX`, `LB`, `SLB`, `TMR`, `STMR`, `UID`, `Overdrive`, `HP`, digits, and rarity markers). The
long-label increase is driven by localized evidence notes (for example
`evidence.note.brave_shift` and `evidence.note.dual_wield`); owned screens use smart word
wrap, and the report treats long labels as a layout diagnostic rather than a failure.

The drop from the previously reported 237 diagnostic-only unused keys to 230 is expected:
manifest-backed keys are now counted as referenced. The remaining 230 are keys used through
local `t(...)` wrappers, data-driven fields, or other consumers the literal scanner cannot
resolve. They were not deleted.

## 3. Verification commands

Run from the repository root. Logs were written only to the approved temporary log
directory for this prompt.

| Command | Exit code | Result |
|---|---:|---|
| `python3 -m unittest discover -s tests -v` | 0 | 61 tests passed |
| `python3 tools/localization/coverage_report.py` | 0 | `status: pass`; evidence JSON regenerated |
| `godot --headless --path game --import` | 0 | project import completed |

## 4. Caveats and owner decisions

- Godot prints three `Unicode parsing error ... Invalid unicode codepoint (400000)` warnings
  during import. The same warnings appear in earlier baseline import logs, so they are
  pre-existing and unrelated to these localization edits. Import still exits 0.
- Hardcoded strings in unowned files (`game/scenes/menu/`, `game/scenes/battle/`,
  `game/core/player_state.gd`, `tools/importer/`, and `game/tests/`) were not touched.
- Other pre-existing working-tree changes outside the ownership list were preserved as-is:
  `game/scenes/battle/battle_scene.gd`, `tests/test_phase3_importer.py`,
  `tests/test_phase3_qa_tools.py`, `tools/importer/import_content.py`,
  `tools/importer/approval_registry.py`, `data/import-approvals/`,
  `tools/qa/capture_phase3.sh`, and `tools/qa/phase3_visual_report.py`.
- `FFBE_QA_LOCALE` remains a capture-only override and does not persist settings. `vi` stays
  the default, `en` the fallback, and `ja` selectable through the existing settings path.
- No commit, push, merge, reset, clean, or branch change was performed. Owner approval is
  required before the next milestone.
