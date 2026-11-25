# Unresolved-reference classification

**Status:** Evidence classification only. No Phase 0 source record or validation output has been changed.

**Input:** [`data/validation/missing-references.json`](../../data/validation/missing-references.json) — 651 records from the Phase 0 validator.

**Machine-readable result:** [`data/validation/unresolved-reference-classification.json`](../../data/validation/unresolved-reference-classification.json).

## 1. Finding

All 651 reported “unresolved record references” are false positives caused by a validator assumption. Each affected recipe field declares a target type of `EQUIP` or `MATERIA`, but the Phase 0 adapter checks recipe references only against `item.json`.

The exact declared-type catalogs were checked at the Phase 0 revision `ce7d98a6499bb8c2f6656f0698f60c30001a05b0`:

| Region | equip.json | materia.json | item.json |
|---|---:|---:|---:|
| GL | 261 | 154 | 247 |
| JP | 934 | 500 | 606 |

Every one of the 651 missing IDs resolves in the catalog declared by its own source record. After checking the declared catalog, the unresolved count is **0**.

## 2. Breakdown

| Field | GL | JP | Total |
|---|---:|---:|---:|
| `crafts.id` | 208 | 409 | 617 |
| `materials[].id` | 5 | 29 | 34 |
| **Total** | **213** | **438** | **651** |

| Field / declared type | Resolved catalog | Count |
|---|---|---:|
| `crafts.id` / `EQUIP` | `equip.json` | 444 |
| `crafts.id` / `MATERIA` | `materia.json` | 173 |
| `materials[].id` / `EQUIP` | `equip.json` | 25 |
| `materials[].id` / `MATERIA` | `materia.json` | 9 |

Examples:

- `recipe:GL:901000180` → `crafts.id=409006800`, declared `EQUIP`, resolves in `gl/equip.json`.
- `recipe:GL:905000150` → `materials[].id=504010070`, declared `MATERIA`, resolves in `gl/materia.json`.

## 3. Why Phase 0 still reports 651

`tools/validate/adapters/ffbe_data.spec.json` models recipe relationship targets as `items`. That is correct for records declaring `ITEM`, but incomplete for records declaring `EQUIP` or `MATERIA`. The validator therefore reports a missing `items` key for references that exist elsewhere.

This is a validator-model limitation, not damaged source data and not evidence that 651 game records are absent.

## 4. Decision

- Keep `data/validation/missing-references.json` unchanged as the exact Phase 0 output.
- Keep the 651 figure in Phase 0 reporting, accompanied by this classification.
- Do not edit source records to satisfy the validator.
- Do not promote these references to `VERIFIED`; resolution in a datamine catalog proves relationship consistency, not rights or historical accuracy.
- A later tooling milestone may introduce typed relationship routing (`ITEM → item.json`, `EQUIP → equip.json`, `MATERIA → materia.json`) and regenerate a new report version.

This classification is supplemental evidence only and does not unblock protected-content import.
