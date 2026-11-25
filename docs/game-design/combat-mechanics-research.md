# Combat mechanics research (evidence-led)

**Document status:** Research record for M4/M5 battle design, not a claim of complete FFBE restoration.
**Evidence date:** 2026-11-25 (UTC).
**Scope:** Turn-based damage, mitigation, elements, status effects, chaining, Limit Burst (LB), dual wield, targeting, enemy AI, and party/companion rules for the offline desktop vertical slice.
**Primary evidence:** Cached MediaWiki `action=parse&prop=wikitext` responses from exvius.fandom.com. Direct HTML page fetches returned HTTP 403; the API cache in `/tmp/opencode/ffbe-research/` is the working source.

## 1. Scope, method, and evidence policy

This document records what the cached community wiki text actually says and separates it from what the remaster authors chose to implement. It does **not** import protected FFBE data into the repository. No sprite, texture, animation, ability, unit, enemy, item, reward, or extracted game table from the audited or supplemental sources has been copied into this document's project scope. The implemented vertical slice uses `SYNTHETIC_FIXTURE` data only (`game/data/battles.json`: `"fixture_marker": "SYNTHETIC_FIXTURE"`; `"description": "Project-authored combat vertical-slice fixtures..."`).

The lawful-evidence gate remains unresolved:

- `data/manifests/supplemental-sources.json`: `"status": "supplemental_evidence_only"`.
- `data/manifests/supplemental-sources.json`: `"rights_gate": { "status": "not_passed" }`.
- `docs/audit/supplemental-source-discovery.md` states that no source in that discovery set is imported, altered, downloaded into the repository, or treated as a redistribution licence, and that the Godot foundation uses `SYNTHETIC_FIXTURE` data only.
- Rights to FFBE names, art, text, and extracted game data remain with their holders. **The wiki is a community reference, not a redistribution licence, not official documentation, and not a rights grant.** Cached quotes are evidence of community-described rules only; no revision ID was captured with the cache, so regional/version precision is limited.

### Label definitions

Each row in the rule tables below carries exactly one of these exclusive labels:

| Label | Meaning |
|---|---|
| `VERIFIED_RULE` | The cached wikitext states the rule directly. This means "community wiki states it", not "rights cleared" or "client source verified". |
| `PARTIAL_RULE` | The cached wikitext gives a value or behaviour but adds caveats, exceptions, an explicit evidence warning, or missing page coverage. |
| `UNVERIFIED_RULE` | No usable cached page states the original FFBE rule. It must not be presented as an FFBE mechanic. |
| `REMASTERED_DESIGN` | Project-authored implementation value, formula layer, or simplification. Never presented as an original FFBE rule. |

Citations use wiki section anchors, for example `Mechanics#Damage`, `Mechanics#Elemental_Resistance`, `Chaining#Timing`, `Chaining#Spark_Chain_Order`, `Effect_Stacking#Stack_Caps`, and `Dual_Wield#Notes`. Anchors are taken from the cached wikitext headings; when a section is called "chain timing" in prose, the precise anchor is `Chaining#Timing`.

## 2. Literal wikitext excerpts relied upon

Line numbers below are line numbers in the cached JSON `parse.wikitext` strings, added here for traceability; the quoted text itself is literal.

**Mechanics (damage):**

> L111: `\frac{\text {Unit ATK} ^2}{\text {Enemy DEF}} \times \text {Modifier} \times \text {Level Correction} \times \text {Weapon Variance} \times \text {Final Variance} \times \text {Weapon ATK Correction} \times \text {Multipliers}` — `Mechanics#Physical_Damage`
>
> L121: `1 + \frac{\text {Unit Level}}{100}` — `Mechanics#Physical_Damage`
>
> L123: `Final Variance - Randomly chosen between '''0.85''' to '''1''', with 0.01 steps and averages to 0.925` — `Mechanics#Physical_Damage`
>
> L164: `\frac{\text{Unit MAG}^2}{\text{Enemy SPR}} \times \text{Modifier} \times \text{Level Correction} \times \text {Weapon Variance} \times \text {Final Variance} \times \text{Multipliers}` — `Mechanics#Magic_Damage`
>
> L174: `Final Variance - Randomly chosen between '''0.85''' to '''1''', with 0.01 steps and averages to 0.925` — `Mechanics#Magic_Damage`

**Mechanics (mitigation, healing, elements):**

> L353: `* Decrease all damage taken by 50%` — `Mechanics#Guard`
>
> L380: `\text{Damage} = \text{Initial Damage} \times (1 - \text{Elemental Resistance}) | \text{Min}: 0` — `Mechanics#Elemental_Resistance`
>
> L376: `* Effective resistance for that attack would be <math> \frac{50% + 50% + 100%}{3} = 66.66% </math>` — `Mechanics#Elemental_Resistance`
>
> L386: `* Imperil debuffs do not stack. If there were multiple imperil debuffs, only the strongest imperil takes effect regardless of the order in which the debuffs were applied.` — `Mechanics#Elemental_Resistance`
>
> L544: `\text{Skill Base Healing} + \left(\left(\frac{\text{Unit SPR}}{2} + \frac{\text{Unit MAG}}{10}\right) \times \text{Modifier}\right)` — `Mechanics#Healing`
>
> L547: `* Healing amount will be randomized in the '''85 - 100%''' range` — `Mechanics#Healing`

**Mechanics (buffs, LB, multi-hit, party):**

> L603: `Active buffs and debuffs of the same type don't stack. They will be overwritten by the stronger one.` — `Mechanics#Boosts`
>
> L604: `Finally, a unit can cumulate a buff and a debuff. A +50% buff and a -30% debuff of the same type can coexist for a total of +20% .` — `Mechanics#Boosts`
>
> L606: `Passive buffs do stack additively. Two of ATK +10% will give you ATK +20%, up to a hard cap of +400%.` — `Mechanics#Boosts`
>
> L584: `Generally, the majority of abilities are single action, but there are several abilities which activate multiple actions` — `Mechanics#Multiple_Hits`
>
> L586: `[[Dual Wield]] doubles the amount of action of any physical ability.` — `Mechanics#Multiple_Hits`
>
> L759: `* The automatic filling of the limit burst gauge is limited to '''12 crysts''' per turn.` — `Mechanics#LB_Gauge`
>
> L760: `* The number of lb crysts that can drop per enemy per turn is 20.` — `Mechanics#LB_Gauge`
>
> L839: `* The unit order for spark chains follows the party order from one to six. Unit placed in the first position will always be ordered first during spark chain, while guest unit will always be last.` — `Mechanics#Party_Order`
>
> L734: `* Evidence is still needed to prove this mechanic's functions as described above.` — `Mechanics#Enemy_targeting`

**Chaining:**

> L7: `'Chaining' is a game mechanic that normally allows up to a 4 times increase in damage ... Some units or items allow for a 6 times increase in damage.` — `Chaining`
>
> L17: `A chain starts with the second successive hit. If the same unit hits twice in a row that chain ends.` — `Chaining#Chaining_Mechanics`
>
> L27: `* Caps at 300%, for a total of 4x chain bonus damage. This cap can be increased further using '''chain modifier cap''' passives up to 200% higher, capping at 500%, for a total of 6x chain bonus damage.` — `Chaining#Modifier`
>
> L34: `* '''Normal chain''' is registered if the delay from previous chain is between 0 to 20 frames. If the frame gap from the previous chain is larger than 20 frames, the chain will break.` — `Chaining#Modifier`
>
> L36: `* '''Spark chain''' is registered if there is no delay from previous hit (0 frame). ... The first in the order will '''not''' gain a spark chain modifier, while the rest does.` — `Chaining#Modifier`
>
> L41: `** Chain modifier: 20% for each element` — `Chaining#Modifier`
>
> L81: `The game logic is tied to the frame rate and runs at 60 frames per second.` — `Chaining#Timing`
>
> L94–95: `* First cast offset: 13` / `* Subsequent casts offset: 14` — `Chaining#Offset`
>
> L106: `Cast delay is a delay that happens before a unit can cast subsequent skill on a multicast. The delay is 39 frames, but under certain circumstances, can change:` — `Chaining#Cast_Delay`
>
> L140: `The unit order for spark chains follows the party order from one to six. Unit placed in the first position will always be ordered first during spark chain, while guest unit will always be last.` — `Chaining#Spark_Chain_Order`
>
> L144: `When units cast their skills with gaps between them, their spark chain will be ordered according to cast time.` — `Chaining#Spark_Chain_Order`

**Effect stacking and dual wield:**

> L6–8: `Same active effects don't stack, with some exceptions.` / `Same passive effects stack, with some exceptions.` / `Active effects stack with passive effects and go beyond passive effects caps.` — `Effect_Stacking`
>
> L92: `If a unit has more than one identical effects of different potency, only the strongest one will be active. However, the previous effect is not removed, it stays dormant on that unit until the duration runs out.` — `Effect_Stacking#Layered_Effects`
>
> L107: `| '''Stats''' || 400% / stats || [[HP +10%]], [[ATK +10%]]` — `Effect_Stacking#Stack_Caps`
>
> L27: `* Attack twice when you use any ability which deals physical or hybrid damage.` — `Dual_Wield#Notes`
>
> L30: `* Does not work on limit bursts.` — `Dual_Wield#Notes`
>
> L34: `:: Any physical skill (except limit bursts) will attack first with right hand (300 ATK) and then with the left hand (250 ATK).` — `Dual_Wield#Notes`
>
> L37: `:: Limit bursts, however, will attack using the highest ATK weapon regardless of the hand it is equipped in (300 ATK).` — `Dual_Wield#Notes`
>
> `Mechanics` L95: `When dual wielding weapons of different variance, only the right hand weapon variance is used for both hits.` — `Mechanics#Weapon_Variance`

**Status effects:**

> `Mechanics` L614–630: `Poison || Deals 10% of the target's Max HP as damage every turn`, `Blind || Reduces the targets physical attack accuracy`, `Sleep || Renders the target incapable of taking any action`, `Silence || Renders the target incapable of using magic or songs`, `Paralyze || Renders the target incapable of taking any action or evading attack`, `Confuse || Randomly auto-attacks foes or allies`, `Disease || Reduces stats by 10%`, `Petrify || Renders the target incapable of taking any action regardless of buffs`, `Zombie || Takes damage when recovering HP` — `Mechanics#Status_Ailments`
>
> `Status_Ailments` L134: `'Effect:''' Renders the target incapable of taking any action. Magic type and fixed type abilities used against a sleeping target will not awaken it, however, basic attacks, as well as physical type and hybrid type abilities will.` — `Status_Ailments#Sleep`
>
> `Status_Ailments` L399: `'Effect:''' Lowers the target's base stats by 10%. Stacks with Break abilities.` — `Status_Ailments#Disease`
>
> `Status_Ailments` L530: `'Effect:''' Takes damage when recovering HP. Using restorative abilities, magic, and items ... will deal damage to the target.` — `Status_Ailments#Zombie`

## 3. Rule table

The `Label` column contains exactly one of the four defined tokens per mechanic. Where a value is project-authored, it is explicitly marked `REMASTERED_DESIGN`; it is never described as an original FFBE rule.

| Mechanic | Label | Evidence / rule | Citation |
|---|---|---|---|
| Physical damage formula | `VERIFIED_RULE` | `ATK² / DEF × Modifier × Level Correction × Weapon Variance × Final Variance × Weapon ATK Correction × Multipliers`; Weapon ATK Correction is documented for older battles only. | `Mechanics#Physical_Damage`, `Mechanics#Weapon_ATK_Correction` |
| Magical damage formula | `VERIFIED_RULE` | `MAG² / SPR × Modifier × Level Correction × Weapon Variance × Final Variance × Multipliers`; no Weapon ATK Correction factor is listed for magic damage. | `Mechanics#Magic_Damage` |
| Hybrid damage formula | `VERIFIED_RULE` | `(Physical component + Magic component) / 2 × Multiplier`; physical component uses ATK/DEF and weapon variance, magic component uses MAG/SPR. | `Mechanics#Hybrid_Damage` |
| Level correction | `VERIFIED_RULE` | `1 + Unit Level / 100`; repeated for physical, magic, hybrid, esper, and evoke damage. | `Mechanics#Physical_Damage`, `Mechanics#Magic_Damage`, `Mechanics#Esper_Damage` |
| Final variance | `VERIFIED_RULE` | Random 0.85–1.00 in 0.01 steps; average 0.925. | `Mechanics#Physical_Damage`, `Mechanics#Magic_Damage` |
| Weapon variance | `VERIFIED_RULE` | Typical 1-handed average 115%; typical 2-handed average 150–155%; atypical weapons have wider ranges. | `Mechanics#Weapon_Variance` |
| DEF/SPR after breaks, buffs, ignore | `VERIFIED_RULE` | `Base DEF × (100 - (DEF Break - Buff)) / 100 × (100 - Ignore DEF) / 100`; analogous SPR formula. | `Mechanics#Physical_Damage`, `Mechanics#Magic_Damage` |
| Guard | `VERIFIED_RULE` | Decreases all damage taken by 50%; the wiki separately notes `Defend` reduces only physical damage by the same amount. | `Mechanics#Guard` |
| Mitigation stacking | `VERIFIED_RULE` | Physical, magic, general, and racial mitigation stack multiplicatively; mitigation also stacks multiplicatively with Cover and Guard. | `Mechanics#Damage_Mitigation` |
| Healing formula | `VERIFIED_RULE` | `Skill Base Healing + ((SPR / 2) + (MAG / 10)) × Modifier`; SPR/MAG are the caster's post-buff stats per the wiki context. | `Mechanics#Healing` |
| Healing randomization | `VERIFIED_RULE` | Healing amount randomized in the 85–100% range. | `Mechanics#Healing` |
| Healing over turns | `VERIFIED_RULE` | Base healing and modifier are divided by the number of turns; procs after the caster's turn ends and before the opponent acts. | `Mechanics#Over_Turns` |
| Elemental resistance | `VERIFIED_RULE` | `Damage = Initial Damage × (1 - Elemental Resistance)`, minimum 0. | `Mechanics#Elemental_Resistance` |
| Multi-element averaging | `VERIFIED_RULE` | Multi-element physical attacks are averaged against the target's respective elemental resistances; example `(50% + 50% + 100%) / 3 = 66.66%`. | `Mechanics#Elemental_Resistance` |
| Imperil stacking | `VERIFIED_RULE` | Imperil debuffs do not stack; only the strongest takes effect regardless of application order. | `Mechanics#Elemental_Resistance` |
| Active buff/break stacking | `VERIFIED_RULE` | Same-type active buffs/debuffs do not stack; stronger overwrites weaker. | `Mechanics#Boosts`, `Effect_Stacking#Active` |
| Buff plus debuff coexistence | `VERIFIED_RULE` | A +50% buff and -30% debuff of the same stat coexist for +20%. | `Mechanics#Boosts` |
| Passive stat cap | `VERIFIED_RULE` | Passive stat bonuses stack additively up to a 400% hard cap; active buffs can raise the total beyond it. | `Mechanics#Boosts`, `Effect_Stacking#Stack_Caps` |
| Active versus passive stacking | `VERIFIED_RULE` | Same active effects generally do not stack; same passive effects generally do; active effects stack with passive effects beyond passive caps. | `Effect_Stacking` |
| Layered effects | `PARTIAL_RULE` | Strongest identical effect is active while weaker copies stay dormant and resume when the strong one expires; no known layer limit, but Reflect and Mirage are explicitly unlayerable. | `Effect_Stacking#Layered_Effects` |
| Poison | `VERIFIED_RULE` | Deals 10% of target Max HP every turn; party duration permanent, enemy duration varied with recovery chance. | `Mechanics#Status_Ailments`, `Status_Ailments#Poison` |
| Blind | `VERIFIED_RULE` | Reduces physical accuracy; physical attacks may miss. | `Mechanics#Status_Ailments`, `Status_Ailments#Blind` |
| Sleep | `VERIFIED_RULE` | Target cannot act; physical and hybrid attacks wake it, magic/fixed do not; 3 turns for party, varied for enemies. | `Mechanics#Status_Ailments`, `Status_Ailments#Sleep` |
| Silence | `VERIFIED_RULE` | Target cannot use magic or songs; abilities remain usable. | `Mechanics#Status_Ailments`, `Status_Ailments#Silence` |
| Paralyze | `VERIFIED_RULE` | Target cannot act or evade. | `Mechanics#Status_Ailments`, `Status_Ailments#Paralyze` |
| Confuse | `VERIFIED_RULE` | Target randomly attacks foes or allies; ends after taking damage. | `Mechanics#Status_Ailments`, `Status_Ailments#Confuse` |
| Disease | `VERIFIED_RULE` | Lowers base stats by 10% and stacks with Break abilities. | `Mechanics#Status_Ailments`, `Status_Ailments#Disease` |
| Petrify | `VERIFIED_RULE` | Target cannot act regardless of buffs; counts as death unless cured; entire petrified party ends the game. | `Mechanics#Status_Ailments`, `Status_Ailments#Petrify` |
| Zombie | `VERIFIED_RULE` | HP recovery damages the target; revive effects instantly KO it. | `Mechanics#Status_Ailments`, `Status_Ailments#Zombie` |
| Enfeeblements | `VERIFIED_RULE` | Charm/Stop prevent action and evasion; Berserk forces normal attacks; Break lowers ATK/DEF/MAG/SPR; DoT deals end-of-turn damage; Death is instant KO; Gravity reduces HP by fixed percentage. | `Mechanics#Enfeeblements` |
| Damage over time | `PARTIAL_RULE` | Does not chain or generate LB crystals, cannot be evaded, snapshots caster stats at cast and target stats at damage, and stacks only when stacking ID differs; exact IDs are not in the cache. | `Mechanics#Damage_Over_Time` |
| Hex | `PARTIAL_RULE` | Fixed damage at start of turn based on count of negative effects; currently limited to two named units in the wiki and overwritten by reapplication. Not implemented in the slice. | `Mechanics#Hex` |
| Multi-hit actions | `VERIFIED_RULE` | Wiki distinguishes number of actions from animation hits; abilities are described by action count and status ailments can proc per action. | `Mechanics#Multiple_Hits` |
| Damage weight | `VERIFIED_RULE` | Each hit has a weight, normally summing to 100%; backloaded weights put larger damage later in the chain. | `Chaining#Damage_Weight` |
| Chain initiation and same-unit repeat | `VERIFIED_RULE` | Chain starts on the second successive hit; the same unit hitting twice in succession ends the chain. | `Chaining#Chaining_Mechanics` |
| Normal chain window and increment | `VERIFIED_RULE` | Delay 0–20 frames registers a normal chain with +10%; gap over 20 frames breaks the chain. | `Chaining#Modifier` |
| Spark chain increment | `VERIFIED_RULE` | 0-frame gap registers spark chain with +40%; first internally ordered hit does not gain the spark modifier. | `Chaining#Modifier` |
| Elemental chain increment | `VERIFIED_RULE` | +20% per shared element after the base chain type is registered. | `Chaining#Modifier` |
| Chain bonus formula | `VERIFIED_RULE` | `Chain Bonus Damage = 1 + Chain Modifier / 100`; increments are cumulative until cap. | `Chaining#Modifier` |
| Chain cap and passive cap raise | `VERIFIED_RULE` | Normal cap 300% = 4× damage; chain modifier cap passives raise it to 500% = 6×, but only for units with the passive. | `Chaining#Modifier` |
| 60 fps battle logic | `VERIFIED_RULE` | Game logic is tied to 60 fps; slowed frame rate slows game logic. Movement delay figures are explicitly measured at 60 fps. | `Chaining#Timing`, `Chaining#Movement` |
| First/subsequent cast offsets | `PARTIAL_RULE` | First cast offset 13, subsequent cast offset 14; wiki adds `Only tested on skills with idle movement.` | `Chaining#Offset` |
| Cast delay | `PARTIAL_RULE` | Default 39 frames; +1 when a CG appears and longer waits for certain motion types whose animation exceeds 39 frames. | `Chaining#Cast_Delay`, `Chaining#Motion` |
| Spark ordering | `PARTIAL_RULE` | At exactly the same cast time, party slots 1–6 order hits and guest is last; with gaps, ordering follows cast time. Caveat: ordering was observed only for simultaneous casts. | `Chaining#Spark_Chain_Order` |
| LB gauge auto-fill caps | `VERIFIED_RULE` | Automatic fill limited to 12 crysts per turn; up to 20 LB crysts can drop per enemy per turn. | `Mechanics#LB_Gauge` |
| LB fill rate cap | `VERIFIED_RULE` | LB fill rate boosts cap at 1000%; automatic filling is not affected by fill rate boosts. | `Mechanics#LB_Gauge`, `Effect_Stacking#Stack_Caps` |
| LB leveling chart | `VERIFIED_RULE` | Per-rarity EXP-to-next-level and cumulative tables are given through level 40 for 5★-NV, with normalization noted after Version 3.0.1. | `Limit_Bursts#Experience_Chart` |
| Player target legality | `REMASTERED_DESIGN` | The slice validates `self`, `ally`, `enemy`, `all_allies`, and `all_enemies` and rejects missing/wrong-side targets; no original FFBE target-selection algorithm is cached. | `game/battle/target_resolver.gd` |
| Enemy targeting chance modifiers | `PARTIAL_RULE` | Targeting chance modifiers stack additively and "increase" overrides passive reduction; reduction "fades" over time, but the page explicitly says evidence is still needed. | `Mechanics#Enemy_targeting` |
| Enemy AI decisions | `UNVERIFIED_RULE` | No cached page supplies original FFBE AI conditions, action weights, cooldowns, or script selection. | No cached page; coverage probe `Battle.json` is `missingtitle` |
| Dual wield action doubling | `VERIFIED_RULE` | Physical and hybrid abilities attack twice; limit bursts are unaffected. | `Dual_Wield#Notes`, `Mechanics#Damage_Types` |
| Dual wield variance | `VERIFIED_RULE` | With different weapon variances, right-hand variance is used for both hits; physical/hybrid ATK is calculated per weapon. | `Mechanics#Weapon_Variance`, `Mechanics#Damage_Types` |
| Dual wield magic and LB stat use | `VERIFIED_RULE` | Magic damage uses total MAG while dual wielding; LB uses the highest-ATK weapon regardless of hand. | `Mechanics#Magic_Damage`, `Dual_Wield#Notes` |
| Party order | `PARTIAL_RULE` | Party order controls spark ordering and ST cover chance (left-most highest); `Mechanics#Party_Order` also contains an unfinished note asking for more information. | `Mechanics#Party_Order`, `Mechanics#Cover` |
| Companion / guest rules | `UNVERIFIED_RULE` | Only "guest unit will always be last" in spark ordering is stated; no cached page defines companion selection, limits, stats, or rewards. | `Chaining#Spark_Chain_Order`; coverage probe `Companion.json` is `missingtitle` |
| Counter and Cover | `PARTIAL_RULE` | Counters trigger at most once per attack; Cover precedence and mitigation rules are detailed, but many exceptions and a visual bug are noted. Not implemented in the slice. | `Mechanics#Counter`, `Mechanics#Cover` |
| Loot drop tables | `PARTIAL_RULE` | Common/Rare/Unique tables with 100% cap per table are described, but actual rates are enemy-specific and not present in the cache. | `Mechanics#Loot_Drop` |

## 4. GL/JP differences

The cached pages do not carry a region label or source revision, so most rules are best classified as **shared/unclear** rather than proven for both GL and JP. This matters because the project keeps composite identities such as `unit:GL:<id>` and `unit:JP:<id>` even though the vertical slice uses one shared rule set.

| Area | Classification | Notes |
|---|---|---|
| Damage, level correction, variance, guard, healing, elements, stacking, chain timing, LB caps, dual wield | Shared/unclear | Presented without GL/JP qualifier in the cached community pages. Treat as community-described common rules, not region-certified numeric truth. |
| Chaining "Global delay" | Shared/unclear / terminology caution | `Chaining#Offset` calls offset a "Global delay" meaning overall/global delay in the action sequence. This is **not** evidence of a GL-region rule. |
| LB leveling after `Version 3.0.1` | GL-leaning but region-unlabelled | `Limit_Bursts#Experience_Chart` cites a numbered update and uses NV rarity columns; the cache does not mark it GL-only. |
| Arena, "crysts", NV rarity, GL event lists in `Dual_Wield#Notes` | GL-flavoured but not a complete rule set | These are Global-oriented wiki artifacts. They do not establish that the underlying dual-wield mechanics differ in JP. |
| Reduced encounter cap | JP-specific marker | `Effect_Stacking#Stack_Caps` contains `100%<!--80% for JP-->` for Reduce encounter. This is outside the slice, but it is the clearest explicit regional difference found. |
| Battle, Party, Companion, Targeting | Unverified coverage | Exact API probes returned `missingtitle`; no GL/JP distinction can be asserted from them. |
| Remaster combat rules | Common offline approximation | One deterministic ruleset is applied to both `unit:GL:*` and `unit:JP:*` synthetic fixtures. Region keys are preserved for identity, not for divergent combat math. |

## 5. Implemented remaster approximations

Everything in this section is project-authored. It is not evidence of an original FFBE formula or value.

- **Desktop chain timing equivalence.** `BattleClock` is a logical 60 Hz clock independent of presentation speed. `ActionQueue` schedules hit frames from fixture data and sorts equal-frame hits by actor order. `ChainManager` uses a 20-frame link window, 0-frame spark, +10/+40/+20 increments, 300% cap, and same-actor/timeout resets. The 13/14 offsets, 39-frame cast delay, CG +1 frame rule, motion-specific delays, true tap timing, and 500%/6× passive cap are not simulated. The equal-frame actor-order tie-break is a deterministic desktop equivalence, not the original client implementation.
- **Synthetic ability modifiers and hit weights.** `game/data/battles.json` authors modifiers such as 1.0/1.1 basic attacks, 2.4 `Meteor Slash` split 0.1/0.2/0.3/0.4, 2.0 `Arcane Cascade` split 0.2/0.3/0.5, and LB modifiers 5.0/4.5/3.5. Hit frames such as 4/9/14/19 and chain family names `synthetic_strike`, `synthetic_divine`, and `synthetic_lb` are invented fixtures.
- **Synthetic stats, resistances, and weapon variance.** Unit stats (for example Vanguard 450 ATK and Mender 480 SPR), enemy stats, `resist` maps, and variance ranges such as `[0.95, 1.05]` are authored. They do not reproduce any equipment or unit data.
- **Synthetic effects and status values.** Sleep chance 0.5 for two turns, 0.25 for enemies, +35% three-turn buffs, +50% DEF LB buff, and 3/4-cryst explicit LB fills are fixture values. `StatusEffectManager` replaces same-kind active effects by potency and has no dormant-layer system; that is an intentional simplified implementation, not the wiki's layered-effect rule.
- **Synthetic enemy AI.** Weights (2–4), cooldowns (0–3), HP gates, `max_actions`, `action_start_frames` such as `[4, 34]`, and target rules `random`, `lowest_hp`, `highest_atk`, and `all_allies` are project-authored. No original AI table is claimed.
- **Synthetic rewards.** Victory rewards of 400/1200 gil and synthetic item IDs are authored deterministic snapshots, not reconstructed loot tables or drop rates.
- **Damage implementation layer.** `DamageCalculator` applies the documented ATK²/DEF or MAG²/SPR structure with authored modifier × hit weight, level correction, fixture weapon variance, final variance `range_int(85, 100) / 100`, chain bonus, resistance, and guard ×0.5. It floors the result and clamps to minimum 1; that rounding/clamp choice is project-authored. It omits Weapon ATK Correction, killers, critical hits, hybrid/fixed damage, mitigation categories, evasion, cover, counters, and arena caps, and must not be labelled a complete FFBE calculator.
- **Healing implementation divergence.** The researched formula uses caster SPR/MAG. The current resolver reads the healed target's SPR/MAG (`game/battle/effect_resolver.gd`), applies variance, floors, and restores HP. This is a project implementation divergence to correct or explicitly accept; it is not an original FFBE rule.
- **Element implementation layer.** `ElementResolver` clamps effective resistance to −1.0…1.0, subtracts imperil potency, skips `non_elemental`, and averages `1 - resistance` across elements. The clamp and sentinel handling are project-authored safeguards; the averaging idea is documented at `Mechanics#Elemental_Resistance`.
- **LB implementation layer.** Auto-fill is capped at 12 per turn, but the project grants 1 cryst on action start and damage taken and tracks resets per turn. The original crystal-drop sources, 20-per-enemy-per-turn cap, transfer-by-percentage rule, and LB leveling are not implemented in the slice.
- **Party scope.** The encounter fixtures use five party members. The wiki references party order 1–6 and guest ordering, but no Party or Companion page was available; the five-member party is an M4 slice decision, not a verified FFBE party rule.

## 6. Source list

All URLs below are the exact MediaWiki parse API form used for the cached evidence. They were fetched through the API because direct Fandom page fetches returned 403. The cached files are in `/tmp/opencode/ffbe-research/`.

| Exact URL | Cached file | What it supports |
|---|---|---|
| `https://exvius.fandom.com/api.php?action=parse&page=Mechanics&prop=wikitext&format=json&formatversion=2` | `Mechanics.json` | Physical/magic/hybrid formulas, level correction, final variance, weapon variance, guard, mitigation, elemental resistance, imperil, healing, buff/break stacking, passive caps, status effects, DoT/Hex, multi-hit, LB gauge, enemy targeting, party order, loot. |
| `https://exvius.fandom.com/api.php?action=parse&page=Chaining&prop=wikitext&format=json&formatversion=2` | `Chaining.json` | Chain modifier formula, normal/spark/elemental increments, caps, chain reset, damage weight, 60 fps logic, offsets 13/14, 39-frame cast delay, spark ordering, movement caveats. |
| `https://exvius.fandom.com/api.php?action=parse&page=Effect_Stacking&prop=wikitext&format=json&formatversion=2` | `Effect_Stacking.json` | Active/passive stacking rules, layered effects, 400% passive stat cap, unstackable materia/effects, JP-only reduce-encounter comment. |
| `https://exvius.fandom.com/api.php?action=parse&page=Dual_Wield&prop=wikitext&format=json&formatversion=2` | `Dual_Wield.json` | Dual wield action doubling, no effect on LBs, per-hand ATK, right-hand-first physical sequence, highest-ATK weapon for LBs, weapon elements/status on both hands. |
| `https://exvius.fandom.com/api.php?action=parse&page=Elements&prop=wikitext&format=json&formatversion=2` | `Elements.json` | Resolved as an item page for a staff named "Elements"; supports **no** elemental combat rule. Elemental mechanics are cited from `Mechanics#Elemental_Resistance` instead. |
| `https://exvius.fandom.com/api.php?action=parse&page=Limit_Bursts&prop=wikitext&format=json&formatversion=2` | `Limit_Bursts.json` | LB experience chart, cumulative EXP, burst pot requirements, Version 3.0.1 normalization note. |
| `https://exvius.fandom.com/api.php?action=parse&page=Status_Ailments&prop=wikitext&format=json&formatversion=2` | `Status_Ailments.json` | Ailment effects, durations, post-battle persistence, removal/infliction/nullification lists, Sleep wake rule, Disease stacking with Break, Petrify and Zombie details. |
| `https://exvius.fandom.com/api.php?action=parse&page=Limit_burst&prop=wikitext&format=json&formatversion=2` | `Limit_burst.json` | Redirect `#REDIRECT [[Limit Bursts]]`; no independent rule evidence. |
| `https://exvius.fandom.com/api.php?action=parse&page=Status_ailments&prop=wikitext&format=json&formatversion=2` | `Status_ailments.json` | Redirect `#REDIRECT [[Status Ailments]]`; no independent rule evidence. |

**Coverage probes that did not resolve:**

| Exact URL pattern | Cached file | Result |
|---|---|---|
| `...action=parse&page=Battle&prop=wikitext&format=json&formatversion=2` | `Battle.json` | `missingtitle`; no battle overview evidence. |
| `...action=parse&page=Party&prop=wikitext&format=json&formatversion=2` | `Party.json` | `missingtitle`; no general party rules evidence. |
| `...action=parse&page=Companion&prop=wikitext&format=json&formatversion=2` | `Companion.json` | `missingtitle`; no companion rules evidence. |
| `...action=parse&page=Targeting&prop=wikitext&format=json&formatversion=2` | `Targeting.json` | `missingtitle`; no targeting overview evidence. |

## 7. Coverage notes and open gaps

1. **Battle, Party, Companion, and Targeting titles are missing.** Their coverage probes returned `missingtitle`; related observations in `Mechanics#Party_Order`, `Mechanics#Enemy_targeting`, `Mechanics#Cover`, and `Chaining#Spark_Chain_Order` are therefore marked `PARTIAL_RULE` where partial, and companion selection is marked `UNVERIFIED_RULE`.
2. **Enemy AI remains `UNVERIFIED_RULE`.** The audited Phase 0 data includes an `enemy_ai` category, but this research document relies only on the cached community pages and must not promote recovered-but-unverified records to verified truth. The slice's weights and cooldowns are `REMASTERED_DESIGN`.
3. **Target selection is only partly evidenced.** Chance modification is described but self-contradictory enough to say "evidence is still needed". Player-side legality in the slice is explicitly project-authored.
4. **Version and region are unpinned.** The cache has no page revision or access timestamp metadata beyond the research batch. Any claim that a number applied to a specific GL or JP build would require a new revisioned evidence pass.
5. **Rights remain unresolved.** `supplemental_evidence_only` and `not_passed` are current gate values. No protected FFBE asset or data is imported, and no public build may include third-party content until the documented lawful-basis, revision, checksum, region, category, import-report, and separation requirements are met.
6. **Implementation completeness is deliberately limited.** Unsupported mechanics must produce explicit unsupported results or remain excluded. A deterministic synthetic vertical slice is evidence of a working remaster system, not proof of faithful or complete FFBE combat.
