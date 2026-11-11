local _, addon = ...
local inventory
local reservations = {}

function addon.reservationsFor(snapshot)
    if inventory ~= snapshot then
        inventory = snapshot
        reservations = {}
    end
    return reservations
end

function addon.reserveRecipePlan(plan)
    local current = addon.inventorySnapshot
    if not current or current ~= plan.inventory then
        return "Bag counts changed. Recalculate the plan."
    end
    local ok, reason = addon.materialReservations.reserve(addon.reservationsFor(current),
        plan.recipeId, plan.used, current.totals)
    if ok then
        return "Carried reagents reserved for this recipe."
    end
    return reason
end

function addon.clearReservations()
    inventory = nil
    reservations = {}
    addon.recipePlan = nil
    return "Session reservations cleared. Recalculate the plan."
end
