# GW-009 profession verification

The disposable probe checks [API-005](../research/API_EVIDENCE.md#api-005--gw-009-profession-context) on Forever build `70862`. It reads the player's open crafting profession on manual request. It prints the current skill and cap, the number of learned recipes it observed under the current filters, and one learned sample if available. The probe has no SavedVariables and sends no data.

1. Close WoW and extract the profession probe ZIP into Forever's `Interface/AddOns` folder. Its manifest belongs at `Interface/AddOns/GoldWiseProfessionProbe/GoldWiseProfessionProbe.toc`. To install from source, copy `tests/probes/GoldWiseProfessionProbe` and put copies of `data/ProfessionSnapshot.lua` and `adapters/ProfessionCapture.lua` alongside the manifest.
2. Enable **GoldWise Profession Probe** and log in. Open one of your own crafting profession windows and wait for its recipe list to appear. Clear any search text if you want to compare a larger recipe list. The probe leaves the filters as they are.
3. Paste this command into chat:

   ```text
   /run if GoldWiseProfessionProbe_Run then GoldWiseProfessionProbe_Run() else print("GoldWise Profession Probe is not loaded") end
   ```

4. Compare the printed skill and cap with the window. If the probe prints `sample learned`, check whether that recipe is learned in the open list. Report whether the values and sample match and whether recipes reported `filtered`, `partial`, or `unavailable`. Item and recipe names can stay private.
5. Close the crafting window and repeat the command once. The expected result is `crafting window unavailable`. Disable or remove the probe after testing.

If the probe reports that the window, mode, or APIs are unavailable, share that status and any Lua error. A gathering-only skill without a crafting window is outside this capture path.

## Snapshot contract

`data/ProfessionSnapshot.lua` records a timestamp, character scope, skill-line ID, skill and cap, and only recipes confirmed as learned. `filtered` describes the list visible under current filters. `partial` means some rows could not be checked or the 1,024-row project limit was reached. `unavailable` means the reader could not establish a usable list. A recipe absent from the snapshot is unknown.

The owner reported skill `87/150` and 35 observed learned recipes from an open Leatherworking window on `70862` and confirmed that the [installed addon's](../../README.md#test-the-startup-build) scan matched the window. Its chat summary describes the source and filtered state and omits the learned count if enumeration is unavailable. The snapshot stays in memory. Closed-window handling passed offline and awaits a separately reported live result.
