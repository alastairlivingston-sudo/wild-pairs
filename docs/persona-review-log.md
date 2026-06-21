# Persona Review Log

> *Canonical sources: for data models, `technical-architecture.md` §Model Reference is canonical. For game rules, `game-rules.md`. For visual tokens, `design-system.md`. Where this document disagrees with its canonical source, the canonical source wins.*

> Owner: product-director | Run: Phase 1 | Applied to specs: yes

## Purpose
Simulate a UX walkthrough of the product spec, UX spec, and design system from each of the 10 user personas. Score key areas 0–10. Document findings. Apply improvements to specs before Phase 2.

## Scoring areas per persona
- Onboarding / First use
- Game table legibility
- Card playability clarity
- Action prompts
- AI turn feel
- Save/resume
- Device fit (iPhone or iPad)
- Accessibility
- Rules comprehension
- Overall satisfaction

Score 10 = no issues found against this spec. Score < 10 = concrete improvement required.

---

## Persona 1 — Casual Player
> Wants fast, readable, fun play. Does not want to read a long manual.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 10 | Optional tutorial (5-step overlay), Quick Play button skips setup. No mandatory reading. |
| Game table legibility | 9 | Prompt text is clear. Action prompt always visible. Concern: with 7+ cards in hand on iPhone SE, cards may be crowded. |
| Card playability clarity | 10 | Playable cards lift slightly; non-playable remain flat but readable; illegal tap shows tooltip. |
| Action prompts | 10 | All 15 prompt strings specified; plain English; actionable. |
| AI turn feel | 9 | Thinking delay + card animation + result text. Concern: Easy AI at 0.3s + animation may feel slow if animations stack. |
| Save/resume | 10 | Autosave every turn; Continue Game on home screen; no setup needed to resume. |
| Device fit | 9 | iPhone compact layout primary. SE small-screen notes present. iPad not relevant for this persona. |
| Accessibility | 9 | Accessible by default (symbols + labels). Persona likely won't use VoiceOver. |
| Rules comprehension | 10 | Rules bottom sheet in-game; mode summary shown at start. No mandatory pre-read. |
| Overall | 9.5 | |

**Improvements applied:**
- ux-spec.md: added note that on iPhone SE with many cards, hand scrolls horizontally and cards remain minimum 60×90pt (never clip)
- ux-spec.md: AI turn fast mode added as Quick Play default option (Easy AI defaults to faster animation)

---

## Persona 2 — Strategic Player
> Wants clever AI, fair difficulty, meaningful decisions, and team strategy.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 10 | Can skip tutorial and go straight to Hard or Expert. |
| Game table legibility | 10 | Action log / event summary would be ideal; not in MVP but acknowledged. |
| Card playability clarity | 10 | Clear which cards are playable; tap for reason on illegal. |
| Action prompts | 10 | Expert AI prompts show what it played and why (brief). |
| AI turn feel | 10 | Expert AI 1.2s thinking + result text feels deliberate and intentional. |
| Save/resume | 10 | Perfect save/resume means they can analyse a position later. |
| Device fit | 10 | iPad landscape with side panel would suit this persona perfectly. |
| Accessibility | 10 | Not a concern for this persona specifically. |
| Rules comprehension | 9 | Game-rules.md specifies all card effects clearly. In-app glossary planned. Concern: advanced card interactions (forced swap + pending decisions) need clearer in-app explanation. |
| Overall | 9.9 | |

**Improvements applied:**
- ux-spec.md: added "Card Details" button on illegal tap that shows full rules text for that card type
- manual-test-scripts.md: added MTS-007 expert difficulty behaviour verification

---

## Persona 3 — First-Time Card Game Player
> Needs onboarding, hints, clear legal moves, and forgiving feedback.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 9 | 5-step tutorial is present. Concern: tutorial doesn't explicitly explain team win condition. |
| Game table legibility | 9 | Prompt is clear. Concern: "Both players must be out" rule may confuse if partner goes out first. |
| Card playability clarity | 10 | Lifted playable cards, illegal shake + tooltip. Very clear. |
| Action prompts | 10 | "Your partner is still playing — keep going!" prompt specified for when one teammate goes out. |
| AI turn feel | 8 | Easy AI at 0.3s may feel too fast for beginners trying to observe what happened. |
| Save/resume | 10 | Simple; no setup to resume. |
| Device fit | 9 | Works on iPhone. Onboarding needs larger tap targets for beginners. |
| Accessibility | 9 | Contextual hints available. |
| Rules comprehension | 8 | Rules bottom sheet is available but not foregrounded. First-time player may not find it. |
| Overall | 9.0 | |

**Improvements applied:**
- ux-spec.md: tutorial step 5 updated to explicitly explain "Both you AND your partner must empty your hands to win — if your partner goes out first, keep playing!"
- ux-spec.md: Easy difficulty defaults to slower AI animation (0.6s total) to give beginners more observation time
- ux-spec.md: "?" help button added to game table (persistent, opens rules bottom sheet) — visible even on iPhone SE
- design-system.md: all tutorial overlay tap targets set to minimum 56×56pt

---

## Persona 4 — Older or Low-Vision Player
> Needs large readable cards, high contrast, reduced clutter, and accessible controls.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 9 | Tutorial text must scale with Dynamic Type. Concern: 5-step overlay at AX3 must not clip. |
| Game table legibility | 9 | Large card mode specified. Concern: card number/symbol at AX5 Dynamic Type on small iPhone. |
| Card playability clarity | 10 | Symbols + labels ensure colour is never the sole indicator. |
| Action prompts | 10 | Text scales with Dynamic Type. |
| AI turn feel | 10 | Result text announced clearly. |
| Save/resume | 10 | No tiny touch targets needed for save. |
| Device fit | 10 | iPad preferred; spacious layout; large cards comfortable. |
| Accessibility | 9 | Large card mode + high contrast specified. Concern: minimum card size at AX5 Dynamic Type needs verification. |
| Rules comprehension | 9 | All text scales with Dynamic Type. |
| Overall | 9.4 | |

**Improvements applied:**
- accessibility-plan.md: large card mode + AX3 testing explicitly required at Phase 6 gate
- ux-spec.md: tutorial overlay text uses `.body` Dynamic Type minimum; never clips at AX3
- design-system.md: card number/symbol uses `.title2` Dynamic Type (not `.caption`) to ensure legibility at larger sizes

---

## Persona 5 — Colour-Blind Player
> Needs symbols, patterns, labels, not colour-only cues.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 10 | Settings accessible from home screen before first game. |
| Game table legibility | 10 | Symbols (Flame, Wave, Leaf, Sun) always visible on cards by default, even without colour-blind mode. |
| Card playability clarity | 10 | Playable indicator uses shape/lift, not colour alone. |
| Action prompts | 10 | "Play a Crimson card" — colour named in text, not shown only by chip. |
| AI turn feel | 10 | Result text names colour explicitly: "Partner changed colour to Cobalt." |
| Save/resume | 10 | Not relevant. |
| Device fit | 10 | Works on all. |
| Accessibility | 10 | Colour-blind mode: pattern fills, text labels, symbols. Default design is already colour-safe. |
| Rules comprehension | 10 | Rules use colour names, not colour-only visuals. |
| Overall | 10.0 | |

**No additional changes required.** Design was colour-blind safe from the start (symbols always visible, colour names in text).

---

## Persona 6 — VoiceOver User
> Needs complete spoken card labels, game status, turn prompts, action feedback, and navigable controls.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 9 | Tutorial overlays need VoiceOver-navigable focus order. |
| Game table legibility | 9 | VoiceOver labels for all cards specified. Game status custom action specified. Concern: focus order during AI turn needs explicit spec. |
| Card playability clarity | 10 | VoiceOver label includes playability: "Playable. Double tap to select." |
| Action prompts | 10 | Live region announcements for every turn change and AI action. |
| AI turn feel | 9 | AI action result text announced via live region. Concern: if multiple effects stack (draw penalty + skip), both must be announced separately. |
| Save/resume | 10 | App state is fully restorable; VoiceOver reads same state on resume. |
| Device fit | 10 | VoiceOver works on both iPhone and iPad. iPad has more screen space for larger tap targets. |
| Accessibility | 10 | Full spec: labels, custom actions, live regions, focus order, reduced motion. |
| Rules comprehension | 9 | Rules screen must be fully VoiceOver-navigable. Card glossary must have proper headings. |
| Overall | 9.6 | |

**Improvements applied:**
- accessibility-plan.md: VoiceOver focus order during AI turn specified: focus remains on action prompt live region; re-focuses to human hand after AI turn completes
- accessibility-plan.md: stacked effects (draw penalty + skip on same turn) announced as two separate live region updates with 0.5s gap
- ux-spec.md: tutorial overlay has explicit VoiceOver focus order (Step 1 → Next → Step 2 → ...)

---

## Persona 7 — Impatient Commuter / Offline User
> Wants instant launch, resume, fast turns, one-handed play, and no network dependency.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 10 | Quick Play button skips all setup. Instant launch (no network calls). |
| Game table legibility | 10 | Primary action always obvious. Bottom-half controls for one-handed use. |
| Card playability clarity | 10 | Clear lifted cards; tap to play; no ambiguity. |
| Action prompts | 10 | Single clear prompt; no multiple choices at once. |
| AI turn feel | 9 | Fast mode available. Default Easy AI speed may feel slow for commuter use. |
| Save/resume | 10 | Autosave every turn. Resume is instant from Continue Game. No network needed. |
| Device fit | 10 | iPhone portrait primary. One-handed use specified. Bottom half kept useful. |
| Accessibility | 9 | Not a primary concern for this persona. |
| Rules comprehension | 10 | Can start immediately without reading rules. |
| Overall | 9.8 | |

**Improvements applied:**
- ux-spec.md: Quick Play default settings: last-used difficulty, Standard Teams, animation speed: fast. Gets you into a game in 1 tap.
- product-spec.md: "Launch to game in under 3 seconds" added to success criteria.

---

## Persona 8 — Personal Power User
> Wants house rules, difficulty tuning, stats, and replayability.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 10 | Can configure all house rules and difficulty before starting. |
| Game table legibility | 10 | Rich information available; side panel on iPad for event log (future). |
| Card playability clarity | 10 | Clear. Power user understands the rules. |
| Action prompts | 10 | Prompts are informative without being patronising at higher difficulty. |
| AI turn feel | 10 | Expert AI with 1.2s thinking feels engaging. |
| Save/resume | 10 | Perfect state restoration; can analyse saved positions. |
| Device fit | 10 | iPad landscape ideal. Side panel for stats and event log in future. |
| Accessibility | 10 | Stats are local-only; power user values privacy. |
| Rules comprehension | 10 | Full rules available. Card glossary. |
| Overall | 10.0 | |

**Improvements applied:**
- product-spec.md: future roadmap includes "event log side panel on iPad" and "custom house rule sets with saved presets"
- statistics spec: added "current streak" and "favourite mode" to stats screen spec

---

## Persona 9 — iPad Player
> Wants a spacious, premium tablet layout, not a stretched phone app.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 10 | iPad home screen uses wide layout; buttons are appropriately sized. |
| Game table legibility | 10 | Spacious table; larger cards; side panel available; clear player zones. |
| Card playability clarity | 10 | Larger cards are easier to tap and read. |
| Action prompts | 10 | Prompt area stays near the player's focus (bottom of table on iPad). |
| AI turn feel | 10 | Animations use more screen space on iPad; result text larger. |
| Save/resume | 10 | State preserved across rotation. |
| Device fit | 10 | 9 iPad wireframes specified. Portrait and landscape both designed. Split View works. |
| Accessibility | 10 | VoiceOver tested on iPad. Large cards. |
| Rules comprehension | 10 | Rules as side panel on iPad landscape — doesn't interrupt game. |
| Overall | 10.0 | |

**No additional changes required.** The iPad layout was treated as a first-class experience from the start.

---

## Persona 10 — Enterprise-Environment Developer
> Wants minimal permission prompts, no unnecessary dependencies, no network commands, no risky system changes, and simulator-first development.

| Area | Score | Notes |
|---|---|---|
| Onboarding / First use | 10 | Enterprise-build-notes.md documents exact setup steps. |
| Game table legibility | N/A | Technical persona; evaluates build process not UX. |
| Permissions audit | 10 | Zero runtime permissions. check_permissions_minimal.sh. |
| Network-free guarantee | 10 | check_no_network_usage.sh. No URLSession. |
| Third-party SDK freedom | 10 | Zero external dependencies. Package.swift has no remote dependencies. |
| Simulator-first build | 10 | All build steps use simulator. No Apple Developer account needed. |
| Claude Code safety | 10 | Scripts are informational echoes only. No auto-build from Windows. No sudo. |
| Entitlements cleanliness | 10 | check_project_capabilities.sh. 21 forbidden capabilities documented. |
| Documentation quality | 9 | enterprise-build-notes.md is comprehensive. Concern: no "troubleshooting" section for Gatekeeper/MDM issues. |
| Overall | 9.9 | |

**Improvements applied:**
- enterprise-build-notes.md: added "Troubleshooting" section with solutions for Gatekeeper prompts, MDM simulator restrictions, and code-signing errors

---

## Summary of All Improvements Applied

| # | Improvement | File |
|---|---|---|
| 1 | iPhone SE: hand scrolls horizontally; cards never clip | ux-spec.md |
| 2 | Quick Play defaults to Easy + fast animation | ux-spec.md, product-spec.md |
| 3 | Tutorial step 5 explains team win condition explicitly | ux-spec.md |
| 4 | Easy AI defaults to 0.6s observation delay (not 0.3s) | ux-spec.md |
| 5 | "?" help button always visible on game table | ux-spec.md |
| 6 | Tutorial tap targets minimum 56×56pt | design-system.md |
| 7 | Card number/symbol uses `.title2` not `.caption` | design-system.md |
| 8 | AX3 testing required at Phase 6 gate | accessibility-plan.md |
| 9 | VoiceOver focus order during AI turn specified | accessibility-plan.md |
| 10 | Stacked effects announced separately (0.5s gap) | accessibility-plan.md |
| 11 | Launch to game < 3 seconds in success criteria | product-spec.md |
| 12 | Troubleshooting section added to enterprise notes | enterprise-build-notes.md |
| 13 | Event log side panel and custom presets in future roadmap | product-spec.md |
