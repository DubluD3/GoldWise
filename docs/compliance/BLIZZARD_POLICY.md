# Blizzard policy and compliance gate
Date reviewed: 2026-11-09. **Internal interpretation, not legal advice or Blizzard approval.**

## Authoritative policy to recheck
- Blizzard UI Add-On Development Policy: https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642
- Blizzard legal/EULA index: https://www.blizzard.com/en-us/legal/
- Developer API terms (only if external Blizzard APIs later used): verify official Blizzard developer site before starting companion integration.

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
| Read inventory, professions, AH via verified UI APIs | Candidate, only after live validation |
| Local historical price analysis | Candidate |
| Suggest listing price, item strategy, profession path | In scope |
| Player manually executes trades and crafts | In scope |
| Automated purchase/post/cancel/bid/craft/input | **Forbidden** |
| Throttle circumvention, API abuse, process memory, packet injection | **Forbidden** |
| Advertisements, premium in-game modules, donation requests in addon | **Forbidden** |
| Export/transmit data without explicit future approval | Out of scope |

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
- 2026-11-09: initial policy summary against official forum post; specific current Forever API behaviors remain unverified.
