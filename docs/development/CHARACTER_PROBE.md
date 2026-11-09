# GW-007 character context verification

This disposable addon checks the player-only API candidates in [API-008](../research/API_EVIDENCE.md#api-008--gw-007-character-context) on Forever build `70862`. It runs once on entry, checks for restricted results, and displays only availability and short comparison tags. It has no SavedVariables and sends no data. Use the tags only to compare your own outputs locally.

1. Close WoW. Copy `tests/probes/GoldWiseCharacterProbe` into Forever's `Interface/AddOns` folder, or extract the probe ZIP there. Enable **GoldWise Character Probe**.
2. Log in on one character. Look for `entry=login`, a `character` tag and a `realm` tag, and `faction=ok region=ok time=ok`.
3. Run `/reload` on that character. Look for `entry=reload` and compare the character and realm tags with the login output.
4. Log in on a second character, if available. Compare its character tag with the first character's tag.

Report whether all fields were available, whether the first character's tags matched after reload, and whether the second character's character tag differed. Share field names marked `unavailable` and any probe error. Keep the tag values and character details local. Disable or remove the probe when done.

## Offline snapshot contract

`data/CharacterSnapshot.lua` accepts one normalized observation and the existing `Storage.scopeKey` function. It returns a scope key, reported realm context, faction, region code, client build, observation time, and source. A second observation in the same scope can have a newer timestamp with the same key. Missing or invalid context yields no snapshot. The key treats the player identifier as opaque. Reported realm context needs separate verification before it can represent a stable realm or market identity.

The product addon will connect the live adapter after API-008 is verified. Run `sh scripts/test.sh` with Lua 5.1 for the offline model and probe checks.
