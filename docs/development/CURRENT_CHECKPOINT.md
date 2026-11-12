# Development checkpoint — GoldWise (2026-11-12)

**Stop reason:** actual installed WoW Forever QA and owner-approved licensing/release are unavailable to the engineering agent. Safe independent offline stories have been implemented on reviewable draft branches; this is not a production release. Read this document before resuming.

## Current stack: merge only after sequential owner review
1. [PR #34](https://github.com/DubluD3/GoldWise/pull/34) GW-013 trainer probe → `main`
2. [PR #35](https://github.com/DubluD3/GoldWise/pull/35) GW-014 reagent graph → #34
3. [PR #36](https://github.com/DubluD3/GoldWise/pull/36) GW-019 five-tab dashboard → #35
4. [PR #37](https://github.com/DubluD3/GoldWise/pull/37) GW-017 reservations → #36
5. [PR #42](https://github.com/DubluD3/GoldWise/pull/42) GW-026 first-run guide → #37, head `8689c7e698af3f39983389f15c46ed5cd42f3578`; [CI PASS](https://github.com/DubluD3/GoldWise/actions/runs/43191696374)
6. [PR #43](https://github.com/DubluD3/GoldWise/pull/43) GW-018 offline vendor/crafting/ask model → #42, head `78dd33a1aa5e3fb40fb99a0afe77d4375752a6c2`; [CI PASS](https://github.com/DubluD3/GoldWise/actions/runs/43192391313)
7. [PR #44](https://github.com/DubluD3/GoldWise/pull/44) GW-025 QA ZIP, privacy, release gate → #43, head `2103954671a756eb9fc5819a70d327d11f90d568`; [CI + artifact PASS](https://github.com/DubluD3/GoldWise/actions/runs/43193418138)
8. [PR #46](https://github.com/DubluD3/GoldWise/pull/46) GW-027 offline alt gear/transfer model → #44, head `b79c22f79c3d05976e0795f851c1c25aa2aefe81`; [CI PASS](https://github.com/DubluD3/GoldWise/actions/runs/43194083422)
9. GW-024 client QA documentation (this branch, review pending), to be based on #46.

Do NOT merge/rebase the stack without rechecking actual heads, tests, conflicts, issue acceptance and user-tested functionality. Do not self-approve production or source rights.

## Functionality currently provided in the **stacked** QA candidate
- Existing verified scope on prior owner tests: bootstrap, character, manual bags/professions, native AH browse-result observation, manual money delta; direct AH queries remain prohibited/unverified.
- Earlier draft functionality: fixed-output recipe material DAG, session reservations, five-tab informational dashboard and guarded trainer probe.
- GW-026: per-source guide, first-run/on-demand navigation, accurate missing/stale/partial states; isolated `GoldWiseGuideDB` version 1 preference state, original `GoldWiseDB` version 1 untouched.
- GW-018: guarded offline item-vendor/crafting comparisons, synthetic fixtures, no live expected auction proceeds.
- GW-025: privacy disclosure and explicit QA ZIP packaging with validated TOC, CI artifact, public release disabled without human gate.
- GW-027: offline conservative alt gear eligibility, synthetic fixtures; no live equipment capture, mailing or swap.

## Exact CI proof
- #42 head `8689c7e`: syntax/unit/contract/all PASS.
- #43 head `78dd33a`: syntax/unit/contract/all PASS.
- #44 head `2103954`: syntax/unit/contract/all and candidate ZIP job PASS. A QA artifact with short expiration was uploaded. Artifact expires 2026-11-19 09:40 UTC.
- #46 head `b79c22f`: syntax/unit/contract/all and candidate ZIP job PASS.
- This documentation PR's final checks need their own Actions run.
- **Actual Forever in-game test results for integrated candidate: NOT RUN.**

## True gates and limitations
1. Client build verification: current allowlist only `1.60.1` builds `70862` and `70888`, interface `16001`. Each patch requires fresh live proof.
2. API-010/012 and GW-011: market identity, per-unit price interpretation, AH fees/deposits, durable market history unknown. Never auto-query or infer sales.
3. Profession skill-up probabilities, progression/trainer behaviors beyond verified probe, comprehensive craft economics, bank, alt snapshots, equipment stats/bind/transfer rule APIs, and complete goals UI require evidence/adapters. Avoid claims they are implemented.
4. No chosen public redistribution `LICENSE`; owner selects after review; do NOT fabricate a license or grant.
5. No in-game performance, real-client accessibility, combat taint, multi-session, multi-character regression signoff. Actual owner must test and provide sanitized evidence.
6. Existing upstream PRs #34-#37 are open drafts; no merges performed.

## Next action
Run the **[GW-024 owner E2E QA checklist](OWNER_E2E_QA.md)** on the latest integrated candidate ZIP and report the real build, UI scale, E01-E20 results and errors. Keep failures as issues. Revalidate API evidence, implement independent only-evidenced adapters/stories and rerun all four Lua suites and ZIP checks. Merge PRs in dependency order after owner reviews. Only after all release gates and rights/license decision should an owner-authorized release ZIP be considered.

No background automation or unchecked gameplay action is authorized by this checkpoint.

## Follow-up hardening (2026-11-12)
- The Node.js 20 deprecation warning was resolved on packaging PR #44 (head `02b269efc199736ebda96e3183c9b239287cb62e`, [CI PASS](https://github.com/DubluD3/GoldWise/actions/runs/43194780775)). This downstream hardening branch incorporates the same pinned Node.js 24 artifact uploader so its own QA ZIP does not reintroduce the warning. Future stack reconciliation must preserve this change when merging PR #44.
- Guide completeness now requires an **explicit boolean true**, not merely absence of false. Unknown/malformed coverage is Partial. Missing character scope is Pending. Malformed scanner definitions fail closed. These are offline-only defensive semantics; actual Forever UI QA remains NOT RUN.
