# Verification strategy / quality gates

Status as of 2026-11-09. The GW-013 offline checks use a local Lua 5.1.5 interpreter. This branch does not bundle the interpreter.

## Offline tests
- Fast unit tests for pure domain math: copper rounding, item quantities, availability, recipe dependency graph, resource reservations, goal constraints, confidence/abstain.
- Contract mocks for WoW adapters. Tests must model nil API, cache misses, unavailable profession frames, partial scan, throttled scan, stale snapshot, unsupported build and secret values where relevant.
- Schema tests: deterministic encode/decode, old-version upgrades, corrupt/truncated data recovery, market isolation.
- Property/invariant tests: never reserve more than owned; never negative available stack; every recommendation has reasons; no fictitious completed sale based on price listing.

## In-game manual test cases
- Client build/interface from game UI recorded, installation path and TOC compatibility.
- Startup/reload/logout/full client restart: settings and SavedVariables preserved.
- Empty bags, many stacks, missing items, full inventory, bank not visited.
- Two professions, zero professions, recipes unavailable, skill cap/trainer gate.
- AH closed, open, throttled, no results, changing results, incomplete scan, cooldown and manual repeat.
- Realm/faction context; cached alt stale state.
- CPU/frame responsiveness, data size, logs, taint/errors; accessibility and keyboard navigation.
- NO automated trade, crafting or client control in test runner.

## Acceptance reporting table
| Check | Command or in-game steps | Actual output | Status |
|---|---|---|---|
| GW-013 catalog | `lua tests/recipe_catalog.lua` with Lua 5.1.5 | Four groups passed for provenance, known/unknown/unavailable status, freshness and scope gates, and malformed or oversized snapshots. | PASS |
| GW-013 GW-009 snapshot contract and regression | Overlay the catalog and its suite on the pinned [GW-011 code revision](https://github.com/DubluD3/GoldWise/commit/3dfb4d78a1747678f35fc80c75de540d95e07643), then run `sh scripts/test.sh` and exercise `ProfessionSnapshot.capture` with mocked reader callbacks | 80 checks passed across 15 suites. The separate contract check returned known and unknown recipes from an actual GW-009 partial snapshot produced with mocks. | PASS |
| GW-013 trainer and catalog integration | Verify the visible trainer requirement and its association with the matching recipe on the target client | NOT RUN. The offline catalog does not load in WoW. The earlier [GW-009 observations](../research/API_EVIDENCE.md#gw-013-recipe-catalog-and-trainer-requirements) cover the local crafting window. | BLOCKED |
| Lua format/lint | TBD once toolchain chosen | NOT RUN | BLOCKED |
| Domain unit tests | TBD once harness installed | NOT RUN | BLOCKED |
| API adapter mock tests | TBD | NOT RUN | BLOCKED |
| Forever live client QA | Manual owner-run | NOT RUN | BLOCKED |
| Blizzard policy review | docs checklist | NOT APPROVED | BLOCKED |

## Release gate
All P0 tests pass, current build verified, no critical performance/migration defects, explicit owner sign-off. Do not equate an offline mock PASS with in-game API safety.
