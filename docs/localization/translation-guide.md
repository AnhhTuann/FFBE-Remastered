# Localization translation guide

This guide covers the static UI dictionaries under `game/data/localization/`. It does not
claim that every in-game string is translated or that Godot scenes already consume every
key. Use the generated evidence in [coverage-report.md](coverage-report.md) for measured
counts.

## 1. Dictionary contract

- `en.json`, `vi.json`, and `ja.json` are **flat JSON objects**: `string key -> string value`.
- All three files must contain **exactly the same key set**. Adding a key means adding it
  to all three dictionaries in the same change.
- Keys are stable identifiers (`battle.chain`, `details.tmr`, `unit.arcanist.nv.name`).
  Never rename a key without auditing every locale and every generator that emits it.
- Values must be non-empty strings. Nested objects, arrays, numbers, and `null` are invalid.
- `vi` is the default locale; `en` is the fallback. Missing keys fall back to `en` and then
  to the raw key, which is visible to players and must be avoided.
- Keys are sorted alphabetically in the repository files to keep diffs reviewable.

## 2. Placeholders

Preserve placeholders **byte for byte**, including spelling and order. Do not translate,
remove, rename, or reorder them.

| Pattern | Example key | Meaning |
|---|---|---|
| `{name}` | `settings.path` (`{path}`), `settings.locale_changed` (`{locale}`) | Godot `String.format()` named argument |
| `%s`, `%d` | `collection.copy_count`, `battle.turn`, `upgrade.gain_exp` | printf-style substitution |

If a source value is `"Slot %d"`, a valid Vietnamese value is `"Vị trí %d"` and a valid
Japanese value is `"スロット %d"`. `"Vị trí"` or `"Slot %s"` is a defect. The coverage tool
compares placeholders in source order and treats any difference as blocking.

## 3. Terminology and tokens

Use the canonical vocabulary in [glossary.md](glossary.md). The preferred Vietnamese
fantasy-JRPG register includes **Nhân vật**, **Đội hình**, **Trang bị**, **Kho đồ**,
**Thức tỉnh**, **Cường hóa**, **Triệu hồi**, **Kỹ năng**, **Kỹ năng bị động**,
**Chuỗi liên kích**, **Kháng nguyên tố**, **Mảnh nhân vật**, **Chiến thắng**, and
**Thất bại**.

Keep these recognizable in every locale and do not invent expansions:

- Progression/system tokens: `NV`, `EX`, `TMR`, `STMR`, `LB`, `SLB`.
- Currency: `gil` (Japanese uses `ギル（gil）`).
- Digits and numeric placeholders stay ASCII (`%d`, `NV+`, level and slot numbers).

Japanese values must use Japanese glyphs (kanji/kana), not romaji placeholders. A bare
`TMR` in `ja.json` is not acceptable; use a form such as `TMR（信頼報酬）`.

All names in this dictionary are **newly authored synthetic fixture labels**, not recovered
original game text. Do not add protected source strings without a rights review.

## 4. Workflow

1. Edit the three dictionaries together, keeping keys alphabetically sorted.
2. Add a key only when a UI consumer needs it or when a listed document requires it; record
   the consumer or reason in the change description.
3. Run the coverage CLI from the repository root:

   ```sh
   python3 tools/localization/coverage_report.py --root .
   ```

   To write somewhere else:

   ```sh
   python3 tools/localization/coverage_report.py --root . --output /tmp/opencode/localization-coverage.json
   ```

4. Run the localization tests:

   ```sh
   python3 -m unittest tests.test_phase3_localization -v
   ```

5. Commit the dictionaries and the regenerated
   `data/validation/localization-coverage.json` together. If the report changes, update
   [coverage-report.md](coverage-report.md) from that report, not by hand-written guesses.

## 5. Reading the report

`data/validation/localization-coverage.json` contains:

- `status`: `pass` only when there are no missing keys and no placeholder mismatches.
- `blocking.missing_key_count` and `blocking.placeholder_mismatch_count`: exit-code inputs.
- `per_locale.<locale>.missing_keys`: keys in the union of dictionary keys and scanned
  source literals that the locale lacks.
- `per_locale.<locale>.unused_keys`: dictionary keys not yet referenced by a literal
  `L.t(...)` or `LocaleManager.t(...)` call. Currently these are expected: the Godot scenes
  have not adopted the locale service for all labels. Unused keys are **diagnostic**, not
  a failure.
- `placeholder_mismatches`: per-key placeholder lists by locale.
- `vietnamese_diacritics`: number and share of `vi` strings containing diacritics, plus
  the intentional token-only exceptions.
- `japanese_glyphs`: number and share of `ja` strings containing kana or kanji.
- `long_label_risk`: values longer than 40 characters for UI review (diagnostic only).
- `source_scan`: GDScript files scanned, call-site counts, and literal keys found.

Exit codes: `0` when `status` is `pass`, `1` otherwise. Dynamic key expressions such as
`L.t(key_variable)` are counted as call sites but cannot be resolved statically; use a
literal key or add an explicit test when a dynamic key must be validated.
