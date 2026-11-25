# Animation frame validation note

**Status:** Supplemental source inspection only. No source file was modified and no protected asset was imported.

## 1. Context

A non-monotonic frame sequence was inspected in Phase 0 Source A at `origin/main` (`f82d603c90ec799f539280267d3af7589c79f117`):

`regional_units/gl/401008507/unit_animated_csv/unit_limit_atk_cgs_401008507.csv`

This file is a Limit Burst CGS sequence for a GL unit form. It is **not** used by the Godot foundation. The current viewer uses synthetic frame metadata only.

## 2. Inspection result

The CGS sequence contains 53 frame rows:

| Metric | Value |
|---|---:|
| First frame ID | 30 |
| Last frame ID | 78 |
| Minimum frame ID | 30 |
| Maximum frame ID | 78 |
| Unique frame IDs | 49 |
| Repeated frame IDs | 62 (3 occurrences), 63 (3 occurrences) |
| Backward transitions | 2 (`63 → 62` at rows 34 and 36) |
| IDs within companion CGG table bounds | Yes |

The companion frame-rectangle table `unit_cgg_401008507.csv` has 108 rows, indexed 0–107. Every CGS frame ID is inside that range.

The repeated local pattern is:

`61, 62, 63, 62, 63, 62, 63, 64, 65`

This is consistent with a deliberate short back-and-forth hold or oscillation in the source animation, not with a missing frame or an out-of-bounds reference.

## 3. Validator interpretation

A naive strict rule such as “frame IDs must always increase” would flag this sequence. Phase 0 did **not** produce such a finding from this file: `data/validation/asset-coverage.json` records `animation_csv.checked = 0` and `rows = 0`, because accessible CSV frame data was not bulk-materialized during the audited run.

Therefore:

- This is not a contradiction of the Phase 0 report.
- It is not evidence of corrupt source data.
- It is not a VERIFIED animation reconstruction.
- It remains supplemental evidence pending rights review, frame-rectangle validation, and in-engine playback against the exact source revision.

## 4. Relevance to the current implementation

The Character Viewer's validator accepts repeated frame IDs and non-monotonic frame order when the referenced rectangle, timing, origin, and offset are all valid. It rejects:

- empty clips;
- missing `rect`, `offset`, `origin`, `duration`, or `loop`;
- rectangles outside atlas bounds;
- non-positive dimensions or durations;
- non-finite numeric values.

That design preserves the possibility of hold/oscillation sequences like this one while still failing malformed metadata. No original FFBE CSV is shipped in `game/`.
