local _, addon = ...
local Review = {}
local MAX = 2147483647
local EXACT = 9007199254740991
local function integer(value, minimum, maximum)
    return type(value) == "number" and value >= minimum and value <= (maximum or MAX)
        and value % 1 == 0
end
-- Remaining carried stock is NEVER a sell recommendation.
function Review.evaluate(input)
    local unavailable = { status = "unknown", reason = "Current, complete carried-bag observation unavailable." }
    if type(input) ~= "table" or type(input.inventory) ~= "table"
        or type(input.characterScope) ~= "string" or #input.characterScope == 0
        or not integer(input.now, 1, EXACT) or not integer(input.maxAge, 1, EXACT) then
        return unavailable
    end
    local bag = input.inventory
    if bag.characterScope ~= input.characterScope or bag.status ~= "complete"
        or not integer(bag.observedAt, 1, EXACT) or bag.observedAt > input.now
        or input.now - bag.observedAt > input.maxAge or type(bag.totals) ~= "table" then
        return unavailable
    end
    if type(input.reservations) ~= "table" then
        return { status = "unknown", reason = "Session reservations unavailable." }
    end
    local reserved = {}
    for recipeId, counts in pairs(input.reservations) do
        if not integer(recipeId, 1) or type(counts) ~= "table" then
            return { status = "unknown", reason = "Reservation contents invalid." }
        end
        for id, count in pairs(counts) do
            if not integer(id, 1, EXACT) or not integer(count, 0) then
                return { status = "unknown", reason = "Reservation quantity invalid." }
            end
            local sum = (reserved[id] or 0) + count
            if sum > MAX then return { status = "unknown", reason = "Reservation overflow." } end
            reserved[id] = sum
        end
    end
    local plan = input.plan
    local planStatus = "not-observed"
    if plan ~= nil then
        if type(plan) ~= "table" or plan.inventory ~= bag
            or plan.characterScope ~= input.characterScope
            or not integer(plan.observedAt, 1, EXACT)
            or plan.observedAt > input.now or input.now - plan.observedAt > input.maxAge
            or not integer(plan.recipeId, 1) or type(plan.used) ~= "table"
            or type(plan.missing) ~= "table" then
            planStatus = "unavailable-or-stale"
            plan = nil
        else
            planStatus = "observed"
            for id, count in pairs(plan.used) do
                if not integer(id, 1, EXACT) or not integer(count, 0)
                    or (count > 0 and not integer(bag.totals[id], 0))
                    or (integer(bag.totals[id], 0) and count > bag.totals[id]) then
                    return { status = "unknown", reason = "Reagent plan invalid or exceeds observed carried stock." }
                end
            end
        end
    end
    local rows, ids = {}, {}
    for id, count in pairs(bag.totals) do
        if not integer(id, 1, EXACT) or not integer(count, 0) then
            return { status = "unknown", reason = "Carried-bag quantity invalid." }
        end
        ids[#ids + 1] = id
    end
    for id, count in pairs(reserved) do
        if not integer(bag.totals[id], 0) or count > bag.totals[id] then
            return { status = "unknown", reason = "Reservations exceed observed carried stock." }
        end
    end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local owned = bag.totals[id]
        local reservedCount = reserved[id] or 0
        local planned = plan and (plan.used[id] or 0) or 0
        if planned > owned then
            return { status = "unknown", reason = "Reagent plan exceeds observed carried stock." }
        end
        -- Count the current recipe reservation only once, with its plan usage.
        local sameRecipe = plan and input.reservations[plan.recipeId]
        local sameCount = sameRecipe and (sameRecipe[id] or 0) or 0
        local held = math.max(sameCount, planned) + reservedCount - sameCount
        if held > owned then
            return { status = "unknown", reason = "Combined review holds exceed carried stock." }
        end
        rows[#rows + 1] = {
            itemId=id, carried=owned, reserved=reservedCount, activePlanUse=planned,
            hold=held, reviewQuantity=owned-held,
            status=held > 0 and "hold-and-review" or "review-only",
        }
    end
    return {
        status=planStatus == "observed" and "observed-plan" or "review-only",
        planStatus=planStatus, rows=rows,
        caution="Remaining carried items require manual review; not safe-to-sell advice. Bank, alt, future use and demand unknown.",
    }
end
if addon then addon.materialReview = Review end
return Review
