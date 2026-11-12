# GoldWise

GoldWise is a planned **free, open-source, local-first, read-only economic and profession advisor** for World of Warcraft: Forever.

> **Status: integrated test candidate.** Run `/goldwise` to open the native dashboard. The [integrated test guide](docs/development/INTEGRATED_TEST.md) covers the current build and manual feature flows.

## Draft integrated guide (not merged into main)
The stacked draft PRs #34-#37 contain the five-tab dashboard and session reagent reservations. The follow-on [GW-026 Scan & Setup Guide](docs/development/SCAN_GUIDE_TEST.md) adds a first-run wizard, Guide button and `/goldwise guide`. The guide labels automatic character observation separately from manual bags/professions/AH/ledger, and marks unsupported bank/equipment/alt sources honestly. The new account-local `GoldWiseGuideDB` stores only completion/step/skip preferences; existing `GoldWiseDB` is unchanged. **This is a test candidate, not a released or live-verified implementation.**

## Test the startup build

1. Close WoW: Forever. Open the Forever installation folder from Battle.net.
2. In its `Interface/AddOns` folder, create a folder named `GoldWise`. Copy `GoldWise.toc`, `adapters`, and `data` into `GoldWise`. The manifest should be directly at `Interface/AddOns/GoldWise/GoldWise.toc`.
3. Start Forever, enable GoldWise in the AddOns list, and log in. The startup message identifies the verified client build. A fresh install prints `GoldWise local storage created (schema 1).` A previously initialized install prints `GoldWise local storage current (schema 1).`
4. Look for `GoldWise character snapshot ready.` on login and after `/reload`. If you have another character available, look for the same status when you log in on it. Report the status messages and any Lua error. The snapshot stays in memory for the session.
5. Open your bags and run `/run GoldWiseInventoryScan()`. Compare the sample stack and carried total with the visible bags. A complete read reports `bags=complete, bank=unobserved, alts=unobserved`. A partial read labels the sample total as observed. Run the command again after bag changes to take a new observation.
6. Open your own crafting window and run `/run GoldWiseProfessionScan()`. Compare the skill, cap, and learned sample with the window under its current filters. Close the window and repeat the command. It should report `crafting window unavailable`. The scan keeps the latest observation in memory and clears it on a failed refresh.
7. In the Auction House **Buy** browse view, run `/run GoldWiseAuctionObserve()`. After `armed, ready=yes`, perform one native Search. When the update and results appear, run the command again within 60 seconds of arming. It reports the source, row coverage, and a browse-minimum sample if available. The observation stays in memory. Use `/reload` to start another observation. [Auction House verification](docs/development/AUCTION_PROBE.md)
8. Outside trade and with no coins on the cursor, run `/run GoldWiseLedgerSample()` to record a baseline. Repeat at least one second later to observe a balance change or an unchanged status. [Ledger verification](docs/development/MONEY_PROBE.md#installed-addon-check)

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
