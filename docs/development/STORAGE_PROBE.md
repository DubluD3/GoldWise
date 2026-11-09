# GW-005 storage verification

This separate probe tests whether Forever build `70862` restores one disposable account-wide SavedVariables marker before the probe's `ADDON_LOADED` callback. It reads the marker once per load. The only write is the manual test command below.

On 2026-11-09 the owner reported `marker present at ADDON_LOADED` after `/reload` and a full quit and reopen. A separate character-selection relog was not reported. The [product smoke test](../../README.md#test-the-startup-build) covers the integrated `GoldWiseDB` path.

## In-game procedure

1. Close WoW: Forever. Copy `tests/probes/GoldWiseStorageProbe` from this repo into Forever's `Interface/AddOns` folder, or extract the probe ZIP there. It is a separate folder alongside `GoldWise`.
2. Start Forever, enable **GoldWise Storage Probe**, and log in. On the first run, the expected message is `GoldWise storage probe: marker missing at ADDON_LOADED`.
3. In game chat, set the test marker once:

   ```text
   /run GoldWiseStorageProbeMarker = "gw005"
   ```

4. Run `/reload`. Record whether the probe prints `marker present at ADDON_LOADED`.
5. Log out to character selection and log back in. Record the message again.
6. Quit WoW normally, fully reopen it, and log in again. Record the message a third time. Leave the marker alone between the three checks.

If the probe prints `client build unverified`, record the build and stop. If it prints `ADDON_LOADED registration unavailable`, prints nothing, or fails to restore the marker, record that result and any Lua error. Remove or disable the probe addon when done. The marker is a test string specific to the probe.

## Offline storage contract

`data/Storage.lua` works on Lua tables supplied by its caller. Schema v1 stores one last-observed timestamp per scope. Keys include the scope kind, build, region, realm and faction, plus a local character identifier for character scopes. Each component is length-prefixed, so separators in identifiers do not merge distinct scopes. There are no market prices, snapshots, or account identifiers in v1.

- At 64 distinct scopes, the store rejects new scopes explicitly and still accepts updates to existing scopes. An older observation cannot replace a newer timestamp.
- A synthetic v0 fixture uses `lastSeen`. Opening it returns an independent v1 table without changing the source. GW-004 shipped without SavedVariables.
- Corrupt, oversized, or unsupported saved data returns an error and leaves the input untouched. A caller can open a clean table for the current session while preserving the original saved value. Future format changes need a specific migration before enabling writes.
- The client owns SavedVariables serialization. Offline tests round-trip the table boundary and simulate the lifecycle callback. The live test above covers actual client restoration.

Run `lua5.1 tests/storage.lua` and `lua5.1 tests/storage_probe.lua` from the repo root.
