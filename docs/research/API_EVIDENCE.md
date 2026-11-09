# Forever API evidence register

**Live evidence on 2026-11-09:** The owner ran the build-identity probe on Forever `1.60.1`, build `70862`, interface `16001`. Each row tracks the specific behavior covered by that evidence. Before implementing a call, capture the exact signature, returns, events, build, and any required in-game result.

## Sources to verify
1. Official Blizzard addon policy: https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642 (reviewed 2026-11-09).
2. Client-extracted community index: https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/README.md (extraction 2026-10-01, build 70170, interface 16001; **not current live proof**).
3. Searchable extracted catalog: https://atraeau.github.io/WoW-Addons/ (build 70170).
4. Community compatibility report: https://wowforeveraddons.com/articles/wow-forever-addon-api (updated 2026-11-02; non-official).
5. Blizzard EULA: https://www.blizzard.com/en-us/legal/ (locate the current EULA from Blizzard's legal index).

## Research matrix
| ID | Candidate namespace / behavior | Evidence class | Current build verified? | Implementation status |
|---|---|---|---|---|
| API-001 | `GetBuildInfo` / TOC interface | CLIENT-EXTRACTED signature; OBSERVED-IN-GAME first four returns | YES for build metadata on `70862` | Use observed interface `16001` for the GW-004 load test |
| API-002 | addon lifecycle events and SavedVariables | CLIENT-EXTRACTED signatures; OBSERVED-IN-GAME probe and product schema | YES for `ADDON_LOADED` and GW-005 initialization and restoration on `70862` | GW-005 live smoke test passed |
| API-003 | `C_Container` bag slots, occupancy, and stack quantity | CLIENT-EXTRACTED signatures; OBSERVED-IN-GAME probe and product scan | YES for the manual carried-bag scan on `70862` | GW-008 live smoke test passed |
| API-004 | `C_Item` item details/cache behavior | CLIENT-EXTRACTED | NO | BLOCKED |
| API-005 | open crafting profession, skill, cap, and observed learned recipes | CLIENT-EXTRACTED signatures and UI usage; OBSERVED-IN-GAME probe and product scan | YES for the manual open-window path on `70862` | GW-009 open-window smoke test passed |
| API-006 | AH readiness, browse cache, and result events | CLIENT-EXTRACTED signatures and UI usage; OBSERVED-IN-GAME probe and product read | YES for the reported ready and browse update/cache path on `70862` | Manual cache observation passed live smoke testing |
| API-007 | character balance and money event | OBSERVED-IN-GAME manual balance read and timestamp; CLIENT-EXTRACTED money event | YES for the manual read on `70862` | Manual balance read verified; event unverified |
| API-008 | realm/faction/character context | CLIENT-EXTRACTED signatures; OBSERVED-IN-GAME probe and product capture | YES for readable player fields and entry callbacks on `70862` | GW-007 live smoke test passed |
| API-009 | tooltip and safe UI events | UNKNOWN live behavior | NO | BLOCKED |
| API-010 | AH deposit/cut by auction type | UNKNOWN live behavior | NO | BLOCKED |
| API-011 | TOC Lua loading and local startup status | CLIENT-EXTRACTED manifest and namespace; OBSERVED-IN-GAME startup status | YES on login and `/reload` on `70862` | GW-004 live smoke test passed |
| API-012 | active Auction House market discriminator | CLIENT-EXTRACTED game-mode candidate; market identity UNKNOWN | NO | BLOCKED-API-VERIFICATION |

## GW-001 startup evidence

The following signatures come from a Blizzard-generated UI source export mirrored by the community. The export identifies itself as Forever `1.60.1.70658` (October 28, 2026). Its declarations establish what that build documented. Record the actual running build separately. [Export provenance](https://github.com/reckhou/WoWBlzCode/tree/7245053a9f2cab5ea5e1ac5221489329d28b320c#current-versions)

### API-001 · Build identity

- Source class and access: `CLIENT-EXTRACTED`, 2026-11-09 09:50 UTC. [BuildDocumentation.lua](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/BuildDocumentation.lua)
- Signature: global `GetBuildInfo()` takes no arguments. It returns `buildVersion: cstring`, `buildNumber: cstring`, `buildDate: cstring`, `interfaceVersion: number`, `localizedVersion: cstring`, and `buildInfo: string`, in that order. The export declares all six non-nil and lists no secret-value annotation for this symbol.
- Lifecycle and rate: the owner ran the probe once after login. It registers no event and uses no polling. Behavior in other lifecycle states and any rate limits remain `UNKNOWN`.
- Classification: read-only build metadata. The probe runs locally and prints the first four values in the chat window. Share only that output.
- Observed in game: `PASS`, owner-reported on 2026-11-09. Output: `1.60.1 70862 Nov 6 2026 16001`. `Nov 6 2026` is the returned build date.
- Decision: `VERIFIED` for the four values consumed by the probe on build `70862`. `localizedVersion` and `buildInfo` remain client-extracted. Use the observed interface for the GW-004 TOC and validate actual loading separately. Recheck on client patches.

#### Manual probe

Select **World of Warcraft: Forever** in Battle.net, log in on a character in a safe area, and paste this single line into the in-game chat box. Run it once.

```text
/run local ok,v,b,d,i=pcall(GetBuildInfo);if ok and type(v)=="string" and v~="" and type(b)=="string" and b~="" and type(d)=="string" and d~="" and type(i)=="number" and i>0 then print(v,b,d,i) else print("GW-001: build unavailable") end
```

- **Normal:** record the version, build number, build date, interface number, and time observed in UTC. The reported interface number is a candidate for the GW-004 TOC. A load test still has to establish that the addon works on that build.
- **Missing or partial:** a missing function, an error, or incomplete metadata prints `GW-001: build unavailable`. If the command itself is unavailable or gives no output, record that outcome. Keep API-001 blocked and use the client UI's displayed version/build as partial evidence if available.
- **Wrong client or stale evidence:** if the result comes from a different game version, or the client has patched since the observation, keep it separate from evidence for the current Forever build.

Offline verification on 2026-11-09 used the exact Lua from the chat command and a stubbed `GetBuildInfo` in Lua 5.1.5. All seven cases passed: complete result, missing function, thrown error, missing interface, empty build, wrong interface type, and zero interface.

### API-002 · Lifecycle events and persistence

- Source class and access: `CLIENT-EXTRACTED`, 2026-11-09 09:50 UTC. [AddOnsDocumentation.lua](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua) · [SystemDocumentation.lua](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/SystemDocumentation.lua)
- The export declares synchronous `ADDON_LOADED(addOnName: cstring, containsBindings: bool)`, `PLAYER_LOGIN()`, and `PLAYER_LOGOUT()`. It declares `C_AddOns.GetAddOnMetadata(name: uiAddon, variable: cstring) -> value: cstring` with `SecretArguments = AllowedWhenUntainted`.
- `CLIENT-EXTRACTED`, accessed 2026-11-09. The `70658` export contains the account-wide `## SavedVariables: <global>` declaration and `EventUtil.RegisterOnceFrameEventAndCallback(frameEvent, callback, ...)`. The Lua function filters event payload values against the supplied arguments, unregisters on the first match, and forwards the payload to the callback. It returns no value. The GW-005 probe uses `ADDON_LOADED` and filters on its own addon name. [Manifest example](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_AuctionHouseUI/Blizzard_AuctionHouseUI.toc) · [EventUtil.lua](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_SharedXML/EventUtil.lua#L71)
- `COMMUNITY-REPORTED`, accessed 2026-11-09. Beta players reported saved values disappearing at cold launch. The report concerns beta builds. [Beta report](https://us.forums.blizzard.com/en/wow/t/wowf-beta-addon-savedvariables-appear-to-write-correctly-to-disk-but-are-not-restored-at-startup/2356559)
- `OBSERVED-IN-GAME`, owner-reported on 2026-11-09. The [GW-005 probe](../development/STORAGE_PROBE.md) reported the marker present at `ADDON_LOADED` after `/reload` and after quitting and reopening Forever build `70862`. A separate relog via character selection was `NOT RUN` for the probe.
- `OBSERVED-IN-GAME`, owner-reported on 2026-11-09. GoldWise `0.1.1-dev` on build `70862` reported `GoldWise local storage created (schema 1).` on first login. It reported `GoldWise local storage current (schema 1).` after `/reload`, a relog via character selection, and a full quit and reopen.
- Decision: `VERIFIED` for probe restoration and for initialization and restoration of the product's empty schema v1 on `70862`. The adapter uses the same one-shot `ADDON_LOADED` registration and its own account-wide `GoldWiseDB`. Migration and rejected-data paths were exercised offline. `PLAYER_LOGIN`, `PLAYER_LOGOUT`, and metadata lookup still require their own evidence before use.

### API-011 · GW-004 manifest and startup output

- `CLIENT-EXTRACTED`, accessed 2026-11-09. The Forever `70658` export uses `.toc` file entries to load Lua and passes a private addon table as the second top-level argument. [Manifest](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_ChatFrameBase/Blizzard_ChatFrameBase.toc) · [Lua entry example](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua#L1)
- `OBSERVED-IN-GAME` on `70862` after login. The API-001 probe successfully used `GetBuildInfo()` followed by local `print(...)` with display arguments. The bootstrap calls `GetBuildInfo()` once via `pcall` and uses `print(message: string)` once for local status. It does not consume a return value from `print`.
- `OBSERVED-IN-GAME`, owner-reported on 2026-11-09. Both login and `/reload` displayed `GoldWise 0.1.0-dev: loaded on Forever build 70862. Gameplay features disabled`. The message comes from the TOC-loaded Lua file after it initializes the private table and checks the build.
- Decision: `VERIFIED` for this bootstrap's startup path on login and `/reload` on `70862`. Missing, failing, and mismatched build checks passed with offline stubs. Lifecycle events, metadata lookup, and SavedVariables still require separate evidence.

### API-008 · GW-007 character context

The following candidates are `CLIENT-EXTRACTED` from Forever build `70658`, accessed November 9, 2026. [Function index](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/functions.txt) · [Event index](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/events.txt)

| Call or event | Exported signature and probe usage |
|---|---|
| `UnitGUID` | `UnitGUID(unit: UnitTokenPvPRestrictedForAddOns) → result?: WOWGUID`. The export flags identity-restricted results as secret. Probe passes only `player` and treats a readable result as opaque. |
| `GetRealmName` | `GetRealmName() → realmName: cstring`. Probe records availability and compares the reported context across a reload. The returned value's scope is unverified. |
| `UnitFactionGroup` | `UnitFactionGroup(unitName: cstring, checkDisplayRace: bool = false) → factionGroupTag: cstring, localized: cstring`. Probe passes `player` and checks the first return. |
| `GetCurrentRegion` | `GetCurrentRegion() → region: number`. Probe checks for a positive integer without mapping it to a region label. |
| `GetServerTime` | `GetServerTime() → time: number`. Probe checks for a positive integer and uses the client value as a timestamp candidate. |
| `issecretvalue` | `issecretvalue(value: LuaValueReference) → isSecret: bool`. Probe calls it before checking or formatting a candidate value. A failed check suppresses that value. |
| `PLAYER_ENTERING_WORLD` | Synchronous event with `isInitialLogin: bool` and `isReloadingUi: bool`. The disposable addon subscribes once through the source-backed helper in API-002. This event path requires live verification. |

The [disposable probe](../development/CHARACTER_PROBE.md) is local and read-only. It queries the player once per load or on a manual request and prints availability and local comparison tags. It neither stores nor sends player identifiers. A missing, secret, or invalid field leaves the candidate unavailable. The pure snapshot model requires complete context and falls back to no snapshot.

`OBSERVED-IN-GAME`, owner-reported on 2026-11-09. After the first probe produced no output, v2 reported on automatic login, automatic reload, and the manual command. Character and realm tags appeared and faction, region, and time each reported `ok`. The two characters produced different character tags. No raw values or tags were recorded. The owner did not report a separate comparison of the same character's tag across reload.

`OBSERVED-IN-GAME`, owner-reported on 2026-11-09. GoldWise `0.1.2-dev` displayed `GoldWise character snapshot ready.` on login and after `/reload` on build `70862`.

Decision: `VERIFIED` for readable player context and product capture on the two observed entry paths on build `70862`. The snapshot is scoped to the reported realm context and stays in memory for the session. Same-character scope stability was exercised offline.

One `COMMUNITY-REPORTED` launch diagnostic describes a different value for `GetRealmName` than the second return from `UnitFullName`. Treat the observed realm as client context. Market or realm-wide identity semantics need separate evidence. [Launch diagnostic](https://eu.forums.blizzard.com/en/wow/t/wow-forever-1601-addon-communication-stopped-working-after-launch-invalidchannel-7/640089)

### API-003 · GW-008 carried bag inventory

These declarations are `CLIENT-EXTRACTED` from Forever build `70658`, accessed November 9, 2026. [Functions](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/functions.txt) · [Enums](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/enums.txt) · [Structures](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/structures.txt)

| Candidate | Signature and probe usage |
|---|---|
| `C_Container.GetContainerNumSlots` | `(containerIndex: BagIndex) → numSlots: number`. Read once per carried bag. |
| `C_Container.HasContainerItem` | `(containerIndex: BagIndex, slotIndex: luaIndex) → hasItem: bool`. Distinguish an observed empty slot from unavailable item information. |
| `C_Container.GetContainerItemInfo` | `(containerIndex: BagIndex, slotIndex: luaIndex) → containerInfo: ContainerItemInfo`, may return nothing. Read only occupied slots. The export lists `itemID: number`, `stackCount: number`, and `itemName: string`. The last is optional for the probe's local sample display. |
| `Enum.BagIndex` | `Backpack=0`, `Bag_1=1`, `Bag_2=2`, `Bag_3=3`, `Bag_4=4`, `ReagentBag=5`. The probe resolves these by name. Bank containers, keyring, and alts are out of this probe's scope. |

The [disposable probe](../development/INVENTORY_PROBE.md) runs on manual request, checks results with `issecretvalue`, and uses `GetServerTime` for the observation timestamp. The model caps work at 128 slots per bag as a project limit. Missing or restricted values produce partial or unavailable observations. Bank and alt inventory are unobserved. No bag-update event, item-cache call, or inventory action is used.

`OBSERVED-IN-GAME`, owner-reported on 2026-11-09. On build `70862` the probe reported `bags=complete`, with all six carried bags individually `complete` and bank and alts `unobserved`. The sample in backpack slot 1 reported stack `1` and carried total `1`. A separate comparison to the visible bags was not reported. The sample item name is omitted here.

`OBSERVED-IN-GAME`, owner-reported on 2026-11-09. The installed GoldWise `0.1.3-dev` manual scan produced the same complete six-bag result and sample stack and carried total of `1`. Bank and alts were reported as unobserved.

Decision: `VERIFIED` for the manual carried-bag read path in the probe and installed addon on `70862`. Aggregation across multiple stacks and partial or unavailable refreshes were exercised offline. Inventory is an in-memory observation with a timestamp, and a failed refresh clears the previous observation.

### API-005 · GW-009 profession context

These signatures and call sites are `CLIENT-EXTRACTED` from Forever build `70658`, accessed November 9, 2026. [Functions](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/functions.txt) · [Structures](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/structures.txt) · [Profession UI source](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_Professions.lua)

| Candidate | Signature and probe usage |
|---|---|
| `ProfessionsFrame.CraftingPage:IsVisible()` | Frame method `IsVisible() → isVisible: bool`. The probe requires the crafting page to be visible. The UI also checks this in `ProfessionsCraftingPageMixin:Refresh`. |
| `Professions.InLocalCraftingMode()` | `() → bool`, from shipped Lua. The helper rejects NPC crafting and external linked, guild, or guild-member lists. |
| `C_TradeSkillUI.GetChildProfessionInfo` and `GetBaseProfessionInfo` | Both take no arguments and return `ProfessionInfo`. Read `professionID`, `professionName`, `skillLevel`, and `maxSkillLevel`. Follow the shipped UI's base fallback when the child ID is zero. The probe uses the reported skill level without applying a modifier. |
| `C_TradeSkillUI.GetFilteredRecipeIDs` | The shipped Lua calls it with no arguments and iterates the result with `ipairs`. The return shape is inferred from that call site as an array of recipe IDs. The probe leaves the player's filters in place. |
| `C_TradeSkillUI.IsRecipeInSkillLine` | `(recipeID: number, skillLineID: number) → result: bool`. Check the active skill line before inspecting a recipe. |
| `C_TradeSkillUI.GetRecipeInfo` | `(recipeSpellID: number, recipeLevel?: luaIndex) → recipeInfo?: TradeSkillRecipeInfo`. Read `recipeID` and `learned`; optional `name` is used for one local sample. A missing row or a mismatched ID supplies no recipe evidence. |

The [disposable probe](../development/PROFESSION_PROBE.md) runs on manual request in the player's open crafting window on build `70862`. It uses the verified `issecretvalue` guard and `GetServerTime`. It opens no frame, changes no filters, and initiates no crafting. It captures only recipes present in the filtered view and explicitly marked learned. A recipe absent from the list remains unknown.

`OBSERVED-IN-GAME`, owner-reported on 2026-11-09. The probe returned Leatherworking skill `87/150`, `recipes=filtered`, `observed learned=35`, and Camp Tent as a learned sample. The closed-window result was not reported. The base-profession fallback and external-view rejection were exercised offline.

`OBSERVED-IN-GAME`, owner-reported on 2026-11-09. The installed GoldWise `0.1.4-dev` manual scan passed and its reported data matched the open crafting window on build `70862`. The owner did not separately report the closed-window result.

Decision: `VERIFIED` for the manual read of an open local crafting window in the probe and installed addon on `70862`. Closed-window handling, base-profession fallback, and rejection of external views passed offline checks.

### API-006 · GW-010 Auction House browse cache

These signatures and UI call sites are `CLIENT-EXTRACTED` from Forever build `70658`, accessed November 9, 2026. [Functions](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/functions.txt) · [Events](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/events.txt) · [Structures](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/structures.txt) · [Blizzard browse frame](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseBrowseResultsFrame.lua)

| Candidate | Signature and probe use |
|---|---|
| `AuctionHouseFrame.BrowseResultsFrame:IsVisible()` | `IsVisible() → bool`. Check the shipped browse frame and its parent without modifying either. |
| `C_AuctionHouse.IsThrottledMessageSystemReady` | `() → canSendThrottledMessage: bool`. Probe checks at arm and read. False or unavailable stops that attempt. The probe does not infer a cooldown length. |
| `C_AuctionHouse.GetBrowseResults` | `() → browseResults: table<BrowseResultInfo>`. The shipped UI uses this for replacement browse rows. The probe reads it once on explicit request after observing an update. |
| `C_AuctionHouse.HasFullBrowseResults` | `() → hasFullBrowseResults: bool`. Describes the current browse result set. False or unavailable yields partial coverage. |
| `BrowseResultInfo` and `ItemKey` | Read only `itemKey`, `totalQuantity`, and `minPrice`, with key fields `itemID`, `itemLevel`, `itemSuffix`, and `battlePetSpeciesID`. `minPrice` is `BigUInteger` in the export. The model accepts only safe integer values and labels this a browse minimum in copper without inferring a unit basis or completed sale. |
| `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED`, `AUCTION_HOUSE_BROWSE_FAILURE`, `AUCTION_HOUSE_CLOSED` | Synchronous events with no payload. Subscribe once per event via the API-002 helper. A failure or close cancels the test. An update has no request ID and may also follow item or commodity activity. |

The [disposable probe](../development/AUCTION_PROBE.md) checks readiness, the observed event, and a bounded local cache sample on build `70862`. It uses the existing secret-value guard and `GetServerTime`. The player makes one native search. The probe makes zero requests and reads at most 128 rows. The cap is a project limit, independent of any Blizzard throttle.

`OBSERVED-IN-GAME`, owner-reported on 2026-11-09. On build `70862` the probe armed with `ready=yes`. The owner used Blizzard's Search button and saw a browse update. The second manual command reported `ready=yes`, `cache=partial`, 154 cache rows, 128 observed rows, and a sample the owner confirmed was correct. The 128-row limit was reached. The result does not establish the client's full-results flag or a cooldown duration. Item and price details are omitted.

`OBSERVED-IN-GAME`, owner-reported on 2026-11-09. The installed GoldWise `0.1.5-dev` manual observation returned correct data on build `70862`. Cache status, row counts, and sample details were not separately reported for the installed addon.

Decision: `VERIFIED` for the observed manual cache-read path on `70862`. The addon keeps a single character-scoped, timestamped observation in memory. Closed, failed, expired, and throttled paths passed offline checks.

`C_AuctionHouse.SendBrowseQuery(query: AuctionHouseBrowseQuery)` and `C_AuctionHouse.RequestMoreBrowseResults()` are documented candidates. Exact query attribution, addon-originated request behavior, and cooldown duration remain unverified. Addon-originated querying remains `BLOCKED-API-VERIFICATION` and requires the applicable [policy review](../compliance/BLIZZARD_POLICY.md). The official policy and EULA were rechecked November 9, 2026.

### API-012 · GW-011 market scope

- `OBSERVED-IN-GAME` on `70862` under API-008 and API-006. The addon has readable character region, reported realm, and player faction, and can read the visible browse cache. Those observations do not identify the auction market that returned the cache.
- `CLIENT-EXTRACTED` from build `70658`, accessed November 9, 2026. `C_GameRules.GetCurrentGameModeRecordID()` takes no arguments and returns `gameModeRecordID: number`, declared non-nil in the export. It is a candidate for recording mode context. Its behavior on `70862` and its relationship to an auction market are unverified. The pinned export search identified no read-only current market ID in `C_AuctionHouse`. [GameRules declaration](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/GameRulesDocumentation.lua) · [Function index](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/functions.txt)
- `COMMUNITY-REPORTED`, accessed November 9, 2026. A forum participant reported multiple auction-house IDs and overlapping results between rulesets in an external API. This is a research lead about why mode or faction alone may be insufficient. It does not map an in-client browse cache to a house ID. [Community report](https://us.forums.blizzard.com/en/blizzard/t/wow-forever-api-what-works-so-far-plus-a-ts-client/60334/3)
- Decision: `BLOCKED-API-VERIFICATION` for production retention. Require a supported discriminator tied to the visible browse context and evidence it stays stable within the same market and differs across separate markets. Keep the GW-010 in-memory observation until then. No new client call, external lookup, or SavedVariables write is used for GW-011. The offline history model takes an explicit market scope supplied by its caller.

## GW-003 dataset scope

GW-003 introduces no WoW API calls. For the actual target build and verified local observations, the [source audit](DATA_PROVENANCE.md#local-observations) links the pinned GW-001, GW-009, and GW-010 evidence, including exact call signatures and owner reports. The audit also records excluded web and client-extract sources. Web endpoint reports establish no in-client market identity.

## GW-013 recipe catalog and trainer requirements

- `OBSERVED-IN-GAME` on Forever `1.60.1`, build `70862`, interface `16001`. GW-009 verified local crafting-window reads for profession ID/name, current skill/cap, and filtered learned recipe IDs. An optional recipe name came from the same read. The GW-013 offline catalog consumes the normalized GW-009 snapshot. See the pinned evidence for signatures and the owner report. [API-005](https://github.com/DubluD3/GoldWise/blob/c4fdf0eaaec597b76c4162c9bdc9452d79af0bef/docs/research/API_EVIDENCE.md#api-005--gw-009-profession-context)
- `CLIENT-EXTRACTED` from Forever build `70658`, accessed November 9, 2026. `C_TradeSkillUI.GetRecipeRequirements(recipeID: number)` returns `table<CraftingRecipeRequirement>`, with `name: cstring`, `met: bool`, and `type: RecipeRequirementType`. The signature establishes no trainer identity or minimum trainer skill. `C_TooltipInfo.GetTrainerService(serviceIndex: luaIndex)` returns `TooltipData` when available, but service-to-recipe mapping and structured trainer requirements have no live proof. `C_TradeSkillUI.GetRecipeSchematic(recipeSpellID: number, isRecraft: bool, recipeLevel?: luaIndex)` returns `CraftingRecipeSchematic`. That is a candidate for later material and output evidence. None of these candidates is called by the catalog. [Pinned function index](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/functions.txt) · [Pinned structures](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/index/Forever/structures.txt)
- `UNKNOWN` on build `70862`. Trainer identity, unlock requirements, rank thresholds, materials, and outputs have no live evidence in GW-013. Trainer and catalog integration are `BLOCKED-API-VERIFICATION` where they require these fields. The model reports trainer data as unavailable. No source is imported. [GW-003 source audit](https://github.com/DubluD3/GoldWise/blob/1bb09037e54265d05f2cb28bcb4b8f275a0860db/docs/research/DATA_PROVENANCE.md)

### Selected trainer service probe

These are `CLIENT-EXTRACTED` candidates from Forever build `70658`, reviewed November 9, 2026. Legacy globals below come from Blizzard's shipped Lua call sites. Their exact declared types are unavailable in the generated index. The probe validates only the fields it uses and falls back to unavailable on any mismatch. [Trainer window definition](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_TrainerUI/Mainline/Blizzard_TrainerUI.xml) · [Trainer read call sites](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_TrainerUI/Mainline/Blizzard_TrainerUI.lua)

| Candidate | Evidence and probe usage |
|---|---|
| `ClassTrainerFrame:IsVisible()` | Existing frame method `() → isVisible: bool`, used on this frame by the shipped trainer bootstrap. Require the native trainer window to be open. [Trainer bootstrap](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_TrainerUI/Blizzard_TrainerUI_Bootstrap.lua) |
| `IsTradeskillTrainer()` | No arguments. Native code branches on the truthiness of the return. The probe accepts only true or legacy numeric true. |
| `GetTrainerSelectionIndex()`, `GetNumTrainerServices()` | Both take no arguments. Native code uses the results as the selected underlying service index and current service count, respectively. Require an integer index within the current count. A native selection can default to an existing service, so the tester explicitly selects the intended row and compares its name. |
| `GetTrainerServiceInfo(index)` | The native caller unpacks service name, service type, texture, required player level, subtext, and category. The probe reads only the first return and requires a readable string. |
| `GetTrainerServiceSkillReq(index)` | The native caller unpacks skill, rank, and a requirement flag used for color. The probe reads the first two, requires a readable skill string and positive integer rank, and makes no interpretation of the flag. |
| `C_TooltipInfo.GetTrainerService(index)` | Generated signature above. The native tooltip handler maps the trainer setter to this getter and reads `tooltipData.type` generically. Other native tooltip rules use `tooltipData.id`. A readable ID on a trainer result of `Enum.TooltipDataType.Spell` is an `INFERRED` identity candidate only. An absent or differently typed payload is unavailable. [Tooltip handler](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua) · [Tooltip data rules](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataRules.lua) · [Type enum](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua) |

The disposable probe reads one selected service after a player command. A second command compares a spell candidate within five minutes against API-005 in the player's visible local crafting view. It requires matching profession name, recipe ID, recipe name and skill-line membership. These checks can establish evidence for one tested service. They establish neither a complete trainer catalog nor a general mapping for trainer wrappers or profession ranks. The probe does not change selection, modify any frame, register events, train, craft, or persist data. Live verification is `NOT RUN` and production trainer integration remains blocked.

### API-007 · GW-021 character balance

- `CLIENT-EXTRACTED` from Forever build `70658`, accessed November 9, 2026. Global `GetMoney() → result: number` takes no arguments, with a non-nil return in the export. The native money frame passes the result, adjusted for cursor and trade money, into copper-based display formatting. The test compares against the player's purse outside trade and with no money attached to the cursor. [PlayerScript declaration](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/PlayerScriptDocumentation.lua) · [Money frame source](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_MoneyFrame/Shared/MoneyFrame.lua)
- `CLIENT-EXTRACTED` from the same build. `PLAYER_MONEY()` is a synchronous event with no documented payload. Its live trigger and coverage are `UNKNOWN`. The probe registers no event. [CurrencyInfo declaration](https://github.com/reckhou/WoWBlzCode/blob/7245053a9f2cab5ea5e1ac5221489329d28b320c/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua)
- The [disposable probe](../development/MONEY_PROBE.md) uses the build gate from API-001, local output from API-011, and the existing API-008 `issecretvalue` and `GetServerTime` checks. On explicit request it reads the candidate once and displays a readable nonnegative integer copper balance locally. Missing, failing, invalid, or restricted reads report unavailable. It stores no balance and uses no transaction or automatic event path.
- `OBSERVED-IN-GAME`, owner-reported on November 9, 2026. On Forever build `70862`, the disposable probe's copper amount matched the owner's purse and it reported `timestamp readable`. The amount is private and omitted.
- `OBSERVED-IN-GAME`, owner-reported on November 9, 2026. The installed GoldWise `0.1.6-dev` ledger reported a positive net copper change that matched a quest reward and marked the entry `unclassified`. The reward's cause came from the owner. The sample itself supplied only the net change. The entry ID is omitted.
- `OBSERVED-IN-GAME`, owner-reported on November 9, 2026. The owner confirmed that labeling the entry `other` reported user attribution and that setting it back to `unclassified` reported the classification cleared.
- Decision: `VERIFIED` for the manual balance read in the tested context. The product uses one guarded balance and timestamp read per manual sample. An observed delta supplies neither transaction type nor sale evidence. Manual categorization supplies the user's attribution. Automatic money events remain `BLOCKED-API-VERIFICATION`. Ledger samples and classifications stay in memory for the session.

## GW-023 verification boundary

GW-023 splits existing offline tests into syntax, unit, and adapter contract checks. The matrix uses synthetic fixtures and exercises the documented contracts without a live game client. It adds no new WoW calls or live API evidence. [Test strategy and fixture policy](../development/TEST_STRATEGY.md#fixture-policy)

## Evidence record template (copy per symbol)
- Symbol and exact namespace:
- Purpose / story:
- URL + accessed UTC timestamp:
- Source class: OFFICIAL / CLIENT-EXTRACTED / COMMUNITY-REPORTED / OBSERVED-IN-GAME / INFERRED / UNKNOWN:
- Exact parameters, types, returns:
- Events and lifecycle:
- Game version / build / interface:
- In-game probe used + sanitized output:
- Error/nil/secret-value handling:
- Rate/cooldown behavior:
- Policy/protected action classification:
- Decision: VERIFIED / UNVERIFIED / UNSUPPORTED / BLOCKED:
- Fallback and next review date:

## Test probe rules
Use harmless, read-only console inspection of known symbols; do not query AH until trigger/cooldown semantics verified. Record client version using supported client UI. Never spam APIs, try protected calls or run automation. Ask owner to execute controlled client probes; Codex cannot assert test success from generated code alone.
