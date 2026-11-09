# GW-010 Auction House verification

This disposable addon checks [API-006](../research/API_EVIDENCE.md#api-006--gw-010-auction-house-browse-cache) on Forever build `70862`. It observes browse events and reads the locally cached rows only when you explicitly ask. You initiate one search in Blizzard's Auction House interface. The probe has no SavedVariables, sends no requests, and sends no data elsewhere.

1. Close WoW, extract the probe ZIP into Forever's `Interface/AddOns` folder, and enable **GoldWise Auction Probe**. The manifest belongs at `Interface/AddOns/GoldWiseAuctionProbe/GoldWiseAuctionProbe.toc`. To install from source, copy `tests/probes/GoldWiseAuctionProbe` and put copies of `data/AuctionObservation.lua` and `adapters/AuctionCapture.lua` beside its manifest.
2. Open the Auction House on its **Buy** browse view. Wait for the normal Search button to be ready, then paste this into chat:

   ```text
   /run if GoldWiseAuctionProbe_Run then GoldWiseAuctionProbe_Run() else print("GoldWise Auction Probe is not loaded") end
   ```

3. After `armed, ready=yes`, search for one specific item using Blizzard's **Search** button. Stay on the browse results list without opening a result or scrolling for more rows.
4. When `browse update observed` appears and the results are visible, run the same command again. Complete this within 60 seconds of arming. If it reports `ready=no`, wait for the normal Search button and retry the chat command once within that window. The probe never retries on its own.

Report the readiness and cache summary, including `cache=complete` or `cache=partial`, and whether the probe printed a sample. Keep item and price details private. If an update is absent or the probe reports an error, share the status. An expired, completed, failed, or cancelled run requires `/reload` before another attempt. Disable or remove the probe when done.

## What the result means

The event signals a browse update during the observation window. It carries no request ID, so the probe cannot attribute it to a specific query. `cache=complete` describes the client-reported result set and readable rows within the 128-row project limit. Partial data is explicitly labelled. The sample is the browse minimum in copper and the client-reported quantity. No sale, unit-price basis, or recommendation is inferred.

The owner confirmed a ready state, a browse update, and a correct partial result with 154 cache rows and 128 observed rows on `70862`. The owner also confirmed the [installed addon](../../README.md#test-the-startup-build) returned correct data. The installed addon retains one timestamped result in memory for the active character and sends zero Auction House queries. Query attribution, addon-originated requests, and cooldown duration need separate evidence and policy review.
