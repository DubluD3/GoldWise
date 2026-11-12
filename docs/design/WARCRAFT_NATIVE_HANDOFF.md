# Warcraft-native implementation handoff

Status: design handoff / 2026-11-12; NOT a live WoW UI validation.

## Direction
Prioritize **70% modern WoW utility / 30% classic fantasy identity**: bronze-trimmed game frame, dark stone/leather, parchment inset content, game-style tabs and beveled controls, consistent item rarity colors, a readable profession journal and an item-analysis dialog.

## Screens in the browser prototype
1. Overview — purse, observed bag asking value, profession skill, goal progress, three advisory next actions.
2. Inventory — list, text filtering, item advisor.
3. Professions — skill bar, trainer/recipe guidance, reagent summary.
4. Auction House — example observed-ask chart, explicit data freshness/uncertainty and manual scan explanation.
5. My Plan — quest-like steps, progress and priority selection.

## Interaction contract
- Buttons change screens, open explanations, filter items or adjust **only local prototype state**.
- No automated WoW gameplay, remote commands, network calls, AH queries, credentials or real market data.
- All prices, names, skill progress and recipes in preview are fictional fixtures; production must never use fake values.
- 'Close' in the browser prototype displays a prototype info message rather than exiting WoW; implement genuine Blizzard-compliant window behavior separately.

## Implementation guidance for Codex
- Do **not** embed the browser prototype inside the addon. Implement equivalent native frame interactions only after verifying Forever API/template support in `docs/research/API_EVIDENCE.md`.
- Retain no more than five first-level tabs; first render should emphasize next actions over dense numerical tables.
- Build compact tab navigation, metric rows, recommendation cards, explanation panel, profession steps, manual market status.
- Use consistent quality colors and gold/copper notation; expose uncertainty and source freshness.
- Verify screen layout at multiple resolutions and UI scales, focus, taint/combat effects, localization, accessibility, frame budget and keyboard/gamepad behavior where supported.
- No unlicensed Blizzard art or competitor assets. Game assets used only through allowed, verified game UI mechanisms.
- Compare screenshots of implementation to approved design; do not claim equivalence from mock tests.

## Acceptance checklist
- [ ] Main panel looks like an extension of WoW, not a web SaaS dashboard.
- [ ] Five tabs and back-navigation are clear.
- [ ] Every recommendation leads to a readable Why breakdown and shows provenance.
- [ ] No listing price is represented as realized revenue.
- [ ] Missing/stale data is visible and does not trigger automatic AH polling.
- [ ] Real client, build, screenshots and QA recorded before merge.
