# GoldWise UI/UX design system (proposed)

Status: DESIGN GUIDANCE — not a claim that screens or APIs are implemented. Updated 2026-11-09.
Companion rules in the repository root [AGENTS.md](../../AGENTS.md) are mandatory for Codex.

## Product feel
A **clear, restrained economy dashboard native to World of Warcraft**, not a website recreated inside the game. Fantasy identity comes from sparing gold accents, familiar item icons/rarity cues, and subtle frame details. Optimize for fast decisions and long sessions; avoid over-decorated parchment, excessively bright gold, dense tables as the first view, flashy animations and false financial certainty.

Hierarchy: **What should I consider doing? → Why? → Evidence / uncertainty → More detail**.
The addon offers information and never performs trades or crafting.

## Visual tokens (design targets; do not assume every WoW font/UI API supports these values)
| Role | Hex | Usage |
|---|---|---|
| Main background | `#151A22` | main window |
| Elevated surface | `#252C38` | cards, panels |
| Subtle border | `#394351` | separation |
| Primary text | `#F3F1EB` | headings and important data |
| Secondary text | `#A8B5C5` | descriptive labels |
| Gold accent | `#E9B956` | brand, selected nav, key highlights |
| Positive | `#54C79A` | confirmed positive outcomes |
| Caution | `#E6B85C` | uncertainty, outdated observations |
| Negative | `#F17678` | costs, loss, critical warnings |
| Focus | `#91B7F0` | keyboard focus and visible affordances |

### Color usage
- Colors are suggestions to be evaluated in the real client for contrast, accessibility, compatibility and legibility; use validated rendering mechanisms.
- Never use color alone to communicate Sell/Keep/Craft, item quality, freshness or confidence: add text/icons.
- Preserve player familiarity with WoW item-quality colors, and do not redefine rarity meanings.
- Positive/negative are for factual net values; a possible margin with uncertain sales is not "confirmed profit".
- Aim for >=4.5:1 text contrast for normal text and >=3:1 for major graphical controls where feasible; verify, don't assume.

## Layout / spacing / typography
- 8px spacing rhythm with 4px fine adjustments; stable padding: 12–16px per section, 8–12px between related controls. These are target sizes, not engine promises.
- 3 levels of hierarchy: page title, section heading, small metadata; no giant heading that hides actual content.
- Right-align copper/gold and quantities in lists; use consistent digit grouping and explicit units. Never display fictional prices as live.
- Default resizable and movable main window **only if supported by verified UI APIs**; remember size/position when safe; provide Reset Position and a recoverable on-screen default.
- Test typical laptop/desktop resolutions and UI scaling; do not hard-code entire UI to a single screen size.
- Avoid clipped tooltips, horizontally overflowing tables or controls placed off screen; support scrolling and ellipsis with accessible full text.
- Build with actual supported WoW Frame/XML/Lua UI primitives. Do **not** introduce HTML/CSS, React, external webviews, undocumented frame templates or external assets by assumption.

## Navigation and interaction
- Proposed top-level tabs: Overview, Inventory, Professions, Market, My Plan. Ledger/Insights may be a subview. Keep navigation <=5 primary areas until user testing.
- Overview prioritizes: key numbers with timestamps/labels, up to three relevant actions, and goal progress; avoid fake charts when data absent.
- Show a compact item advisory summary from bags/tooltips where verified, with a distinct "Why?" explanation path; never auto-open UI on every loot event.
- Recommendation details: proposed action, alternatives (sell raw/craft/keep/vendor), source + last scan, material reservations, cost assumptions, and a confidence/unknown state.
- Data freshness must be visible ("Last scan", "No recent AH data", "Unverified recipe") rather than implying real-time market awareness.
- Never make recommendations look like automatic trading buttons. Label actions "View reasoning", "Add to plan", "Mark reserved", "Open guide", not "Instant sell" or "Auto buy".
- Profession progression screens: current skill / cap, target, gating, next **verified** recipe step, required/owned/reserved/missing reagents; show unknown steps rather than inventing trainer/recipe guidance.
- Prefer progressive disclosure; initial dashboard should not be a spreadsheet.
- Explicit empty/loading/error/stale/unsupported states and helpful non-destructive manual next steps.
- Use nonblocking user-triggered updates and appropriate throttling; never query AH automatically just to paint a dashboard.

## Components
1. **MetricCard:** concise label, value, qualifier/time; no ambiguous "profit" if valuation is only an ask price.
2. **RecommendationCard:** item icon/name/quantity, proposed action, brief reason, confidence, optional estimated amount; drill into breakdown.
3. **ItemAnalysisPanel:** compare alternatives with assumptions, uncertainty and source; respects ownership and reservations.
4. **ProfessionProgress:** skill + cap + target, verified gate and missing reagent breakdown, reachable step only.
5. **MarketFreshness:** timestamp + source + status; stale threshold is a policy/configuration decision, never a made-up global constant.
6. **Confirm/Reset dialog:** only for local data resets or destructive preference changes, not automated game actions.
7. **PlanStep:** action user can perform manually, required materials, target, costs, evidence and completion state.
Build reusable UI helpers once they are justified by at least two screens, not a speculative component factory.

## Accessibility and performance
- Readable font sizes at supported UI scales; avoid tiny metadata as only indicator of a warning.
- Support tooltip text without reliance on hover where practical; focus/keyboard navigation if verified APIs allow it.
- Motion should be subtle; no continuously animated gradient, distracting bounce or rapid flashing.
- Frame creation and scan data processing must be bounded; defer heavy calculations and avoid unnecessary OnUpdate loops.
- No custom fonts/art/sounds without provenance and redistribution rights.
- Ensure error and partial-data states remain usable even when market or profession APIs are unavailable.

## Mockups and reference images
- Design mockups may use clearly labeled **fictional data**, but production surfaces must not show fake market/skill numbers to fill gaps.
- Any external screenshot/mockup or palette reference is inspiration only. Do not copy protected competitor assets or ship third-party icons without license.
- Screenshots for review should contain no real character names, account info or potentially sensitive saved data unless explicitly approved.

## UI acceptance criteria for each GW story touching UI
- [ ] Matches the navigation/hierarchy and uses consistent tokens or documents a justified exception.
- [ ] Real item prices, source, time and confidence are not misrepresented; explicit missing-data path.
- [ ] No automated game actions; labels never imply automation.
- [ ] Keyboard/UI scale/contrast and clipping checked manually on the supported client where feasible.
- [ ] Loading, empty, stale, error and unsupported states included as relevant.
- [ ] Manual QA notes include client build, resolution/UI scale, screenshots where safe, and actual results (NOT RUN unless executed).
- [ ] Reusable components and data flows documented; no unauthorized asset dependencies.
- [ ] Feature does not hijack Blizzard frames, taint protected interactions or trigger forbidden AH API calls.

## Proposed screens and development order
1. **Shell**: accessible window, title, tabs, configuration, safe empty state.
2. **Overview**: gold/observed inventory value, 3 evidence-based recommendations, active goal.
3. **Inventory + Item Advisor**: filters, reserve and explain.
4. **Professions**: skills, verified recipes and requirements, progression route.
5. **Market**: observed asking prices, timestamp, manual scan status, history when available.
6. **My Plan**: target and manual next actions; optimize constrained allocations.
7. **Ledger/Insights**: reconcilable transaction observations and trends.

## Review rule
When a proposed design requires an unverified game UI API, document it in API_EVIDENCE.md and implement a mockable interface, **not** a guessed call. All layout decisions are subject to actual WoW client constraints and player testing.
