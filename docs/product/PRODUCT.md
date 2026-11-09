# Product requirements — GoldWise
Version: draft 2026-11-09. Status: PROPOSED, not implemented.

## Problem
Players juggle inventory, professions, recipe needs, goals and changing auction prices. Existing tools often present market data or isolated crafting routes, leaving tradeoffs to the player.

## Promise
Personalized, transparent suggestions for **sell / retain / craft / vendor / gather / buy materials manually**, grounded in recorded character state, supported AH observations and verified recipe data. Never trade on behalf of the player.

## Personas
1. Casual player: understand bag items and what to do next.
2. Profession leveler: preserve reagents, find recipes/training gates, compare advancement costs.
3. Gold earner: compare realistic net returns and risks.
4. Alt player: allocate scarce materials with explicitly stale alt snapshots.

## Core user journeys
- Open bag → inspect item → see choices, reasons, price age, missing information.
- Set profession skill target → identify known recipes, required materials and training gates → reserve materials → show manual next steps.
- Manually scan AH → calculate listing-based indicative value (not guaranteed sale) → compare alternatives.
- Set goal (gold + profession) → choose objective weights, session time and allowed spending → recalculate next actions.
- Record recommendation → optionally compare with observed outcomes without implying causation.

## Functional requirements
- CR-01: Character, realm/faction and profession identification; capture skill/current cap/known recipes only where supported.
- CR-02: Inventory snapshots (bag first; bank/alt only with clear last-observed labels).
- CR-03: Manual AH scan or supported price adapter with source/time/provenance; no polling automation.
- CR-04: Recipe knowledge graph with version, origin, verified availability and missing materials.
- CR-05: Material reservations and conflict detection across goals/alts.
- CR-06: Explainable candidate comparison including selling fees/deposits, opportunity cost and conservative uncertainty.
- CR-07: Ledger with reconciled observations; never infer sale solely from gold delta.
- CR-08: Personal goals, progression plan and revisions after changes.
- CR-09: Local persistent storage, schema migration, reset/export plan and bounded retention.
- CR-10: accessible, performant UI, no misleading 'live' pricing when stale.
- CR-11: abstain when unknown API/data/recipe/sale likelihood makes advice unreliable.

## Non-goals (V1)
Automated trade, AH sniping, botting, external AI inference, predictive price guarantee, cloud accounts, marketplace, multiplayer sharing, paywalls, live external API dependency, and farming path automation.

## Product success measures (not promises)
- Correct material reservation / no double-counting in test fixtures.
- Share of recommendations with traceable evidence and explanation = 100%.
- Zero automated game transactions.
- In-game QA: no critical errors; bounded memory/runtime and scan load.
- User validation: can answer 'why keep this?' in <=2 UI interactions.

## Releases
- A: character + inventory + manual market + profession context + explainable item suggestions.
- B: profession route optimizer + reservations + ledger + goals + alt snapshots.
- C: scenario comparison + calibrated market confidence + evaluation of recommendation outcomes.

## Open questions
- Actual current Forever build/interface/API availability.
- Recipe/trainer datasets with reusable licensing.
- AH query limits/readiness and available sale evidence.
- User preference for side panel vs standalone dashboard.
