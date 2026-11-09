# GW-008 inventory verification

The disposable probe checks the carried-bag calls in [API-003](../research/API_EVIDENCE.md#api-003--gw-008-carried-bag-inventory) on Forever build `70862`. It reads the backpack, four regular bag slots, and the reagent bag on manual request. It prints bag availability and one sample item and keeps the observation in memory only while the command runs. Bank, keyring, and alt inventory are outside this check.

1. Close WoW and extract the inventory probe ZIP into Forever's `Interface/AddOns` folder. The manifest belongs at `Interface/AddOns/GoldWiseInventoryProbe/GoldWiseInventoryProbe.toc`. To install from source, copy `tests/probes/GoldWiseInventoryProbe` and put a copy of `data/InventorySnapshot.lua` directly in that folder alongside the manifest.
2. Enable **GoldWise Inventory Probe**, log in, and open the bags. While the contents are steady, paste this command into chat:

   ```text
   /run if GoldWiseInventoryProbe_Run then GoldWiseInventoryProbe_Run() else print("GoldWise Inventory Probe is not loaded") end
   ```

3. Look for `bags=complete, bank=unobserved, alts=unobserved`. The sample line shows one item's stack at a specific bag slot and its total across all six carried bags. Check the sample against the bags, including the reagent bag if it contains the same item. If any bag is `partial` or `unavailable`, report the bag name and status. If the scan has no sample, report whether the carried bags were empty.

Share whether the counts matched and any error or unavailable bag. Keep item names and IDs private. Disable or remove the probe when done.

## Snapshot contract

`data/InventorySnapshot.lua` takes a character scope, observation timestamp, and a reader for carried bags. A slot read returns `false` for an observed empty slot, `nil` for an unreadable slot, or a numeric item ID and positive stack quantity. The model preserves each readable stack and aggregates by base item ID. Totals from a partial snapshot represent only the readable stacks. An unavailable snapshot provides no usable counts.

The timestamp describes one observation. The reader does not subscribe to bag events or poll. The capture limit of 128 slots per bag is a project bound. Product inventory stays disabled until the probe confirms the live path.
