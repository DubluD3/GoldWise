# Architecture (PROPOSED, API-dependent)

```text
WoW Forever supported UI events / read-only APIs
          ↓ (verified adapters only)
Adapters: Client / Inventory / Professions / Auction / Gold
          ↓ (normalised observations with provenance)
Local data: CharacterSnapshot / MarketSnapshot / RecipeCatalog / Ledger
          ↓
Pure-Lua engines: RecipeGraph → Allocator → Valuation → Plan → Explanation
          ↓
Game UI: Dashboard / Item advice / Profession plan / Gold goals / Settings
```

## Hard module contracts
- `adapters/`: only layer allowed to call WoW globals; guard every capability based on a verified client probe, not guessed namespaces.
- `domain/`: pure Lua, deterministic functions, no side effects or UI globals.
- `data/`: versioned schema and migrations; scoped by game build, region/realm/faction when applicable; no usernames beyond locally necessary character labels.
- `ui/`: projections of domain output; no transaction APIs; no undocumented secure frame interactions.
- `tests/`: fixtures include absent APIs, stale prices, nil item info, missing recipe, sparse market, conflicting material reservations.

## Proposed layout (create incrementally when story requires)
```text
GoldWise.toc
AGENTS.md
README.md
adapters/       # guarded Forever client API
domain/         # pure decision, money, planner, recipe math
data/           # SavedVariables, models, migration
ui/             # information only
tests/          # unit, contract, fixtures
scripts/        # offline lint and checks
docs/           # product, planning, policy, architecture, research
.github/        # issue / PR templates and CI
```

## Data design
- `Money`: integer copper; math checks overflow, rounding and display formatting.
- `MarketObservation`: item key, source, retrievedAt, realm/faction/ruleset, ask price, quantity, optional scan completeness and version; no implied sale.
- `CharacterSnapshot`: locally scoped character, timestamp, profession state, inventory locations + availability.
- `Recipe`: id, skill gating, profession, materials, outputs, unlock source, provenance, validated build, license.
- `RecipeCatalog` (GW-013, offline): schema v1 wraps one verified local crafting snapshot. Reads match build, character and profession and require a caller-supplied freshness limit. A present learned row is known, a missing row in a filtered or partial view is unknown, and a missing recipe list is unavailable. Trainer requirements are unavailable. The catalog stores up to 1,024 observed rows, attributes them to Blizzard's local crafting view, and records redistribution as unverified. [Evidence and limits](../research/API_EVIDENCE.md#gw-013-recipe-catalog-and-trainer-requirements)
- `Reservation`: goal id, item key, quantity; never allocate the same unit twice.
- `Recommendation`: candidate options, assumptions, inputs, uncertainties, reasons, optional abstain; immutable record for audit.
- `LedgerEntry`: observed delta or verified transaction, classification confidence, timestamp, manual correction support.

## Computation rules
- Listing is an ASK price, not a completed trade. Do not pretend to know probability of sale.
- Cost includes opportunity cost (possible material sale), fee, deposits, and relisting scenarios only when verified.
- Skill-up calculation must update probability as skill changes and respect trainer/rank boundaries; unknown probability blocks numeric craft counts.
- `ABSTAIN` is a first-class decision when uncertainty is material.
- Alt and bank snapshots are stale by default until re-observed.
- No dynamic executable code, network calls, process access or input generation.

## GW-026 guided capture state
The pure `data/ScanGuide.lua` model describes supported local sources and maps actual session observations to Pending/Partial/Stale/Last observed/Unsupported. Capture method and successful capture are different fields. The dashboard reuses existing verified manual adapter entrypoints and does not issue new gameplay or AH requests. A new separate `GoldWiseGuideDB` (schema 1; completion, current step and skipped-step flags only) stores onboarding preferences without mutating or migrating `GoldWiseDB`. Reject invalid guide preferences without overwriting them. Actual snapshot contents are never reconstructed from a saved preference flag.

## Performance/privacy
Player-triggered bounded AH scans; no polling loops. Throttle UI updates; cap history and SavedVariables size; no telemetry. No external AI in runtime.

## Integration gates
G0 validate actual client API first. Any proposed module may be postponed when client capabilities are unproven.
