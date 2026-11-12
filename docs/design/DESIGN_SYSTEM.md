# GoldWise UI/UX design system (proposed)

Status: DESIGN GUIDANCE — not a claim that screens or APIs are implemented. Updated 2026-11-12.
Companion rules in the repository root [AGENTS.md](../../AGENTS.md) are mandatory for Codex.

## Product feel
**Warcraft-native GoldWise:** a familiar in-game interface with a framed header, bronze trim, muted stone/leather and parchment-colored inset areas, Blizzard-like tabs and buttons, native-feeling tooltips and item-quality cues. Balance **70% modern Warcraft utility with 30% classic fantasy texture**. This is NOT a banking SaaS dashboard, nor a pixel-for-pixel copy of Blizzard's UI. Prefer supported Blizzard UI assets/templates where explicitly verified; otherwise use original, appropriately licensed artwork. Avoid excessive ornament and dense tables on the first screen.

Hierarchy: **What should I consider doing? → Why? → Evidence / uncertainty → More detail**.
The addon offers information and never performs trades or crafting.

## Visual tokens (design targets; do not assume every WoW font/UI API supports these values)
| Role | Hex | Usage |
|---|---|---|
| Main frame stone | `#171613` | outer window and shadowed game frame |
| Leather surface | `#28251E` | side navigation, inset panels |
| Parchment inset | `#393226` | information and recipe panels |
| Bronze border | `#80653B` | framed edges and selected separators |
| Antique gold | `#D6B46A` | headings, selected tab and emphasis |
| Primary text | `#EFE4C9` | main legible text |
| Muted text | `#B2A78F` | subtitles and metadata |
| Profit | `#83B99A` | verified favorable numbers, also label text |
| Caution | `#D8AB5F` | uncertainty/stale observations |
| Risk | `#D98275` | costs/losses and warning, always labeled |
| Focus | `#A7CCEB` | visible keyboard focus |

### Color usage
- Colors are suggestions to be evaluated in the real client for contrast, accessibility, compatibility and legibility; use validated rendering mechanisms.
- Never use color alone to communicate Sell/Keep/Craft, item quality, freshness or confidence: add text/icons.
- Preserve player familiarity with WoW item-quality colors, and do not redefine rarity meanings.
- Positive/negative are for factual net values; a possible margin with uncertain sales is not "confirmed profit".
- Aim for >=4.5:1 text contrast for normal text and >=3:1 for major graphical controls where feasible; verify, don't assume.

## Warcraft-specific styling rules
- Use a bounded framed game window with a dark carved/bronze edge, title ornament or emblem, header, footer and familiar close control; preserve compact content.
- Tabs should resemble WoW's game UI navigation rather than a sidebar copied from a fintech app. Optional sidebar is acceptable on wide screens if game-native styling is preserved.
- Use fantasy-styled section titles sparingly; main content typography prioritizes legibility and system localization.
- Item icons, quality colors, reagent counts, profession skill bars and tooltips are primary interaction vocabulary.
- Buttons need distinct normal, hovered, active, disabled and focused states; bronze-trimmed bevels may be used. Avoid clickable gold text without a control affordance.
- The data-view may use dark parchment inset backgrounds; do not use textured backgrounds that obscure rows.
- Never use custom sound effects, Blizzard branding, borrowed textures or proprietary game assets unless their use is documented and verified in the supported client.
- Keep any game-client UI implementation free of web/HTML dependencies; the browser mockup is a design-only reference.

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
