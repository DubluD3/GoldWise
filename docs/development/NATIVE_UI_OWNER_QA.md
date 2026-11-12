# GoldWise — cumulative native UI owner acceptance

Status: **NOT RUN in WoW Forever**. This document is a field checklist, not an
automated certification. Use only the latest stacked draft branch's exact head
SHA and its successful GitHub Actions candidate artifact. Never assume that a
green Lua fixture means the installed native frames exist or are protected-safe.

## Test identity

- Full commit SHA: TBD
- Artifact / Actions URL: TBD
- Forever version / build / interface: TBD (allowed: 1.60.1 / 70862 or 70888 / 16001)
- Platform, resolution, UI scale: TBD
- Other addons (especially bag and AH UI replacements): TBD
- Game Lua errors / taint: NOT RUN
- Owner disposition: PENDING

## End-to-end flow and expected outcomes

| Case | Procedure | Expected / failure boundary | Status |
|---|---|---|---|
| N01 | Install only the inner candidate ZIP, with a single GoldWise/GoldWise.toc path | No double-nesting or unrelated addons/data in package | NOT RUN |
| N02 | Launch at allowed build; `/goldwise` | Five tabs and manual guide usable; other builds stop, not bypassed | NOT RUN |
| N03 | Open native crafting, manually scan profession, open GoldWise companion | Exact observed name, skill and *filtered* learned count; no auto-read | NOT RUN |
| N04 | Scan complete carried bags, plan a fixed-yield recipe, reopen profession companion | Exact GoldWise planned recipe, counted missing *carried* reagents; no claims for bank/alts | NOT RUN |
| N05 | Open native bags, manually scan, use GoldWise Bags | Real carried counts, not item-selling authorization; no item interaction | NOT RUN |
| N06 | Open native AH Browse; arm GoldWise, do one Blizzard search, observe cache | Shows min asking price and quantity with partial/stale labels; never executes a search or trade | NOT RUN |
| N07 | Re-scan profession/inventory, age AH cache, switch character | Old companion buttons and panels disappear; stale counts cannot be revived | NOT RUN |
| N08 | Move native windows left/right/top/bottom; vary scale | Sidecars flip or abstain without clipping or hiding Blizzard native buttons | NOT RUN |
| N09 | Test in combat, near secure native buttons, with competing UI addons | No taint, protected-action errors, overlay interception or UI freezes | NOT RUN |
| N10 | Close/reopen native frames and the GoldWise dashboard | No duplicate controls, no unwarranted scan, standalone fallback preserved | NOT RUN |
| N11 | `/reload`, full restart, different character | No session scan/plan/AH facts presented as persisted current truth; guide prefs only where expected | NOT RUN |
| N12 | Uninstall/rollback with saved backups | No unrelated SavedVariables touched; restoration works | NOT RUN |

## Safety checks and interpretation

Never intentionally trigger sales, purchases, postings, crafting, mailing,
equipment moves or automation to test GoldWise: none are addon actions.
Observe the game's normal controls without automating them.

If companion controls do not attach on an otherwise working supported build,
record the native frame name/API behavior and treat that companion as
**BLOCKED — native frame not verified**. Do not infer support from an offline
mock. If there is a Lua/taint error, protected control interference,
unexpected auction query, or wrong-character information: **STOP, FAIL**,
exit the game and restore the backed-up addon and SavedVariables. Share
sanitized errors/screenshots only; no account or WTF data.

This matrix supplements E01–E20 in `docs/development/OWNER_E2E_QA.md`
and the detailed steps in `docs/development/INTEGRATED_TEST.md`.

## Completion gate

Release and PR integration remain blocked until the owner records in-game
evidence for all applicable cases, resolves BLOCKED/FAIL entries, reviews
license and public release documentation, and explicitly authorizes merging
and release. AI-maintained automation cannot sign these gates.
