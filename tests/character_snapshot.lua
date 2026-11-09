local Storage = dofile("data/Storage.lua")
local globals = setmetatable({ type = type, string = string }, {
    __index = function(_, key)
        error("snapshot read an unexpected global: " .. key)
    end,
})
local Snapshot = setfenv(assert(loadfile("data/CharacterSnapshot.lua")), globals)()

local function observation()
    return {
        build = "70862",
        region = 3,
        reportedRealm = "Fixture Realm",
        faction = "Fixture Faction",
        characterId = "fixture:one",
        observedAt = 1794220000,
    }
end

local original = observation()
local first = assert(Snapshot.fromObservation(original, Storage.scopeKey))
assert(first.source == "wow-client" and first.observedAt == original.observedAt)
assert(first.reportedRealm == original.reportedRealm and first.region == original.region and first.faction == original.faction)
assert(first.build == original.build and first.characterId == nil)
original.observedAt = original.observedAt + 1
local same = assert(Snapshot.fromObservation(original, Storage.scopeKey))
assert(same.scopeKey == first.scopeKey and same.observedAt > first.observedAt)
print("PASS snapshot provenance and repeatable scope")

local changes = {
    { "characterId", "fixture:two" },
    { "reportedRealm", "Other Fixture Realm" },
    { "region", 1 },
    { "faction", "Other Fixture Faction" },
    { "build", "70863" },
}
for _, change in ipairs(changes) do
    local nextObservation = observation()
    nextObservation[change[1]] = change[2]
    local different = assert(Snapshot.fromObservation(nextObservation, Storage.scopeKey))
    assert(different.scopeKey ~= first.scopeKey, change[1])
end
print("PASS two characters and distinct client scopes stay separate")

local unavailable = {
    { "characterId", nil, "invalid-scope" },
    { "reportedRealm", "", "invalid-scope" },
    { "faction", nil, "invalid-scope" },
    { "region", "unknown", "invalid-region" },
    { "observedAt", math.huge, "invalid-timestamp" },
}
for _, change in ipairs(unavailable) do
    local incomplete = observation()
    incomplete[change[1]] = change[2]
    local snapshot, reason = Snapshot.fromObservation(incomplete, Storage.scopeKey)
    assert(snapshot == nil and reason == change[3], change[1])
end
local snapshot, reason = Snapshot.fromObservation(nil, Storage.scopeKey)
assert(snapshot == nil and reason == "missing-context")
print("PASS missing and invalid context produces no snapshot")
