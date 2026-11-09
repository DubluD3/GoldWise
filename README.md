# GoldWise

GoldWise is a planned **free, open-source, local-first, read-only economic and profession advisor** for World of Warcraft: Forever.

> **Status: development smoke test.** This build checks the client build and displays startup status. Gameplay features are disabled while their APIs are being validated.

## Test the startup build

1. Close WoW: Forever. Open the Forever installation folder from Battle.net.
2. In its `Interface/AddOns` folder, create a folder named `GoldWise`. Copy `GoldWise.toc` and the `adapters` directory into `GoldWise`. The manifest should be directly at `Interface/AddOns/GoldWise/GoldWise.toc`.
3. Start Forever, enable GoldWise in the AddOns list, and log in. On build `70862` the expected local message is `GoldWise 0.1.0-dev: loaded on Forever build 70862. Gameplay features disabled.` Run `/reload` and check for the same message once after the reload.
4. Record the build, whether GoldWise appeared in the AddOns list, the actual message, and any Lua error. If the client reports a different build, record that separately. The expected fallback on a build where the manifest still loads is `GoldWise 0.1.0-dev: client build unverified. Gameplay features disabled.`

Disable GoldWise in the AddOns list or remove its folder to undo the install. The smoke test uses no SavedVariables. From the repo root, run `lua5.1 tests/bootstrap.lua` with Lua 5.1 for the offline checks.

## Start here
- [Codex instructions](AGENTS.md)
- [Product vision and requirements](docs/product/PRODUCT.md)
- [Roadmap](docs/planning/ROADMAP.md)
- [Capability → feature → story backlog](docs/planning/BACKLOG.md)
- [Story execution workflow](docs/development/WORKFLOW.md)
- [API evidence register](docs/research/API_EVIDENCE.md)
- [Blizzard policy and compliance](docs/compliance/BLIZZARD_POLICY.md)
- [Architecture](docs/architecture/ARCHITECTURE.md)
- [Decisions](docs/architecture/ADR-0001-scope-and-boundaries.md)
- [Competition and differentiation](docs/research/COMPETITORS.md)

## Principles
1. Observational/advisory only: **no automated buying, posting, cancelling, bidding, movement or input simulation**.
2. Never invent Blizzard API signatures, game mechanics, recipe data or prices. Unverified claims are explicitly `UNVERIFIED`.
3. Work story-by-story with evidence, tests, and acceptance criteria.
4. All code and features free; no ads or donation solicitation in-game.
5. No accounts, telemetry, third-party transmission or companion process in MVP.

This project is unofficial and unaffiliated with Blizzard Entertainment.
