# GoldWise

GoldWise is a planned **free, open-source, local-first, read-only economic and profession advisor** for World of Warcraft: Forever.

> **Status: integrated test candidate.** Run `/goldwise` to open the native dashboard. The [integrated test guide](docs/development/INTEGRATED_TEST.md) covers the current build and manual feature flows.

## Goals and progression (GW-020 cumulative candidate)
`domain/Goals.lua` models player-selected gold and profession targets without predicting earnings or skill-up probabilities. The **My Goals** session panel and `/goldwise goal gold <copper>`, `/goldwise goal skill <level>` commands are implemented in the **unmerged QA candidate**, with observed-data and client-build guards. The targets have no persistent storage, and their installed WoW Forever UI behavior still requires owner QA.

## Offline cross-character gear checks (GW-027 foundation)
`domain/EquipmentAdvisor.lua` is a synthetic-test-only cross-character advisory model. It requires two fresh scoped character snapshots, verified binding/equipment/eligibility fields, and independent observed transfer-route evidence. If all match it says **potential upgrade — review**, never a factual or automatic upgrade. Current Forever equipment, binding and alt transfer APIs are **unverified**, so there is no live UI suggestion, gear capture, automatic mail or automatic equip.

## Offline item-alternative comparison (GW-018 foundation)
The `domain/ItemChoices.lua` module runs only on explicitly supplied, validated copper values and recipe inputs. It compares local vendor references against reserved-stock-aware crafting opportunities, and can describe hypothetical Auction House asking prices only when a future adapter supplies verified price basis, market scope, freshness and optionally fees. **No live AH economics or item advice is enabled**: the current client evidence does not support those claims. The 100-cloth scenarios are synthetic tests, not game data.

## Cumulative integrated candidate (not merged into main)
The [current integration checkpoint](docs/development/CURRENT_CHECKPOINT.md) documents the **20 stacked draft PRs #34 through #58** and the actual parent/base chain. The candidate includes the five-tab dashboard, manual scan guide, session reagent planning/reservations, read-only material and profession reviews, direct reagent capacity, and session goal controls. The [GW-026 Scan & Setup Guide](docs/development/SCAN_GUIDE_TEST.md) labels automatic character observation separately from manual bag/profession/AH/ledger observation and identifies unsupported bank/equipment/alt sources. The account-local `GoldWiseGuideDB` stores only completion/step/skip preferences; `GoldWiseDB` remains at schema 1. **The candidate is neither released nor verified in the installed game client.**

## Owner client verification and engineering handoff
The complete [Forever E2E checklist](docs/development/OWNER_E2E_QA.md) records **NOT RUN** until a human tests the installed client on the exact build. The [short owner smoke test](docs/development/INTEGRATED_TEST.md) covers current session goals, material review and reservation guards. The [engineering checkpoint](docs/development/CURRENT_CHECKPOINT.md) lists all 20 stacked draft PRs, blocked APIs, release rights and the next task. Select a QA candidate matching the **exact latest passing PR #58 head SHA**. Treat CI success as offline evidence only.

## QA candidate ZIP and release restrictions
From a checked-out branch with `zip` and `unzip`, run `sh scripts/package.sh candidate` to create a manifest-validated `dist/GoldWise-<version>-candidate.zip` with a single `GoldWise/` root for direct extraction into `Interface/AddOns/`. This is **only for owner testing** and includes a NOT-FOR-PUBLIC-RELEASE notice; do not publish it as a public addon release.

The repo intentionally has **no chosen LICENSE yet**. A public release requires an owner-approved open-source license, signed actual client QA and explicit release approval in `docs/release/OWNER_RELEASE_APPROVAL.md`, compatible non-test version, and an independently reviewed legal/compliance gate. `sh scripts/package.sh release` blocks while these are absent. [Release checklist](docs/planning/RELEASE_CHECKLIST.md) · [Privacy disclosure](PRIVACY.md).

## Test the startup build

1. Close WoW: Forever. Open the Forever installation folder from Battle.net.
2. In its `Interface/AddOns` folder, create a folder named `GoldWise`. Copy `GoldWise.toc`, `adapters`, `data`, and `domain` into `GoldWise`. The manifest should be directly at `Interface/AddOns/GoldWise/GoldWise.toc`.
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

### Session goals in the dashboard (GW-020 integration)
The **Goals** action from Overview or My Plan opens **My Goals**. After sampling balance or scanning your open profession, set a gold target **1 gold above the sampled balance** and/or a skill target **up to 10 levels above the sampled profession skill**, capped at the observed skill limit. Both are temporary, recalculated from matching fresh observations, and can be cleared. This is not a gold-income forecast or an automated plan. All goals reset on addon reload. The native client integration still requires owner QA.

### Carried-material retention review (GW-018)
Choose **Inventory → Review materials** after manually scanning complete bags. The page shows per-item carried quantity, amounts held by the current reagent plan/reservations and remaining units requiring **manual review, not permission to sell**. Bank, alts, future crafting needs, market prices and demand remain unknown. Missing or stale inventory disables quantities. No automatic scan, AH query or inventory movement occurs.

### Exact session goal targets via chat
Alongside the quick +1g and +10-skill dashboard actions, you can specify custom targets: `/goldwise goal gold 25000` (explicit **copper**, never gold) and `/goldwise goal skill 75` (requires a fresh manual scan of the open matching profession and must fit its observed cap). `/goldwise goal help` shows usage; `/goldwise goal clear` clears both. These commands never execute game actions, read AH data, or persist goals. You must sample character balance manually to see current gold progress.

### Profession progression review (GW-020)
In **My Plan → Review progression**, GoldWise shows your manually observed profession skill/cap, observed learned-recipe count and coverage, any matching skill goal gap, and carried reagent shortages for the currently planned recipe. The recipe snapshot is tagged to the profession it was actually planned under, so another profession's plan is not misattributed. A recipe can require multiple crafts to earn a skill point—or none—so the addon **never predicts how many crafts to level**. Missing or stale evidence stays unknown. No new API calls or automatic crafting.

### Direct-reagent capacity (GW-014)
After a manual fixed-output recipe plan, choose **My Plan → Direct capacity** to review how many *direct reagent sets* are covered by fresh observed carried bags. This only counts the recorded recipe's immediate fixed reagents, excludes stock held for other recipes and does not double count its own reservation. It does **not** account for nested crafts, bank, other characters, item quality, fees, actual crafting eligibility or profession skill-up odds. No crafting action is executed.

### Recipe producer cache isolation (GW-014)
Nested reagent plans use only schematics captured during the **same manual profession scan**, for the same character and client build. Switching professions, rescanning a profession, switching characters, or changing a verified build invalidates the temporary producer cache. The dashboard also stops showing a plan if its creating profession scan is no longer current. Refresh your profession scan, bags and recipe plan after changing context. No background scanning or cross-character crafting is assumed.

### Reservation safety (GW-017)
A session plan can only reserve carried materials while it is still the **active plan**, the same complete inventory snapshot, the **exact profession scan** that created it, the same character and verified client build, and all observations are fresh (15 minutes). Expired or superseded plans are rejected without changing reservations. Clear or recalculate plans after a scan, relog or client patch. No items are moved or crafted.

### Defensive reservation integrity
Before an in-session material hold is created or replaced, GoldWise validates **all** existing holds against the complete observed carried bag stock. Invalid allocations, impossible held quantities and unknown item IDs are rejected without changing the existing session map. Reservation changes do not move or sell items and never imply that remaining stock is safe to sell.

### Safe inventory availability reads (GW-017)
The Inventory tab and manual reagent planner use a validated carried-stock calculation. If any session reservation is impossible, malformed or refers to an unobserved item, GoldWise refuses to show misleading remaining quantities or create a new recipe plan. Even a reservation for the currently selected recipe is validated before it is excluded from its own availability calculation. Rescan complete bags or clear the invalid session holds; no automatic inventory action is performed.

### Native profession companion (GW-028; draft, game verification pending)
When a supported crafting window is **already open** and the player manually scans the profession, GoldWise attempts to add an optional **GoldWise** button as a child of the game's existing `ProfessionsFrame`. Clicking it toggles a nearby read-only summary showing the exact observed skill and count of learned recipes in the filtered view; **Open GoldWise** navigates to the existing Professions dashboard. **Hide** closes only the companion. The companion does not trigger new reads, hooks, timers, auctions, crafting, or changes to Blizzard's controls. If the required frame or UI primitive is missing/restricted, it quietly leaves the dashboard usable. The exact placement and compatibility **remain unverified in the installed client**; the player can keep it hidden.

### Contextual plan information in the profession companion (GW-028 follow-up)
The optional profession sidecar now shows a **read-only summary of the current exact manual reagent plan** (including validated missing carried units), or explicitly says **Plan unavailable** when the plan is stale, mismatched, absent or malformed. It updates the display only on a successful manual profession scan or when the player opens the sidecar; it does not scan bags or professions in the background, start crafting, or infer bank/alt stock. This remains an **unmerged candidate** awaiting native UI placement and protected-frame QA on Forever.

### GW-029 in-frame recipe details (draft)
The optional profession companion now shows the current manually calculated **root recipe name and craft count**, and up to two sorted **missing carried item IDs and quantities**, with a count of additional missing item types. This remains conservative: it does not claim item availability from bank/alts, success probability, or the selected native recipe, and does not modify protected controls. Only a fresh plan bound to the same exact profession scan, complete carried inventory, character and build can appear. Panel size/position and taint are pending real client QA; the full dashboard remains the fallback.

### GW-030 optional carried-bag companion (draft)
After an explicit manual bag scan, GoldWise may offer a **GoldWise Bags** button on an already visible, readable `ContainerFrame1` (a **candidate** native frame, not yet verified on the supported Forever build). Its player-toggled side panel summarizes only fresh, complete, character-scoped carried inventory, with three item IDs/quantities maximum and no sell advice. No auto-scans or native inventory interactions. A missing frame or other invalid conditions leave the existing standalone inventory dashboard as the fallback. In-game positioning/protected UI safety **NOT RUN**.

### GW-031 optional native Auction House observation (draft)
After the player manually arms a browse observation, performs one native Auction House search and explicitly reads back the cache, GoldWise may add a **GoldWise Market** button to the already visible Auction House window. The player-toggled companion displays up to three validated cache rows and labels all amounts as **minimum asking prices in copper**, not confirmed revenue, profit or per-unit rates. No addon-originated searches, refreshes, purchases or postings. The native panel is optional, not yet tested for placement/taint on a live Forever client; the standalone Market page remains the fallback.

### GW-032 shared presentation foundation (draft)
Profession, carried-bag and market companions now share a consistent small set of dark/gold-toned button, label and panel primitives. This removes duplicated style definitions without adding automatic UI hooks or modifying protected Blizzard controls. The visual fit and actual frame positions remain unverified in the client and are release-blocking QA items; use the standalone dashboard if a native companion cannot attach.

### GW-033 responsive companion placement (draft)
The three native context panels now calculate a screen-bounded side placement from their native parent and UIParent geometry, flip when needed and abstain when frame bounds or effective scaling cannot be validated. They recheck placement on player reopening; unsupported positions leave the standalone dashboard available. **Live-client scaling, native visual overlap and protected-frame QA remain NOT RUN**.

### GW-034 native companion lifecycle safety (draft)
Contextual buttons are now created only after panel construction succeeds, hidden on observation invalidation and restored only when fresh scoped evidence can render successfully. Character context recapture invalidates all three companions. Unreadable native geometry fails closed to the independent dashboard. Real-client visibility, layout and protected action/taint verification remain mandatory.

### GW-035 guided recovery (draft)
The standalone dashboard now gives concise manual recovery steps for missing or stale inventory, profession, reagent plans and market observations. **Go to Professions** and **Go to Inventory** shortcuts change views only and never trigger game reads; the existing AH observation remains strictly one-shot and requires a fresh Blizzard search after reload. This improves usability while contextual native UI compatibility remains pending live game QA.
