local Fixture = assert(loadfile("tests/fixtures/ForeverClient.lua"))()

local function load(build)
    local client = Fixture.new(Fixture.build("1.60.1", build, 16001))
    local globals = client.globals
    local sample = { at = 100, balance = 12345, moneyReads = 0 }
    globals.GetMoney = function()
        sample.moneyReads = sample.moneyReads + 1
        return sample.balance
    end
    globals.GetServerTime = function() return sample.at end
    globals.issecretvalue = function(value) return value == sample.restricted end
    globals.UnitGUID = function() return "fixture:one" end
    globals.GetRealmName = function() return "Fixture Realm" end
    globals.UnitFactionGroup = function() return "Fixture Faction" end
    globals.GetCurrentRegion = function() return 3 end
    local addon = {}
    client:loadToc("GoldWise.toc", "GoldWise", addon)
    assert(sample.moneyReads == 0)
    return client, globals, sample, addon
end

local function last(client)
    return client.output[#client.output]
end

local client, globals, sample, addon = load("70862")
assert(client:fire("ADDON_LOADED", "GoldWise"))
local saved = globals.GoldWiseDB
assert(saved.schemaVersion == 1 and next(saved.lastObservedAt) == nil)
assert(client:fire("PLAYER_ENTERING_WORLD", true, false) and sample.moneyReads == 0)
globals.GoldWiseLedgerSample()
assert(last(client) == "GoldWise ledger: baseline recorded." and sample.moneyReads == 1)
sample.at, sample.balance = 102, 12349
globals.GoldWiseLedgerSample()
assert(last(client) == "GoldWise ledger: entry=102, net change=+4 copper, unclassified.")
globals.GoldWiseLedgerCategorize(102, "sale")
assert(last(client) == "GoldWise ledger: net change labeled sale (user-reported)." and sample.moneyReads == 2)
globals.GoldWiseLedgerCategorize(102, "unclassified")
assert(last(client) == "GoldWise ledger: classification cleared." and sample.moneyReads == 2)
print("PASS installed ledger records a manual baseline and labels an explicit entry without another read")

sample.at, sample.balance, sample.restricted = 103, 999, 999
globals.GoldWiseLedgerSample()
assert(last(client) == "GoldWise ledger: balance or timestamp unavailable.")
sample.at, sample.balance = 104, 12350
globals.GoldWiseLedgerSample()
assert(last(client):find("net change=+1 copper", 1, true))
globals.GoldWiseLedgerSample()
assert(last(client):find("sample time did not advance", 1, true))
sample.at = 405
globals.GoldWiseLedgerSample()
assert(last(client):find("baseline expired", 1, true))
print("PASS restricted, duplicate, and expired samples are handled without creating changes")

addon.characterSnapshot = { scopeKey = "fixture:other" }
globals.GoldWiseLedgerCategorize(102, "sale")
assert(last(client):find("entry unavailable", 1, true))
globals.GoldWiseLedgerSample()
assert(last(client) == "GoldWise ledger: baseline recorded.")
assert(globals.GoldWiseDB == saved and saved.schemaVersion == 1 and next(saved.lastObservedAt) == nil)
for field in pairs(saved) do
    assert(field == "schemaVersion" or field == "lastObservedAt")
end
print("PASS changing character scope drops the session ledger and leaves SavedVariables untouched")

client, globals, sample = load("70863")
globals.GoldWiseLedgerSample()
assert(last(client):find("client build unverified", 1, true) and sample.moneyReads == 0)
client, globals, sample = load("70862")
globals.GoldWiseLedgerSample()
assert(last(client):find("character snapshot unavailable", 1, true) and sample.moneyReads == 0)
assert(client:fire("PLAYER_ENTERING_WORLD", true, false))
globals.issecretvalue = nil
globals.GoldWiseLedgerSample()
assert(last(client):find("guard unavailable", 1, true) and sample.moneyReads == 0)
print("PASS unsupported build, missing character, and missing guard block installed balance reads")
