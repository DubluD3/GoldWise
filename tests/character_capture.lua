local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")

local function product(id, build, prepare)
    local client = ForeverClient.new(ForeverClient.build("1.60.1", build or "70862", 16001))
    local globals = client.globals
    local identityReads = 0
    globals.issecretvalue = function(value) return value == "restricted fixture value" end
    globals.UnitGUID = function(unit)
        assert(unit == "player")
        identityReads = identityReads + 1
        return id
    end
    globals.GetRealmName = function() return "Fixture Realm" end
    globals.UnitFactionGroup = function(unit)
        assert(unit == "player")
        return "Fixture Faction"
    end
    globals.GetCurrentRegion = function() return 3 end
    globals.GetServerTime = function() return 1794220000 end
    if prepare then
        prepare(globals)
    end

    local addon = {}
    client:loadToc("GoldWise.toc", "GoldWise", addon)
    assert(identityReads == 0 and addon.characterSnapshot == nil, "captured before world entry")
    client:fire("ADDON_LOADED", "GoldWise", false)
    assert(identityReads == 0 and addon.characterSnapshot == nil, "captured on addon load")
    return client, addon, function() return identityReads end
end

local first, addon, reads = product("fixture:one")
assert(first:fire("PLAYER_ENTERING_WORLD", true, false))
local snapshot = assert(addon.characterSnapshot)
assert(snapshot.build == "70862" and snapshot.observedAt == 1794220000 and snapshot.source == "wow-client")
assert(snapshot.region == 3 and snapshot.reportedRealm == "Fixture Realm" and snapshot.faction == "Fixture Faction")
assert(not first:fire("PLAYER_ENTERING_WORLD", true, false) and reads() == 1)
assert(first.output[#first.output] == "GoldWise character snapshot ready.")
assert(next(first.globals.GoldWiseDB.lastObservedAt) == nil)
print("PASS product captures once at login and keeps the snapshot in memory")

local reload, reloadedAddon = product("fixture:one")
local alt, altAddon = product("fixture:two")
assert(reload:fire("PLAYER_ENTERING_WORLD", false, true))
assert(alt:fire("PLAYER_ENTERING_WORLD", true, false))
assert(reloadedAddon.characterSnapshot.scopeKey == snapshot.scopeKey)
assert(altAddon.characterSnapshot.scopeKey ~= snapshot.scopeKey)
print("PASS product scope is stable on reload and distinct for two profiles")

local restricted, restrictedAddon = product("restricted fixture value")
assert(restricted:fire("PLAYER_ENTERING_WORLD", true, false))
assert(restrictedAddon.characterSnapshot == nil)
assert(restricted.output[#restricted.output] == "GoldWise character snapshot unavailable (invalid-scope).")
local missing, missingAddon = product("fixture:one", nil, function(globals)
    globals.GetServerTime = nil
end)
assert(missing:fire("PLAYER_ENTERING_WORLD", true, false))
assert(missingAddon.characterSnapshot == nil)
assert(missing.output[#missing.output] == "GoldWise character snapshot unavailable (invalid-timestamp).")
print("PASS restricted and missing fields block the product snapshot")

local unsupported, unsupportedAddon, unsupportedReads = product("fixture:one", "70863")
assert(not unsupported:fire("PLAYER_ENTERING_WORLD", true, false))
assert(unsupportedAddon.characterSnapshot == nil and unsupportedReads() == 0)
local guardless, guardlessAddon, guardlessReads = product("fixture:one", nil, function(globals)
    globals.issecretvalue = nil
end)
assert(guardless:fire("PLAYER_ENTERING_WORLD", true, false))
assert(guardlessAddon.characterSnapshot == nil and guardlessReads() == 0)
print("PASS unverified build and missing secret guard skip player reads")

local zoned, zonedAddon, zoneReads = product("fixture:one")
assert(zoned:fire("PLAYER_ENTERING_WORLD", false, false))
assert(zonedAddon.characterSnapshot == nil and zoneReads() == 0)
print("PASS a later world transition does not capture")
