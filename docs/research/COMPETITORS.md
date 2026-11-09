# Competitive research / differentiation
Snapshot date: 2026-11-09. **Feature reports are not independent hands-on benchmarks.** Recheck versions, source licenses, APIs and integration permissions before implementing interoperability.

| Competitor | Public reference | Reported positioning | GoldWise differentiation hypothesis |
|---|---|---|---|
| Auctionator | https://www.curseforge.com/wow/addons/auctionator | auction scanning, prices, shopping/posting helpers | optional price integration; goal-aware advice rather than duplicate AH UI |
| AHledger | https://ahledger.com/addon | history, valuations, sell-through, ledger | transparent multi-goal plan with resource reservations |
| Market | https://marketforever.dev/ | profession routes, pricing and tracking | combined gold+profession constraint optimizer |
| ProfessionsForever | https://www.curseforge.com/wow/addons/professionsforever | recipes, queues, crafting and alts | opportunity-cost modeling across all item uses |
| What's It For? | https://www.curseforge.com/wow/addons/whats-it-for | what items are for, progression paths | personalized next action based on goals and ownership |
| Everloot | https://everloot.app/ | market/profession observation and data | local-first explanation and source provenance |
| Forever AH | https://www.curseforge.com/wow/addons/foreverah | AH trading workflows | no automated trade tools; focus on choices |

## Research and implementation protocol
- Never assume a competitor lacks a feature because marketing doesn't mention it.
- Track tested version, screenshot/test notes, platform, source license, changes and source date.
- Use clean-room implementation and documented public APIs. No proprietary code/data copying or unauthorized scraping.
- Reevaluate each major milestone as Forever addon ecosystem changes quickly.

## Five differentiating experiments
1. Explain 'why keep X materials' in <=2 clicks; validate with players.
2. Goals: gold target + profession skill target with budget and optional session time.
3. Resource reservation engine detects conflicting objectives across recipes/alts.
4. Scenario: sell raw vs craft vs keep, showing gross/net/opportunity cost + uncertainty.
5. Recommendation diary: compare suggestion with later observed result and flag errors, not pretend causal success.

## Validation metrics
Decision explanation coverage, allocation correctness, abstention on stale data, player comprehension, performance. Avoid unverifiable earnings claims.
