# GW-021 character balance verification

This disposable probe checks [API-007](../research/API_EVIDENCE.md#api-007--gw-021-character-balance) on Forever `1.60.1`, build `70862`, interface `16001`. Each manual call reads the candidate balance once. If the balance and timestamp are readable, it prints the amount in copper in your local chat. The probe records no identifiers, keeps no history, and registers no events.

1. Close WoW and copy the `tests/probes/GoldWiseMoneyProbe` folder into Forever's `Interface/AddOns` folder. Enable **GoldWise Money Probe** on the character selection screen.
2. Log in and open your bags. Make sure you have no trade window open and no coins on the cursor. Run this command in chat once:

   ```text
   /run if GoldWiseMoneyProbe_Run then GoldWiseMoneyProbe_Run() else print("GoldWise Money Probe is not loaded") end
   ```

3. Compare the displayed copper amount with your purse. Gold counts for 10,000 copper and silver for 100. Report only whether it matched and whether it said `timestamp readable`. Keep the amount private. If the balance, timestamp, or build is unavailable, share only that status. Remove or disable the probe when finished.

On November 9, 2026, the owner confirmed that the copper amount matched the purse on build `70862` and that the probe reported `timestamp readable`. The amount is omitted. Automatic event coverage and verified transaction attribution require separate evidence.

## Installed addon check

1. Install GoldWise `0.1.6-dev` and log in on build `70862`. Wait for `GoldWise character snapshot ready.` Outside trade and with no coins on the cursor, run `/run GoldWiseLedgerSample()`. The first read should say `baseline recorded`.
2. Run the same command at least one second later. If the balance stayed the same, expect `balance unchanged`. If ordinary gameplay changed your purse within five minutes of the previous sample, expect an entry number and a signed net copper change labeled `unclassified`.
3. To test manual categorization on a recorded change, replace `ENTRY_ID` with its printed number in `/run GoldWiseLedgerCategorize(ENTRY_ID, "other")`. Expect `net change labeled other (user-reported)`. Repeat with `"unclassified"` to clear it. Share statuses only.

On November 9, 2026, the owner reported that the installed ledger's positive net change matched a quest reward and was labeled `unclassified`. The owner then confirmed both expected responses when labeling the entry `other` and clearing the classification. The entry ID is omitted.

## Session ledger behavior

- The model accepts validated integer copper samples for one character and build. It keeps one current baseline and at most 64 net changes in memory. The installed adapter allows at most five minutes between samples. A stale interval starts a new baseline without adding an entry.
- Missing, invalid, mismatched, or out-of-order samples supply no new baseline or entry. An unchanged balance updates the baseline without adding a change.
- Entries carry timestamps, source, signed net change, and attribution. The player can categorize a change as a sale, purchase, or other and undo it. A categorized entry remains a net balance change with user-reported confidence. The model never treats that value as sale proceeds or a verified transaction.
- Reloading or changing character clears the session ledger. The installed commands use no SavedVariables fields. Rollback removes the adapter and model from the manifest without a data migration.
