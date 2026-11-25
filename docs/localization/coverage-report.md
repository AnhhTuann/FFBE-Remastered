# Localization coverage report

**Evidence file:** `data/validation/localization-coverage.json`
**Generator:** `tools/localization/coverage_report.py` (`tool_version` 1.1.0, `schema_version` 2)
**Default locale:** `vi` · **Fallback:** `en` · **Locales:** `en`, `ja`, `vi`

This is a generated snapshot of static dictionary and dynamic-token checks. It measures key
parity, placeholder parity, dynamic manifest integrity, Vietnamese diacritic presence,
Japanese glyph coverage, and long-label risk. It is **not** a claim that translation is
complete, that every UI label uses the locale service, or that recovered source text exists
for these strings. All values are project-authored synthetic fixture copy.

## 1. Blocking results

| Check | Result |
|---|---|
| `status` | `pass` |
| Missing keys (all locales) | 0 |
| Placeholder mismatches | 0 |
| Dynamic manifest errors | 0 |
| Dynamic keys missing from dictionaries | 0 |
| Invalid dictionaries | 0 |
| Exit status of the generator | 0 |

All three dictionaries contain the same **495 keys**. The union of dictionary keys, literal
GDScript translation keys, and dynamic manifest references is also **495**, so no source
key is missing and no locale is short of a key. `LocaleManager` resolves static copy with
`t(...)`, data-driven names with `label_for(...)`, and stable identifiers through the
dynamic token manifest described in [translation-guide.md](translation-guide.md).

## 2. Per-locale results

| Locale | Keys | Missing | Unused (diagnostic) | Empty values |
|---|---:|---:|---:|---:|
| `en` | 495 | 0 | 230 | 0 |
| `ja` | 495 | 0 | 230 | 0 |
| `vi` | 495 | 0 | 230 | 0 |

`unused_keys` are dictionary keys referenced neither by a literal `L.t(...)` /
`LocaleManager.t(...)` call nor by the dynamic manifest. The source scan found 106
translation call sites (93 with a literal key) across 50 scanned GDScript files. Keys
consumed through local `t(...)` wrappers, `name_key` fields, or other dynamic data paths
remain diagnostic-only "unused"; they are deliberately not deleted because the static scan
cannot resolve them.

## 3. Dynamic reference evidence

| Check | Result |
|---|---|
| Manifest | `game/data/phase3/localization_tokens.json` |
| Categories | 22 |
| Mappings (identifier -> key) | 223 |
| Distinct dictionary keys referenced | 211 |
| Malformed manifest entries | 0 |
| Referenced keys absent from dictionaries | 0 |

The largest categories are `reason` (42), `mechanic_key` (26), `ability` (25), `resource`
(22), `mechanic_note` (16), `field` (12), `category` (10), and `slot` (9). Repeated keys
across categories explain why 223 mappings resolve to 211 distinct keys. The manifest lets
the coverage tool distinguish genuine dynamic references from keys that are unused by every
known consumer.

## 4. Script and placeholder checks

| Check | Result |
|---|---|
| Vietnamese strings with diacritics | 471 / 495 (`0.9515`) |
| Japanese strings with kana or kanji | 495 / 495 (`1.0`) |
| Values longer than 40 characters | 66 (`en` 25, `ja` 16, `vi` 25) |
| Placeholder mismatches | 0 |

The 24 Vietnamese strings without diacritics are intentional token-only values:
`awakening.ex`, `awakening.nv`, `awakening.nv_plus`, `awakening.star`, `battle.hp`,
`battle.limit`, `battle.overdrive`, `battle.super_limit`, `code.form.nv`,
`code.rarity.3`, `code.rarity.5`, `code.rarity.6`, `code.rarity.7`, `code.rarity.nv`,
`common.uid`, `details.overdrive`, `details.stmr`, `details.super_lb`, `details.tmr`,
`field.star`, `field.uid`, `mechanic.name.nv_plus`, `mechanic.name.overdrive`, and
`mechanic.name.super_limit_burst`. They preserve `NV`, `EX`, `LB`, `SLB`, `STMR`, `TMR`,
`UID`, `Overdrive`, `HP`, and numeric tokens as required by the glossary.

Placeholder-bearing keys include `settings.path`, `settings.locale_changed`,
`collection.copy_count`, `upgrade.gain_exp`, `upgrade.level_cap`, `awakening.star`,
`party.slot`, `party.build_summary`, `party.error.empty_slot`, `party.error.duplicate`,
`battle.turn`, `battle.chain_status`, `battle.character_card`, `battle.result_detail`, and
`battle.reward_status`. Every locale keeps the same named placeholder token in the same
order.

Long labels are flagged for layout review, not treated as translation errors. The new
longest values are localized evidence notes such as `evidence.note.brave_shift` and
`evidence.note.dual_wield`; labels use smart word wrap in the owned Phase 3 screens.

## 5. Reproduction

```sh
python3 tools/localization/coverage_report.py --root .
python3 -m unittest tests.test_phase3_localization -v
```

The generator writes deterministic, sorted JSON with UTF-8 text preserved. Re-running it
against unchanged dictionaries, GDScript files, and manifest data produces byte-identical
output. If any of those inputs change, regenerate the JSON and update this summary from the
new report.
