# GoldWise — integrated owner smoke test (QA candidate only)

**Updated 2026-11-12 · Live Forever client QA: NOT RUN.** This is the short, end-to-end **human** walkthrough of the cumulative draft PR #58. The authoritative full acceptance and release gate remains [OWNER_E2E_QA.md](OWNER_E2E_QA.md), cases E01–E20. Offline CI success does not prove any of these live checks.

## A. Choose the exact current candidate

1. Open [PR #58](https://github.com/DubluD3/GoldWise/pull/58), record its **full current head SHA**, and select its latest **successful** Lua regression Actions run **on that same SHA**. The current head may change after this document. Do not install an artifact merely because an older workflow says PASS.
2. Download the `GoldWise-QA-candidate-<SHA>` GitHub Actions artifact. This is an outer ZIP holding an **inner** `GoldWise-0.2.0-test2-candidate.zip`. Extract the **inner ZIP** so `Interface/AddOns/GoldWise/GoldWise.toc` is the final path, not `GoldWise/GoldWise/GoldWise.toc`.
3. **Fully exit WoW**, back up the existing GoldWise addon and its two SavedVariables files/entries (do not share them), disable disposable GoldWise probes, then install. Verify the current Forever version/build/interface using `/run local v,b,d,i=GetBuildInfo();print(v,b,d,i)`. Only `1.60.1` build `70862` or `70888`, interface `16001`, is allowlisted. If patched, **STOP** rather than bypassing the guard.
4. Run `/console scriptErrors 1`, `/reload`, `/goldwise`. Record OS, resolution, UI scale, other addons, current SHA and errors.

## B. Test player-controlled observations and navigation

1. **Guide:** On first run, complete or skip steps. Reopen using `/goldwise guide`; confirm Pending / Partial / Stale states, manual vs automatic labels and Unsupported equipment, bank, alt sources. Completion does not mean scans succeeded.
2. **Dashboard:** Open Overview, Inventory, Professions, Market and My Plan. Close/reopen `/goldwise`; check native UI placement, text and navigation at 100% and a smaller usable scale. Do not expect automated buying/crafting/mailing.
3. **Inventory:** Click **Scan bags** and compare totals with native bags. Select a stack, use **Check vendor value** only if readable. Open **Review materials**: carried/held/manual-review amounts are informational, **never permission to sell**.
4. **Ledger:** Outside trade and with no money on cursor, choose **Sample balance**; sample again after at least a second. Verify signed unclassified changes and reversible user labels, no fabricated sales.
5. **Professions:** Open a normal player crafting window and click **Scan profession**. Compare skill, cap and learned **filtered** recipe rows. No complete recipe catalog is implied. Trainer matching is offered on verified build `70888` only; it must abstain when the requirement is not observed.
6. **AH browse:** At the native Auctioneer Buy view, choose **Observe browse** in GoldWise, manually trigger one Blizzard search, then reopen GoldWise and observe within 60 seconds. Compare cache labels and visible asking price. There must be no addon-initiated auction query, sale proceeds, fees or forecast. Abort on throttle/error.

## C. Reagent, reservation, goal and review integration

1. Scan **complete bags** and the open profession. Pick a learned fixed-output recipe, optionally choose **More crafts**, then **Plan reagents**. Compare missing inputs, nested crafting steps and item names against source observations. Unsupported schematics must abstain rather than invent ingredients.
2. In **My Plan → Direct capacity**, compare the observed immediate reagent sets. This is **not** guaranteed craftability or skill gain; nested crafts and bank/alts are excluded.
3. In **My Plan → Review progression**, confirm observed skill/cap, filtered learned-recipe count and any selected skill target remaining. No skill-up probability or crafts-per-level estimate is allowed.
4. Choose **Reserve carried reagents**. Check Inventory's held count and **Review materials**. Plan a second recipe sharing reagents; verify no double allocation. Re-plan the same recipe and confirm its own prior hold is not double-subtracted. **Clear reservations** returns the in-memory holds to zero.
5. Test **Goals** from Overview/My Plan and **My Goals**: use **Gold +1g**, **Skill +10**, `/goldwise goal gold 25000` (**copper**), `/goldwise goal skill 75` (only with a fresh profession scan), `/goldwise goal help` and `/goldwise goal clear`. Without manual balance observation, progress should be **unknown**, not a guessed zero/completion.
6. **Invalidation:** After creating a plan, manually rescan the **same profession**. The old plan must disappear from My Plan; the guide's **Recipe plans and reservations** step must be **Pending**, not current. An obsolete plan must not reserve. Repeat after rescanning bags, changing characters, reloading, and after the 15-minute freshness window. Do not force live in-memory corruption; CI covers malformed holds in synthetic tests.

## D. Safety, persistence and acceptance

1. Check normal combat, mouse input, Blizzard UI coexistence, at least one existing AH addon if installed, and lack of protected-action taint. Check performance/FPS for noticeable regression; do not claim a benchmark without measurements.
2. After `/reload` and full restart, verify only bounded **local guide preferences and storage metadata** persist; session recipes, goals, inventory/AH observations, reservations and money ledger do not become current by magic. Re-login as another character and check scope isolation.
3. Inspect addon folder and privacy disclosures for no account/network/telemetry/auto-play. If anything attempts automated AH searches, crafting, mail, equip, or protected actions, **STOP**.
4. Record results in [E01–E20](OWNER_E2E_QA.md) with PASS / FAIL / BLOCKED / NOT RUN and **sanitized** screenshots or exact error strings, not raw SavedVariables or character names. On any error, fully close game, restore the backed-up addon and leave unrelated SavedVariables untouched.

**Release is explicitly BLOCKED.** No approved LICENSE, no signed owner in-client QA, and no integrated merge/release authorization. The candidate ZIP is private-owner QA only. Do not equate a green CI badge with production readiness.
