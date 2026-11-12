# GoldWise privacy and data handling (QA candidate)

**Last updated:** 2026-11-12. Product status: development / client test candidate. GoldWise is an unofficial, free, transparent WoW: Forever addon. It is not affiliated with Blizzard Entertainment.

## What GoldWise observes

On explicitly supported Forever builds, the addon uses the game client's existing local interface to read character-specific context such as client version, character scope (realm, faction, region and character identifier), and when requested, carried bag item IDs/counts, the player's visible profession and learned recipe rows, already-present native Auction House **browse-cache** results, base vendor price references and manually sampled character money. Read-only data can be temporarily combined into per-session plans and manually labeled balance changes. Bank and persistent alternate-character inventories are **not** implemented in this candidate.

Observations represent what was readable at the observation time; unobserved or filtered fields do not mean zero, absent or available. Auction House asking prices are **not** confirmed sales, buyer demand or guaranteed proceeds. The item-economics alternative model uses fictional prices in offline tests only; it does not run a live automated trading strategy.

## Local storage and retention

- `GoldWiseDB`: a bounded account-local SavedVariables schema (version 1) holding last-observed timestamps keyed by character context (at most 64 scope records); game client stores the file in its usual `WTF` account SavedVariables directory.
- `GoldWiseGuideDB`: separate account-local SavedVariables schema (version 1) holding only a finished boolean, a current guide step and skipped-step flags. A skipped step never means a scan succeeded.
- Character inventory/profession/AH browse observations, reagent reservations, recipe plans and ledger entries currently remain **in memory for the session**, not a permanent economic transaction or market history. On reload, read-only observation caches must be refreshed.
- The addon does not store unrelated account credentials, email, chat, precise GPS, outside-app documents, or payment card details.

GoldWise has no accounts, advertising identifiers, tracking, telemetry, companion app, cloud synchronization, user data upload, or third-party network calls. A future sync/provider feature would need a separate explicit approval and disclosure. Blizzard and the WoW client are separate software; their handling of your game account is governed by their own policies.

## Choices, deletion and limitations

Use the in-game Guide button or `/goldwise guide` for scan explanations. GoldWise does not buy, post, cancel, craft, equip, mail, gather or move for you, and never simulates input. Do not enable it on an unsupported client build.

Disabling/removing the addon folder stops its execution but does **not** automatically delete Blizzard-managed SavedVariables. To remove GoldWise's local data, first close the game, back up your `WTF` data, and then remove only GoldWise's corresponding SavedVariables entries/file from the correct account. Review the actual folder and avoid deleting another addon's data. Do not send raw SavedVariables in public bug reports because their scope keys may include character identifiers.

No guarantee is made of compatibility on all builds, availability of all source data, or immunity from Blizzard policy changes. Report suspected privacy/security issues via the repository issue tracker without including character names or private saved data.

## Questions

Project: https://github.com/DubluD3/GoldWise
