# Blizzard policy and compliance gate
Date reviewed: 2026-11-09. **Internal interpretation, not legal advice or Blizzard approval.**

## Sources reviewed for GW-002

- `OFFICIAL`, accessed 2026-11-09. Blizzard's add-on policy covers distribution, source visibility, performance, in-game promotions, and adherence to Blizzard's terms. [WoW UI Add-On Development Policy](https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642)
- `OFFICIAL`, accessed 2026-11-09. Blizzard's EULA page reports a revision date of 2024-03-21. Section 1.C covers unauthorized automation, client modification, data collection, and connections. Use the agreement applicable to the account when reviewing a release. [Blizzard EULA](https://www.blizzard.com/en-us/legal/fba4d00f-c7e4-4883-b8b9-1b4500a402ea/blizzard-end-user-license-agreement)
- `OFFICIAL`, posted 2025-08-05 and accessed 2026-11-09. Blizzard reiterated restrictions on third-party client modification and security bypass. [Prohibitions on Third-party Software](https://us.forums.blizzard.com/en/wow/t/prohibitions-on-third-party-software/2142972)

## Policy summary (source: Blizzard UI addon policy)
- Addons free of charge; no premium addon features or charged related access.
- Programming code visible and non-obfuscated.
- No realm/client/player negative performance impact.
- No in-addon advertisements.
- No in-addon donation solicitations.
- No objectionable material; must follow EULA, Terms and other Blizzard rules.
- Blizzard has sole discretion; interpretation can change.

## Hard boundaries
| Behavior | GoldWise |
|---|---|
| Display addon version and read local client build metadata | In scope for the GW-004 smoke test. Read once on load and display one local status message. |
| Read inventory and professions via supported UI APIs | Candidate. Require per-call evidence on the target build and a fallback for missing or restricted data. |
| Read Auction House results already returned to the visible browse window | In scope for a manual GW-010 discovery probe. Bound reads and keep the data local. |
| Issue addon-originated Auction House queries | Blocked pending verified trigger, readiness, throttling, and result lifecycle, plus owner policy review. |
| Local historical price analysis | Candidate |
| Suggest listing price, item strategy, profession path | In scope |
| Player manually executes trades and crafts | In scope |
| Automated purchase/post/cancel/bid/craft/input | **Forbidden** |
| Throttle circumvention, API abuse, process memory, packet injection, client patching, or simulated input | **Forbidden** |
| Advertisements, premium in-game modules, donation requests in addon | **Forbidden** |
| Export/transmit data without explicit future approval | Out of scope |

## GW-002 review outcome

GoldWise's scope decisions above are `INFERRED` from the official sources and the project's stricter read-only design. The GW-004 smoke test is limited to reading build metadata and displaying startup status. It uses no protected actions, persistent data, external connections, or dependencies. Block any ambiguous behavior before implementation. Leave optional data providers and companion software for separate review if proposed.

The policy check is a document review. Client QA for the bootstrap belongs to GW-004. Project owner review is pending before merge.

## Feature compliance gate for every PR
- [ ] What game actions does feature read or initiate?
- [ ] Does code call protected APIs or perform actions without a discrete player input?
- [ ] Are AH queries bounded and trigger-controlled?
- [ ] Have API signatures and limits been verified in the current client?
- [ ] Does data leave local device or access other software? If yes, BLOCK for new ADR.
- [ ] Does it change performance / persist sensitive identifiers?
- [ ] Does UI contain ads/donations/paywalls?
- [ ] Is code visible and are dependency licenses compatible?
- [ ] If interpretation uncertain: stop and request Blizzard clarification; do not infer permission from competitors.

## Enforcement note
No addon design can guarantee zero account enforcement risk. Avoid any claims of 'Blizzard approved' without written proof.

## Change log
- 2026-11-09: Rechecked the official addon policy and EULA for GW-010. The probe observes a native search and reads the local browse cache on request. The query path remains blocked.
- 2026-11-09: GW-002 reviewed the add-on policy, EULA, and Blizzard's third-party software notice. Recorded the smoke-test scope and kept Auction House queries blocked pending review.
- 2026-11-09: initial policy summary against official forum post; specific current Forever API behaviors remain unverified.
