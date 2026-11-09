# Blizzard UI, security and privacy design review

Reviewed: 2026-11-09. Scope: WoW Forever addon, observational/read-only MVP.

## Evidence levels and legal boundary
- **Official, binding addon policy**: [Blizzard WoW UI Add-On Development Policy](https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642) (policy post 2018; retrieved 2026-11-09). Requires free addon access, public unobfuscated source, no detrimental performance, no advertisements or in-game donation solicitation, no objectionable content, compliance with Blizzard terms, and allows Blizzard to disable functionality.
- **Client technical security**: [Warcraft Wiki Object security](https://warcraft.wiki.gg/wiki/Object_security) and [Secure Execution and Tainting](https://warcraft.wiki.gg/wiki/Taint) are *community technical documentation*, not a new Blizzard addon policy. Actual restrictions must be verified in Forever.
- **GoldWise standards, not explicitly mandated by that policy**: local-only storage, minimal data capture, no tracking/telemetry, consent for any future data transmission, accessibility contrast and stable navigation.
- **Unknowns:** no Blizzard-approved GoldWise status; no evidence that every Retail frame behavior is identical in the current Forever build. Do not claim an approved or unbannable addon.

## Design / security guardrails
1. No modifying action bars, secure frames, merchant or auction transaction controls, combat-protected regions, or Blizzard global UI objects unless documented and tested; default to standalone, ordinary information frames.
2. Never try to work around `InCombatLockdown`, object protection, secret values or taint errors. If a UI action is restricted, disable it gracefully and show a nonintrusive explanation.
3. UI displays recommendations and explanatory data **only**; avoid commands labeled 'auto buy', 'instant post' or 'one-click trade'.
4. Explicitly player-triggered AH scans, bounded processing and safe cooldown behavior. UI refresh must not become hidden AH polling.
5. No unnecessary `OnUpdate` work, repeated disk-heavy persistence, huge frame trees, continual alerts or disruptive popups. Measure client responsiveness.
6. Do not impersonate official Blizzard UI or imply Blizzard sponsorship. Fantasy-style inspiration is fine; custom art, fonts and music must be independently licensed or game-client assets used only via supported APIs.
7. No advertising, donation banners or links in the game. All addon functionality is free. Public source must not be obfuscated.
8. Never collect Battle.net credentials, authenticator codes, passwords, email, precise location or unrelated chat messages. Local character/realm identifiers only when necessary; avoid account IDs.
9. SavedVariables store only required snapshots, provenance and preferences. Provide documented retention, privacy reset and migration behavior; avoid debug logs with player data by default.
10. If a future companion, cloud or market-data sync is proposed, STOP for separate privacy assessment, data-sharing consent, Blizzard terms check and explicit owner approval before implementation.
11. Respect input focus, screen scaling and protected frames. Hide nonessential dashboard overlays during combat where safe, without trying to bypass combat restrictions.
12. Maintain neutral risk labels: asking price is not sale price, market timestamp is not live valuation, and chance of sale is unknown unless model evidence supports it.

## Per-screen release tests
- [ ] WoW interface interactions work with no protected/forbidden object errors or taint.
- [ ] Layout remains readable at multiple UI scales; window can be recovered after offscreen positioning.
- [ ] Changing character/realm does not leak one character's inventory or private data into another view.
- [ ] Low-data, stale-market, no-profession and unavailable-API states never invent numbers.
- [ ] AH scans stop on client cooldown and do not retry rapidly.
- [ ] No auto-trading and no in-game advertising/donation prompts.
- [ ] Measured framerate/latency impact and storage volume recorded on actual Forever build.
- [ ] No unintended network traffic (addon design), debug dumps or companion integration.
- [ ] UI displays source and observation age for advice.
- [ ] Screenshots for issue reports are sanitized.

## Competitive UI research (developer-reported, not independently tested)
| Addon | Evidence dated 2026-11-09 | Pattern worth studying | Caution |
|---|---|---|---|
| [ForeverArtisan](https://www.curseforge.com/wow/addons/foreverartisan) | v0.9.39-forever on Nov 9, 2026 | progression goals, reagent availability, context-rich tooltips, scan/provenance qualifiers | All Rights Reserved; do not copy assets, source or data |
| [ProfessionsForever](https://www.curseforge.com/wow/addons/professionsforever) | v0.9.4 Nov 5 | compact/roomy list density, tabs, consistent footer summary, reagent source strips | Custom License; inspect permission before reuse |
| [Auctionator](https://www.curseforge.com/wow/addons/auctionator) | Forever release available | established auction pricing mental model, explicit search flows | do not clone proprietary UI/assets |
| [Baganator](https://www.curseforge.com/wow/addons/baganator) | community reports Forever support | inventory filtering and integration ergonomics | verify current Forever release |
| [ElvUI](https://www.tukui.org/) | community reports Forever support | modular skins, scalable interface | addon interoperability is not guaranteed |

### Competitive findings and GoldWise differentiator
- Profession planning, shopping lists, alt awareness, and even 'where to sell' already exist in recent competitors; they are not novel alone.
- **Differentiate through trust and decisions:** explain why to reserve particular materials for a combined gold+profession target, reveal alternative actions, quantity allocation conflicts, price freshness, uncertainty and long-term recommendation outcomes.
- Create a small compatibility smoke matrix testing GoldWise alongside Auctionator, ProfessionsForever, ForeverArtisan and common UI-overhaul addons, without relying on or modifying their protected UI.

## Process
Recheck the Blizzard policy at every release, and after major game patches. Capture client build, observed behavior and source classification. If rules are ambiguous, send a specific question to `WoWUI@blizzard.com` rather than assume approval.
