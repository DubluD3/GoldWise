local domainGlobals = setmetatable({ pairs = pairs, table = table, type = type }, {
    __index = function(_, key)
        error("storage read an unexpected global: " .. key)
    end,
    __newindex = function(_, key)
        error("storage wrote an unexpected global: " .. key)
    end,
})
local Storage = setfenv(assert(loadfile("data/Storage.lua")), domainGlobals)()

local function expectFailure(value, reason, expected)
    assert(not value and reason == expected, "expected " .. expected .. ", got " .. tostring(reason))
end

local market = assert(Storage.scopeKey("market", "70862", "EU", "Realm:A", "Alliance"))
local character = assert(Storage.scopeKey("character", "70862", "EU", "Realm:A", "Alliance", "local:1"))
assert(character ~= market)
assert(market ~= Storage.scopeKey("market", "70863", "EU", "Realm:A", "Alliance"))
assert(market ~= Storage.scopeKey("market", "70862", "US", "Realm:A", "Alliance"))
assert(market ~= Storage.scopeKey("market", "70862", "EU", "Realm:B", "Alliance"))
assert(market ~= Storage.scopeKey("market", "70862", "EU", "Realm:A", "Horde"))
assert(character ~= Storage.scopeKey("character", "70862", "EU", "Realm:A", "Alliance", "local:2"))
assert(Storage.scopeKey("market", "a:b", "c", "realm", "faction")
    ~= Storage.scopeKey("market", "a", "b:c", "realm", "faction"))
local value, reason = Storage.scopeKey("character", "70862", "EU", "Realm:A", "Alliance")
expectFailure(value, reason, "invalid-scope")
value, reason = Storage.scopeKey("market", "70862", "EU", "Realm:A", "Alliance", "local:1")
expectFailure(value, reason, "invalid-scope")
print("PASS scope isolation and invalid scope rejection")

local state, status = Storage.open(nil)
assert(status == "created" and state.schemaVersion == 1)
assert(Storage.observe(state, market, 100))
assert(Storage.observe(state, character, 200))
value, reason = Storage.observe(state, market, 99)
expectFailure(value, reason, "stale")
value, reason = Storage.observe(state, market, math.huge)
expectFailure(value, reason, "invalid-observation")
local loaded, loadedStatus = Storage.open(state)
assert(loadedStatus == "current" and loaded.lastObservedAt[market] == 100 and loaded.lastObservedAt[character] == 200)
assert(Storage.observe(loaded, market, 101))
assert(state.lastObservedAt[market] == 100)
print("PASS current table round trip and stale observation rejection")

local legacy = { schemaVersion = 0, lastSeen = { [market] = 5 } }
local migrated, migratedStatus = Storage.open(legacy)
assert(migratedStatus == "migrated" and migrated.schemaVersion == 1 and migrated.lastObservedAt[market] == 5)
assert(legacy.schemaVersion == 0 and legacy.lastObservedAt == nil)
print("PASS legacy migration preserves input")

local newer = { schemaVersion = 2, customData = true }
value, reason = Storage.open(newer)
expectFailure(value, reason, "unsupported-version")
assert(newer.customData == true)
local corruptInputs = {
    false,
    {},
    { schemaVersion = 1 },
    { schemaVersion = 1, lastObservedAt = { [market] = "invalid" } },
    { schemaVersion = 1, lastObservedAt = {}, customData = true },
    { schemaVersion = 0, lastSeen = { [false] = 5 } },
}
for _, input in ipairs(corruptInputs) do
    value, reason = Storage.open(input)
    expectFailure(value, reason, "corrupt")
end
assert(next(assert(Storage.open(nil)).lastObservedAt) == nil)
print("PASS corrupt and future schemas fail closed")

local bounded = assert(Storage.open(nil))
for index = 1, 64 do
    local key = assert(Storage.scopeKey("market", "70862", "EU", tostring(index), "Alliance"))
    assert(Storage.observe(bounded, key, index))
end
value, reason = Storage.observe(bounded, market, 100)
expectFailure(value, reason, "capacity")
assert(bounded.lastObservedAt[market] == nil)
assert(Storage.observe(bounded, Storage.scopeKey("market", "70862", "EU", "1", "Alliance"), 100))
assert(Storage.open(bounded))
bounded.lastObservedAt[market] = 100
value, reason = Storage.open(bounded)
expectFailure(value, reason, "corrupt")
print("PASS capacity preserves existing scopes and rejects oversized saves")
