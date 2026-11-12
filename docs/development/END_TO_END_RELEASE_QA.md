# GoldWise Forever — owner E2E release QA
Status: proposed script, NOT RUN. Run on target Forever client and record live version/build/interface; previous verified build 70862.

## Setup
Back up SavedVariables. Pull release commit; verify addon TOC, install under the Forever client Interface/AddOns/GoldWise (no nested folder), restart client. Enable script errors with `/console scriptErrors 1`. Record actual build and sanitized screenshots.

## Checklist (mark PASS/FAIL/BLOCKED/NOT RUN for every step)
1. Clean first login: first-run guide appears or is discoverable; no Lua errors; no fake scan completions.
2. Wizard Back/Next/Skip/Finish: explains sources, privacy, why scans matter and verified scan status.
3. Help > Scan & Setup Guide: reopen any time; statuses and last-observed times truthful.
4. Open bags and change item stacks: automatic updates only if observed on target build; verify quantities, empty/error states and performance.
5. Record gold, then a legitimate manual gold change: ledger shows observation, not fictitious completed sale.
6. Open a profession panel, capture learned recipes, close it; show last-seen/unsupported correctly.
7. Visit banker: bank only captured while available and actually supported; otherwise guided fallback.
8. AH closed: no queries; open AH and perform native search: passive capture only of permitted observed results.
9. User-triggered AH scan, if verified: readiness/15-minute replication limits (if applicable), retry/cooldown/abort and no query storms.
10. Empty, partial, stale, throttled, unsupported and no-results market states show separate statuses.
11. Item Advisor: verify sell raw/craft/vendor/keep calculations in integer copper, provenance, fee/cost assumptions, no invented realized profit.
12. Profession material reservations and nested crafting: no double counting; compare multiple character uses.
13. Equipment alt candidate: binding/tradeability/class/level restrictions honored; unknown role stats say potential upgrade only.
14. Log into second character, then first: distinct timestamped profiles; no incorrect realm/faction mixing.
15. Create goal and planned manual steps: persistence, no autonomous gameplay.
16. Reload `/reload`, character switch, full game restart: state correct; recover offscreen window; migrations non-destructive.
17. Combat and UI-scale/resolution QA: no taint, no protected action faults, clipping, excessive CPU or frame stutter.
18. Interoperability with Auctionator or commonly installed UI addon, where available; report conflicts.
19. Release ZIP check: publicly readable code; no in-game ads/donations, network upload, credentials or unlicensed assets.
20. Uninstall/disable and backup restore procedure: normal gameplay and saved data preserved.

## Red flags
Unexpected auction requests, rate limit failures, stutter/disconnect, hidden scans, automatic buys/posts/equips/crafts/mails, unsupported API used as if verified, private data leaked between characters, stale asking price presented as realized income, guessed recipe/market identifiers, contaminated SavedVariables, UI taint.

## Test evidence template
- Commit and ZIP/checksum:
- Forever version/build/interface:
- Step results PASS/FAIL/BLOCKED/NOT RUN:
- Console errors, sanitized screenshot and reproduction:
- CPU/frame responsiveness and saved data size:
- Compatibility and rollback:
- Owner approval: APPROVE / REJECT / PENDING

Offline synthetic Linen Cloth/bolt/bandage examples test model behavior only. An agent cannot mark live client QA PASS or declare production ready without user-reported results.