# Phase 3 export and runtime evidence

**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`, pinned by `game/project.godot`.
No engine version change was made.

## Presets

`game/export_presets.cfg` contains the two Phase 1/2 desktop presets, unchanged in shape:

| Preset | Platform | Export path | Non-resource filter |
|---|---|---|---|
| `Windows Desktop` | Windows Desktop | `build/windows/FFBE-Remastered.exe` | `*.json, *.png, *.svg, *.import` |
| `Linux` | Linux | `build/linux/FFBE-Remastered.x86_64` | `*.json, *.png, *.svg, *.import` |

## Template check

`~/.local/share/godot/export_templates/4.7.2.stable/` exists but contains no
matching template files. The exact missing files reported by Godot are:

- `linux_debug.x86_64`
- `linux_release.x86_64`
- `windows_debug_x86_64.exe`
- `windows_release_x86_64.exe`

No templates were downloaded, substituted, or silently upgraded.

## Commands and results

| Check | Command | Exit | Result |
|---|---|---:|---|
| Linux release export | `godot --headless --path game --export-release "Linux" build/linux/FFBE-Remastered.x86_64` | 1 | `No export template found` for both Linux templates |
| Windows release export | `godot --headless --path game --export-release "Windows Desktop" build/windows/FFBE-Remastered.exe` | 1 | `No export template found` for both Windows templates |
| Linux PCK data pack | `godot --headless --path game --export-pack "Linux" build/pack/phase3-linux.pck` | 0 | Pack written under `game/build/pack/` |

The release-export logs contain three non-fatal `Unicode parsing error ... Invalid unicode
codepoint` lines emitted while Godot scans existing binary files (the synthetic PNG atlas and
older PCKs). They do not affect the template-missing failure and are recorded rather than
suppressed.

Logs are stored outside the repository under `/tmp/opencode/ffbe-logs/phase3/`:
`export-linux.log`, `export-windows.log`, and the final `export-pack.log`.

## Honest status distinction

| Item | Status |
|---|---|
| Export presets configured | PASS |
| Matching 4.7.2.stable templates present | BLOCKED |
| Linux PCK generated | PASS |
| PCK loaded and smoke-run | PASS (`godot --headless --main-pack game/build/pack/phase3-linux.pck --quit-after 300`, exit 0, no error lines) |
| Linux executable generated | BLOCKED |
| Windows executable generated | BLOCKED |
| Executable launched | NOT RUN |
| Windows runtime tested | NOT RUN |

A Linux build cannot be claimed as a Windows runtime test. No executable exists to launch on
this host, so executable launch and Windows runtime checks remain `NOT RUN`.
