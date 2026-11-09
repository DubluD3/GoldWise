local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")
local probe = "tests/probes/GoldWiseProfessionProbe/Probe.lua"

local function fixture(build, product)
    local client = ForeverClient.new(ForeverClient.build("1.60.1", build or "70862", 16001))
    local globals = client.globals
    local state = { visible = false, owned = true, skillReads = 0, recipeReads = 0 }
    globals.issecretvalue = function(value) return value == "restricted fixture value" end
    globals.GetServerTime = function() return 1794220000 end
    globals.UnitGUID = function() return "fixture:one" end
    globals.GetRealmName = function() return "Fixture Realm" end
    globals.UnitFactionGroup = function() return "Fixture Faction" end
    globals.GetCurrentRegion = function() return 3 end
    globals.ProfessionsFrame = { CraftingPage = { IsVisible = function() return state.visible end } }
    globals.Professions = { InLocalCraftingMode = function() return state.owned end }
    globals.C_TradeSkillUI = {
        GetChildProfessionInfo = function()
            state.skillReads = state.skillReads + 1
            return { professionID = 100, professionName = "Fixture profession", skillLevel = 11, maxSkillLevel = 25 }
        end,
        GetFilteredRecipeIDs = function() return { 201, 202, 203, 201 } end,
        IsRecipeInSkillLine = function(id, line)
            assert(line == 100)
            return id ~= 203
        end,
        GetRecipeInfo = function(id)
            assert(id ~= 203, "foreign skill line must not be inspected")
            state.recipeReads = state.recipeReads + 1
            return { recipeID = id, learned = id == 201, name = "Fixture recipe" }
        end,
    }
    local addon = {}
    if product then
        client:loadToc("GoldWise.toc", "GoldWise", addon)
    else
        client:load("data/ProfessionSnapshot.lua", "GoldWiseProfessionProbe", addon)
        client:load("adapters/ProfessionCapture.lua", "GoldWiseProfessionProbe", addon)
        client:load(probe, "GoldWiseProfessionProbe", addon)
    end
    assert(#client.output == 1 and state.skillReads == 0)
    return client, state, addon
end

local client, state = fixture()
client.globals.GoldWiseProfessionProbe_Run()
assert(client.output[2]:match("crafting window unavailable") and state.skillReads == 0)
state.visible = true
state.owned = false
client.globals.GoldWiseProfessionProbe_Run()
assert(client.output[3]:match("local crafting mode unavailable") and state.skillReads == 0)
print("PASS closed and external crafting views skip skill and recipe reads")

state.owned = true
client.globals.GoldWiseProfessionProbe_Run()
assert(state.skillReads == 1 and state.recipeReads == 2)
assert(client.output[4]:match("skill=11/25, recipes=filtered, observed learned=1"))
assert(client.output[5]:match("sample learned Fixture recipe"))
print("PASS own crafting view reports the skill range and a learned filtered sample")

local globals = client.globals
globals.C_TradeSkillUI.GetChildProfessionInfo = function() return { professionID = 0 } end
globals.C_TradeSkillUI.GetBaseProfessionInfo = function()
    return { professionID = 100, professionName = "Fixture profession", skillLevel = 12, maxSkillLevel = 25 }
end
globals.C_TradeSkillUI.GetRecipeInfo = function(id)
    return { recipeID = id, learned = "restricted fixture value" }
end
globals.GoldWiseProfessionProbe_Run()
assert(client.output[6]:match("skill=12/25, recipes=partial, observed learned=0"))
print("PASS base fallback preserves skill and suppresses restricted learned flags")

globals.C_TradeSkillUI.GetFilteredRecipeIDs = nil
globals.GoldWiseProfessionProbe_Run()
assert(client.output[7]:match("skill=12/25, recipes=unavailable"))
assert(not client.output[7]:find("observed learned", 1, true))
local unsupported, unsupportedState = fixture("70863")
unsupported.globals.GoldWiseProfessionProbe_Run()
assert(unsupported.output[2]:match("client build unverified") and unsupportedState.skillReads == 0)
print("PASS unavailable recipe enumeration preserves skill and unverified builds stop")

local product, productState, addon = fixture(nil, true)
product.globals.GoldWiseProfessionScan()
assert(product.output[#product.output]:match("character snapshot unavailable") and productState.skillReads == 0)
assert(product:fire("ADDON_LOADED", "GoldWise", false))
assert(product:fire("PLAYER_ENTERING_WORLD", true, false))
assert(productState.skillReads == 0 and addon.professionSnapshot == nil)
productState.visible = true
product.globals.GoldWiseProfessionScan()
assert(productState.skillReads == 1 and addon.features.professions)
assert(addon.professionSnapshot.characterScope == addon.characterSnapshot.scopeKey)
assert(addon.professionSnapshot.observedAt == 1794220000 and addon.professionSnapshot.knownRecipes[1].id == 201)
assert(next(product.globals.GoldWiseDB.lastObservedAt) == nil)
assert(product.output[#product.output - 1]:match("skill=11/25, recipes=filtered, observed learned=1"))
print("PASS product scan uses the active character and keeps profession data in memory")

product.globals.C_TradeSkillUI.GetFilteredRecipeIDs = nil
product.globals.GoldWiseProfessionScan()
assert(addon.professionSnapshot.skill == 11 and addon.professionSnapshot.recipeStatus == "unavailable")
assert(not addon.features.professions and not product.output[#product.output]:find("observed learned", 1, true))
productState.visible = false
product.globals.GoldWiseProfessionScan()
assert(addon.professionSnapshot == nil and not addon.features.professions and productState.skillReads == 2)
assert(product.output[#product.output]:match("crafting window unavailable"))
print("PASS unavailable recipe lists preserve skill and closed refresh clears the snapshot")

local otherBuild, otherState, otherAddon = fixture("70863", true)
otherBuild.globals.GoldWiseProfessionScan()
assert(otherState.skillReads == 0 and otherAddon.professionSnapshot == nil)
assert(otherBuild.output[#otherBuild.output]:match("client build unverified"))
print("PASS product skips profession reads on unverified builds")
