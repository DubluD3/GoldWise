local _, addon = ...
local Reservations = {}
local MAX_PLANS = 8

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

function Reservations.reserve(byRecipe, recipe, requested, owned)
    local free = Reservations.available(byRecipe, owned, recipe)
    local accepted = {}
    for item, quantity in pairs(requested) do
        if type(quantity) ~= "number" or quantity < 0 or quantity >= 2 ^ 53 or quantity % 1 ~= 0
            or quantity > (free[item] or 0) then
            return false, "Reagents are already reserved or unavailable."
        end
        if quantity > 0 then
            accepted[item] = quantity
        end
    end
    if next(accepted) == nil then
        return false, "This plan uses no carried reagents."
    end
    if not byRecipe[recipe] then
        local count = 0
        for _ in pairs(byRecipe) do
            count = count + 1
        end
        if count >= MAX_PLANS then
            return false, "Reservation limit reached. Clear reservations to continue."
        end
    end
    byRecipe[recipe] = accepted
    return true
end

if addon then
    addon.materialReservations = Reservations
end

return Reservations
