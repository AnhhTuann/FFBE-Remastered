---
name: ffbe-battle-engine
description: Design and test data-driven FFBE turn-based combat, effects, chaining, Limit Burst, AI and regional mechanics after milestone approval.
---
# FFBE battle engine

Use only when the roadmap authorizes gameplay. Read the project plan, audited data and RPG skills.

- Separate battle state and rules from animation, UI and persistence. Presentation consumes events. Preserve region-aware content keys.
- Model actions, targeting, costs, ordered effects, status durations, hit events and rewards explicitly. Use seeded RNG and a controllable battle clock for chain timing.
- Keep formulas, resistance, modifiers, rounding and effect order traceable to evidence. Generic RPG examples are design references, not FFBE mechanics.
- Unknown effects must yield explicit unsupported results or be excluded from faithful play. Remastered approximations require an explicit design decision and tests.
- Build the approved vertical slice before bulk content. Verify wins, losses, targeting, damage, status interactions, chain boundaries, deterministic replay and reward persistence with synthetic fixtures and permitted verified samples.
- Report unsupported mechanics and failures; never label a generic prototype faithful or complete.
