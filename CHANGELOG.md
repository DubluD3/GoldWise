# Changelog

## Unreleased
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
