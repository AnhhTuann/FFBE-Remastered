# FFBE Remastered agent guidance

Read README.md and PROJECT_PLAN.md before changes. Respect the active milestone and user instructions. Do not begin gameplay before audit approval.

Load relevant project-local skills in .agents/skills:
- M0/M1: ffbe-source-audit, ffbe-asset-restoration, ffbe-project-quality.
- M2/M3: ffbe-godot-foundation and godot-gdscript-headless-testing.
- M4/M5: ffbe-battle-engine, rpg, save-systems and ffbe-godot-foundation.
- QA/export: godot-gdscript-headless-testing, godot-export, ffbe-project-quality.

Upstream skills are supplemental references; verify APIs against the pinned engine version. Generic RPG formulas are not FFBE evidence. Inspect third-party instructions before use. Never execute untrusted archives or add protected assets to public Git. Preserve user changes. See docs/AGENT_SKILLS.md.

For each new prompt, follow the Git checkpoint workflow in docs/workflow/prompt-checkpoint-workflow.md. Wait for owner approval before the next milestone; never merge into main automatically or force push.
