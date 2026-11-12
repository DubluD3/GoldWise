local _, addon = ...
local Summary = {}
local MAX_AGE = 300
local MAX_INT = 2 ^ 53 - 1

local function integer(value, minimum)
    return type(value) == "number" and value % 1 == 0
        and value >= minimum and value <= MAX_INT
end

-- Only an explicitly user-observed native browse cache. These are minimum
-- asking prices, not revenue, profit, per-unit prices or confirmed sales.
function Summary.evaluate(observation, character, now)
    if type(observation) ~= "table" or observation.source ~= "wow-ah-browse-cache"
        or type(character) ~= "table" or type(character.scopeKey) ~= "string"
        or character.scopeKey == "" or observation.characterScope ~= character.scopeKey
        or not integer(now, 1) or not integer(observation.observedAt, 1)
        or observation.observedAt > now or now - observation.observedAt > MAX_AGE
        or (observation.status ~= "complete" and observation.status ~= "partial")
        or type(observation.rows) ~= "table"
        or not integer(observation.reportedRows, 0)
        or #observation.rows > 128 or #observation.rows > observation.reportedRows
        or (observation.status == "complete" and #observation.rows ~= observation.reportedRows) then
        return nil, "Observed browse data unavailable or stale."
    end
    local rows = observation.rows
    local count = #rows
    for index in pairs(rows) do
        if not integer(index, 1) or index > count then
            return nil, "Browse data malformed."
        end
    end
    for _, item in ipairs(rows) do
        if type(item) ~= "table" or not integer(item.itemId, 1)
            or not integer(item.itemLevel, 0)
            or not integer(item.itemSuffix, -MAX_INT)
            or not integer(item.battlePetSpeciesId, 0)
            or not integer(item.minimumCopper, 1)
            or not integer(item.reportedQuantity, 1) then
            return nil, "Browse data malformed."
        end
    end
    local lines = {
        string.format("Observed browse cache | %s", observation.status),
        string.format("%d readable of %.0f reported rows", count, observation.reportedRows),
        "Minimum asking prices (copper); NOT sale proceeds.",
    }
    for i = 1, math.min(count, 3) do
        local row = rows[i]
        lines[#lines + 1] = string.format("Item %.0f | min %.0f copper | qty %.0f",
            row.itemId, row.minimumCopper, row.reportedQuantity)
    end
    if count > 3 then
        lines[#lines + 1] = string.format("Plus %d other observed rows.", count - 3)
    end
    lines[#lines + 1] = "No fee, profit, per-unit or market identity verified."
    return table.concat(lines, "\n")
end

if addon then addon.marketCompanionSummary = Summary end
return Summary
