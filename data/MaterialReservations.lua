local _, addon = ...
local Reservations = {}
local MAX_PLANS = 8
local MAX_COUNT = 2147483647
local EXACT = 9007199254740991

local function validId(value)
    return type(value) == "number" and value % 1 == 0 and value >= 1 and value <= EXACT
end

local function count(value, minimum)
    return type(value) == "number" and value % 1 == 0
        and value >= minimum and value <= MAX_COUNT
end

-- Backwards-compatible read-only calculation. The action boundary below is
-- stricter: it validates the ENTIRE observed inventory and hold map first.
function Reservations.available(byRecipe, owned, exceptRecipe)
    local free = {}
    for item, quantity in pairs(owned) do
        free[item] = quantity
    end
    for recipe, quantities in pairs(byRecipe) do
        if recipe ~= exceptRecipe then
            for item, quantity in pairs(quantities) do
                free[item] = (free[item] or 0) - quantity
            end
        end
    end
    return free
end

-- Validate both old and new reservations before replacing any held amounts.
-- An impossible prior hold must not silently make subsequent plans plausible.
function Reservations.reserve(byRecipe, recipe, requested, owned)
    if type(byRecipe) ~= "table" or type(owned) ~= "table"
        or type(requested) ~= "table" or not validId(recipe) then
        return false, "Reservation input unavailable."
    end
    local free, otherHeld = {}, {}
    for item, quantity in pairs(owned) do
        if not validId(item) or not count(quantity, 0) then
            return false, "Observed inventory invalid."
        end
        free[item] = quantity
    end
    local plans = 0
    for heldRecipe, quantities in pairs(byRecipe) do
        if not validId(heldRecipe) or type(quantities) ~= "table" then
            return false, "Existing reservations invalid."
        end
        plans = plans + 1
        if plans > MAX_PLANS then
            return false, "Reservation limit reached. Clear reservations to continue."
        end
        local hasHeld = false
        for item, quantity in pairs(quantities) do
            if not validId(item) or not count(quantity, 1)
                or free[item] == nil then
                return false, "Existing reservations invalid."
            end
            hasHeld = true
            local held = (otherHeld[item] or 0) + quantity
            if held > free[item] then
                return false, "Existing reservations exceed carried stock."
            end
            otherHeld[item] = held
        end
        if not hasHeld then
            return false, "Existing reservations invalid."
        end
    end

    for item, quantity in pairs(requested) do
        if not validId(item) or not count(quantity, 0)
            or free[item] == nil then
            return false, "Requested reagents unavailable."
        end
    end
    -- Own prior hold is replaceable, while all OTHER recipe holds count.
    local own = byRecipe[recipe]
    local accepted = {}
    for item, quantity in pairs(requested) do
        local available = free[item] - (otherHeld[item] or 0) + (own and own[item] or 0)
        if quantity > available then
            return false, "Reagents are already reserved or unavailable."
        end
        if quantity > 0 then
            accepted[item] = quantity
        end
    end
    if next(accepted) == nil then
        return false, "This plan uses no carried reagents."
    end
    if not own and plans >= MAX_PLANS then
        return false, "Reservation limit reached. Clear reservations to continue."
    end
    byRecipe[recipe] = accepted
    return true
end

if addon then
    addon.materialReservations = Reservations
end

return Reservations
