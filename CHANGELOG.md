## Unreleased - GW-020 profession review against scoped goals (2026-11-12)
- My Plan → Review progression shows observed skill/cap, count and completeness label of learned recipes in the filtered crafting view, optional matching skill goal gap and fresh same-profession recipe material gaps.
- Explicitly refuses skill-up forecasts or treating crafts as guaranteed skill increases; stale/cross-character observations remain unknown.
- No new WoW APIs, automatic interactions, goals storage or Auction House queries. Real client UI NOT RUN.

## Unreleased - GW-020 exact player goal targets (2026-11-12)
- Added strictly validated /goldwise goal gold <copper>, goal skill <level>, help, and clear commands. Goal panel displays the result without closing on repeated command.
- No new game APIs; targets remain local session only. Profession selection requires an existing fresh, matching manual scan; invalid targets cannot mutate goals.
- Offline unit and dashboard contract tests; live Forever client test NOT RUN.

## Unreleased - GW-018 material retention review (2026-11-12)
- Read-only Material Review subview distinguishes carried, conservatively held and manual-review quantities.
- Active plan and session reservations avoid counting the same recipe twice; invalid/stale/partial/cross-character data abstains.
- Never recommends selling. No bank/alt assumptions, AH requests, automation or new WoW APIs. Actual in-game review NOT RUN.

## Unreleased - GW-020 session goals in My Plan (2026-11-12)
- New My Goals view reachable from Overview and My Plan; choose +1g and +10 skill from fresh manual snapshots.
- Evaluates both targets with stale/character guards, allows reset and supports combined goals without persisting or predicting game outcomes.
- Offline dashboard contract tests cover display, scope/freshness, creation and clearing; **client E2E NOT RUN**.

## Unreleased - GW-020 offline combined goal foundation (2026-11-12)
- Added bounded copper/profession targets and read-only evaluation of fresh scoped observations with manual suggestions.
- Missing, stale, mismatched or partially known observations abstain. No skill-up probabilities or projected earnings fabricated.
- **Offline only**, no live goal UI, automatic game behavior or persistence migration.

## Unreleased - GW-026 guide source-status hardening (2026-11-12)
- Unknown completeness never becomes a completed scan, and missing active character scope fails closed. Added regression cases for incomplete/malformed observations.
- Updated stacked QA workflow to immutable Node.js 24 `actions/upload-artifact` pin to prevent previous warning from returning.

## Unreleased - GW-024 owner E2E QA handoff (2026-11-12)
- Added comprehensive manual Forever E01-E20 matrix, reproducible install/rollback, actual client reporting form and an agent checkpoint.
- Client QA and owner release approval **NOT RUN/PENDING**; no release gate has been waived.

## Unreleased - GW-027 alt equipment advice (offline only, 2026-11-12)
- Added conservative, pure Lua alternate-character equipment/transfer evidence evaluator and synthetic security/regression fixtures.
- No live equipment capture, transfer automation or upgrade claim. Client transfer rules and item usability APIs need actual Forever evidence. **BLOCKED from live UI.**

## Unreleased - GW-025 QA candidate packaging (2026-11-12)
- Added explicit local privacy disclosure, verified TOC-layout candidate ZIP creation, release-gate enforcement and CI candidate artifact output.
- Public release remains **BLOCKED** by missing owner license choice, missing target-build E2E approval and unreconciled earlier draft PRs.

## Unreleased - GW-018 economic comparisons (offline only, 2026-11-12)
- Pure Lua vendor-reference and crafting-opportunity-cost comparison using reservation-aware verified recipe graphs, plus guardrails for AH asking-price scenarios and externally evidenced fees.
- Synthetic 100-unit cloth alternative regression; no live price/advice UI integration because market identity, unit basis and auction fees remain blocked.
- **NOT A LIVE FEATURE** until target-build data and owner E2E evidence exist.

## Unreleased - GW-026 scan guide candidate (2026-11-12)
- Added first-run and on-demand native Scan & Setup Guide, per-source method, status, timestamps/reasons, steps and nonautomated retry actions.
- Added isolated versioned local `GoldWiseGuideDB` preferences for completion, resume step and skip flags; `GoldWiseDB` unchanged.
- Added offline readiness and corruption tests. **Pending:** actual Lua 5.1/CI outcomes, real Forever UI and persistence QA, parent PR integration and owner release approval. NOT PRODUCTION READY.

# Changelog

## Unreleased
- 2026-11-11: Added session reagent reservations for competing recipe plans in `0.2.0-test2`.
- 2026-11-11: Added the GoldWise native dashboard, session reagent planning, and base vendor references in `0.2.0-test1`. The combined client test is pending.
- 2026-11-11: Added bounded reagent plans for learned recipes with fixed output and supported item reagents.
- 2026-11-11: Added Forever build `70888` as a target for the disposable GW-013 trainer probe. The owner verified one selected trainer requirement and its matching recipe on that build.
- 2026-11-09: Added a disposable GW-013 probe for a selected trainer service's skill requirement and candidate recipe identity. Live verification is pending.
- 2026-11-09: Added GW-021 manual balance sampling and categorization in GoldWise `0.1.6-dev`. The owner confirmed the balance probe, an installed unclassified net change, and manual labeling and clearing on build `70862`.
- 2026-11-09: Split GW-023 offline regression checks into Lua and shell syntax, unit, and adapter contract jobs. Documented fixture and manual verification requirements.
- 2026-11-09: Added the GW-013 offline recipe catalog for verified local profession snapshots. Trainer requirements remain unavailable pending live evidence.
- 2026-11-09: Audited recipe and market sources for GW-003. Documented verified local observations, external dataset exclusions, and fallback rules.
- 2026-11-09: Added the GW-011 offline history model for bounded, market-scoped observations with explicit staleness. Live persistence is blocked pending verification of the active Forever market ID.
- 2026-11-09: Added GW-010 manual Auction House browse-cache observation. The owner confirmed the installed addon returned correct data on build `70862`. Addon-originated queries remain blocked.
- 2026-11-09: Added GW-009 manual profession capture. The owner confirmed the installed addon matched the open crafting window on build `70862`.
- 2026-11-09: Added GW-008 manual carried-bag capture. The owner confirmed the installed addon matched the disposable probe's complete six-bag read and sample counts on build `70862`.
- 2026-11-09: Added the GW-007 character snapshot model and capture adapter. The owner confirmed GoldWise captured character context on login and `/reload` on build `70862`.
- 2026-11-09: Added the GW-006 Lua 5.1 test runner, shared Forever client fixture, and GitHub Actions smoke workflow.
- 2026-11-09: Added GW-005 schema v1 and the `GoldWiseDB` adapter. The owner verified initialization and restoration after reload, character-selection relog, and full restart on build `70862`.
- 2026-11-09: Added the GW-004 startup smoke test. The owner verified startup on login and `/reload` on Forever build `70862`. All gameplay features remain disabled.
- 2026-11-09: Recorded the GW-001 live build probe on Forever `1.60.1`, build `70862`, interface `16001`. Addon loading and persistence still require separate live checks.
- 2026-11-09: Planning foundation, proposed architecture, API evidence register, compliance guardrails, story backlog and Codex workflow. No addon code shipped.
