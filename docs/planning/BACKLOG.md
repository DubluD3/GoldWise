# Jira-style hierarchy: Capability → Feature → Story

Status key: `PROPOSED`, `READY`, `BLOCKED`, `IN_PROGRESS`, `IN_REVIEW`, `DONE`. All entries below start **PROPOSED**, pending G0. IDs are stable even if GitHub issue numbers differ. Priority P0=blocking MVP, P1=release B, P2=later. GitHub issues are execution records; this file is the taxonomy.

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
Format: **Story — priority — dependency — acceptance**. Stories must not be self-marked DONE without actual test evidence.

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
