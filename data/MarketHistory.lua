local MarketHistory = {}
local MAX_MARKETS = 8
local MAX_OBSERVATIONS = 3

local function positiveInteger(value)
    return type(value) == "number" and value >= 1 and value < 2 ^ 53 and value % 1 == 0
end

local function scopeText(value)
    return type(value) == "string" and #value > 0 and #value <= 64
end

local function normalizeScope(scope)
    if type(scope) ~= "table" or not scopeText(scope.build) or not positiveInteger(scope.region)
        or not scopeText(scope.reportedRealm) or not scopeText(scope.faction)
        or not positiveInteger(scope.gameModeRecordId) or not scopeText(scope.marketId) then
        return nil
    end

    local parts = {
        scope.build, string.format("%.0f", scope.region), scope.reportedRealm, scope.faction,
        string.format("%.0f", scope.gameModeRecordId), scope.marketId,
    }
    for index, part in ipairs(parts) do
        parts[index] = #part .. ":" .. part
    end
    return {
        build = scope.build,
        region = scope.region,
        reportedRealm = scope.reportedRealm,
        faction = scope.faction,
        gameModeRecordId = scope.gameModeRecordId,
        marketId = scope.marketId,
    }, table.concat(parts)
end

-- Scope must be supplied by a verified provider before the production adapter can write.
function MarketHistory.record(state, scope, observation, copyObservation)
    local normalized, key = normalizeScope(scope)
    if not normalized then
        return false, "invalid-market-scope"
    end
    local copy = copyObservation(observation)
    if not copy then
        return false, "invalid-observation"
    end

    local market = state.markets[key]
    if not market then
        local count = 0
        for _ in pairs(state.markets) do
            count = count + 1
        end
        if count >= MAX_MARKETS then
            return false, "market-capacity"
        end
        market = { scope = normalized, observations = {} }
        state.markets[key] = market
    end

    local observations = market.observations
    local latest = observations[#observations]
    if latest and copy.observedAt <= latest.observedAt then
        return false, "out-of-order"
    end
    local pruned = #observations == MAX_OBSERVATIONS
    if pruned then
        table.remove(observations, 1)
    end
    observations[#observations + 1] = copy
    return true, pruned and "pruned-oldest" or "recorded"
end

function MarketHistory.open(saved, copyObservation)
    local state = { schemaVersion = 1, markets = {} }
    if saved == nil then
        return state, "created"
    end
    if type(saved) ~= "table" or type(saved.schemaVersion) ~= "number" then
        return nil, "corrupt"
    end
    if saved.schemaVersion ~= 1 then
        return nil, "unsupported-version"
    end
    if type(saved.markets) ~= "table" then
        return nil, "corrupt"
    end
    for field in pairs(saved) do
        if field ~= "schemaVersion" and field ~= "markets" then
            return nil, "corrupt"
        end
    end

    local marketCount = 0
    for key, market in pairs(saved.markets) do
        marketCount = marketCount + 1
        if marketCount > MAX_MARKETS or type(market) ~= "table" or type(market.observations) ~= "table" then
            return nil, "corrupt"
        end
        for field in pairs(market) do
            if field ~= "scope" and field ~= "observations" then
                return nil, "corrupt"
            end
        end
        local _, expectedKey = normalizeScope(market.scope)
        local count = #market.observations
        if key ~= expectedKey or count == 0 or count > MAX_OBSERVATIONS then
            return nil, "corrupt"
        end
        for index in pairs(market.observations) do
            if not positiveInteger(index) or index > count then
                return nil, "corrupt"
            end
        end
        for index = 1, count do
            if not MarketHistory.record(state, market.scope, market.observations[index], copyObservation) then
                return nil, "corrupt"
            end
        end
    end
    return state, "current"
end

function MarketHistory.latest(state, scope, now, maxAge, copyObservation)
    local _, key = normalizeScope(scope)
    if not key then
        return nil, "invalid-market-scope"
    end
    if not positiveInteger(now) or not positiveInteger(maxAge) then
        return nil, "freshness-unavailable"
    end

    local market = state.markets[key]
    if not market then
        return nil, "unavailable"
    end
    local latest = market.observations[#market.observations]
    local age = now - latest.observedAt
    if age < 0 then
        return nil, "freshness-unavailable"
    end
    if age > maxAge then
        return nil, "stale", age
    end
    local copy = copyObservation(latest)
    if not copy then
        return nil, "corrupt"
    end
    return copy, copy.status, age
end

return MarketHistory
