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

## GW-020 combined goals foundation
`domain/Goals.lua` is a pure, session-only model for explicitly supplied copper and profession skill targets. It recalculates remaining amounts from fresh, character/build-scoped money/profession observations; missing or stale inputs remain unknown. Manual next actions never promise earning rates, crafting outcomes, skill-up probabilities or confirmed sales. No storage migration or live UI until evidence/owner acceptance.

## GW-027 cross-character equipment eligibility
Pure `domain/EquipmentAdvisor.lua` consumes caller-normalized last-observed character/item data and independent, fresh transfer authorization evidence. No client APIs or SavedVariables schema changes. Unknown trade route/binding/eligibility restrictions trigger abstain; explicit BoP/soulbound restrictions, incompatible realm/faction/build and disqualifying usability trigger block. Even a fully matching fixture produces **potential-upgrade-review**, never a verified upgrade, until an evidence-backed role/stat comparator is designed. Runtime adapters and UI integration remain blocked under API_EVIDENCE.

## GW-018 offline economic alternative contracts
`domain/ItemChoices.lua` is pure Lua: exact integer copper bounds, explicit vendor reference alternatives, reserved-stock-aware nested recipe material accounting (using `data/RecipeMaterials.lua`), and optional scoped fresh verified-unit-basis AH asking-price hypotheticals. Output differentiates vendor-reference comparisons from **ask-only** and **unknown**. AH fee/cut/deposit scenarios require explicit *verified* inputs and must never be interpreted as expected sale proceeds. No live Forever adapter is wired because API-010/012 and price unit basis remain unverified; test fixtures alone never authorize them.

## GW-026 guided capture state
The pure `data/ScanGuide.lua` model describes supported local sources and maps actual session observations to Pending/Partial/Stale/Last observed/Unsupported. Capture method and successful capture are different fields. The dashboard reuses existing verified manual adapter entrypoints and does not issue new gameplay or AH requests. A new separate `GoldWiseGuideDB` (schema 1; completion, current step and skipped-step flags only) stores onboarding preferences without mutating or migrating `GoldWiseDB`. Reject invalid guide preferences without overwriting them. Actual snapshot contents are never reconstructed from a saved preference flag.

## GW-025 release packaging
`scripts/package.sh` packages only source files referenced by `GoldWise.toc`, public README/CHANGELOG and local PRIVACY disclosure under one `GoldWise/` folder. Candidate ZIP contains a clearly named not-for-public-release warning. Public release mode requires a non-test version, approved LICENSE and owner client-QA sign-off document. No game-client execution is attempted by the script. The script verifies ZIP contents and refuses ambiguous TOC paths.

## Performance/privacy
Player-triggered bounded AH scans; no polling loops. Throttle UI updates; cap history and SavedVariables size; no telemetry. No external AI in runtime.

## Integration gates
G0 validate actual client API first. Any proposed module may be postponed when client capabilities are unproven.

## GW-020 dashboard session targets (2026-11-12)
The existing five-tab layout remains unchanged. A Goals action in Overview and My Plan opens a temporary My Goals subview. Goals can only be derived from a player-triggered sampled character balance (+10,000 copper) or the currently observed profession (+10 skill, capped); they do not call game APIs or persist. The dashboard wraps `addon.ledgerView().latest` with the ledger's known build and scope before evaluating; profession data likewise receives the verified build and character scope. Missing, expired or wrong-scoped snapshots yield unknown rather than projections. The player may clear the goal at any time. This UI does not implement arbitrary custom input, alt goals, earning estimates or skill-up probabilities.

## GW-018 conservative carried-material review (2026-11-12)
`domain/MaterialReview.lua` requires complete, fresh, scoped carried-bag stock and validates snapshot-anchored session reservations. It computes holds as `other recipe reservations + max(active recipe reservation, current plan usage)`, refusing impossible allocations. Inventory's **Review materials** subview displays held and manual-review counts but does not assert sell safety. No game reader or persistent state was added.

## GW-020 profession goal review (2026-11-12)
`domain/ProfessionGoalReview.lua` is a pure, bounded read-only summary for fresh current-character profession scans and optional current matching goals and recipe plans. `adapters/RecipePlan.lua` adds `professionId` to the ephemeral plan at manual creation. The review rejects cross-profession, stale or mismatched plan/inventory evidence; filtered learned recipes cannot be interpreted as the full available catalog. No craft count or leveling outcome is inferred from skill differences.

## GW-014 direct craft capacity (2026-11-12)
The manual RecipePlan adapter attaches the captured fixed-output recipe to its ephemeral plan, scoped to its current character and timestamp. The read-only `domain/CraftCapacity.lua` coalesces duplicate direct reagents and computes floor(free stock/per-run requirement), where free stock subtracts other recipes' reservations but not the plan's own reservation. It fails closed on stale, partial, mismatched, malformed or impossible quantities. The My Plan subview never invokes a reader or crafts an item and never equates covered reagents with successful craft or skill gain.
