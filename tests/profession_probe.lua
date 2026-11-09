local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")
local probe = "tests/probes/GoldWiseProfessionProbe/Probe.lua"

local function fixture(build)
    local client = ForeverClient.new(ForeverClient.build("1.60.1", build or "70862", 16001))
    local globals = client.globals
    local state = { visible = false, owned = true, skillReads = 0, recipeReads = 0 }
    globals.issecretvalue = function(value) return value == "restricted fixture value" end
    globals.GetServerTime = function() return 1794220000 end
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
    client:load("data/ProfessionSnapshot.lua", "GoldWiseProfessionProbe", addon)
    client:load(probe, "GoldWiseProfessionProbe", addon)
    assert(#client.output == 1 and state.skillReads == 0)
    return client, state
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
local unsupported, unsupportedState = fixture("70863")
unsupported.globals.GoldWiseProfessionProbe_Run()
assert(unsupported.output[2]:match("client build unverified") and unsupportedState.skillReads == 0)
print("PASS unavailable recipe enumeration preserves skill and unverified builds stop")
