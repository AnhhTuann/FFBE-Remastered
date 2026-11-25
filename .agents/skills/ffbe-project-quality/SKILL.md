---
name: ffbe-project-quality
description: Enforce FFBE milestone gates, Git safety, reproducible Python and Godot testing, offline save integrity and Windows/Linux release checks.
---
# FFBE project quality

- Confirm repo, branch, clean status and user scope. Read project documents. Preserve user changes. No force push, hard reset, clean, unrequested merge or branch change.
- Match the pinned engine version; upstream examples are not permission to upgrade.
- Keep original data, audit outputs, normalized content and runtime saves separate. Do not commit protected game assets, credentials, caches or large raw archives.
- Use small synthetic fixtures and reproducible Python tests for audit tools. For Godot prove parse/import and headless tests with nonzero failure exit codes; inspect logs for script errors.
- Test Linux case-sensitive paths and Windows paths. Verify offline startup, atomic saves, migration and backup recovery before release.
- Inspect third-party instructions and scripts before use; never execute them automatically or elevate privileges. No unrequested dependency installs, network transfers or deployment.
- Report actual commands, exit codes, evidence, limitations and blockers. Do not mark a milestone complete unless its exit criteria are met.
