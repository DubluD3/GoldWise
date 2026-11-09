# GoldWise

GoldWise is a planned **free, open-source, local-first, read-only economic and profession advisor** for World of Warcraft: Forever.

> **Status: development smoke test.** This build checks the client build and opens versioned local storage on build `70862`. Gameplay features are disabled while their APIs are being validated.

## Test the startup build

1. Close WoW: Forever. Open the Forever installation folder from Battle.net.
2. In its `Interface/AddOns` folder, create a folder named `GoldWise`. Copy `GoldWise.toc`, `adapters`, and `data` into `GoldWise`, or extract the GW-005 product ZIP into `Interface/AddOns`. The manifest should be directly at `Interface/AddOns/GoldWise/GoldWise.toc`.
3. Start Forever, enable GoldWise in the AddOns list, and log in. On build `70862` the expected startup message begins `GoldWise 0.1.1-dev: loaded on Forever build 70862`. A fresh install then prints `GoldWise local storage created (schema 1).`
4. Run `/reload`, log out to character selection and back in, then quit normally and fully reopen WoW. At each load, look for `GoldWise local storage current (schema 1).` Report the build, actual messages, and any Lua error.

Disable GoldWise in the AddOns list or remove its addon folder to undo the install. Leave the client-managed SavedVariables file in place if you want to keep the local schema. From the repo root, run `lua5.1 tests/bootstrap.lua` and `lua5.1 tests/saved_variables.lua` for the offline checks.

The separate [GW-005 storage probe](docs/development/STORAGE_PROBE.md) tests client persistence with a disposable marker.

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
