---
name: ffbe-asset-restoration
description: Audit and reconstruct lawfully usable FFBE sprites, textures, frame metadata and asset mappings; validate pixel-art imports and animation.
---
# FFBE asset restoration

- Check rights, region, revision, native ID and checksum. Public availability is not permission to redistribute. Preserve immutable source binaries in ignored storage.
- Record dimensions, alpha, format, duplicate hashes and source paths. Resolve assets by region and form; catalog entries are not proof of file availability.
- Parse frame rectangles, origins, offsets, ordering, durations and loop metadata. Validate bounds and references; report missing clips instead of silently substituting frames.
- Preserve source pixels, alpha and alignment. Use nearest-neighbor scaling for pixel art. Do not upscale or use lossy conversion on raw assets by default.
- Generate deterministic Godot SpriteFrames or atlas resources only after import approval. Keep reconstructed and newly authored material distinguishable.
- Validate idle, attack, damage and victory clips where available with frame-by-frame checks and in-engine playback. Record evidence and remaining limitations.
- Never execute extracted code or automatically redistribute restricted archives.
