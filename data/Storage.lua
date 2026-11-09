local Storage = {}

local MAX_SCOPES = 64
local MAX_PART_BYTES = 64
local MAX_KEY_BYTES = 6 * (MAX_PART_BYTES + 3)

local function validKey(key)
    return type(key) == "string" and #key > 0 and #key <= MAX_KEY_BYTES
end

local function validTimestamp(value)
    return type(value) == "number" and value >= 0 and value < 9007199254740992 and value % 1 == 0
end

function Storage.scopeKey(kind, build, region, realm, faction, character)
    if kind ~= "character" and kind ~= "market" then
        return nil, "invalid-scope"
    end
    if kind == "market" and character ~= nil then
        return nil, "invalid-scope"
    end

    local parts = { kind, build, region, realm, faction, character }
    local count = kind == "character" and 6 or 5
    for index = 1, count do
        local part = parts[index]
        if type(part) ~= "string" or #part == 0 or #part > MAX_PART_BYTES then
            return nil, "invalid-scope"
        end
        parts[index] = #part .. ":" .. part
    end
    return table.concat(parts)
end

function Storage.open(saved)
    local state = { schemaVersion = 1, lastObservedAt = {} }
    if saved == nil then
        return state, "created"
    end
    if type(saved) ~= "table" or type(saved.schemaVersion) ~= "number" then
        return nil, "corrupt"
    end

    local version = saved.schemaVersion
    if version ~= 0 and version ~= 1 then
        return nil, "unsupported-version"
    end
    local field = version == 0 and "lastSeen" or "lastObservedAt"
    local timestamps = saved[field]
    if type(timestamps) ~= "table" then
        return nil, "corrupt"
    end
    for key in pairs(saved) do
        if key ~= "schemaVersion" and key ~= field then
            return nil, "corrupt"
        end
    end

    local count = 0
    for key, timestamp in pairs(timestamps) do
        count = count + 1
        if count > MAX_SCOPES or not validKey(key) or not validTimestamp(timestamp) then
            return nil, "corrupt"
        end
        state.lastObservedAt[key] = timestamp
    end
    return state, version == 0 and "migrated" or "current"
end

-- State must come from Storage.open. At capacity, preserve existing scopes.
function Storage.observe(state, key, timestamp)
    if not validKey(key) or not validTimestamp(timestamp) then
        return false, "invalid-observation"
    end

    local timestamps = state.lastObservedAt
    local previous = timestamps[key]
    if previous == nil then
        local count = 0
        for _ in pairs(timestamps) do
            count = count + 1
        end
        if count >= MAX_SCOPES then
            return false, "capacity"
        end
    elseif timestamp < previous then
        return false, "stale"
    end

    timestamps[key] = timestamp
    return true
end

return Storage
