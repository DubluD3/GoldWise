# ADR-0001 — Local-only advisory addon and API boundary
Status: **PROPOSED** (requires owner acceptance)
Date: 2026-11-09

## Context
GoldWise aims to recommend better decisions for inventory, professions, crafting and market value. Blizzard's UI policy and EULA constrain implementation, and Forever may differ from Classic/Retail.

## Decision
- Free and open-source Lua addon; no mandatory companion, account, server or payment.
- Observation + analysis + player-directed guidance only.
- All game API calls in evidence-backed, guarded adapters.
- Pure deterministic domain engines and local SavedVariables.
- Manual market observations; never automated trading.
- Recommendations report uncertainties and abstain when data insufficient.

## Rejected
Autobuy/post/cancel, unattended actions, automated inputs, process inspection, cloud-first sync, paid tiers, runtime LLM, scraping unlicensed competitor data.

## Consequences
Lower enforcement/privacy risk and simpler testing; more limited automatic freshness and stronger dependence on player scans. Approval of this ADR does not constitute Blizzard approval.

## Revisit when
Official policy changes, client APIs verified, or optional companion proposed; separate ADR and compliance review required.
