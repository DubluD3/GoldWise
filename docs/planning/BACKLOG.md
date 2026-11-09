# Jira-style hierarchy: Capability → Feature → Story

Statuses are `PROPOSED`, `READY`, `BLOCKED`, `IN_PROGRESS`, `READY_FOR_REVIEW`, `IN_REVIEW`, and `DONE`. Stories without a progress row are `PROPOSED`. IDs are stable even if GitHub issue numbers differ. P0 blocks the MVP, P1 targets release B, and P2 is later. GitHub issues hold story scope and acceptance criteria.

## Current progress

Last updated November 9, 2026. `READY_FOR_REVIEW` means the work is pushed and ready for owner review. Use `IN_REVIEW` when a story PR is open and `DONE` after owner acceptance, required evidence, and merge.

| Story | Status | Evidence and next action |
|---|---|---|
| [GW-001](https://github.com/DubluD3/GoldWise/issues/1) | `DONE` | Owner confirmed Forever `1.60.1`, build `70862`, interface `16001`. The discovery register identifies unsupported calls and their fallbacks. [Evidence commit](https://github.com/DubluD3/GoldWise/commit/cc1bdfc27321724077543c8d03dea001edcb3312) |
| [GW-002](https://github.com/DubluD3/GoldWise/issues/2) | `DONE` | Blizzard sources reviewed and the smoke-test boundaries documented. Owner approved the documented scope for merge. [Review commit](https://github.com/DubluD3/GoldWise/commit/81daf60749a8df51ab9e923cbacc1ff2f7d24c04) |
| [GW-003](https://github.com/DubluD3/GoldWise/issues/3) | `DONE` | Audited local recipe and browse observations and seven external sources. External imports remain excluded. Owner approved the local-only source audit for merge. [Audit PR](https://github.com/DubluD3/GoldWise/pull/29) |
| [GW-004](https://github.com/DubluD3/GoldWise/issues/4) | `DONE` | Bootstrap passed 8 offline checks. Owner confirmed startup on login and `/reload` on build `70862`. [Verification commit](https://github.com/DubluD3/GoldWise/commit/3cf8c375bd195f32e0a22ef8614a3d0d6d129624) |
| [GW-005](https://github.com/DubluD3/GoldWise/issues/5) | `DONE` | Owner confirmed schema v1 was created on first login and restored after reload, character-selection relog, and full restart. Migration and rejected data were tested offline. [Verification commit](https://github.com/DubluD3/GoldWise/commit/4796811962458fcb797d73297cdbb321962483d4) |
| [GW-006](https://github.com/DubluD3/GoldWise/issues/6) | `DONE` | All 26 Lua checks passed locally and in GitHub Actions. [Implementation](https://github.com/DubluD3/GoldWise/commit/a8da2ff064b3e9e969961b938e29d2bf01165533) · [CI run](https://github.com/DubluD3/GoldWise/actions/runs/42600890124) |
| [GW-007](https://github.com/DubluD3/GoldWise/issues/7) | `DONE` | Owner confirmed product capture on login and `/reload` on build `70862`. The live probe distinguished two characters, and all 38 offline checks passed in CI. [Live evidence](https://github.com/DubluD3/GoldWise/blob/feature/GW-007-character-snapshot/docs/research/API_EVIDENCE.md#api-008--gw-007-character-context) · [CI run](https://github.com/DubluD3/GoldWise/actions/runs/42604760991) |
| [GW-008](https://github.com/DubluD3/GoldWise/issues/8) | `DONE` | Owner confirmed the installed manual scan matched the probe's complete six-bag result and sample counts on build `70862`. All 48 offline checks passed in CI. [Live evidence](https://github.com/DubluD3/GoldWise/blob/feature/GW-008-bag-inventory/docs/research/API_EVIDENCE.md#api-003--gw-008-carried-bag-inventory) · [CI run](https://github.com/DubluD3/GoldWise/actions/runs/42607693130) |
| [GW-009](https://github.com/DubluD3/GoldWise/issues/9) | `DONE` | Owner confirmed the installed manual scan matched the open crafting window on build `70862`. All 59 offline checks passed in CI. Closed-window handling passed offline and has no separate live result. [Live evidence](https://github.com/DubluD3/GoldWise/blob/feature/GW-009-profession-snapshot/docs/research/API_EVIDENCE.md#api-005--gw-009-profession-context) · [CI run](https://github.com/DubluD3/GoldWise/actions/runs/42628542851) |
| [GW-010](https://github.com/DubluD3/GoldWise/issues/10) | `DONE` | Owner confirmed correct data from the installed manual cache observation on `70862`. The probe read 128 of 154 rows, and all 70 offline checks passed in CI. The verified path covers cache observation after a native search. Addon-originated queries remain blocked. [Live evidence](https://github.com/DubluD3/GoldWise/blob/feature/GW-010-ah-observation/docs/research/API_EVIDENCE.md#api-006--gw-010-auction-house-browse-cache) · [CI run](https://github.com/DubluD3/GoldWise/actions/runs/42635947850) |
| [GW-011](https://github.com/DubluD3/GoldWise/issues/11) | `BLOCKED` | The offline model is merged and passed offline checks for scope isolation, stale reads, and reopening. Verify a discriminator tied to the active Forever auction market before enabling SavedVariables writes and testing a full client restart. [API-012 evidence](https://github.com/DubluD3/GoldWise/blob/feature/GW-011-market-retention/docs/research/API_EVIDENCE.md#api-012--gw-011-market-scope) |
| [GW-013](https://github.com/DubluD3/GoldWise/issues/13) | `BLOCKED` | The offline catalog is merged. Verify trainer requirements and their association with a recipe on build `70862` before live integration. [Implementation PR](https://github.com/DubluD3/GoldWise/pull/30) |
| [GW-021](https://github.com/DubluD3/GoldWise/issues/21) | `IN_REVIEW` | Owner confirmed the installed ledger recorded the unclassified quest reward change and returned the expected responses when labeling and clearing it on `70862`. Ready for merge review. [PR](https://github.com/DubluD3/GoldWise/pull/33) · [Live evidence](../development/MONEY_PROBE.md#installed-addon-check) |
| [GW-023](https://github.com/DubluD3/GoldWise/issues/23) | `DONE` | Owner approved merge. Syntax and all 80 unit and adapter contract checks passed locally and in GitHub Actions. New client QA was not run for this offline tooling story. [CI run](https://github.com/DubluD3/GoldWise/actions/runs/42643013448) |

| Capability | Feature | Stories | Delivery |
|---|---|---|---|
| CAP-01 Trust & Compliance | F-01 evidence and policy | GW-001, GW-002, GW-003 | G0 |
| CAP-02 Foundation | F-02 addon runtime and local state | GW-004, GW-005, GW-006 | G1 |
| CAP-03 Character Intelligence | F-03 profiles and inventory | GW-007, GW-008, GW-009 | G1 |
| CAP-04 Market Intelligence | F-04 manual AH and prices | GW-010, GW-011, GW-012 | G2 |
| CAP-05 Profession Intelligence | F-05 skills, recipes, paths | GW-013, GW-014, GW-015, GW-016 | G3 |
| CAP-06 Economic Decisions | F-06 reservations and valuation | GW-017, GW-018, GW-019 | G4 |
| CAP-07 Goals & Accounting | F-07 personal plan and ledger | GW-020, GW-021, GW-022 | G5 |
| CAP-08 Quality & Delivery | F-08 testing, UX, release | GW-023, GW-024, GW-025 | G6-G7 |

## Stories (each entry is an independently testable issue)
Each entry lists the story, priority, dependencies, and acceptance criteria.

### CAP-01 / F-01 — Trust & Compliance
- **GW-001 — P0 — none:** Build Forever API evidence register and safe in-client discovery probe. Accept: real client version recorded; symbols + signatures cited; unknowns blocked; no transactions.
- **GW-002 — P0 — none:** Policy/EULA risk register and forbidden-call boundaries. Accept: current policy URLs/date, compliance matrix, owner review for ambiguous behavior.
- **GW-003 — P0 — GW-001:** Verify recipe and market dataset licensing, source quality, patch/build provenance. Accept: permitted sources and exclusions documented; no unlicensed copying.

### CAP-02 / F-02 — Foundation
- **GW-004 — P0 — GW-001, GW-002:** Minimal Forever addon TOC/bootstrap and feature flags. Accept: loads in verified build, displays version, disabled unsupported features.
- **GW-005 — P0 — GW-004:** SavedVariables schema v1, scoped keys, retention, migration, corruption recovery. Accept: offline round-trip + logout/restart manual proof.
- **GW-006 — P0 — GW-004:** Pure-Lua domain boundaries, adapter interface, fixtures and CI smoke tests. Accept: deterministic offline tests, no WoW globals in domain modules.

### CAP-03 / F-03 — Character Intelligence
- **GW-007 — P0 — GW-001, GW-004:** Character/realm/faction snapshot with provenance. Accept: stable identity scope, nil handling, test with 2 profiles.
- **GW-008 — P0 — GW-007:** Inventory snapshots, stack aggregation, unavailable bank flags. Accept: counts match bags; missing/bank-unopened clearly labelled.
- **GW-009 — P0 — GW-007:** Profession skill/rank/cap/known-recipe snapshot adapter. Accept: verified in-client data or explicit unsupported fallback.

### CAP-04 / F-04 — Market Intelligence
- **GW-010 — P0 — GW-001, GW-004:** Manual, read-only AH scan lifecycle. Accept: explicit user trigger, cooldown/readiness handling, no trading, no retry storms.
- **GW-011 — P0 — GW-010, GW-005:** Market snapshot with realm/faction/time/source and bounded retention. Accept: no cross-market contamination, stale indicator, restart proof.
- **GW-012 — P1 — GW-011:** Optional third-party price adapter. Accept: documented interface and license; fallback without dependency.

### CAP-05 / F-05 — Profession Intelligence
- **GW-013 — P0 — GW-003, GW-009:** Versioned recipe/skill/trainer model. Accept: known vs unknown vs unavailable distinct, source attribution.
- **GW-014 — P0 — GW-013, GW-008:** Recipe material graph with cycle detection and missing ingredient math. Accept: nested recipe fixtures, no double-count.
- **GW-015 — P0 — GW-014:** Skill progression route estimator with gating/expected skill-ups. Accept: skill-color assumptions evidenced; recalculation per rank.
- **GW-016 — P1 — GW-015:** Cheapest/balanced/fastest progression preferences and shopping list. Accept: compare paths with fixed fixtures and explain constraints.

### CAP-06 / F-06 — Economic Decisions
- **GW-017 — P0 — GW-008, GW-014:** Reserved material allocator across recipes and goals. Accept: allocation invariant, shortage explanations, manual override.
- **GW-018 — P0 — GW-011, GW-017:** Copper-based sell/vendor/craft/keep comparison with fees/opportunity cost. Accept: property tests, uncertain prices abstain.
- **GW-019 — P0 — GW-018:** Item recommendation + 'why' breakdown UI. Accept: price age, source, inputs, rationale, no calls to transactions.

### CAP-07 / F-07 — Goals & Accounting
- **GW-020 — P1 — GW-018:** Gold + profession objective model and plan recalculation. Accept: constraints respected and plans update on snapshots.
- **GW-021 — P1 — GW-005:** Ledger observations + explicit categorization/reconciliation. Accept: distinguish gold changes from confirmed sales.
- **GW-022 — P1 — GW-005, GW-017:** Cached alt snapshots and age-aware material allocation. Accept: 'last seen' surfaced, no false real-time claim.

### CAP-08 / F-08 — Quality & Delivery
- **GW-023 — P0 — GW-006:** CI lint/unit/contract test matrix and fixture policy. Accept: scripted repeatable suite; missing game tests reported.
- **GW-024 — P0 — GW-019:** Performance, UX, accessibility and persistence QA. Accept: documented client QA on 2 inventories, low-data case and patched build.
- **GW-025 — P0 — GW-024:** Beta package, attribution, license decision, privacy docs and release gate. Accept: manual installation works; no unsupported promises.

## Story discipline
Each issue: context, user story, evidence links, acceptance checklist, dependencies, tests, risks, DoD. Keep IDs unchanged. No 'AI-only' self-approval of compliance or release gates.
