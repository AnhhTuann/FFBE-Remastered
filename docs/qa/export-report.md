# Export report — Phase 1

**Date:** 2026-11-25
**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`
**Presets:** `game/export_presets.cfg`

## 1. Configured presets

| Preset | Platform | Export path | Architecture |
|---|---|---|---|
| `Windows Desktop` | `Windows Desktop` | `game/build/windows/FFBE-Remastered.exe` | x86_64 |
| `Linux` | `Linux` | `game/build/linux/FFBE-Remastered.x86_64` | x86_64 |

Both presets use `export_filter="all_resources"` and `include_filter="*.json, *.png, *.svg, *.import"` so the synthetic JSON content and atlas are packed. Configuration is **not** proof that an executable was produced.

## 2. Commands attempted

```bash
godot --headless --path game --export-pack Linux \
  /home/tuan/Documents/FFBE-Remastered/game/build/pack/foundation.pck

godot --headless --path game --export-release "Windows Desktop" \
  game/build/windows/FFBE-Remastered.exe

godot --headless --path game --export-release Linux \
  game/build/linux/FFBE-Remastered.x86_64
```

## 3. Results

| Artifact | Status | Evidence |
|---|---|---|
| Linux PCK | **Generated** | Exit 0; `game/build/pack/foundation.pck`, 67,764 bytes |
| Windows Desktop executable | **Configured only — BLOCKED** | Exit 1: no `windows_debug_x86_64.exe` / `windows_release_x86_64.exe` template |
| Linux x86_64 executable | **Configured only — BLOCKED** | Exit 1: no `linux_debug.x86_64` / `linux_release.x86_64` template |
| Windows runtime launch | **NOT RUN** | No Windows executable was generated |

`strings` on the generated PCK confirms it contains `data/units.json`, `data/animations.json`, the synthetic atlas and its `.import` file, and the viewer scene remap. Build outputs are ignored by Git via `game/build/`.

## 4. Blocker and resolution path

The required templates were not found at:

```text
/home/tuan/.local/share/godot/export_templates/4.7.2.stable/
```

The directory exists but is empty; `/usr/share/godot/export_templates` is absent. The exact errors were:

```text
No export template found at the expected path:
.../4.7.2.stable/windows_debug_x86_64.exe
.../4.7.2.stable/windows_release_x86_64.exe

No export template found at the expected path:
.../4.7.2.stable/linux_debug.x86_64
.../4.7.2.stable/linux_release.x86_64
```

Install the official `4.7.2.stable` template archive through *Editor → Manage Export Templates*, or place it at the path above, then rerun the three commands. Do not install archives as root unless explicitly authorized. After a successful export, record the executable checksums and actually launch each binary before claiming runtime verification.

## 5. Distinction requested by the milestone

- **Configured:** both presets exist in `game/export_presets.cfg`.
- **Generated:** one Linux PCK exists locally.
- **Launched:** only the Godot editor binary running the project from source on Arch Linux.
- **Runtime-tested:** only that Arch Linux source run; neither exported executable qualifies.
