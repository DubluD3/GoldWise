local Ledger = {}
local MAX_ENTRIES = 64

local function integer(value, minimum)
    return type(value) == "number" and value >= minimum and value < 2 ^ 53 and value % 1 == 0
end

function Ledger.new(build, characterScope)
    if build ~= "70862" or type(characterScope) ~= "string" or #characterScope == 0 then
        return nil, "scope-unavailable"
    end
    return { build = build, characterScope = characterScope, entries = {} }
end

---@class LedgerBalanceSample
---@field build string
---@field characterScope string
---@field observedAt integer
---@field balanceCopper integer
---@field source "wow-character-money"

-- Work with a session created by Ledger.new and an adapter's normalized sample.
---@param sample LedgerBalanceSample?
---@param maxAge integer Maximum interval between the two samples, in seconds.
function Ledger.observe(state, sample, maxAge)
    if type(sample) ~= "table" or sample.source ~= "wow-character-money"
        or not integer(sample.observedAt, 1) or not integer(sample.balanceCopper, 0)
        or not integer(maxAge, 1) then
        return nil, "unavailable"
    end
    if sample.build ~= state.build or sample.characterScope ~= state.characterScope then
        return nil, "scope-unavailable"
    end

    local previous = state.latest
    if previous and sample.observedAt <= previous.observedAt then
        return nil, "out-of-order"
    end
    state.latest = { observedAt = sample.observedAt, balanceCopper = sample.balanceCopper }
    if not previous then
        return nil, "baseline"
    end
    if sample.observedAt - previous.observedAt > maxAge then
        return nil, "stale-baseline"
    end

    local delta = sample.balanceCopper - previous.balanceCopper
    if delta == 0 then
        return nil, "unchanged"
    end
    local entries = state.entries
    if #entries == MAX_ENTRIES then
        table.remove(entries, 1)
    end
    entries[#entries + 1] = {
        kind = "balance-change",
        fromObservedAt = previous.observedAt,
        observedAt = sample.observedAt,
        deltaCopper = delta,
        source = sample.source,
        category = "unclassified",
        confidence = "unknown",
    }
    return sample.observedAt, "recorded"
end

-- Categorization records the player's interpretation of a net change.
function Ledger.categorize(state, observedAt, category)
    if category ~= "unclassified" and category ~= "sale" and category ~= "purchase" and category ~= "other" then
        return false, "invalid-category"
    end
    for _, entry in ipairs(state.entries) do
        if entry.observedAt == observedAt then
            if (category == "sale" and entry.deltaCopper < 0) or (category == "purchase" and entry.deltaCopper > 0) then
                return false, "category-direction-mismatch"
            end
            entry.category = category
            entry.confidence = category == "unclassified" and "unknown" or "user-reported"
            return true
        end
    end
    return false, "entry-unavailable"
end

return Ledger
