# Event Center visual design architecture

**Status:** Prompt 07.2 presentation-only redesign of the synthetic Event Center.
**Rights gate:** `not_passed`. All artwork is original project-authored procedural geometry; no FFBE interface, character art, music, dialogue or banner data was copied or imported.
**Engine:** Godot 4.7.2 stable; project root `game/`.
**Baseline:** `e1da3eccf663a882a09de7a33d5823bf00939ef3` (Prompt 07.1).

## 1. Scope and non-goals

This phase replaces the Event Center presentation layer with a polished fantasy RPG PC interface. It does **not** change gameplay rules, save format, reward identity, mission progression, repeatable cycles, unlock evaluation, battle settlement, `WorldContext`, GL/JP identity, rights gate or event fixtures.

Prompt 07 and Prompt 07.1 reports and screenshots remain intact as historical evidence. New visual evidence uses a separate `prompt07-2` directory and report.

## 2. Visual language

The interface uses a midnight navy foundation, layered deep-blue panels, warm gold borders/highlights and cyan/turquoise active accents. Primary text is warm white and secondary text is muted silver. Depth is created with stacked panels, translucent glows, thin rules and deterministic geometric motifs rather than imported art.

| Token | Colour | Use |
|---|---|---|
| Background | `#081321` | Root backdrop |
| Secondary | `#0D1B2B` | Scroll areas and inset surfaces |
| Panel | `#13263B` | Standard cards and sections |
| Elevated panel | `#1B3048` | Hover/selected surfaces |
| Gold | `#D7B36A` | Borders, titles, reward emphasis |
| Cyan | `#55C7CF` | Active/available/claimable state |
| Primary text | `#F4F0E8` | Titles and primary values |
| Secondary text | `#AAB8C7` | Metadata and helper text |

The palette is implemented in `game/scenes/event/ui/event_theme.gd`, which builds a Godot `Theme` at runtime. No proprietary font or UI atlas is used.

## 3. Component architecture

| Component | File | Responsibility |
|---|---|---|
| Theme tokens and builders | `game/scenes/event/ui/event_theme.gd` | Palette, font sizes, spacing, `Theme` construction, reduced-motion gate, tween helper. |
| Atmospheric backdrop | `game/scenes/event/ui/event_backdrop.gd` | Non-interactive gradient bands, glows, faint geometry and border ornament drawn with `_draw()`. |
| Procedural fixture artwork | `game/scenes/event/ui/event_artwork.gd` | Deterministic per-event vector motifs, category accents and a localized synthetic-fixture caption. |
| Designed card | `game/scenes/event/ui/event_card.gd` | Reusable `Button` with artwork, badge, state, title, metadata, reward preview and optional progress. Emits `activated(payload)` only. |
| Progress display | `game/scenes/event/ui/event_progress.gd` | One progress bar plus one localized value label per card, created idempotently with a restrained animated fill. |

`event_center.gd` remains the sole coordinator. It owns filter/region/selection state, localizes strings, constructs components from repository/service data and connects card signals to the unchanged gameplay services. New UI components never call `PlayerState`, award rewards, mutate event state or decide unlock eligibility.

### Artwork provenance

`EventArtwork` draws from a deterministic `RandomNumberGenerator` seeded by the region-aware event ID. Motifs are original category-specific geometry (radial stars, crescents, pillars, interlocking rings, chevrons). The visible caption uses a localized `SYNTHETIC PLACEHOLDER ART` key, so the distinction from recovered original content stays explicit.

## 4. Screen structure

- **Header:** localized title and subtitle, GL/JP region selector, back navigation and event currency summary where applicable.
- **Filter rail:** status filters (`All`, `Active`, `Upcoming`, `Ended`, `Archive`, `Collaboration`) and category filters (`Story`, `Limited`, `Permanent`, `Collaboration`, `Seasonal`, `Challenge`). Filters are buttons inside scroll containers, with selected styling and explicit focus.
- **Overview:** designed event cards with procedural art, category, availability badge, schedule and selected highlight.
- **Detail hero:** large procedural art panel beside localized title, description, status, region, schedule, currency and main action.
- **Sections:** designed stage, mission, shop and summon cards. Locked/available/completed/repeatable states are visually distinct but determined only by existing services.

No raw technical ID or claim key is rendered in any of these areas.

## 5. Responsive behaviour

The scene keeps a `Control` root with anchors, containers and scroll containers per ADR 0006.

| Profile | Layout |
|---|---|
| 1280×720 baseline | Left event navigation, central hero/detail, lower or right section cards. |
| 1024×640 | Reduced spacing and artwork height; all sections remain scrollable. |
| 1920×1080 | Max-width content columns prevent sparse, stretched layouts. |
| 720×1280 portrait | Stacked header → filters → overview/hero → sections in one vertical scroll flow; no horizontal overflow. |

The existing deterministic portrait QA override is preserved. Layout changes are driven by container size flags and profile-specific minimum sizes, not fixed absolute positions. Artwork minimum sizes are profile-aware so the 1024×640 card column does not force horizontal overflow. QA section focus uses declared control geometry rather than unsettled canvas transforms, so `stages`, `rewards`, `shop` and `summon` produce distinct scroll positions. The summon capture uses the JP banner fixture so it is regionally distinct from the GL shop evidence, and replay uses the ended collaboration fixture so it is visually distinct from the archive capture.

## 6. Animation and interaction

- Card hover and selection use short `modulate`/style transitions via `EventTheme.tween_property()`.
- Progress bars animate their fill; no animation blocks input or delays navigation.
- Focus style is a visible cyan border; keyboard Enter/Space and mouse clicks both activate cards.
- Reduced motion is honoured through `ffbe_remastered/ui/reduced_motion` and the `FFBE_REDUCED_MOTION=1` environment override used by automated checks. When reduced motion is active, properties are set immediately and no tween is created.

## 7. Localization

All visible text is routed through `LocaleManager.t()`, `label_for()` or existing token helpers. Region badges and scene-open failures use localized strings rather than raw region codes or error integers. New keys for redesigned labels are added to `en`, `ja` and `vi` together; no locale falls back to an untranslated English string. The generated coverage artifact is refreshed and must report zero missing keys, placeholder mismatches and dynamic-reference errors.

## 8. Integration boundaries

Preserved without behavioural change:

- `EventRepository`, `EventSchedule`, `EventStateService`, `EventUnlockEvaluator`, `PlayerState`.
- `WorldContext` battle entry and return path.
- `EventStateService.can_launch_stage()` as the only launch gate.
- Canonical `world|event|...` claim keys and transactional rewards.
- Save format v4 and additive `events` section.
- Existing Prompt 07 capture scripts and reports.

## 9. Verification and limitations

Fresh evidence is recorded in `docs/qa/prompt07-2-final-report.md` and `docs/qa/prompt07-2-visual-review.md`. Automated capture verification covers file counts, sidecar validity, runtime error lines, non-blank image heuristics and byte-identical PNG detection. The Event Center emits a QA-only readiness marker after two rendered frames, and the capture wrapper waits for that marker after a 10-second settle so transient pre-layout frames are not retained as evidence. Subjective human visual approval is explicitly **NOT VERIFIED**.

Known limitations:

- Windows runtime execution is not possible from the Linux QA host; only Windows export is verified.
- Corrupted-save and process-termination recovery are outside this presentation-only phase.
- The previously identified stage-region validation concern remains a separate gameplay issue; this redesign does not silently expand scope into it.
