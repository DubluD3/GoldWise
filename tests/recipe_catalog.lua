local globals = setmetatable({ type = type, pairs = pairs }, {
    __index = function(_, key)
        error("recipe catalog read an unexpected global: " .. key)
    end,
})
local Catalog = setfenv(assert(loadfile("data/RecipeCatalog.lua")), globals)()

-- Synthetic input shaped like the GW-009 normalized snapshot.
local function snapshot()
    return {
        characterScope = "fixture:one", source = "wow-client", observedAt = 100,
        professionId = 501, professionName = "Fixture profession", skill = 11, cap = 25,
        recipeStatus = "filtered", knownRecipes = { { id = 601, name = "Fixture recipe" } },
    }
end

local function query(overrides)
    local request = {
        build = "70862", characterScope = "fixture:one", professionId = 501,
        recipeId = 601, now = 160, maxAge = 60,
    }
    for key, value in pairs(overrides or {}) do
        request[key] = value
    end
    return request
end

local input = snapshot()
local catalog = assert(Catalog.fromSnapshot("70862", input))
input.knownRecipes[1].name = "Changed input"
local view = assert(Catalog.read(catalog, query()))
assert(view.recipeStatus == "known" and view.recipe.id == 601 and view.recipe.name == "Fixture recipe")
assert(catalog.schemaVersion == 1 and view.skill == 11 and view.cap == 25)
assert(view.build == "70862" and view.characterScope == "fixture:one" and view.observedAt == 100)
assert(view.source == "wow-client" and view.attribution == "Blizzard local crafting view")
assert(view.licenseStatus == "redistribution-unverified" and view.trainerStatus == "unavailable")
view.recipe.name = "Changed output"
assert(Catalog.read(catalog, query()).recipe.name == "Fixture recipe")
print("PASS catalog retains learned recipe and skill provenance without sharing input or output rows")

local missing = assert(Catalog.read(catalog, query({ recipeId = 602 })))
assert(missing.recipeStatus == "unknown" and missing.recipe == nil and missing.coverage == "filtered")
input.recipeStatus = "partial"
input.knownRecipes[1].name = nil
local partial = assert(Catalog.fromSnapshot("70862", input))
assert(Catalog.read(partial, query()).recipeStatus == "known")
assert(Catalog.read(partial, query({ recipeId = 602 })).recipeStatus == "unknown")
input.recipeStatus = "unavailable"
input.knownRecipes = {}
local unavailable = assert(Catalog.fromSnapshot("70862", input))
view = assert(Catalog.read(unavailable, query()))
assert(view.recipeStatus == "unavailable" and view.recipe == nil and view.skill == 11)
input.recipeStatus = "filtered"
local empty = assert(Catalog.fromSnapshot("70862", input))
assert(Catalog.read(empty, query()).recipeStatus == "unknown")
print("PASS filtered and partial omissions remain unknown while an unavailable list preserves observed skill")

for field, value in pairs({ build = "70863", characterScope = "fixture:two", professionId = 502 }) do
    local result, reason = Catalog.read(catalog, query({ [field] = value }))
    assert(result == nil and reason == "scope-unavailable", field)
end
local result, reason = Catalog.fromSnapshot("70863", snapshot())
assert(result == nil and reason == "unsupported-build")
result, reason = Catalog.read(catalog, query({ now = 161 }))
assert(result == nil and reason == "stale")
for _, request in ipairs({ query({ now = 99 }), query({ maxAge = 0 }) }) do
    result, reason = Catalog.read(catalog, request)
    assert(result == nil and reason == "freshness-unavailable")
end
catalog.schemaVersion = 2
result, reason = Catalog.read(catalog, query())
assert(result == nil and reason == "unavailable")
print("PASS scope, schema, unsupported builds, and stale or untrusted time gate every read")

result, reason = Catalog.fromSnapshot("70862", nil)
assert(result == nil and reason == "invalid-snapshot")
input = snapshot()
input.skill = input.cap + 1
assert(Catalog.fromSnapshot("70862", input) == nil)
input = snapshot()
input.knownRecipes[2] = input.knownRecipes[1]
result, reason = Catalog.fromSnapshot("70862", input)
assert(result == nil and reason == "invalid-recipes")
input.knownRecipes = { [2] = { id = 602 } }
assert(Catalog.fromSnapshot("70862", input) == nil)
input = snapshot()
input.recipeStatus = "unavailable"
assert(Catalog.fromSnapshot("70862", input) == nil)
input.recipeStatus = "partial"
for index = 1, 1024 do
    input.knownRecipes[index] = { id = index }
end
assert(Catalog.fromSnapshot("70862", input))
input.knownRecipes[1025] = { id = 1025 }
result, reason = Catalog.fromSnapshot("70862", input)
assert(result == nil and reason == "invalid-recipes")
print("PASS malformed snapshots and recipe rows are rejected at the collection boundary")

local patched = assert(Catalog.fromSnapshot("70888", snapshot()))
local request = query({ build = "70888" })
local requirement = {
    build = "70888", characterScope = request.characterScope, professionId = request.professionId,
    recipeId = request.recipeId, observedAt = 105, requiredSkill = 19, source = "wow-trainer-service",
}
view = assert(Catalog.read(patched, request, requirement))
assert(view.trainerStatus == "observed" and view.trainer.requiredSkill == 19)
requirement.recipeId = 602
assert(Catalog.read(patched, request, requirement).trainerStatus == "unavailable")
requirement.recipeId, requirement.observedAt = 601, 99
assert(Catalog.read(patched, request, requirement).trainerStatus == "unavailable")
print("PASS trainer requirements are scoped to the matching recipe and freshness interval")
