# Data provenance and licenses
## GW-003 decision

Reviewed on November 9, 2026 against WoW Forever `1.60.1`, build `70862`, interface `16001`. GoldWise can use the verified player-local observations below within their stated scope. The audit found no reviewed external dataset with both reuse permission for GoldWise and verified coverage of the target build or market. The bundled recipe, trainer, and price datasets remain empty. [GW-001 client evidence](https://github.com/DubluD3/GoldWise/blob/cc1bdfc27321724077543c8d03dea001edcb3312/docs/research/API_EVIDENCE.md#gw-001-startup-evidence)

### Local observations

| Source | Evidence and coverage | Project decision |
|---|---|---|
| Blizzard's local crafting view, GW-009 / API-005 | `OBSERVED-IN-GAME` on `70862`. The owner confirmed that the installed addon matched the open crafting window. The probe verified a filtered set of learned recipes for one character. | Use the observed skill and learned rows locally with character, build, source, and time provenance. An absent recipe remains unknown. Reagents, trainer sources, and skill-up thresholds require separate evidence. [API-005](https://github.com/DubluD3/GoldWise/blob/c4fdf0eaaec597b76c4162c9bdc9452d79af0bef/docs/research/API_EVIDENCE.md#api-005--gw-009-profession-context) |
| Blizzard's local Auction House browse cache, GW-010 / API-006 | `OBSERVED-IN-GAME` on `70862`. A native search yielded a partial cache observation with 128 observed of 154 reported rows. The owner separately confirmed the installed addon returned correct data. | Use only a timestamped, local observation with completeness and browse-cache provenance. A browse minimum is an asking-price observation with unverified unit basis. Market identity and durable history remain blocked under GW-011. [API-006](https://github.com/DubluD3/GoldWise/blob/75d1f28b8da575033bcf2fbd1b43b99b0c81c370/docs/research/API_EVIDENCE.md#api-006--gw-010-auction-house-browse-cache) · [API-012](https://github.com/DubluD3/GoldWise/blob/3dfb4d78a1747678f35fc80c75de540d95e07643/docs/research/API_EVIDENCE.md#api-012--gw-011-market-scope) |
| GoldWise synthetic fixtures | Authored for offline tests. They have no live build or market coverage. | Test use only. Never load them as a fallback for real observations. |

Local use is a GoldWise scope decision under the [policy review](../compliance/BLIZZARD_POLICY.md). It does not grant redistribution rights. Attribute the local sources as Blizzard's crafting view or Auction House browse cache in provenance. Keep observations on the player's device.

### External sources reviewed

Publisher statements below establish what each publisher declares. Coverage or rights inherited from an upstream source require independent verification. All links were reviewed or attempted on November 9, 2026.

| Source and publisher | Version, quality, and permission evidence | Decision |
|---|---|---|
| Forever Journal, X1X | `COMMUNITY-REPORTED` build `1.60.1.70790`. The site documents a mixture of client tables and Classic or community data and reserves rights in its compiled content and translations. Some upstream contributions are described as uncleared. [Publisher provenance and rights](https://x1x.tw/wow/en/about/) | Reference only. Exclude the compiled dataset, translations, and upstream tables. A similar client version does not verify current Forever data. |
| Forever Twinking and upstream wago.tools client tables | `COMMUNITY-REPORTED` build-specific extracts mixed with community observations and Classic baselines. The source page credits wago.tools and identifies the underlying tables as Blizzard data. The reviewed page provides no primary Blizzard grant for bundling those tables. [Publisher provenance](https://forevertwinking.com/sources) | Reference only. Block repackaging extracts or combining inherited values into a Forever catalog without field-level rights and target-build proof. |
| Classic-DB, CMaNGOS | `COMMUNITY-REPORTED` Classic patches `1.12.1` through `1.12.3`, builds `5875`, `6005`, and `6141`. The project declares GPLv3 and requires retaining its license file on redistribution. Its copyright notice separately identifies Blizzard material outside that grant. [Project README](https://github.com/cmangos/classic-db/blob/master/README.md) · [Copyright notice](https://github.com/cmangos/classic-db/blob/master/COPYRIGHT.md) | Exclude the database. It has the wrong game version and a separate upstream rights question. |
| Wowhead, Fanbyte/ZAM | `UNKNOWN` for field-level build provenance and permission to redistribute a recipe or trainer dataset in GoldWise. The publisher's terms landing page was located, and no dataset-specific redistribution grant was verified. [Publisher terms](https://help.zam.com/support/solutions/articles/27000016858-terms-of-service) | Reference only. Exclude scraped lists, guides, descriptions, and icons. |
| Auctionator, plusmouse | The publisher lists Forever support and release `343` on November 8, 2026. Its license page reserves rights unless explicitly stated. The addon listing does not establish a redistribution grant or an independently attributable market feed. [Publisher license and release listing](https://www.curseforge.com/wow/addons/auctionator/license) | Exclude bundled files, code, and copied scan history. |
| TradeSkillMaster, TradeSkillMaster LLC | Provider docs describe public CSV access and a separate addon API. The reviewed CSV version list contains Retail, Classic, and Classic Progression. Forever coverage and redistribution permission for bundled copies are `UNKNOWN`. [Pricing docs](https://tradeskillmaster.com/public-data) · [Addon API overview](https://support.tradeskillmaster.com/en_US/api-documentation/what-is-the-tsm-addon-api-and-how-do-i-use-it) · [Provider terms](https://tradeskillmaster.com/terms) | Exclude CSVs and integration in this story. Any optional GW-012 adapter requires its own permission, Forever scope and freshness evidence, and policy review. |
| Blizzard Developer APIs, Blizzard Entertainment | `OFFICIAL` legal index links separate Developer API terms. The primary terms page returned HTTP 403 during review, so current terms for the intended use were not verified. A November 6 community report describes auction endpoint results across multiple Forever houses and warns of overlap across rulesets. `COMMUNITY-REPORTED` only. [Blizzard legal index](https://www.blizzard.com/en-us/legal/) · [Developer API terms](https://www.blizzard.com/en-us/legal/a2989b50-5f16-43b1-abec-2ae17cc09dd6/blizzard-developer-api-terms-of-use) · [Community report](https://us.forums.blizzard.com/en/blizzard/t/wow-forever-api-what-works-so-far-plus-a-ts-client/60334/3) | Block importing, redistributing, or querying this web source for GoldWise. Verify the applicable terms and the mapping from a market to the target build, region, ruleset, and house before proposing integration. |

### Missing, stale, and unsupported data

- A verified local recipe row explicitly marked learned is evidence that the character knows it. A filtered-out recipe has unknown status. A missing or unsupported view supplies no new recipe evidence.
- A partial browse observation supplies only its observed rows. Missing rows do not imply zero supply or zero price. A browse minimum and quantity cannot establish a completed sale, demand, or sale probability.
- A missing market observation, mismatched scope or build, or stale observation supplies no current price. Never substitute another ruleset, synthetic price, or Classic data.
- GW-013 can model observed recipes with explicit unknown or unavailable fields. A trainer catalog and unobserved skill thresholds stay outside that evidence. GW-012 stays gated on GW-011 and provider review.

### Approval and rollback

The project owner approved merging the local-only source decision and the exclusions. Keep external sources blocked until permission for the specific files and transformations, compatible attribution, and current-build coverage are documented. When a publisher's terms are unclear, resolve the question with the rights holder before use. Recheck on the next client patch or a change to provider terms or data. This audit changes documentation only and can be reverted without data cleanup.

Each external dataset needs:
- Dataset name/author, canonical URL and retrieval timestamp.
- License text/terms, permission for redistribution/derivatives, attribution.
- WoW build/version and realm/region/ruleset scope.
- Method of extraction; recipe/item source confirmation.
- Transform steps, checksum, confidence and expiry. GW-003 has no imported artifacts to transform or checksum.
- Removal/update plan and explicit owner approval.

**Do not include competitor source code or datasets** merely because they are visible online. A public GitHub repository without appropriate license does not grant unrestricted reuse. Keep synthetic fixtures clearly labeled, never substitute them for real market observations.

### GW-018 synthetic test data (2026-11-12)
The fictional `tests/item_choices.lua` item identifiers, 100-cloth conversion, prices and fee examples are authored test-only data. They are **not** Forever recipes, vendor values, observed market prices or verified charges. The corresponding pure domain implementation does not import any third-party dataset and never consults external providers.
