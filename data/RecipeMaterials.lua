local _, addon = ...
local RecipeMaterials = {}
local MAX_COUNT = 2147483647
local MAX_VISITS = 1024

local function quantity(value)
    return type(value) == "number" and value >= 1 and value <= MAX_COUNT and value % 1 == 0
end

-- Recipes are normalized, fixed-output schematics. A false producer is ambiguous.
function RecipeMaterials.plan(root, crafts, owned, producers)
    if not quantity(crafts) then
        return nil, "invalid craft count"
    end

    local plan = { missing = {}, used = {}, crafts = {} }
    local stock, surplus, active = {}, {}, {}
    local visits = 0

    local function craft(recipe, count, depth)
        if depth > 32 then
            return false, "plan exceeds the calculation limit"
        end
        if active[recipe.itemId] then
            return false, "recipe dependency cycle"
        end
        active[recipe.itemId] = true

        for _, reagent in ipairs(recipe.reagents) do
            visits = visits + 1
            local needed = reagent.quantity * count
            if visits > MAX_VISITS or not quantity(needed) then
                return false, "plan exceeds the calculation limit"
            end
            local item = reagent.itemId
            local available = stock[item] or owned[item] or 0
            local fromBags = math.min(available, needed)
            stock[item] = available - fromBags
            plan.used[item] = (plan.used[item] or 0) + fromBags
            needed = needed - fromBags

            local extra = surplus[item] or 0
            local fromCrafts = math.min(extra, needed)
            surplus[item] = extra - fromCrafts
            needed = needed - fromCrafts

            if needed > 0 then
                local producer = producers[item]
                if producer then
                    local runs = math.ceil(needed / producer.quantity)
                    local output = runs * producer.quantity
                    if not quantity(output) then
                        return false, "plan exceeds the calculation limit"
                    end
                    local ok, reason = craft(producer, runs, depth + 1)
                    if not ok then
                        return false, reason
                    end
                    surplus[item] = output - needed
                else
                    local missing = (plan.missing[item] or 0) + needed
                    if not quantity(missing) then
                        return false, "plan exceeds the calculation limit"
                    end
                    plan.missing[item] = missing
                end
            end
        end

        active[recipe.itemId] = nil
        plan.crafts[#plan.crafts + 1] = { recipeId = recipe.recipeId, name = recipe.name, count = count }
        return true
    end

    local ok, reason = craft(root, crafts, 1)
    if not ok then
        return nil, reason
    end
    return plan
end

if addon then
    addon.recipeMaterials = RecipeMaterials
end

return RecipeMaterials
