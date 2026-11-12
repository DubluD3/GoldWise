# GW-026 - Scan & Setup Guide verification

**Candidate:** stacked on PR #37 (0.2.0-test2). **Forever in-game verification: NOT RUN.** Local tests must be re-run on the final candidate commit. Do not merge until the parent PRs are integrated and this client QA is signed off.

## Installation
Close Forever. Copy the contents of a packaged GoldWise folder to `<Forever installation>/Interface/AddOns/GoldWise/`. Confirm that `GoldWise.toc` is inside that folder, not a nested second GoldWise folder. Enable the addon and disable disposable GoldWise probe addons. The exact installation root depends on the Battle.net install selection.

## Safe client checks
1. In game run `/run local v,b,d,i=GetBuildInfo();print(v,b,d,i)`; record **actual** version/build/interface. Only 1.60.1 builds 70862/70888 and interface 16001 are allowlisted. A newer or unknown build must show an unavailable dashboard; do not edit the allowlist to bypass verification.
2. On a fresh install (no `GoldWiseGuideDB`), log in and run `/goldwise`. Expect the native dashboard to show **Scan & Setup Guide**, step 1, privacy/no-automation statement, capture method, state and specific next player step. Missing character data stays **Pending**.
3. Navigate with Next step, Previous step, and Skip this step. Confirm that Skipped is *not* equivalent to collected. Close the guide with Exit guide and reopen it via the top **Guide** button or `/goldwise guide`. Verify the last step resumes.
4. At Carried bags, use Scan bags and inspect complete/partial observation timestamps versus the actual bags. Change character/realm: earlier character observations must never appear current for the new scope. Verify behavior on an empty inventory.
5. At Professions, first try Scan profession with the panel closed; do not show a successful state. Open your own crafting panel and select a profession; scan again. A filtered set of known recipes remains **Partial** and does not imply a complete recipe catalog.
6. At Auction House, use Observe browse to arm, make **one Blizzard-native Buy search**, reopen GoldWise, and Observe browse again within 60 seconds. Confirm state is never falsely marked complete for an unverified market identity. Check closing AH, unavailable readiness, throttling and stale data; no addon-originated AH query or retry loop is allowed.
7. Ledger: Sample balance outside trade with no coins on cursor. Repeat after one second; show only observation provenance, not sale causation. Unsupported equipment/bank/alts must remain Unsupported. Recipe planning is manual and session-scoped, not a persistent gold goal.
8. Finish guide on last step. After `/reload`, character-switch, and full game restart, `/goldwise` should open Overview, while Guide or `/goldwise guide` still opens the guide. Skip and last-step preference data is local account SavedVariables. If a SavedVariables table is corrupt, it must be left untouched, and no false persistence success displayed.
9. Check all five existing tabs, closed window recovery, 100% and reduced UI scale, narrow viewport, mouse/keyboard accessibility, and active combat. Watch for Lua errors, taint, clipped content, duplicate chat messages and frame-rate/stutter. Test with at least one popular AH/UI addon enabled.

**Expected:** informational UI only; no automated craft/equip/mail/post/cancel/buy/gather or search. No remote traffic, telemetry, in-game ads or real user financial identifiers in reports.

**Red flags:** actual client build not allowlisted; erroneous Last observed; stale/cross-character state presented as current; addon-generated AH requests; UI taint; lost or erased storage; Lua errors. **STOP** rollout and record the exact sanitized reproduction.

## Local verification commands
Run at repo root with an **actual Lua 5.1** interpreter installed:

```sh
sh scripts/test.sh syntax
sh scripts/test.sh unit
sh scripts/test.sh contract
sh scripts/test.sh
```

Record exact outputs, exit status, CI links, client build, scale, and owner approval. Without owner-provided live proof: **in-game NOT RUN, release BLOCKED.**

## Rollback
Disable/remove GoldWise from AddOns. Restoring the previous PR #37 addon folder removes only the guide code; the prior `GoldWiseDB` storage schema remains untouched. `GoldWiseGuideDB` is a separate new SavedVariables table: leave it in place, or remove it manually after backing up the saved-variable file if the owner explicitly wants a preference reset. Never delete account SavedVariables without a backup and explicit request.
