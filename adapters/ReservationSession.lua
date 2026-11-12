local _, addon = ...
local inventory
local reservations = {}
local MAX_AGE = 900

function addon.reservationsFor(snapshot)
    if inventory ~= snapshot then
        inventory = snapshot
        reservations = {}
    end
    return reservations
end

local function validTimestamp(value, now)
    return type(value) == "number" and value % 1 == 0
        and value >= 1 and value <= now and now - value <= MAX_AGE
end

local function readTime()
    if type(issecretvalue) ~= "function" or type(GetServerTime) ~= "function" then
        return nil
    end
    local ok, value = pcall(GetServerTime)
    if not ok then return nil end
    local checked, secret = pcall(issecretvalue, value)
    if checked and secret == false and type(value) == "number"
        and value % 1 == 0 and value >= 1 and value < 2 ^ 53 then
        return value
    end
end

function addon.reserveRecipePlan(plan)
    local current = addon.inventorySnapshot
    local profession = addon.professionSnapshot
    local character = addon.characterSnapshot
    if type(plan) ~= "table" or addon.recipePlan ~= plan
        or not addon.supportedClient or not character
        or type(character.scopeKey) ~= "string" or #character.scopeKey == 0
        or not current or current ~= plan.inventory
        or current.status ~= "complete" or current.characterScope ~= character.scopeKey
        or not profession or profession ~= plan.professionSnapshot
        or profession.characterScope ~= character.scopeKey
        or profession.professionId ~= plan.professionId
        or plan.characterScope ~= character.scopeKey or plan.build ~= addon.clientBuild then
        return "Plan context changed. Scan current bags and profession, then recalculate."
    end
    local time = readTime()
    if not time or not validTimestamp(current.observedAt, time)
        or not validTimestamp(profession.observedAt, time)
        or not validTimestamp(plan.observedAt, time)
        or type(plan.recipeId) ~= "number" or plan.recipeId % 1 ~= 0
        or plan.recipeId < 1 or type(plan.used) ~= "table" then
        return "Plan expired or observation time unavailable. Refresh and recalculate."
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
