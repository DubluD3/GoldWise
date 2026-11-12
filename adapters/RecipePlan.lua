local _, addon = ...
local MAX_AGE = 900
local MAX_RECIPES = 32
local scope
local professionSnapshot
local scopedBuild
local recipes = {}
local order = {}

function GoldWisePlanRecipe(recipeId, crafts)
    addon.recipePlan = nil
    local character = addon.characterSnapshot
    local profession = addon.professionSnapshot
    local inventory = addon.inventorySnapshot
    if not addon.supportedClient or not character or not profession or profession.characterScope ~= character.scopeKey then
        return "Scan your open profession first."
    end
    if not inventory or inventory.characterScope ~= character.scopeKey or inventory.status ~= "complete" then
        return "Scan your bags for a complete inventory."
    end
    local ok, now = pcall(GetServerTime)
    local checked, secret = pcall(issecretvalue, now)
    if not ok or not checked or secret ~= false or type(now) ~= "number"
        or now < 1 or now >= 2 ^ 53 or now % 1 ~= 0 then
        return "Observation time unavailable. Try again."
    end
    if type(profession.observedAt) ~= "number" or profession.observedAt % 1 ~= 0
        or profession.observedAt < 1 or profession.observedAt > now
        or now - profession.observedAt > MAX_AGE then
        return "Profession scan is stale or unavailable. Scan your open profession again."
    end
    if type(inventory.observedAt) ~= "number" or inventory.observedAt % 1 ~= 0
        or inventory.observedAt < 1 or inventory.observedAt > now
        or now - inventory.observedAt > MAX_AGE then
        return "Bag counts are stale or unavailable. Scan your bags again."
    end
    -- Never reuse a producer from another character, build, or manual profession
    -- scan. Identity comparisons catch a new scan even in the same second.
    if scope ~= character.scopeKey or professionSnapshot ~= profession
        or scopedBuild ~= addon.clientBuild then
        scope, professionSnapshot, scopedBuild = character.scopeKey, profession, addon.clientBuild
        recipes, order = {}, {}
    end
    local recipe, reason = addon.recipeSchematic.capture(recipeId, profession.professionId)
    if not recipe then return reason end
    if not recipes[recipeId] then
        if #order == MAX_RECIPES then
            recipes[table.remove(order, 1)] = nil
        end
        order[#order + 1] = recipeId
    end
    recipe.observedAt = now
    recipe.characterScope = scope
    recipe.professionId = profession.professionId
    recipes[recipeId] = recipe

    local producers = {}
    for _, candidate in pairs(recipes) do
        if candidate.characterScope == scope and candidate.professionId == profession.professionId
            and candidate.observedAt <= now and now - candidate.observedAt <= MAX_AGE then
            if producers[candidate.itemId] == nil then
                producers[candidate.itemId] = candidate
            else
                producers[candidate.itemId] = false
            end
        end
    end
    local free = addon.materialReservations.available(addon.reservationsFor(inventory), inventory.totals, recipeId)
    local plan, failure = addon.recipeMaterials.plan(recipe, crafts or 1, free, producers)
    if not plan then
        return failure
    end
    recipe.characterScope = scope
    plan.recipeSchematic = recipe
    plan.professionSnapshot = profession
    plan.professionId = profession.professionId
    plan.recipeId = recipeId
    plan.characterScope = scope
    plan.observedAt = now
    plan.inventory = inventory
    addon.recipePlan = plan
    return "Reagent plan ready."
end
