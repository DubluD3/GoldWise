# GoldWise

GoldWise is a planned **free, open-source, local-first, read-only economic and profession advisor** for World of Warcraft: Forever.

> **Status: development smoke test.** This build checks the client, opens versioned local storage, captures character context, and supports a manual carried-bag scan on build `70862`.

## Test the startup build

1. Close WoW: Forever. Open the Forever installation folder from Battle.net.
2. In its `Interface/AddOns` folder, create a folder named `GoldWise`. Copy `GoldWise.toc`, `adapters`, and `data` into `GoldWise`, or extract the GW-008 product ZIP into `Interface/AddOns`. The manifest should be directly at `Interface/AddOns/GoldWise/GoldWise.toc`.
3. Start Forever, enable GoldWise in the AddOns list, and log in. On build `70862` the expected startup message begins `GoldWise 0.1.3-dev: loaded on Forever build 70862`. A fresh install prints `GoldWise local storage created (schema 1).` A previously initialized install prints `GoldWise local storage current (schema 1).`
4. Look for `GoldWise character snapshot ready.` on login and after `/reload`. If you have another character available, look for the same status when you log in on it. Report the status messages and any Lua error. The snapshot stays in memory for the session.
5. Open your bags and run `/run GoldWiseInventoryScan()`. Compare the sample stack and carried total with the visible bags. A complete read reports `bags=complete, bank=unobserved, alts=unobserved`. A partial read labels the sample total as observed. Run the command again after bag changes to take a new observation.

Disable GoldWise in the AddOns list or remove its addon folder to undo the install. Leave the client-managed SavedVariables file in place if you want to keep the local schema.

The separate [GW-005 storage probe](docs/development/STORAGE_PROBE.md) tests client persistence with a disposable marker.

## Run the offline checks

With Lua 5.1 installed, run `sh scripts/test.sh`. Set `GOLDWISE_LUA` to an absolute path if your interpreter is named differently. [Test strategy](docs/development/TEST_STRATEGY.md)

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
