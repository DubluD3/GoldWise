local Model = dofile("data/RecipeMaterials.lua")
local function recipe(id, itemId, count, reagents)
    return { recipeId = id, itemId = itemId, quantity = count, reagents = reagents, name = "Fixture" }
end
local function reagent(itemId, quantity)
    return { itemId = itemId, quantity = quantity }
end

local component = recipe(11, 2, 3, { reagent(4, 2) })
local root = recipe(12, 1, 1, { reagent(2, 2), reagent(2, 2), reagent(4, 1) })
local owned = { [2] = 1, [4] = 2 }
local plan = assert(Model.plan(root, 1, owned, { [2] = component }))
assert(plan.missing[4] == 1 and plan.missing[2] == nil)
assert(plan.used[2] == 1 and plan.used[4] == 2 and #plan.crafts == 2)
assert(plan.crafts[1].recipeId == 11 and plan.crafts[2].recipeId == 12)
assert(owned[2] == 1 and owned[4] == 2)
print("PASS nested plans reuse inventory and crafted surplus once")

local ambiguous = assert(Model.plan(root, 1, owned, { [2] = false }))
assert(ambiguous.missing[2] == 3 and #ambiguous.crafts == 1)
local loop = recipe(13, 2, 1, { reagent(1, 1) })
local failure, reason = Model.plan(root, 1, {}, { [2] = loop, [1] = root })
assert(failure == nil and reason == "recipe dependency cycle")
failure, reason = Model.plan(root, 2147483647, {}, {})
assert(failure == nil and reason == "plan exceeds the calculation limit")
print("PASS ambiguous producers, cycles, and oversized quantities have bounded fallbacks")
