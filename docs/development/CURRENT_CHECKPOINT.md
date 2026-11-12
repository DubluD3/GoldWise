# GoldWise — consolidated integration checkpoint (2026-11-12)

**Status: REVIEW / OWNER QA PENDING — NOT A RELEASE.** This document describes the cumulative draft head `feature/GW-017-safe-availability-reads` (PR #58) as verified at commit `dc691b7ea28df23916692f645e5da059d72e59b0`, [offline CI #43211210854](https://github.com/DubluD3/GoldWise/actions/runs/43211210854). Later commits require their **own** successful CI evidence. Do not infer real-client compatibility from CI.

## Integration graph

The GitHub PR graph was inspected on 2026-11-12: **20 open draft PRs, one contiguous parent-to-child base chain, no observed chain breaks**. The target of #34 is `main`; all other PRs target the previous PR's branch. This validates branch topology, **not** mergeability, absence of conflicts or owner acceptance.

| Order | PR | Scope | Base |
|---:|---|---|---|
| 1 | [#34](https://github.com/DubluD3/GoldWise/pull/34) | Trainer verification foundation | main |
| 2 | [#35](https://github.com/DubluD3/GoldWise/pull/35) | Nested recipe reagents | #34 |
| 3 | [#36](https://github.com/DubluD3/GoldWise/pull/36) | Five-tab dashboard | #35 |
| 4 | [#37](https://github.com/DubluD3/GoldWise/pull/37) | Session reservations | #36 |
| 5 | [#42](https://github.com/DubluD3/GoldWise/pull/42) | First-run scan guide | #37 |
| 6 | [#43](https://github.com/DubluD3/GoldWise/pull/43) | Offline economics model | #42 |
| 7 | [#44](https://github.com/DubluD3/GoldWise/pull/44) | QA ZIP and release gates | #43 |
| 8 | [#46](https://github.com/DubluD3/GoldWise/pull/46) | Offline equipment advisor | #44 |
| 9 | [#47](https://github.com/DubluD3/GoldWise/pull/47) | Owner QA handoff | #46 |
| 10 | [#48](https://github.com/DubluD3/GoldWise/pull/48) | Guide source hardening | #47 |
| 11 | [#49](https://github.com/DubluD3/GoldWise/pull/49) | Goal domain model | #48 |
| 12 | [#50](https://github.com/DubluD3/GoldWise/pull/50) | Dashboard goals | #49 |
| 13 | [#51](https://github.com/DubluD3/GoldWise/pull/51) | Material retention review | #50 |
| 14 | [#52](https://github.com/DubluD3/GoldWise/pull/52) | Custom goal chat commands | #51 |
| 15 | [#53](https://github.com/DubluD3/GoldWise/pull/53) | Profession progression review | #52 |
| 16 | [#54](https://github.com/DubluD3/GoldWise/pull/54) | Direct-reagent craft capacity | #53 |
| 17 | [#55](https://github.com/DubluD3/GoldWise/pull/55) | Profession-scoped producer cache | #54 |
| 18 | [#56](https://github.com/DubluD3/GoldWise/pull/56) | Reservation action-time validation | #55 |
| 19 | [#57](https://github.com/DubluD3/GoldWise/pull/57) | Atomic reservation validation | #56 |
| 20 | [#58](https://github.com/DubluD3/GoldWise/pull/58) | Fail-closed availability and guide integrity | #57 |

**Do not merge or rebase this chain without explicit owner authorization.** Before any approved merge sequence, re-fetch actual PR base/head SHAs and reviews, inspect each diff for rebase/conflict issues, test the integrated result after each dependency resolution, and preserve signed-off QA/license gates. A single final cumulative test run does **not** mean that each individual merge will automatically succeed.

## What the cumulative candidate actually offers

- On-device, accountless addon and five informational tabs: Overview, Inventory, Professions, Market and My Plan.
- First-run/on-demand scan guide; character-scope observation on login and *manual* carried bag, visible profession, AH browse-result and money samples; data freshness/unknown labels.
- Fixed-output recipe schematic capture on player action, bounded nested reagent planning, temporary per-recipe reservations, inventory material review and direct reagent coverage; producer cache restricted to current exact profession scan.
- Session-only customizable copper and profession skill targets, read-only progression review; no skill-up forecasting.
- Offline-only equipment and item alternative models are **not** verified live equipment, market pricing or cross-character data support.
- Known platform allowlist: `1.60.1` build `70862` or `70888`, interface `16001`. This is a development compatibility constraint, not a guarantee after new game patches.

## Evidence and exact blocked gates

| Gate | Current result | Requirement to progress |
|---|---|---|
| Lua 5.1 syntax, unit, contract, complete regression | PASS at prior head | Rerun on **new current head** after every change |
| Candidate ZIP integrity and manifest | PASS at prior head | Reverify newest artifact by matching full head SHA |
| Contiguous stacked draft PR base graph | PASS (topology only) | Recheck heads/bases before any authorized integration |
| Actual installed Forever E01–E20 | **NOT RUN** | Owner executes [E2E checklist](OWNER_E2E_QA.md) using latest passing candidate |
| Combat taint, UI scale, game compatibility, AH coexistence, performance | **NOT RUN** | Record live evidence and defects |
| Accurate skill-up odds, actual AH fee/net profit, durable bank/alt/gear evidence | **UNKNOWN / NOT VERIFIED** | Current-client API proof and separate explicitly approved stories |
| Open-source license and third-party content rights | **BLOCKED** | Owner selects/approves license and legal/compliance review |
| Signed release approval and final integration | **BLOCKED** | Owner signs actual QA and explicitly authorizes merge/release |

No public GitHub release was found in the inspected repository release list. Missing LICENSE / owner approval keeps `sh scripts/package.sh release` intentionally blocked; the CI artifact is a **QA-only candidate**.

## Owner next step

Use [INTEGRATED_TEST.md](INTEGRATED_TEST.md) for the compact game walkthrough and [OWNER_E2E_QA.md](OWNER_E2E_QA.md) for complete E01–E20 acceptance. In GitHub Actions for PR #58's **head branch**, select the most recent **successful** Lua regression workflow whose commit equals the current PR head. Download the candidate artifact there; do **not** follow an old immutable run link for installation. Back up addon folder and GoldWise SavedVariables first.

**Engineering next step after test feedback:** collect sanitized defects, fix reproducible failures, reverify current build/API restrictions, retest and only then ask for explicit integration/merge approval. Do not silently turn another `continue` into merge or release authorization.
