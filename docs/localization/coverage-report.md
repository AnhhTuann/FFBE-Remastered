# Localization coverage report

**Evidence file:** `data/validation/localization-coverage.json`
**Generator:** `tools/localization/coverage_report.py` (`tool_version` 1.0.0, `schema_version` 1)
**Default locale:** `vi` · **Fallback:** `en` · **Locales:** `en`, `ja`, `vi`

This is a generated snapshot of static dictionary checks. It measures key parity,
placeholder parity, Vietnamese diacritic presence, Japanese glyph coverage, and
long-label risk. It is **not** a claim that translation is complete, that every UI label
uses the locale service, or that recovered source text exists for these strings.

## 1. Blocking results

| Check | Result |
|---|---|
| `status` | `pass` |
| Missing keys (all locales) | 0 |
| Placeholder mismatches | 0 |
| Invalid dictionaries | 0 |
| Exit status of the generator | 0 |

All three dictionaries contain the same **294 keys**. The union of dictionary keys and
literal GDScript translation keys is also **294**, so no source key is missing and no
locale is short of a key. The battle screen resolves its UI copy through
`LocaleManager.t(...)` directly, including active-party combatant, advanced-ability
status labels, and `name_key`-driven synthetic ability names.

## 2. Per-locale results

| Locale | Keys | Missing | Unused (diagnostic) | Empty values |
|---|---:|---:|---:|---:|
| `en` | 294 | 0 | 237 | 0 |
| `ja` | 294 | 0 | 237 | 0 |
| `vi` | 294 | 0 | 237 | 0 |

`unused_keys` are dictionary keys not referenced by a literal `L.t(...)` or
`LocaleManager.t(...)` call. The source scan found 101 translation call sites (84 with a
literal key) across 49 scanned GDScript files. Screens that build labels through a local
`t(...)` helper, data-driven `name_key` fields, or dynamic keys are not resolved by the
static scanner, so 237 keys remain diagnostic-only "unused". This is not a failure
condition.

## 3. Script and placeholder checks

| Check | Result |
|---|---|
| Vietnamese strings with diacritics | 281 / 294 (`0.9558`) |
| Japanese strings with kana or kanji | 294 / 294 (`1.0`) |
| Values longer than 40 characters | 31 |
| Placeholder mismatches | 0 |

The 13 Vietnamese strings without diacritics are intentional, token-only values:
`awakening.ex`, `awakening.nv`, `awakening.nv_plus`, `awakening.star`, `battle.hp`,
`battle.limit`, `battle.overdrive`, `battle.super_limit`, `common.uid`, `details.overdrive`,
`details.stmr`, `details.super_lb`, and `details.tmr`. They preserve `NV`, `EX`, `LB`,
`SLB`, `STMR`, `TMR`, `UID`, `Overdrive`, `HP`, and numeric placeholders as required by
the glossary.

Placeholder-bearing keys include `settings.path`, `settings.locale_changed`,
`collection.copy_count`, `upgrade.gain_exp`, `upgrade.level_cap`, `awakening.star`,
`party.slot`, `party.build_summary`, `battle.turn`, `battle.chain_status`,
`battle.character_card`, `battle.result_detail`, and `battle.reward_status`. Every locale
keeps the same named placeholder token in the same order. Long labels are flagged for
layout review; they are not treated as a translation error.

## 4. Reproduction

```sh
python3 tools/localization/coverage_report.py --root .
python3 -m unittest tests.test_phase3_localization -v
```

The generator writes deterministic, sorted JSON with UTF-8 text preserved. Re-running it
against unchanged dictionaries and GDScript files produces byte-identical output. If
GDScript call sites or dictionary files change, regenerate the JSON and update this
summary from the new report.
