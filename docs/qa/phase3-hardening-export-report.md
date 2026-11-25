# Prompt 04.6 export and runtime evidence

**Engine:** Godot `4.7.2.stable.arch_linux.ed1daf0bf`, unchanged from the pinned
version. No engine upgrade or template substitution was used.

## 1. Official template verification

The previous Phase 3 export blocker was the absence of version-matched
`4.7.2.stable` export templates. For Prompt 04.6, the official
`Godot_v4.7.2-stable_export_templates.tpz` was downloaded from the Godot release
and verified before installation:

| Check | Result |
|---|---|
| Release metadata SHA-256 | `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` |
| Local SHA-256 | match |
| Local SHA-512 against `SHA512-SUMS.txt` | match |
| `linux_debug.x86_64` | present, `73,703,800` bytes |
| `linux_release.x86_64` | present, `73,519,416` bytes |
| `windows_debug_x86_64.exe` | present, `103,176,704` bytes |
| `windows_release_x86_64.exe` | present, `109,268,480` bytes |

The templates were installed only in the local Godot template directory; no
template archive or executable was added to Git.

## 2. Release exports

Both desktop presets were exported from the final hardened working tree.

| Check | Command | Exit | Result |
|---|---|---:|---|
| Linux release | `godot --headless --path game --export-release "Linux" <repo>/game/build/linux/FFBE-Remastered.x86_64` | `0` | ELF64 executable written |
| Windows release | `godot --headless --path game --export-release "Windows Desktop" <repo>/game/build/windows/FFBE-Remastered.exe` | `0` | PE32+ executable written |

Artifact verification outside Git:

| Artifact | Size | SHA-256 |
|---|---:|---|
| `game/build/linux/FFBE-Remastered.x86_64` | `73,519,416` | `d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63` |
| `game/build/windows/FFBE-Remastered.exe` | `109,133,824` | `06d6853a83a61a758a1e8d14a31672dd45aaf7a379478223e2c5cae05ed3d704` |
| `game/build/linux/FFBE-Remastered.pck` | `584,616` | `6ca1e09a5f76270e9459dbef08c8f45b75910d32b689d8b06b5e6d545a577a66` |

`file` reports the Linux artifact as an x86-64 ELF executable and the Windows
artifact as a PE32+ GUI executable. Build outputs remain ignored by Git.

## 3. Runtime distinction

| Item | Status |
|---|---|
| Matching 4.7.2.stable templates present | PASS |
| Linux release executable generated | PASS |
| Windows release executable generated | PASS |
| Linux executable headless smoke | PASS |
| Windows executable launch | NOT RUN |
| Windows runtime tested on Windows hardware | NOT RUN |

Linux smoke command:
`cd game/build/linux && ./FFBE-Remastered.x86_64 --headless --quit-after 300`.

Exit code was `0`, with zero `SCRIPT ERROR`, `Parse Error`, or leading `ERROR:`
lines. The log shows the pinned engine, four synthetic unit records,
`SaveManager` format version 2, `LocaleManager` starting in Vietnamese, and
`PlayerState` format version 3 with six owned synthetic units.

A Linux smoke test is not a Windows runtime test. No claim is made that the
Windows build was launched or visually verified.
