# GoldWise — integrated owner smoke test (QA candidate only)

**Updated 2026-11-12 · Live Forever client QA: NOT RUN.** This is the short, end-to-end **human** walkthrough of the cumulative draft PR #58. The authoritative full acceptance and release gate remains [OWNER_E2E_QA.md](OWNER_E2E_QA.md), cases E01–E20. Offline CI success does not prove any of these live checks.

## A. Choose the exact current candidate

1. Open [PR #58](https://github.com/DubluD3/GoldWise/pull/58), record its **full current head SHA**, and select its latest **successful** Lua regression Actions run **on that same SHA**. The current head may change after this document. Do not install an artifact merely because an older workflow says PASS.
2. Download the `GoldWise-QA-candidate-<SHA>` GitHub Actions artifact. This is an outer ZIP holding an **inner** `GoldWise-0.2.0-test2-candidate.zip`. Extract the **inner ZIP** so `Interface/AddOns/GoldWise/GoldWise.toc` is the final path, not `GoldWise/GoldWise/GoldWise.toc`.
3. **Fully exit WoW**, back up the existing GoldWise addon and its two SavedVariables files/entries (do not share them), disable disposable GoldWise probes, then install. Verify the current Forever version/build/interface using `/run local v,b,d,i=GetBuildInfo();print(v,b,d,i)`. Only `1.60.1` build `70862` or `70888`, interface `16001`, is allowlisted. If patched, **STOP** rather than bypassing the guard.
4. Run `/console scriptErrors 1`, `/reload`, `/goldwise`. Record OS, resolution, UI scale, other addons, current SHA and errors.

## B. Test player-controlled observations and navigation

1. **Quick test (new):** After exiting the first-run guide, choose **Overview → Quick test**. It lists bags, profession, balance and reagent plan as observed or pending. Use **Scan bags**, **Scan profession** (with native crafting view open), **Sample balance**, **Choose recipe**, **My Plan**, and **Back to Overview**. A scan that fails or becomes stale must not be marked complete. This screen is an in-session QA aid, not a claim of gameplay validation.
2. **Guide:** On first run, complete or skip steps. Reopen using `/goldwise guide`; confirm Pending / Partial / Stale states, manual vs automatic labels and Unsupported equipment, bank, alt sources. Completion does not mean scans succeeded.
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

## UI navigation clarity (2026-11-12; live verification pending)

- [ ] The selected top-level tab has a gold label and visually distinct darker-gold background. Switching from Overview to Inventory, Professions, Market and My Plan updates the selection without moving or acting on game items.
- [ ] Contextual action slot 1 is visually emphasized; other actions remain readable and clickable.
- [ ] Inventory pager reads **Previous item / Next item**, the profession recipe pager reads **Previous recipe / Next recipe**, and long review/market/plan lists use **Previous page / Next page**. Hidden pager buttons must not intercept clicks. Test at 100% and smaller game UI scale.
- [ ] **Overview → Quick test** still works, and its manual actions retain the expected observations. Verify on the actual WoW Forever build; the Lua fixture only validates widget properties and commands.

## D. Safety, persistence and acceptance

1. Check normal combat, mouse input, Blizzard UI coexistence, at least one existing AH addon if installed, and lack of protected-action taint. Check performance/FPS for noticeable regression; do not claim a benchmark without measurements.
2. After `/reload` and full restart, verify only bounded **local guide preferences and storage metadata** persist; session recipes, goals, inventory/AH observations, reservations and money ledger do not become current by magic. Re-login as another character and check scope isolation.
3. Inspect addon folder and privacy disclosures for no account/network/telemetry/auto-play. If anything attempts automated AH searches, crafting, mail, equip, or protected actions, **STOP**.
4. Record results in [E01–E20](OWNER_E2E_QA.md) with PASS / FAIL / BLOCKED / NOT RUN and **sanitized** screenshots or exact error strings, not raw SavedVariables or character names. On any error, fully close game, restore the backed-up addon and leave unrelated SavedVariables untouched.

**Release is explicitly BLOCKED.** No approved LICENSE, no signed owner in-client QA, and no integrated merge/release authorization. The candidate ZIP is private-owner QA only. Do not equate a green CI badge with production readiness.

## GW-028 contextual profession companion — real-client QA NOT RUN
- [ ] On a verified build with the **native crafting profession panel open**, manually choose **Scan profession** in GoldWise. Find the optional **GoldWise** button attached to that profession frame. If it overlaps native controls or is offscreen, report resolution/UI scale and a sanitized screenshot; do not mark it PASS.
- [ ] Click GoldWise to reveal the adjacent summary. Verify it shows the observed profession, skill/cap and **filtered** learned-recipe count, not fabricated up-to-date information.
- [ ] **Open GoldWise** must show the existing Professions dashboard; **Hide** must dismiss just the companion. Confirm native profession controls still function and the game produces no protected-action or taint errors, including in combat.
- [ ] A failed or changed manual scan must dismiss stale companion details. Closing the native panel should hide its child controls. No automatic scan, polling, AH query, crafting or item movement may occur.
- [ ] If the profession frame or widget API is unavailable/restricted, the addon must gracefully leave the standalone `/goldwise` dashboard usable. Record real build/interface and test status; currently **NOT RUN**.

## GW-028 current plan status in the profession companion — NOT RUN in client
- [ ] Open the existing native crafting window and manually scan that profession. Open **GoldWise** in its companion. Before planning, it must show **Plan: unavailable** rather than pretending materials are known.
- [ ] Manually scan complete bags and plan a current fixed-output recipe using the GoldWise dashboard. Reopen the companion via its GoldWise toggle: it should display the currently computed **missing carried units / item count** (or no observed shortages) without a new scan or craft.
- [ ] Rescan the same profession, refresh bags, switch characters, or let observations expire. The previously displayed plan must no longer appear current. If the frame is restricted/unavailable, retain standalone `/goldwise` fallback.
- [ ] Check panel positioning at normal and reduced scale, ensure no native control is blocked, and watch for Lua/taint errors. CI covers scoped numeric states but **actual native game test remains NOT RUN**.

## GW-029 itemized recipe panel — real-client QA NOT RUN
- [ ] Scan current bags and crafting profession; choose a learned recipe in GoldWise, set craft count, and explicitly plan its reagents. Open the attached profession companion and confirm it shows the **same recipe name, planned craft count and no more than two missing carried reagent item IDs/quantities**. If more than two different items are missing, the panel must show an additional-item count.
- [ ] Verify a different recipe, changed bag scan, changed profession scan, expiration, and character switch do not present the old plan as current. The sidecar must not infer item names, bank or alt inventory, or claim that crafting is executable.
- [ ] Check the 288x288 adjacent panel on the actual Forever client at multiple window placements and UI scales, including when the profession window is near the right screen edge. It must not cover native buttons, clip or interfere with protected controls. **NOT RUN**; record screenshots and any taint or Lua errors before approval.

## GW-030 optional bag-frame companion — live client NOT RUN
- [ ] On exact supported Forever build, open the ordinary bag UI. Manually choose **Scan bags** from GoldWise. Only if the `ContainerFrame1` candidate exists and is visible should an optional **GoldWise Bags** button appear.
- [ ] Click the button to show **GoldWise | Carried Bags**. Confirm total unit count, number of item types and at most three sorted item IDs against actual *carried* bag contents. Bank/mail/alts must say unknown. Click **Inventory** to enter GoldWise's existing independent Inventory dashboard; **Hide** must dismiss only the small companion.
- [ ] Refresh manual bag scan, close/reopen the bag frame, let data expire, and switch characters. Stale/partial/wrong-character information must never be presented as complete. A missing/restricted frame must leave `/goldwise` usable with no Lua error.
- [ ] At typical and small UI scales, inspect whether the optional controls overlap the native bag slots, tooltips, chat or other panels, and test combat for protected-action or taint warnings. There is **no validated live ContainerFrame1 evidence** yet; a non-attaching companion is not a failure of the existing standalone inventory UI. Record build/UI scale and screenshots before claiming support.

## GW-031 contextual AH browse companion — real-client QA NOT RUN
- [ ] Open the native Auction House browse tab and explicitly start GoldWise's existing **Observe browse** two-stage workflow. Perform a search **using Blizzard's normal Search button**. Read the result cache once using GoldWise's manual action. No GoldWise button should create or repeat a search.
- [ ] If a visible and readable AuctionHouseFrame/BrowseResultsFrame exists, confirm **GoldWise Market** appears. Clicking it should show at most three previously observed cache rows (item ID, minimum asking price in copper, reported quantity) with strong disclosures: not sales, fees, profit or per-unit price. Click **Market details** to navigate to the standalone GoldWise Market tab, and **Hide** to dismiss the companion.
- [ ] Confirm partial results are labeled partial, stale/wrong-character/corrupt data are not presented as current, and missing/restricted native AH UI does not break the existing dashboard.
- [ ] Test at different UI scales, window positions, client build, in and out of combat. Inspect overlap with Blizzard's Buy/Post UI and protected-action errors. Native attachment is **NOT RUN/UNVERIFIED** until owner reports actual game evidence.

## GW-032 shared companion chrome — in-game verification NOT RUN
- [ ] Compare profession, inventory and market companions side-by-side at multiple UI scales: gold-toned titles and control labels, dark panel background, consistent control height, readable details, and no clipping.
- [ ] Verify toggling each panel cannot accidentally click Blizzard's underlying native buttons. Report screenshots, UI scale, layout and protected-action errors if any. These native placement behaviors are **not validated** by the offline widget fixture.
- [ ] Confirm all three context panels still navigate to the correct standalone GoldWise tab and that missing native frames never crash or hide the dashboard. Verify the candidate ZIP includes `ui/CompanionChrome.lua`.

## GW-033 responsive contextual positioning — real-client verification NOT RUN
- [ ] On Forever 70862/70888, position each native profession, bags and Auction House window near the left and right display edges. The companion should open on a side with sufficient space; if neither side fits, it must gracefully abstain rather than overlap or appear outside the screen.
- [ ] Verify top/bottom edge layout at small UI scales and at multiple resolutions. Move the native frame after an observation and reopen its GoldWise side panel to verify placement refresh. A missing geometry API or unequal frame/UIParent scale must fall back to the standalone GoldWise dashboard without Lua errors.
- [ ] Confirm no new hooks, protected Blizzard control changes, automatic bag/AH/profession reads or combat taint; inspect screenshots for incidental overlap. Geometry fixture tests alone do not verify real game layout. Do not approve for release until real UI evidence exists.

## GW-034 companion lifecycle and unavailable evidence — real-client QA NOT RUN
- [ ] Open each contextual GoldWise panel after a fresh explicit observation. Verify button/panel open normally. Make its underlying observation unavailable by closing/hiding the native view or failing a fresh manual scan: no stale GoldWise entry point should be presented as usable after invalidation.
- [ ] Repeat a valid manual scan and confirm the entry point returns once (without duplicate native buttons). Repeat invalid/valid cycles and switch characters or reload: old observations must not reappear.
- [ ] If the native frame changes, has restricted geometry or becomes unsupported, the companion must refuse to attach without a Lua error and must retain the standalone `/goldwise` dashboard.
- [ ] Verify UI scale, combat taint, protected buttons and actual frame hierarchy. Offline regression coverage is NOT evidence of installed-client compatibility.
