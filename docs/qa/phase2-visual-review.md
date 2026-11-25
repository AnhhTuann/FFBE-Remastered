# Phase 2 visual review

**Date:** 2026-11-25 (UTC)
**Method:** Real Godot windows on `DISPLAY=:0`, captured with ImageMagick `import -window`; geometry read with `xdotool`.
**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`
**Scope:** Battle vertical slice UI at 1280×720, 1920×1080, and one smaller resizable window.

---

## 1. Capture procedure

For each state, Godot was launched with the real project and the battle scene:

```bash
FFBE_QA_SCENARIO=<state> FFBE_QA_FREEZE_FRAME=<frame> \
  FFBE_QA_ENCOUNTER=<optional> \
  godot --path game --windowed --resolution 1280x720 --position 0,0 \
  --scene res://scenes/battle/battle_scene.tscn
```

1920×1080 captures used `--fullscreen --resolution 1920x1080`. The smaller window used `--windowed --resolution 1024x640`. After a five-second settle wait, the visible window belonging to the Godot PID was found with `xdotool search --pid`, its geometry was read with `xdotool getwindowgeometry`, and the exact window pixels were captured with `import -window <id>`.

The capture script and per-capture logs are at `/tmp/opencode/ffbe-logs/capture_phase2.sh` and `/tmp/opencode/ffbe-logs/capture-*.log`; the consolidated result is `/tmp/opencode/ffbe-logs/phase2-capture-summary.log`.

## 2. QA state hooks

| Scenario | Purpose | Freeze frame |
|---|---|---|
| `start` | Initial battle layout and HUD. | 20 |
| `formation` | All five controllable units queued with basic attacks. | 20 |
| `abilities` | Ability panel open for the selected character. | 20 |
| `chain` | Two queued multi-hit abilities with overlapping hit frames; chain and damage labels remain visible. | 20 |
| `limit` | LB gauges filled and two Limit Bursts queued. | 16 |
| `boss` (`start` + boss encounter override) | Boss encounter with three enemies and boss flag. | 20 |
| `victory` | All enemies reduced to 1 HP; two attacks complete the encounter and show the victory overlay. | 20 |
| `defeat` | Party reduced to 1 HP; deterministic enemy area attack produces the defeat overlay. | 20 |

`FFBE_QA_FREEZE_FRAME` stops logical advancement after the chosen frame and keeps floating labels visible for capture. Result handling is checked before the freeze check, so victory/defeat overlays still render. These hooks are capture timing aids only; they do not alter damage or outcome rules.

## 3. Captured files

All screenshots are under `docs/qa/screenshots/`.

| File | State | Geometry | Image mean | Runtime errors |
|---|---|---|---|---|
| `phase2-battle-start-1280x720.png` | Battle start | 1280×720 at (0,70) | 0.184304 | 0 |
| `phase2-battle-party-formation-1280x720.png` | Party formation | 1280×720 at (0,70) | 0.186231 | 0 |
| `phase2-battle-ability-selection-1280x720.png` | Ability selection | 1280×720 at (0,70) | 0.184719 | 0 |
| `phase2-battle-chain-damage-1280x720.png` | Damage/chain display | 1280×720 at (0,70) | 0.181767 | 0 |
| `phase2-battle-limit-burst-1280x720.png` | Limit Burst | 1280×720 at (0,70) | 0.182739 | 0 |
| `phase2-battle-boss-encounter-1280x720.png` | Boss encounter | 1280×720 at (0,70) | 0.181784 | 0 |
| `phase2-battle-victory-1280x720.png` | Victory overlay | 1280×720 at (0,70) | 0.178378 | 0 |
| `phase2-battle-defeat-1280x720.png` | Defeat overlay | 1280×720 at (0,70) | 0.175106 | 0 |
| `phase2-battle-start-1920x1080.png` | Battle start | 1920×1080 at (0,0) | 0.182210 | 0 |
| `phase2-battle-party-formation-1920x1080.png` | Party formation | 1920×1080 at (0,0) | 0.184063 | 0 |
| `phase2-battle-ability-selection-1920x1080.png` | Ability selection | 1920×1080 at (0,0) | 0.183982 | 0 |
| `phase2-battle-chain-damage-1920x1080.png` | Damage/chain display | 1920×1080 at (0,0) | 0.181255 | 0 |
| `phase2-battle-limit-burst-1920x1080.png` | Limit Burst | 1920×1080 at (0,0) | 0.183545 | 0 |
| `phase2-battle-boss-encounter-1920x1080.png` | Boss encounter | 1920×1080 at (0,0) | 0.181170 | 0 |
| `phase2-battle-victory-1920x1080.png` | Victory overlay | 1920×1080 at (0,0) | 0.176698 | 0 |
| `phase2-battle-defeat-1920x1080.png` | Defeat overlay | 1920×1080 at (0,0) | 0.175090 | 0 |
| `phase2-battle-start-1024x640.png` | Smaller resizable window | 1024×640 at (0,70) | 0.182597 | 0 |

`identify` confirms every file is a valid PNG at the requested geometry. Non-zero, non-uniform means indicate real rendered content rather than blank frames.

## 4. State distinctness

ImageMagick absolute-error comparisons against the 1280×720 battle-start capture confirm the states are not duplicated frames:

| Comparison | Differing pixels |
|---|---:|
| start vs. victory | 28,995.9 (3.146%) |
| start vs. defeat | 32,925.6 (3.573%) |
| start vs. chain/damage | 17,586.1 (1.908%) |
| start vs. Limit Burst | 15,483.5 (1.680%) |
| start vs. boss encounter | 31,566.4 (3.425%) |

These are objective pixel differences. They corroborate that the QA scenarios produced different rendered states; they are not a substitute for human visual approval.

## 5. Layout and input observations

- Enemies are arranged on the left and the controllable party on the right, with a central battlefield and character panels along the bottom.
- HP/MP bars and LB gauges are present on party cards; enemy cards omit MP/LB gauges as designed.
- Turn counter, phase/chain labels, speed, pause, attack, abilities, Limit Burst, items and guard controls are built as `Control` nodes with anchors and containers.
- The companion slot is present but reserved and visibly non-interactive; no companion gameplay is claimed.
- Only implemented commands are enabled. Item use is limited to synthetic potion/ether fixtures.
- Mouse and keyboard are supported (`A/S/D/F/G`, `Space`, `Escape`, `Tab`, `Backspace`, digits `1–6`). **Controller support is intentionally absent** and was not tested.
- Pixel art uses the existing synthetic 128×128 atlas, 32×32 frames and nearest-neighbour filtering. Battle code does not rescale or stretch sprites.

## 6. Limitations

The model producing this report cannot visually inspect PNG content, so this document makes **no subjective claim** about colour harmony, readability or animation feel. It records real capture provenance, geometry, clean runtime logs, pixel statistics and state distinctness. Human review remains advisable before public release.

No export executable was available, so these captures are from the Godot editor/project runtime, not from a generated Windows or Linux standalone executable. See [phase2-final-report.md](phase2-final-report.md) for the export blocker.
