local _, addon = ...
local CharacterSnapshot = {}

local function positiveInteger(value)
    return type(value) == "number" and value >= 1 and value < 2 ^ 53 and value % 1 == 0
end

-- The caller supplies readable, normalized client values and the storage scope builder.
function CharacterSnapshot.fromObservation(observation, scopeKey)
    if type(observation) ~= "table" then
        return nil, "missing-context"
    end
    if not positiveInteger(observation.region) then
        return nil, "invalid-region"
    end
    if not positiveInteger(observation.observedAt) then
        return nil, "invalid-timestamp"
    end

    local key, reason = scopeKey(
        "character",
        observation.build,
        string.format("%.0f", observation.region),
        observation.reportedRealm,
        observation.faction,
        observation.characterId
    )
    if not key then
        return nil, reason
    end

    return {
        scopeKey = key,
        build = observation.build,
        region = observation.region,
        reportedRealm = observation.reportedRealm,
        faction = observation.faction,
        observedAt = observation.observedAt,
        source = "wow-client",
    }
end

if addon then
    addon.characterSnapshotModel = CharacterSnapshot
end

return CharacterSnapshot
