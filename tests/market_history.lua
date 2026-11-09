local globals = setmetatable({
    type = type, pairs = pairs, ipairs = ipairs,
    string = { format = string.format },
    table = { concat = table.concat, remove = table.remove },
}, {
    __index = function(_, key)
        error("market model read an unexpected global: " .. key)
    end,
})
local History = setfenv(assert(loadfile("data/MarketHistory.lua")), globals)()
local copy = setfenv(assert(loadfile("data/AuctionObservation.lua")), globals)().copyForHistory

local function scope(field, value)
    local result = {
        build = "70862", region = 3, reportedRealm = "Fixture Realm", faction = "Horde",
        gameModeRecordId = 1, marketId = "market-fixture",
    }
    if field then
        result[field] = value
    end
    return result
end

local function observation(observedAt)
    return {
        source = "wow-ah-browse-cache", observedAt = observedAt, reportedRows = 2, status = "partial",
        rows = {{
            itemId = 100, itemLevel = 0, itemSuffix = -2, battlePetSpeciesId = 0,
            minimumCopper = 1200, reportedQuantity = 3,
        }},
    }
end

local state, reason = History.open(nil, copy)
assert(state and reason == "created")
local ok
ok, reason = History.record(state, scope("marketId", nil), observation(100), copy)
assert(not ok and reason == "invalid-market-scope" and next(state.markets) == nil)
ok, reason = History.record(state, scope("gameModeRecordId", nil), observation(100), copy)
assert(not ok and reason == "invalid-market-scope" and next(state.markets) == nil)
print("PASS a market and ruleset discriminator are required before retention")

local market = scope()
assert(History.record(state, market, observation(100), copy))
for field, otherValue in pairs({
    build = "70863", region = 4, reportedRealm = "Other Realm", faction = "Alliance",
    gameModeRecordId = 2, marketId = "different-market",
}) do
    local result, status = History.latest(state, scope(field, otherValue), 100, 60, copy)
    assert(result == nil and status == "unavailable", field)
end
local first = scope("reportedRealm", "A:B")
first.faction = "C"
local second = scope("reportedRealm", "A")
second.faction = "B:C"
assert(History.record(state, first, observation(100), copy))
assert(History.latest(state, second, 100, 60, copy) == nil)
print("PASS market lookups match every scope dimension without delimiter collisions")

local raw = observation(101)
raw.characterScope = "fixture-character"
raw.rows[1].unexpectedField = "ignored"
assert(History.record(state, market, raw, copy))
raw.rows[1].minimumCopper = 500
local latest, status, age = History.latest(state, market, 161, 60, copy)
assert(latest and status == "partial" and age == 60)
assert(latest.source == "wow-ah-browse-cache" and latest.observedAt == 101 and latest.reportedRows == 2)
assert(latest.rows[1].minimumCopper == 1200 and latest.rows[1].reportedQuantity == 3)
assert(latest.characterScope == nil and latest.rows[1].unexpectedField == nil)
latest.rows[1].minimumCopper = 900
assert(History.latest(state, market, 161, 60, copy).rows[1].minimumCopper == 1200)
latest, status, age = History.latest(state, market, 162, 60, copy)
assert(latest == nil and status == "stale" and age == 61)
latest, status = History.latest(state, market, 100, 60, copy)
assert(latest == nil and status == "freshness-unavailable")
latest, status = History.latest(state, market, 101, nil, copy)
assert(latest == nil and status == "freshness-unavailable")
print("PASS retention copies approved fields and stale or untrusted time yields no result")

assert(History.record(state, market, observation(102), copy))
ok, reason = History.record(state, market, observation(103), copy)
assert(ok and reason == "pruned-oldest")
for timestamp = 102, 103 do
    ok, reason = History.record(state, market, observation(timestamp), copy)
    assert(not ok and reason == "out-of-order")
end
for index = 1, 6 do
    assert(History.record(state, scope("marketId", "other-" .. index), observation(103), copy))
end
ok, reason = History.record(state, second, observation(104), copy)
assert(not ok and reason == "market-capacity")
assert(History.latest(state, first, 104, 60, copy).observedAt == 100)
local marketKey, bucket
for key, entry in pairs(state.markets) do
    if entry.scope.marketId == market.marketId and entry.scope.reportedRealm == market.reportedRealm then
        marketKey, bucket = key, entry
    end
end
assert(#bucket.observations == 3 and bucket.observations[1].observedAt == 101)
print("PASS per-market retention prunes oldest only and rejects new markets at capacity")

local reopened
reopened, reason = History.open(state, copy)
assert(reopened and reopened ~= state and reason == "current")
assert(History.latest(reopened, market, 103, 60, copy).observedAt == 103)
assert(History.latest(reopened, first, 103, 60, copy).observedAt == 100)
state.markets["wrong-key"] = bucket
state.markets[marketKey] = nil
local rejected
rejected, reason = History.open(state, copy)
assert(rejected == nil and reason == "corrupt" and state.markets["wrong-key"] == bucket)
state.markets["wrong-key"] = nil
state.markets[marketKey] = bucket
bucket.observations[2].observedAt = 101
rejected, reason = History.open(state, copy)
assert(rejected == nil and reason == "corrupt" and bucket.observations[2].observedAt == 101)
state.schemaVersion = 2
rejected, reason = History.open(state, copy)
assert(rejected == nil and reason == "unsupported-version" and state.schemaVersion == 2)
print("PASS reopen preserves scope and rejects mis-keyed, unordered, or future-schema records")

local invalid = observation(104)
invalid.status = "complete"
ok, reason = History.record(reopened, market, invalid, copy)
assert(not ok and reason == "invalid-observation")
invalid.reportedRows = 1
assert(copy(invalid).status == "complete")
invalid.rows[1].minimumCopper = -1
assert(copy(invalid) == nil)
local oversized = observation(104)
oversized.reportedRows = 129
for index = 2, 129 do
    oversized.rows[index] = oversized.rows[1]
end
assert(copy(oversized) == nil)
print("PASS retention validates completeness, copper, and the 128-row bound")
