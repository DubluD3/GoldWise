local Fixture = dofile("tests/fixtures/ForeverClient.lua")
local client = Fixture.new()
local globals = client.globals
globals.next = next
local addon = {}
local visible = true
local reads = 0
local slot = {
    required = true, hiddenInCraftingForm = false, reagentType = 1, dataSlotType = 1,
    reagents = { { itemID = 43 } }, quantityRequired = 4, variableQuantities = {},
}
local schematic = {
    recipeID = 41, recipeType = 1, isRecraft = false, outputItemID = 42,
    quantityMin = 1, quantityMax = 1, reagentSlotSchematics = { slot }, name = "Fixture",
}
globals.issecretvalue = function(value) return value == "restricted" end
globals.ProfessionsFrame = { CraftingPage = { IsVisible = function() return visible end } }
globals.Professions = { InLocalCraftingMode = function() return true end }
globals.Enum = {
    TradeskillRecipeType = { Item = 1 }, CraftingReagentType = { Basic = 1 },
    TradeskillSlotDataType = { Reagent = 1 },
}
globals.C_TradeSkillUI = {
    GetChildProfessionInfo = function() return { professionID = 19 } end,
    IsRecipeInSkillLine = function(id, profession) return id == 41 and profession == 19 end,
    GetRecipeInfo = function(id) return { recipeID = id, learned = true } end,
    GetRecipeSchematic = function(id, recraft)
        assert(id == 41 and recraft == false)
        reads = reads + 1
        return schematic
    end,
}
client:load("adapters/RecipeSchematic.lua", "GoldWise", addon)
local capture = addon.recipeSchematic.capture
local row = assert(capture(41, 19))
assert(row.itemId == 42 and row.quantity == 1 and row.reagents[1].quantity == 4 and reads == 1)
print("PASS one learned fixed-output recipe normalizes a supported item reagent")
visible = false
assert(capture(41, 19) == nil and reads == 1)
visible = true
assert(capture(41, 20) == nil and reads == 1)
slot.quantityRequired = "restricted"
assert(capture(41, 19) == nil and reads == 2)
slot.quantityRequired = 4
slot.variableQuantities = { {} }
assert(capture(41, 19) == nil and reads == 3)
print("PASS unavailable and unsupported schematic contexts fail closed")
