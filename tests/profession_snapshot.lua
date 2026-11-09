local globals = setmetatable({ type = type }, {
    __index = function(_, key)
        error("profession model read an unexpected global: " .. key)
    end,
})
local Snapshot = setfenv(assert(loadfile("data/ProfessionSnapshot.lua")), globals)()

local reads = 0
local reader = {
    profession = function() return { id = 100, name = "Fixture profession", skill = 11, cap = 25 } end,
    recipeIds = function() return { 201, 202, 201, 203 } end,
    recipeIdAt = function(ids, index) return ids[index] end,
    learned = function(id, professionId)
        assert(professionId == 100)
        reads = reads + 1
        if id == 201 then return true, "Fixture recipe" end
        if id == 202 then return false end
    end,
}

local partial = assert(Snapshot.capture("fixture:one", 1794220000, reader))
assert(partial.professionId == 100 and partial.skill == 11 and partial.cap == 25)
assert(partial.characterScope == "fixture:one" and partial.observedAt == 1794220000 and partial.source == "wow-client")
assert(partial.recipeStatus == "partial" and #partial.knownRecipes == 1 and reads == 3)
assert(partial.knownRecipes[1].id == 201 and partial.knownRecipes[1].name == "Fixture recipe")
print("PASS profession provenance and learned recipes exclude duplicates and unknown rows")

reader.recipeIds = function() return { 202 } end
local filtered = assert(Snapshot.capture("fixture:two", 1794220001, reader))
assert(filtered.recipeStatus == "filtered" and #filtered.knownRecipes == 0 and filtered.characterScope == "fixture:two")
reader.recipeIds = function() return {} end
local unavailable = assert(Snapshot.capture("fixture:one", 1794220000, reader))
assert(unavailable.recipeStatus == "unavailable" and unavailable.skill == 11 and #unavailable.knownRecipes == 0)
print("PASS unavailable lists remain distinct from filtered lists with no learned rows")

local ids = {}
for index = 1, 1025 do
    ids[index] = index
end
reader.recipeIds = function() return ids end
reads = 0
reader.learned = function()
    reads = reads + 1
    return false
end
local bounded = assert(Snapshot.capture("fixture:one", 1794220000, reader))
assert(bounded.recipeStatus == "partial" and reads == 1024)
print("PASS oversized recipe lists use the bounded prefix")

reader.profession = function() return { id = 100, name = "Fixture profession", skill = 11 } end
reader.recipeIds = function() error("recipe read after invalid skill range") end
local missing, reason = Snapshot.capture("fixture:one", 1794220000, reader)
assert(missing == nil and reason == "profession or skill range unavailable")
missing, reason = Snapshot.capture("fixture:one", nil, reader)
assert(missing == nil and reason == "timestamp unavailable")
print("PASS missing cap or timestamp does not produce a snapshot")
