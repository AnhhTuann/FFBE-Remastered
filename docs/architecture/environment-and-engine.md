# Environment and engine audit

**Evidence captured:** 2026-11-25T13:05:52Z on this development machine.

## 1. Host

| Check | Observed value |
|---|---|
| OS / architecture | Linux x86_64 |
| Kernel | `6.18.64-1-lts` |
| Python | `3.14.10` |
| Git | `2.56.1` |
| Display | `DISPLAY=:0` |
| Wayland display | unset |
| Filesystem free space | 86 G free on `/` (229 G total) |
| Branch | `phase-1-godot-foundation` |
| HEAD before Phase 1 file work | `46b68cf3affc12375fadbfd5b22265ddc7940463` |

## 2. Godot engine

The executable is now available at `/usr/bin/godot`. Earlier in this session it was absent; the engine was supplied outside this work. No package installation or privilege escalation was performed by this project.

```text
$ command -v godot
/usr/bin/godot

$ godot --version
4.7.2.stable.arch_linux.ed1daf0bf
```

The pinned target is **Godot 4.7.2-stable**, published 2026-08-18T16:12:28Z:
<https://github.com/godotengine/godot/releases/tag/4.7.2-stable>.

`game/project.godot` declares `config/features=PackedStringArray("4.7", "GL Compatibility")` and uses the Compatibility renderer (`gl_compatibility`) for predictable 2D behaviour on Windows and Linux.

## 3. Export templates

No export-template directory or `.tpz` archive was found in:

- `/usr/share/godot/export_templates`
- `/home/tuan/.local/share/godot/export_templates`
- `/opt/godot`
- `/home/tuan/Downloads`
- `/home/tuan/.cache`

Status:

| Artifact | Status |
|---|---|
| Godot editor / CLI | Available |
| Headless import | Available |
| Headless GDScript tests | Available |
| `--export-pack` PCK | Available (no templates needed) |
| Windows x86_64 executable export | Configured only; BLOCKED without matching templates |
| Linux x86_64 executable export | Configured only; BLOCKED without matching templates |
| GUI screenshot | To be attempted from the real running project; see QA report |

## 4. Renderer and pixel-art settings

- Renderer: Compatibility (`gl_compatibility`) on desktop and mobile.
- Baseline viewport: 1280×720, resizable.
- QA test viewport: 1920×1080.
- Stretch mode: `canvas_items`, aspect `expand`.
- Default canvas texture filter: `0` = Nearest. Godot 4.7 defines `0` as nearest and `1` as linear; using `1` would have produced blurry pixel art.
- 2D transform and vertex snapping to pixel enabled.

## 5. Arch Linux setup instructions (not executed here)

Verify the installed version first:

```bash
godot --version
# Expected: 4.7.2.stable...
```

If the distribution package does not match the pin, use the official release binary:

```bash
mkdir -p "$HOME/.local/bin"
curl -fL -o /tmp/godot.zip \
  https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip -o /tmp/godot.zip -d "$HOME/.local/bin"
chmod +x "$HOME/.local/bin/Godot_v4.7.2-stable_linux.x86_64"
"$HOME/.local/bin/Godot_v4.7.2-stable_linux.x86_64" --version
```

Install the matching export templates through *Editor → Manage Export Templates*, or place the official template archive at:

```text
~/.local/share/godot/export_templates/4.7.2.stable/
```

The template version must match the editor patch exactly. After installation:

```bash
godot --headless --path game --import
godot --headless --path game --script res://tests/test_runner.gd
```

Do not install templates, packages, or archives as root unless the user explicitly authorizes it.
