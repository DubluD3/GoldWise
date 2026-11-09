# Verification strategy / quality gates

Status as of 2026-11-09: GW-004 startup and GW-005 schema initialization and restoration passed offline and in the live client. The repo has no bundled Lua runtime.

## Offline tests

Run `sh scripts/test.sh` to execute every top-level Lua suite in `tests/`. The runner checks for Lua 5.1 and stops at the first failure. Set `GOLDWISE_LUA` or `GOLDWISE_LUAC` to an absolute tool path when needed. The GitHub Actions regression matrix runs the three checks independently.

| Mode | Scope | Local result |
|---|---|---|
| `sh scripts/test.sh syntax` | Parse Lua sources under `adapters/`, `data/`, and `tests/` without executing them, including nested probes and fixtures. Check the runner with `sh -n`. | 37 Lua files and the shell runner passed |
| `sh scripts/test.sh unit` | Pure data models, with isolated Lua environments and synthetic inputs. | 30 checks across seven suites passed |
| `sh scripts/test.sh contract` | Adapters, addon load order, and disposable probes under mocked client APIs. | 50 checks across eight suites passed |

### Fixture policy

- Keep pure model tests separate from game adapters. Register new top-level suites in the runner. A new `*_probe.lua` suite is classified as a contract test. An unclassified suite fails the check.
- Use synthetic identifiers, timestamps, quantities, and copper values. Keep character names, live SavedVariables, and copied game or provider datasets out of fixtures.
- Document the API signature, build, and source in [API evidence](../research/API_EVIDENCE.md) before adding a new client mock. Use distinct fixtures for missing, partial, stale, restricted, and unsupported data where they affect behavior. A mocked call exercises the addon contract only.
- Run live client QA manually. Record the build, steps, and actual observations, or write `NOT RUN`. The CI matrix runs entirely offline.

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
| GW-003 source audit | Review [sources and exclusions](../research/DATA_PROVENANCE.md), run `git diff --check`, and resolve repository links and headings | Six repository links verified and whitespace check passed. The audit changed only Markdown. | PASS |
| GW-003 existing fallback evidence | Run `sh scripts/test.sh` with Lua 5.1.5 from the pinned [GW-011 code revision](https://github.com/DubluD3/GoldWise/commit/3dfb4d78a1747678f35fc80c75de540d95e07643) | 76 checks passed across 14 suites. Covered learned rows, missing profession data, empty versus unavailable browse cache, mismatched build and scope, and stale reads. | PASS |
| GW-003 new client checks | Documentation-only audit of existing observations | NOT RUN. Prior owner reports on build `70862` are linked in the audit. | N/A |
| GW-023 regression matrix | `sh scripts/test.sh syntax`, `unit`, `contract`, and default mode with Lua 5.1.5 | Syntax passed. Unit and contract selections cover all 15 suites exactly once, with 80 checks total. Default and `all` produced identical output. | PASS |
| GW-023 runner failure paths | Run in an isolated copy with an invalid mode, missing compiler, malformed nested Lua file, and unclassified top-level suite | All four cases exited with an error and identified the cause. | PASS |
| Lua formatting and semantic lint | No formatter or semantic linter configured | NOT RUN. The syntax gate uses Lua's compiler. | NOT RUN |
| GW-023 live client QA | Offline tooling story | NOT RUN. Prior game observations remain listed below. | N/A |
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
| GW-013 catalog | `lua tests/recipe_catalog.lua` with Lua 5.1.5 | Four groups passed for provenance, known/unknown/unavailable status, freshness and scope gates, and malformed or oversized snapshots. | PASS |
| GW-013 GW-009 snapshot contract and regression | Overlay the catalog and its suite on the pinned [GW-011 code revision](https://github.com/DubluD3/GoldWise/commit/3dfb4d78a1747678f35fc80c75de540d95e07643), then run `sh scripts/test.sh` and exercise `ProfessionSnapshot.capture` with mocked reader callbacks | 80 checks passed across 15 suites. The separate contract check returned known and unknown recipes from an actual GW-009 partial snapshot produced with mocks. | PASS |
| GW-013 trainer and catalog integration | Verify the visible trainer requirement and its association with the matching recipe on the target client | NOT RUN. The offline catalog does not load in WoW. The earlier [GW-009 observations](../research/API_EVIDENCE.md#gw-013-recipe-catalog-and-trainer-requirements) cover the local crafting window. | BLOCKED |
| Domain unit tests | TBD once harness installed | NOT RUN | BLOCKED |
| API adapter mock tests | TBD | NOT RUN | BLOCKED |
| Forever live client QA | Manual owner-run | NOT RUN | BLOCKED |
| Blizzard policy review | docs checklist | NOT APPROVED | BLOCKED |

## Release gate
All P0 tests pass, current build verified, no critical performance/migration defects, explicit owner sign-off. Do not equate an offline mock PASS with in-game API safety.
