local _, addon = ...
local Capacity = {}
local MAX = 2147483647
local EXACT = 9007199254740991
local function integer(n, low, high)
    return type(n) == "number" and n % 1 == 0 and n >= low and n <= (high or MAX)
end
-- Direct fixed-output reagent coverage ONLY; does not infer nested crafting,
-- catalysts, quality, skill-up odds, or actual ability to execute a craft.
function Capacity.evaluate(input)
    local unknown = { status = "unknown", reason = "Fresh, complete current-character inputs unavailable." }
    if type(input) ~= "table" or type(input.scope) ~= "string" or #input.scope == 0
        or not integer(input.now, 1, EXACT) or not integer(input.maxAge, 1, EXACT)
        or type(input.recipe) ~= "table" or type(input.inventory) ~= "table"
        or type(input.reservations) ~= "table" then return unknown end
    local recipe, bag = input.recipe, input.inventory
    if bag.status ~= "complete" or bag.characterScope ~= input.scope
        or not integer(bag.observedAt, 1, EXACT) or bag.observedAt > input.now
        or input.now - bag.observedAt > input.maxAge
        or recipe.characterScope ~= input.scope
        or not integer(recipe.observedAt, 1, EXACT) or recipe.observedAt > input.now
        or input.now - recipe.observedAt > input.maxAge
        or not integer(recipe.recipeId, 1) or not integer(recipe.itemId, 1, EXACT)
        or not integer(recipe.quantity, 1) or type(recipe.reagents) ~= "table"
        or type(bag.totals) ~= "table" then return unknown end
    if #recipe.reagents == 0 or #recipe.reagents > 16 then
        return { status = "unknown", reason = "Recipe has no verified, fixed required reagents." }
    end
    local required, reserved = {}, {}
    for _, reagent in ipairs(recipe.reagents) do
        if type(reagent) ~= "table" or not integer(reagent.itemId, 1, EXACT)
            or not integer(reagent.quantity, 1) then
            return { status = "unknown", reason = "Recipe reagent identity or quantity invalid." }
        end
        local current = required[reagent.itemId] or 0
        if current > MAX - reagent.quantity then
            return { status = "unknown", reason = "Reagent count exceeds calculation limit." }
        end
        required[reagent.itemId] = current + reagent.quantity
    end
    -- Exclude the CURRENT recipe's own reservation when recalculating its
    -- direct capacity; hold amounts from all other recipes stay unavailable.
    for recipeId, quantities in pairs(input.reservations) do
        if not integer(recipeId, 1) or type(quantities) ~= "table" then
            return { status = "unknown", reason = "Reservation data invalid." }
        end
        for id, n in pairs(quantities) do
            if not integer(id, 1, EXACT) or not integer(n, 0) then
                return { status = "unknown", reason = "Reservation amount invalid." }
            end
            if recipeId ~= recipe.recipeId then
                local new = (reserved[id] or 0) + n
                if new > MAX then return { status = "unknown", reason = "Reservation overflow." } end
                reserved[id] = new
            end
        end
    end
    for id, quantity in pairs(bag.totals) do
        if not integer(id, 1, EXACT) or not integer(quantity, 0) then
            return { status = "unknown", reason = "Carried inventory amount invalid." }
        end
    end
    for id, amount in pairs(reserved) do
        if not integer(bag.totals[id], 0) or amount > bag.totals[id] then
            return { status = "unknown", reason = "Other reservations exceed carried inventory." }
        end
    end
    local count, rows = MAX, {}
    for id, quantity in pairs(required) do
        local free = (bag.totals[id] or 0) - (reserved[id] or 0)
        local possible = math.floor(free / quantity)
        if possible < count then count = possible end
        rows[#rows+1] = { itemId=id, perCraft=quantity, available=free, craftCount=possible }
    end
    table.sort(rows,function(a,b) return a.itemId < b.itemId end)
    return {
        status = "direct-reagent-coverage", maxDirectCrafts = count, rows = rows,
        caution = "Material-only estimate for observed direct reagents; not craftability, skill-up chance, or permission to craft.",
    }
end
if addon then addon.craftCapacity = Capacity end
return Capacity
