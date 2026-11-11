# GW-013 trainer verification

This disposable addon tests one skill requirement on Forever `1.60.1` builds `70862` and `70888` when the client reports interface `16001`. It checks the native trainer service you select and, if the tooltip supplies a readable spell ID, compares that candidate against your open local crafting profession. [API evidence](../research/API_EVIDENCE.md#selected-trainer-service-probe)

1. Close WoW and extract the trainer probe ZIP into Forever's `Interface/AddOns` folder, or copy `tests/probes/GoldWiseTrainerProbe` there. The manifest should be at `Interface/AddOns/GoldWiseTrainerProbe/GoldWiseTrainerProbe.toc`. Enable **GoldWise Trainer Probe**.
2. Open a native profession trainer for one of your existing professions. Select an unlearned recipe with a visible required skill rank. Leave the trainer window open and run:

   ```text
   /run if GoldWiseTrainerProbe_Sample then GoldWiseTrainerProbe_Sample() else print("GoldWise Trainer Probe is not loaded") end
   ```

3. Compare the printed service and required rank with the selected trainer row. If it prints `spell candidate ready for recipe check`, close the trainer and open your own crafting window for that profession. Within five minutes, run:

   ```text
   /run GoldWiseTrainerProbe_Match()
   ```

4. Report the `testing build` line, whether the selected service and rank matched, and the recipe status. If the probe reports `recipe identity candidate unavailable`, share that status and skip the second command. If it reports `client build unverified`, run `/run local v,b,_,i=GetBuildInfo(); print(v,b,i)` and report that version, build, and interface. Keep recipe IDs private. Remove or disable the probe when finished.

The probe only reads the selected service and compares one candidate. It does not train, change filters or selection, or store data across reloads. A match supports the specific observed recipe and skill requirement. It leaves complete trainer coverage and other prerequisites unknown. A missing or mismatched ID leaves trainer-to-recipe association unavailable.

Live trainer verification is `NOT RUN` on both builds. Production support for `70888` requires its own live checks.
