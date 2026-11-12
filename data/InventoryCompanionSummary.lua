local _, addon = ...
local Summary = {}
local LIMIT = 900
local MAX = 2147483647
local function integer(value, minimum, maximum)
    return type(value) == "number" and value % 1 == 0
        and value >= minimum and value <= maximum
end
local function fresh(time, now)
    return integer(time, 1, 2 ^ 53 - 1) and integer(now, 1, 2 ^ 53 - 1)
        and time <= now and now - time <= LIMIT
end

-- Conservative local inventory overview. This never looks at live bag state,
-- bank, guild bank, mail, or other characters. Incomplete scans cannot claim
-- that an item is safe to sell or that a reservation has available stock.
function Summary.evaluate(snapshot, character, now)
    if type(snapshot) ~= "table" or type(character) ~= "table"
        or type(character.scopeKey) ~= "string" or character.scopeKey == ""
        or snapshot.characterScope ~= character.scopeKey
        or not fresh(snapshot.observedAt, now)
        or snapshot.status ~= "complete" or type(snapshot.totals) ~= "table"
        or type(snapshot.bags) ~= "table" or #snapshot.bags ~= 6 then
        return nil, "Carried inventory unavailable or incomplete."
    end
    for _, bag in ipairs(snapshot.bags) do
        if type(bag) ~= "table" or bag.status ~= "complete" then
            return nil, "At least one bag was not completely observed."
        end
    end
    local types, units, ids = 0, 0, {}
    for id, quantity in pairs(snapshot.totals) do
        if not integer(id, 1, 2 ^ 53 - 1)
            or not integer(quantity, 0, MAX)
            or units + quantity > MAX then
            return nil, "Observed counts are invalid."
        end
        if quantity > 0 then
            types, units = types + 1, units + quantity
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    local lines = {
        "Carried bags | complete manual scan",
        string.format("%d item types | %.0f total units", types, units),
        "Bank, mail and other characters: unknown.",
    }
    for i = 1, math.min(#ids, 3) do
        local id = ids[i]
        lines[#lines + 1] = string.format("Item %.0f: %.0f carried", id, snapshot.totals[id])
    end
    if #ids > 3 then
        lines[#lines + 1] = string.format("Plus %d other item types.", #ids - 3)
    end
    lines[#lines + 1] = "Informational only; not a sell instruction."
    return table.concat(lines, "\n")
end

if addon then addon.inventoryCompanionSummary = Summary end
return Summary
