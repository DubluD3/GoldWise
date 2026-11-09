# GW-007 character context verification

This disposable addon checks the player-only API candidates in [API-008](../research/API_EVIDENCE.md#api-008--gw-007-character-context) on Forever build `70862`. It checks for restricted results and displays only availability and short comparison tags. It has no SavedVariables and sends no data. Use the tags only to compare your own outputs locally.

1. Close WoW. Replace the probe folder with `tests/probes/GoldWiseCharacterProbe` or the v2 ZIP. Confirm the manifest is directly at `Interface/AddOns/GoldWiseCharacterProbe/GoldWiseCharacterProbe.toc`. Enable **GoldWise Character Probe** in the AddOns list.
2. Log in on one character. Look for `GoldWise character probe v2 loaded` and an `entry=login` line with the two tags and `faction=ok region=ok time=ok`. If the result is absent, run the manual command below.
3. Run `/reload` on that character. Compare the character and realm tags with the login output. Use the manual command again if the `entry=reload` line is absent.
4. Log in on a second character, if available. Compare its character tag with the first character's tag.

Report whether all fields were available, whether the first character's tags matched after reload, and whether the second character's character tag differed. Share field names marked `unavailable` and any probe error. Keep the tag values and character details local. Disable or remove the probe when done.

## If no result appears

Paste this in the in-game chat box after login:

```text
/run if GoldWiseCharacterProbe_Run then GoldWiseCharacterProbe_Run() else print("GoldWise Character Probe v2 is not loaded") end
```

An `entry=manual` result confirms the probe loaded and ran the API calls. Report whether the automatic line also appeared. `GoldWise Character Probe v2 is not loaded` means the manual function is unavailable. Check the addon folder and whether the probe is enabled.

## Offline snapshot contract

`data/CharacterSnapshot.lua` accepts one normalized observation and the existing `Storage.scopeKey` function. It returns a scope key, reported realm context, faction, region code, client build, observation time, and source. A second observation in the same scope can have a newer timestamp with the same key. Missing or invalid context yields no snapshot. The key treats the player identifier as opaque. Reported realm context needs separate verification before it can represent a stable realm or market identity.

The product addon will connect the live adapter after API-008 is verified. Run `sh scripts/test.sh` with Lua 5.1 for the offline model and probe checks.
