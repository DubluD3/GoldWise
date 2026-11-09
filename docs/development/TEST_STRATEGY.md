# Verification strategy / quality gates

Status: planning, 2026-11-09. No tests have run; no Lua runtime is configured in this repo.

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
| Lua format/lint | TBD once toolchain chosen | NOT RUN | BLOCKED |
| Domain unit tests | TBD once harness installed | NOT RUN | BLOCKED |
| API adapter mock tests | TBD | NOT RUN | BLOCKED |
| Forever live client QA | Manual owner-run | NOT RUN | BLOCKED |
| Blizzard policy review | docs checklist | NOT APPROVED | BLOCKED |

## Release gate
All P0 tests pass, current build verified, no critical performance/migration defects, explicit owner sign-off. Do not equate an offline mock PASS with in-game API safety.
