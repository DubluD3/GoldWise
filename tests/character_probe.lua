local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")
local path = "tests/probes/GoldWiseCharacterProbe/Probe.lua"
local readBuild = ForeverClient.build("1.60.1", "70862", 16001)

local function clientWithIdentity(id)
    local client = ForeverClient.new(readBuild)
    local globals = client.globals
    globals.issecretvalue = function(value) return value == "restricted fixture value" end
    globals.UnitGUID = function(unit)
        assert(unit == "player")
        return id
    end
    globals.GetRealmName = function() return "Fixture Realm" end
    globals.UnitFactionGroup = function(unit)
        assert(unit == "player")
        return "Fixture Faction"
    end
    globals.GetCurrentRegion = function() return 3 end
    globals.GetServerTime = function() return 1794220000 end
    return client
end

local function run(client, initial, reload)
    client:load(path, "GoldWiseCharacterProbe")
    assert(#client.output == 1 and client.output[1]:match("v2 loaded"))
    assert(client:fire("PLAYER_ENTERING_WORLD", initial, reload))
    assert(not client:fire("PLAYER_ENTERING_WORLD", initial, reload))
    assert(#client.output == 2)
    return client.output[2]
end

local first = run(clientWithIdentity("fixture:one"), true, false)
local repeated = run(clientWithIdentity("fixture:one"), false, true)
local second = run(clientWithIdentity("fixture:two"), true, false)
assert(first:match("entry=login .* faction=ok region=ok time=ok$"))
assert(repeated:match("entry=reload "))
local tag = assert(first:match("character=(%x+)"))
assert(tag == repeated:match("character=(%x+)") and tag ~= second:match("character=(%x+)"))
assert(first:match("realm=(%x+)") == repeated:match("realm=(%x+)"))
assert(not first:find("fixture:one", 1, true) and not first:find("Fixture Realm", 1, true))
print("PASS login and reload produce stable local tags without raw identifiers")

local partial = clientWithIdentity("restricted fixture value")
partial.globals.GetRealmName = nil
partial.globals.UnitFactionGroup = function() error("faction API unavailable") end
partial.globals.GetCurrentRegion = function() return 0 end
partial.globals.GetServerTime = function() return nil end
local unavailable = run(partial, true, false)
assert(unavailable:match("character=unavailable realm=unavailable faction=unavailable region=unavailable time=unavailable$"))
print("PASS restricted and unavailable fields are suppressed")

local guarded = clientWithIdentity("fixture:one")
guarded.globals.issecretvalue = nil
guarded:load(path, "GoldWiseCharacterProbe")
assert(not guarded:fire("PLAYER_ENTERING_WORLD", true, false))
assert(guarded.output[2] == "GoldWise character probe: secret-value guard unavailable")
guarded.globals.GoldWiseCharacterProbe_Run()
assert(guarded.output[3] == guarded.output[2])
assert(run(clientWithIdentity("fixture:one"), false, false) == "GoldWise character probe: unexpected entry event")
print("PASS missing secret guard and unexpected entry fail closed")

local manual = clientWithIdentity("fixture:one")
manual.globals.EventUtil = nil
manual:load(path, "GoldWiseCharacterProbe")
assert(manual.output[2] == "GoldWise character probe: entry event registration unavailable")
assert(not manual:fire("PLAYER_ENTERING_WORLD", true, false))
manual.globals.GoldWiseCharacterProbe_Run()
assert(manual.output[3]:match("entry=manual .* faction=ok region=ok time=ok$"))
assert(tag == manual.output[3]:match("character=(%x+)"))
print("PASS manual check works without an entry event")
