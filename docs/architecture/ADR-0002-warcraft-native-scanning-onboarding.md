# ADR-0002: Warcraft-native UI, tiered data capture and on-demand scan onboarding

Status: **ACCEPTED PRODUCT DIRECTION** (2026-11-12); individual API behaviors remain evidence-gated.

## Context
GoldWise is a free, local-first economic/profession advisor for WoW Forever. The owner wants the addon to feel native to WoW, maximize supported observation automation, and guide players through every manual setup/scan step. The project already has verified client observations on Forever 1.60.1 build 70862 (see API_EVIDENCE.md), but not every scanner or active market identity is verified.

## Decisions
1. **Visuals:** use Blizzard-compatible, native Lua/XML FrameXML widgets; game-native window, tabs, buttons, item quality colors and tooltips where supported. Design target 70% modern WoW usability / 30% restrained classic fantasy; never embed an HTML webview or ship unlicensed art. Preserve Blizzard conventions without implying official endorsement.
2. **Capture tiers:** classify every data source as automatic/passive, player-assisted/contextual, explicit user-initiated, or unsupported. Status must reflect actual on-client evidence, capability and freshness.
3. **Automatic local observations:** when verified, observe current character/gold, carried bags, equipment, and data already supplied by open in-game panels; debounce events, bound reads and never invoke gameplay actions. An event-driven observation is allowed only when its API is verified and works on target build.
4. **AH capture:** prefer passive observation of already loaded native search results; support explicit manual user-requested query/full replication only after verifying restrictions and throttles. Do NOT infer general approval for background periodic AH queries from the existence of query APIs. Such queries remain **off/blocked pending separate evidence and human policy review**. A community wiki reports that C_AuctionHouse.ReplicateItems has a 15-minute account-wide throttle; this is not an installed-client test.
5. **First-run & on-demand guide:** a persistent wizard can be launched after first install and via Help > Scan & Setup Guide on demand. Each step provides: reason for scan, what gets collected locally, supported automatic/manual method, step-by-step WoW instructions, actual last-observed timestamp, completion state, unsupported reason, skip/retry and no-data fallback.
6. **Multi-character:** local cached, timestamped snapshots per character; never assume other characters can be queried without logging into them. Item and equipment recommendations respect realm/faction, binding, proficiency and trade eligibility.
7. **Trust:** all recommendations have provenance, freshness, confidence and assumptions; market asks are not confirmed sales; seller proceeds are not guaranteed. No transactions, movements, mail, crafts or equipment changes performed by addon.
8. **Owner gates:** Codex can write code/tests/docs autonomously but must not self-certify real Forever client E2E tests, policy approval, licensed assets, security/privacy approval or production readiness.

## Evidence
- OFFICIAL: Blizzard policy https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642 (free/source/performance/ads restrictions).
- OFFICIAL: Blizzard Midnight addon disarmament https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight (combat secret values; UI customizability).
- COMMUNITY: https://warcraft.wiki.gg/wiki/API:C_AuctionHouse.ReplicateItems (Forever candidate, 15-minute account-wide throttle); https://warcraft.wiki.gg/wiki/API:C_AuctionHouse.SendSearchQuery (query restrictions); https://warcraft.wiki.gg/wiki/FrameXML (native UI).
- OBSERVED-IN-GAME: GoldWise API_EVIDENCE.md on Forever 1.60.1 build 70862: startup, character, bags (manual), open professions (manual), read-only AH browse cache (manual). NOT proof of auto AH querying.

## Consequences and implementation acceptance
- Add a central capability/scanner-state model and first-run/on-demand wizard before claiming an automatic scan.
- Expose disabled/unsupported scanner states instead of silently failing.
- Full manual test matrix at multiple UI scales, AH states, multiple characters and persistence.
- No release from agent-only tests. Owner signs off client behavior and policy-risk decisions.
