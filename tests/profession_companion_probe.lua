local Fixture = dofile("tests/fixtures/ForeverClient.lua")
local client = Fixture.new()
local g = client.globals
local addon = {
    supportedClient = true, clientBuild = "70888",
    characterSnapshot = { scopeKey = "fixture:A" },
}
local profession = {
    characterScope = "fixture:A", professionName = "Fixture Tailoring",
    skill = 10, cap = 75, knownRecipes = {},
}
addon.professionSnapshot = profession
client:load("adapters/ProfessionCompanion.lua", "GoldWise", addon)
local companion = addon.professionCompanion

assert(companion.show(profession) == false)
assert(companion.isCurrent() == false)
print("PASS absent UI frame and widget factory abstain without error")

g.issecretvalue = function(v) return v == "restricted" end
g.ProfessionsFrame = "restricted"
g.CreateFrameWithOptions = function() error("must not create restricted widget") end
assert(companion.show(profession) == false)
assert(companion.isCurrent() == false)
print("PASS restricted native profession frame prevents companion creation")

g.ProfessionsFrame = { CraftingPage = { IsVisible = function() return false end } }
assert(companion.show(profession) == false)
print("PASS hidden crafting window does not attach")

g.ProfessionsFrame.CraftingPage.IsVisible = function() return true end
assert(companion.show(profession) == false)
assert(not companion.isCurrent())
print("PASS unavailable native widget API fails closed")

g.ProfessionsFrame = { CraftingPage = { IsVisible = function() return true end } }
g.CreateFrameWithOptions = nil
addon.professionSnapshot = { characterScope = "fixture:A", professionName = "Other", skill = 11, cap = 75,
    knownRecipes = {} }
assert(companion.show(profession) == false)
assert(not companion.isCurrent())
companion.invalidate()
print("PASS superseded profession snapshot never becomes current")
