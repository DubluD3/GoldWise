# GW-024 · Owner Forever end-to-end test and release gate

**Prepared 2026-11-12. In-game status: NOT RUN.** An AI-only Lua test is not evidence that the installed addon works or complies on your client. The following is a reproducible owner test for the latest stacked QA candidate. Record exact build/interface and report **PASS, FAIL, BLOCKED or NOT RUN** per case.

## Prerequisites and installation
1. On GitHub, open [latest candidate CI run](https://github.com/DubluD3/GoldWise/actions/runs/43194083422), download the **GoldWise-QA-candidate** workflow artifact (a ZIP containing an inner `GoldWise-0.2.0-test2-candidate.zip`). This is an owner's test artifact, not a public release.
2. Exit WoW: Forever fully. In Battle.net use game settings → **Show in Explorer/Finder**, navigate to the game installation's actual `Interface/AddOns/` folder. Extract the **inner ZIP** there. Final path must be `<actual Forever installation>/Interface/AddOns/GoldWise/GoldWise.toc`. If `GoldWise/GoldWise/GoldWise.toc` appears, move the inner folder up one level.
3. Back up any existing GoldWise addon folder and any prior GoldWise SavedVariables under the relevant `WTF/Account/.../SavedVariables/` directory **before** replacing files. Do not copy SavedVariables into an issue or PR report. Disable disposable GoldWise probe addons to avoid interleaved messages.
4. Start Forever. Confirm GoldWise is enabled in the AddOns list. Open chat and record the output of:

```text
/run local v,b,d,i=GetBuildInfo();print("GoldWise test build",v,b,d,i)
/console scriptErrors 1
/reload
/goldwise
```

**Expected:** only the specifically allowlisted `1.60.1` builds `70862`/`70888` with interface `16001` can open the dashboard. Other builds must fail closed. If the game has patched to a different build, stop compatibility QA: do not bypass the allowlist. Collect an updated client API probe and verify the build before modifying it.

## Live test matrix

| ID | Test, steps and expected result | Status |
|---|---|---|
| E01 | Fresh guide: first `/goldwise` on new guide preferences shows Scan & Setup Guide and states data is local, no account/uploads, no gameplay actions; character identity observed from login when supported | NOT RUN |
| E02 | Guide: Next/Previous/Skip; skipped shows **not observed**, remains reachable; Exit and reopen with Guide top button or `/goldwise guide`; Finish then `/reload` and reopen. Guide preferences persist but source scans do **not** become complete | NOT RUN |
| E03 | Five tabs: Overview / Inventory / Professions / Market / My Plan all open, close and reopen via `/goldwise`. No UI element pretends to auto-buy, craft or mail. No invented currency, recipe, prices, profit or market freshness | NOT RUN |
| E04 | Inventory: with bags visible click Scan bags; compare carried item count and selected stack to native bag UI. Change a stack then rescan; expect updated count. Empty/read-restricted bags show empty/partial/unknown, bank/alt always unobserved | NOT RUN |
| E05 | Professions: scan when panel closed (unavailable). Open your own crafting panel, scan; verify skill/cap and learned rows with in-game UI. Filtered list must stay partial; unlearned recipes must not be asserted. Unsupported schematic must fail safely | NOT RUN |
| E06 | Recipe plan: choose a verified fixed-yield learned recipe with ordinary reagents, Plan reagents and verify missing/craft steps against bag amounts. Increase craft count and recalculate. Reserve carried reagents; second recipe sharing input must not double-count; clear restores available stock | NOT RUN |
| E07 | Trainer on build 70888 only: select trainer recipe, Read trainer, open matching crafting panel within five minutes, Match recipe, verify requirement. On 70862 or unsupported view expected unavailable; no fabricated trainer facts | NOT RUN |
| E08 | AH normal: Visit Auctioneer → Buy → open GoldWise Market → Observe browse to arm → perform **one native** Search → return to GoldWise and Observe browse within 60 seconds. Expected read-only cache rows, source, partial/stale state, ask not sale proceeds; no addon-initiated search or repeat storm | NOT RUN |
| E09 | AH failure: close AH before re-observation; also try unreadable results and a naturally throttled/unready state if encountered (do not force a throttle). Expect cancellation/unknown, no crash, no hidden polling or retry. Reopening AH does not assert previously cached results are live | NOT RUN |
| E10 | Ledger: outside trade with no coins on cursor, Sample balance, repeat after at least 1 sec and make a legitimate gold change if desired. Changes are signed **unclassified**, manual Label other/Clear label are reversible, never marked confirmed AH sales by default | NOT RUN |
| E11 | Alt and scope: log out, log into a *different* character, run `/goldwise`; source inventory/profession/AH/ledger from previous character must not appear current. Local guide preferences may remain account-wide. No last-known alt gear claims until separately verified | NOT RUN |
| E12 | Reload/restart: finish guide, Skip a step, `/reload` and a full game restart. Verify guide preference persistence, original schema 1 storage preserved, session scans/ledger/reservations not falsely persisted; no SavedVariables corruption or lost unrelated addon data | NOT RUN |
| E13 | Unsupported sources: equipment, bank, alts remain labeled Unsupported. `domain/EquipmentAdvisor.lua` has no live UI/gear capture or transfer advice. There must be **no automatic equip, trade or mail** action | NOT RUN |
| E14 | Synthetic vs real economics: `tests/item_choices.lua` supplies **fictional 100 cloth** for testing DAG and numeric comparisons. Do not expect real Linen Cloth conversion, vendor/AH amounts or net profitability from the candidate. UI must not show that fictional test as live. Actual AH sale probability, fees, market scope remain unknown | NOT RUN |
| E15 | Visual: test 100% and a smaller UI scale, e.g. 80%, at your normal display and at 1280×720 if available. Verify buttons, guide navigation, scroll/text fit, no clipping and persistent recoverable close/open. Try keyboard navigation if client supports it; report unavailable focus access as a QA issue | NOT RUN |
| E16 | Combat: open/close GoldWise during normal combat without changing secure frames or blocking actions. Check Lua errors/taint, game UI responsiveness and protected Blizzard controls; stop if taint or protected action errors occur | NOT RUN |
| E17 | Interoperability: repeat critical flows with at least one installed AH addon (e.g. Auctionator) and any UI overhaul you normally use. No AH floods, addon errors, conflicts or misleading scan results | NOT RUN |
| E18 | Performance: compare baseline gameplay responsiveness/FPS against addon enabled after comparable actions. Watch for repeated OnUpdate processing, lag spikes, excessive chat prints, bag scanning overhead. Record build, display resolution, UI scale and any repeatable stutter, not unsupported benchmark claims | NOT RUN |
| E19 | Privacy and install: inspect installed folder and `GoldWiseDB`/`GoldWiseGuideDB` SavedVariables after full restart. Confirm only expected local records, no account tokens/email/chat, no outbound companion service, ads or donation UI; remove/disable GoldWise to confirm safe rollback | NOT RUN |
| E20 | Release: package filename, files and manifest verified by CI. **STOP** public release: no approved open-source `LICENSE`, no signed human QA and parent PR integration until addressed. Public publishing must remain blocked | BLOCKED |

## Offline CI (already performed, not in-client proof)
At commit `b79c22f79c3d05976e0795f851c1c25aa2aefe81`, the [GitHub Actions run](https://github.com/DubluD3/GoldWise/actions/runs/43194083422) passed actual Lua 5.1 syntax/unit/contract/all and QA candidate ZIP validation. Commands executed by the workflow:
```sh
sh scripts/test.sh syntax
sh scripts/test.sh unit
sh scripts/test.sh contract
sh scripts/test.sh all
sh scripts/package.sh candidate
```
Do not mark game tests PASS on the basis of CI. If head SHA changes, rerun all checks and update the evidence.

## Report form (copy/paste, sanitize character/account information)

```text
GoldWise commit:
Forever version/build/interface:
OS:
Resolution / UI scale:
Other addons enabled:
E01: NOT RUN
E02: NOT RUN
E03: NOT RUN
E04: NOT RUN
E05: NOT RUN
E06: NOT RUN
E07: NOT RUN
E08: NOT RUN
E09: NOT RUN
E10: NOT RUN
E11: NOT RUN
E12: NOT RUN
E13: NOT RUN
E14: NOT RUN
E15: NOT RUN
E16: NOT RUN
E17: NOT RUN
E18: NOT RUN
E19: NOT RUN
E20: BLOCKED
Errors/taint/stutter (sanitized):
Owner approval: PENDING
```

## Rollback / red flags
**STOP** when a Lua error, protected UI taint, unintended auction query, unexpectedly deleted SavedVariables, cross-character data leak, or unverified client build appears. Fully exit game, restore backed-up `Interface/AddOns/GoldWise`, and retain backed-up SavedVariables. Re-enable old addon only on a build it previously supported. Do not remove whole `WTF` or touch another addon's SavedVariables. Report only sanitized outputs.

Any blocker that needs new game API must be recorded as `UNKNOWN`/`BLOCKED-API-VERIFICATION` with exact client version, extracted source reference and owner confirmation before implementation. **The owner alone can sign off the game-client and public release gates.**

## GW-020 My Goals additive checks (not yet run)
- [ ] After logging in on a verified build, open `/goldwise`, finish/exit the guide, choose **Goals** from Overview. Without a balance sample verify "No active goal", then choose **Gold +1g** and confirm it refuses with a manual-sample prompt.
- [ ] Return to Overview, choose **Sample balance** and revisit Goals. Choose **Gold +1g**; confirm the target is exactly **10,000 copper above the observed balance**, with no prediction of sales.
- [ ] Open your crafting profession, choose **Scan profession**, return to My Goals and choose **Skill +10**. Confirm target is limited by the observed cap, and gold target remains intact.
- [ ] Change/reload character, allow observations to expire, or switch to a different profession: stale/wrong-scoped targets must show **unknown** or reset, never a completed status. **Clear goals** must immediately remove all session targets.
- [ ] Reload the addon: targets must not persist; no unexpected saved data; no new automatic gameplay action or AH request. Record actual UI scale and client build. Status: **NOT RUN**.

## GW-018 Material Review additive checks (NOT RUN)
- [ ] Manually scan complete bags; Inventory > **Review materials** should show the actual carried totals, 0 held before planning and **no safe-to-sell labels**.
- [ ] Plan and reserve reagents; verify current recipe reservations are not counted twice and other recipe holds remain accounted for.
- [ ] Rescan bags, age the snapshot, switch character or reload; review values should refresh from observation or become unknown, not silently reuse old stock.
- [ ] No vendor/AH request, crafting or inventory action must occur merely from opening the review. Record client build and in-game UI errors. **NOT RUN**.

## GW-020 exact target commands (NOT RUN)
- [ ] With no manual balance observation, enter `/goldwise goal gold 25000`; My Goals should show Gold **unknown**, not zero or completed. Manually sample balance and verify the remaining copper.
- [ ] Enter `/goldwise goal skill 75` before an open-profession scan: expect an explanatory refusal. Scan a profession; choose an attainable target at/below the **observed skill cap**, then confirm it retains the gold target.
- [ ] Invalid inputs (`/goldwise goal gold -1`, `/goldwise goal skill 99999999`, `/goldwise goal gold 12g`) must not change the last valid targets. `/goldwise goal clear` clears them. `/goldwise goal help` displays the copper unit and commands.
- [ ] Repeated goal chat commands while My Goals is open should update the view rather than toggle it closed. Reload and confirm no target persists. **Installed Forever status: NOT RUN**.

## GW-020 Profession Review addendum (NOT RUN)
- [ ] Scan bags and your open profession, set a matching skill target, plan a recipe and choose **My Plan → Review progression**. Skill/cap and observed learned-recipe count should match the manually scanned view; verify the displayed target gap and reagent shortfall.
- [ ] Confirm exact wording does not promise one skill point per craft, a full recipe catalog or any skill-up probability.
- [ ] Switch profession or rescan bags; the previous plan must not be attributed to the new profession. Expire the scan; unknown values must not be presented as current.
- [ ] Confirm no automatic crafting, AH queries or extra API reads when opening review; capture client build, scale, errors, and screenshots only if safe. **Real Forever in-game status: NOT RUN.**

## GW-014 Direct Capacity addendum (NOT RUN)
- [ ] Manually scan complete bags, open and scan a crafting profession, choose a fixed-output learned recipe, and select **Plan reagents**. Choose **Direct capacity** in My Plan. Compare direct reagent counts to your bag totals.
- [ ] Reserve the current plan's carried ingredients. Direct capacity must not subtract the same reservation twice; reservations held for a different recipe must reduce available counts.
- [ ] A recipe with missing direct materials may show 0 covered runs even if nested crafting could theoretically produce them; it must *not* claim guaranteed craftability or future skill gain.
- [ ] Refresh bags or switch characters/expire snapshot. Stale, partial, unknown, or cross-character figures should not remain trusted. Confirm no automatic crafting, Auction House action, extra game reads or persistent state. Record real client build and UI errors. **NOT RUN**.

## GW-014 profession-scope and plan invalidation checks (NOT RUN)
- [ ] On a verified client build, scan a profession and bags, then manually plan a learned fixed-output recipe with dependencies. Confirm its material plan appears.
- [ ] Re-scan the **same profession**. The previous plan must no longer appear current in My Plan. Create a new plan; any producer steps must come from the newly observed profession session.
- [ ] Switch to a different crafting profession (where available), scan and plan. Recipes captured from the previous profession must not be reused as ingredient producers.
- [ ] Log another character or change client build. Cached sources and previous plan must not carry across contexts. Let a profession scan expire; planning must refuse until it is manually refreshed.
- [ ] Check that no automatic game actions, background scans or additional client APIs were introduced. Record actual build, screenshot and Lua errors. **Client QA NOT RUN.**
