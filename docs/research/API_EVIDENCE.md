# Forever API evidence register

**Live current-build status on 2026-11-09: NOT VERIFIED.** This is a research queue, not proof that calls work. Never promote a row based solely on an LLM answer. Before implementing a call capture exact signature, returns, events, build and an in-game observed result (if testing needed).

## Sources to verify
1. Official Blizzard addon policy: https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642 (reviewed 2026-11-09).
2. Client-extracted community index: https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/README.md (extraction 2026-10-01, build 70170, interface 16001; **not current live proof**).
3. Searchable extracted catalog: https://atraeau.github.io/WoW-Addons/ (build 70170).
4. Community compatibility report: https://wowforeveraddons.com/articles/wow-forever-addon-api (updated 2026-11-02; non-official).
5. Blizzard EULA: https://www.blizzard.com/en-us/legal/ (locate the current EULA from Blizzard's legal index).

## Research matrix
| ID | Candidate namespace / behavior | Evidence class | Current build verified? | Implementation status |
|---|---|---|---|---|
| API-001 | `GetBuildInfo` / TOC interface | CLIENT-EXTRACTED/community | NO | BLOCKED |
| API-002 | addon load and SavedVariables lifecycle | CLIENT-EXTRACTED/community | NO | BLOCKED |
| API-003 | `C_Container` bag slots, item info and quantity | CLIENT-EXTRACTED | NO | BLOCKED |
| API-004 | `C_Item` item details/cache behavior | CLIENT-EXTRACTED | NO | BLOCKED |
| API-005 | profession/skill and known recipe API (`C_TradeSkillUI` candidate) | CLIENT-EXTRACTED | NO | BLOCKED |
| API-006 | AH scan readiness, query and result flow (`C_AuctionHouse` candidate) | CLIENT-EXTRACTED | NO | BLOCKED |
| API-007 | money events and balance | UNKNOWN live behavior | NO | BLOCKED |
| API-008 | realm/faction/character context | UNKNOWN live behavior | NO | BLOCKED |
| API-009 | tooltip and safe UI events | UNKNOWN live behavior | NO | BLOCKED |
| API-010 | AH deposit/cut by auction type | UNKNOWN live behavior | NO | BLOCKED |

## Evidence record template (copy per symbol)
- Symbol and exact namespace:
- Purpose / story:
- URL + accessed UTC timestamp:
- Source class: OFFICIAL / CLIENT-EXTRACTED / COMMUNITY-REPORTED / OBSERVED-IN-GAME / INFERRED / UNKNOWN:
- Exact parameters, types, returns:
- Events and lifecycle:
- Game version / build / interface:
- In-game probe used + sanitized output:
- Error/nil/secret-value handling:
- Rate/cooldown behavior:
- Policy/protected action classification:
- Decision: VERIFIED / UNVERIFIED / UNSUPPORTED / BLOCKED:
- Fallback and next review date:

## Test probe rules
Use harmless, read-only console inspection of known symbols; do not query AH until trigger/cooldown semantics verified. Record client version using supported client UI. Never spam APIs, try protected calls or run automation. Ask owner to execute controlled client probes; Codex cannot assert test success from generated code alone.
