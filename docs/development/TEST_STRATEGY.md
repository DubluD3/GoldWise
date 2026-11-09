# Verification strategy / quality gates

Status as of 2026-11-09: GW-004 startup and GW-005 schema initialization and restoration passed offline and in the live client. The repo has no bundled Lua runtime.

## Offline tests

Run `sh scripts/test.sh` to execute every top-level Lua suite in `tests/`. The runner checks for Lua 5.1 and stops at the first failure. Set `GOLDWISE_LUA` to an absolute interpreter path when needed. The GitHub Actions smoke job uses the same command.

- `tests/fixtures/ForeverClient.lua` supplies `GetBuildInfo`, local output, and one-shot event registration to adapter and probe chunks in an isolated environment. Storage tests set the SavedVariables global after loading the TOC files and then dispatch `ADDON_LOADED`. The character probe tests dispatch `PLAYER_ENTERING_WORLD` with explicit login and reload flags. The fixture can omit the build API or event helper and simulate a registration error.
- `data/Storage.lua` is the current pure-Lua boundary. Its unit suite permits only the standard Lua globals the module needs. `Storage.open(saved)` takes a table from the caller, and the SavedVariables adapter owns the game global and uses the returned state only after a successful open.

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
| GW-004 Lua syntax | `luac -p adapters/Bootstrap.lua tests/bootstrap.lua` with Lua 5.1.5 | Parsed both files | PASS |
| GW-004 offline bootstrap | `lua tests/bootstrap.lua` with Lua 5.1.5 | 8 cases passed, including missing API, failed call, and a changed build with the same interface | PASS |
| GW-004 in-game load and reload | Owner logged in and ran `/reload` on Forever build `70862` on 2026-11-09 | Both displayed the expected GoldWise `0.1.0-dev` startup message with gameplay features disabled | PASS |
| GW-005 storage table and migration | `lua tests/storage.lua` with Lua 5.1.5 | 5 groups passed, covering scope isolation, round trip, migration, corrupt/future data, and capacity | PASS |
| GW-005 probe callback | `lua tests/storage_probe.lua` with Lua 5.1.5 | 5 cases passed, covering marker states, unavailable event helper, and changed build | PASS |
| GW-005 in-game persistence probe | [Disposable marker procedure](STORAGE_PROBE.md#in-game-procedure) | Owner observed marker at `ADDON_LOADED` after `/reload` and full restart on `70862`. Character-selection relog was not reported. | PASS for reload and full restart |
| GW-005 offline adapter | `lua tests/saved_variables.lua` with Lua 5.1.5 | 8 cases passed, including TOC load order, initialization, restore, migration, and preservation of rejected data | PASS |
| GW-005 in-game product storage | Owner installed GoldWise `0.1.1-dev` on build `70862` on 2026-11-09 | First login printed `created (schema 1)`. Reload, character-selection relog, and full restart each printed `current (schema 1)`. | PASS |
| GW-006 offline runner | `sh scripts/test.sh` with Lua 5.1.5 | 26 checks passed across four suites. Domain isolation and TOC adapter tests passed. | PASS |
| GW-007 snapshot model, probe, and product adapter | `sh scripts/test.sh` with Lua 5.1.5 | 38 checks passed across seven suites, including TOC load order, two-character scope, reload stability, and restricted or unavailable inputs | PASS |
| GW-007 live character context | [Disposable probe](CHARACTER_PROBE.md#gw-007-character-context-verification) | Owner confirmed login, reload, and manual output on `70862`, all fields available, and different tags for two characters. Same-character tag comparison was not reported. | PASS for observed paths |
| GW-007 in-game product capture | Owner installed GoldWise `0.1.2-dev` on build `70862` on 2026-11-09 | Both login and `/reload` displayed `GoldWise character snapshot ready.` | PASS |
| GW-008 bag snapshot model, probe, and product scan | `sh scripts/test.sh` with Lua 5.1.5 | 48 checks across nine suites passed. Coverage includes aggregation, partial reads, character scope, unavailable refresh, and unverified builds. | PASS |
| GW-008 live bag probe | [Disposable probe](INVENTORY_PROBE.md) | Owner reported all six carried bags complete on `70862`, with a sample stack and carried total of `1`. | PASS for API reads |
| GW-008 installed addon counts | Owner ran `/run GoldWiseInventoryScan()` in GoldWise `0.1.3-dev` on build `70862` on 2026-11-09 | Confirmed the same complete six-bag result and sample stack and carried total of `1`. Bank and alts were unobserved. | PASS |
| GW-009 profession model, probe, and product scan | `sh scripts/test.sh` with Lua 5.1.5 | 59 checks passed across 11 suites. Profession cases cover closed or external views, filtered and unavailable recipe data, character scope, and clearing a failed refresh. | PASS |
| GW-009 live profession probe | [Disposable probe](PROFESSION_PROBE.md) | Owner reported skill `87/150`, 35 observed learned rows, and a learned sample on `70862`. Closed-window result was not reported. | PASS for open-window reads |
| GW-009 installed profession scan | Owner ran `/run GoldWiseProfessionScan()` in GoldWise `0.1.4-dev` on build `70862` on 2026-11-09 | Owner confirmed the open-window scan passed and all reported data was correct. | PASS for open-window scan |
| GW-009 installed closed-window fallback | [Close the crafting window and repeat the scan](../../README.md#test-the-startup-build) | Live result not separately reported. The offline product test verified the unavailable message and cleared snapshot. | PENDING live evidence |
| GW-010 Auction House cache model, probe, and product observer | `sh scripts/test.sh` with Lua 5.1.5 | 70 checks passed across 13 suites. Tests cover readiness, close, failure, expiry, restricted rows, the cap, and character-scoped in-memory capture. | PASS |
| GW-010 live browse-cache probe | [One native search and local cache read](AUCTION_PROBE.md) | Owner confirmed readiness before and after a native search, a browse update, and `cache=partial` with 154 cache rows and 128 observed rows on `70862`. | PASS for the observed read path |
| GW-010 installed addon cache observation | Owner ran the GoldWise `0.1.5-dev` manual observation on build `70862` on 2026-11-09 | Owner confirmed correct data. The installed addon's cache status, row counts, and sample were not separately reported. | PASS for the reported read |
| GW-011 market history model | `sh scripts/test.sh` with Lua 5.1.5 | 76 checks passed across 14 suites, including six groups for required scope, exact market isolation, provenance, staleness, retention limits, reopening, and invalid data. | PASS |
| GW-011 live market isolation and restart | Verify the active market ID against the visible browse cache, then validate retained snapshots across scopes and a full client restart | NOT RUN. The market discriminator is unverified and production persistence is disabled. [API-012](../research/API_EVIDENCE.md#api-012--gw-011-market-scope) | BLOCKED |
| Domain unit tests | TBD once harness installed | NOT RUN | BLOCKED |
| API adapter mock tests | TBD | NOT RUN | BLOCKED |
| Forever live client QA | Manual owner-run | NOT RUN | BLOCKED |
| Blizzard policy review | docs checklist | NOT APPROVED | BLOCKED |

## Release gate
All P0 tests pass, current build verified, no critical performance/migration defects, explicit owner sign-off. Do not equate an offline mock PASS with in-game API safety.
