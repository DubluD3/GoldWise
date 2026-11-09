# GW-021 character balance verification

This disposable probe checks [API-007](../research/API_EVIDENCE.md#api-007--gw-021-character-balance) on Forever `1.60.1`, build `70862`, interface `16001`. Each manual call reads the candidate balance once. If the balance and timestamp are readable, it prints the amount in copper in your local chat. The probe records no identifiers, keeps no history, and registers no events.

1. Close WoW and copy the `tests/probes/GoldWiseMoneyProbe` folder into Forever's `Interface/AddOns` folder. Enable **GoldWise Money Probe** on the character selection screen.
2. Log in and open your bags. Make sure you have no trade window open and no coins on the cursor. Run this command in chat once:

   ```text
   /run if GoldWiseMoneyProbe_Run then GoldWiseMoneyProbe_Run() else print("GoldWise Money Probe is not loaded") end
   ```

3. Compare the displayed copper amount with your purse. Gold counts for 10,000 copper and silver for 100. Report only whether it matched and whether it said `timestamp readable`. Keep the amount private. If the balance, timestamp, or build is unavailable, share only that status. Remove or disable the probe when finished.

Live result on `70862` is `NOT RUN`. A matching result establishes the manual balance-read path in the tested context. Automatic event coverage and transaction attribution require separate evidence.

## Offline ledger behavior

- The model accepts validated integer copper samples for one character and build. It keeps one current baseline and at most 64 net changes in memory. A caller supplies the maximum allowed interval between samples. A stale interval starts a new baseline without adding an entry.
- Missing, invalid, mismatched, or out-of-order samples supply no new baseline or entry. An unchanged balance updates the baseline without adding a change.
- Entries carry timestamps, source, signed net change, and attribution. The player can categorize a change as a sale, purchase, or other and undo it. A categorized entry remains a net balance change with user-reported confidence. The model never treats that value as sale proceeds or a verified transaction.
- The model has no product manifest wiring or SavedVariables schema changes. Rollback removes the model, disposable probe, tests, and documentation without a data migration.
