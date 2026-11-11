local Fixture = dofile("tests/fixtures/ForeverClient.lua")

local function fixture(build, interface)
    local client = Fixture.new(Fixture.build("1.60.1", build or "70862", interface or 16001), "missing")
    local globals = client.globals
    local state = {
        trainer = false, crafting = false, localMode = true,
        at = 100, index = 2, rank = 35, spell = 77, tooltipType = 1, recipeName = "Fixture recipe",
        trainerReads = 0, recipeReads = 0,
    }
    globals.issecretvalue = function(value) return value == state.restricted end
    globals.ClassTrainerFrame = { IsVisible = function() return state.trainer end }
    globals.IsTradeskillTrainer = function() return true end
    globals.GetTrainerSelectionIndex = function() return state.index end
    globals.GetNumTrainerServices = function() return 3 end
    globals.GetTrainerServiceInfo = function(index)
        assert(index == 2)
        state.trainerReads = state.trainerReads + 1
        return "Fixture recipe"
    end
    globals.GetTrainerServiceSkillReq = function(index)
        assert(index == 2)
        return "Fixture profession", state.rank, false
    end
    globals.Enum = { TooltipDataType = { Spell = 1 } }
    globals.C_TooltipInfo = {
        GetTrainerService = function(index)
            assert(index == 2)
            return { type = state.tooltipType, id = state.spell }
        end,
    }
    globals.GetServerTime = function() return state.at end
    globals.ProfessionsFrame = { CraftingPage = { IsVisible = function() return state.crafting end } }
    globals.Professions = { InLocalCraftingMode = function() return state.localMode end }
    globals.C_TradeSkillUI = {
        GetChildProfessionInfo = function() return { professionID = 0 } end,
        GetBaseProfessionInfo = function() return { professionID = 25, professionName = "Fixture profession" } end,
        IsRecipeInSkillLine = function(id, professionId) return id == 77 and professionId == 25 end,
        GetRecipeInfo = function(id)
            state.recipeReads = state.recipeReads + 1
            return { recipeID = id, name = state.recipeName }
        end,
    }
    local addon = {}
    client:load("adapters/TrainerCapture.lua", "GoldWiseTrainerProbe", addon)
    client:load("tests/probes/GoldWiseTrainerProbe/Probe.lua", "GoldWiseTrainerProbe", addon)
    assert(#client.output == 0 and state.trainerReads == 0 and state.recipeReads == 0)
    return client, globals, state
end

local function last(client)
    return client.output[#client.output]
end

local client, globals, state = fixture()
globals.GoldWiseTrainerProbe_Sample()
assert(last(client):find("trainer window unavailable", 1, true) and state.trainerReads == 0)
state.trainer, state.index = true, 4
globals.GoldWiseTrainerProbe_Sample()
assert(last(client):find("selected service unavailable", 1, true) and state.trainerReads == 0)
state.index = 2
globals.IsTradeskillTrainer = function() return false end
globals.GoldWiseTrainerProbe_Sample()
assert(last(client):find("profession trainer unavailable", 1, true) and state.trainerReads == 0)
print("PASS trainer probe reads no services in closed, non-profession, or out-of-range selections")

client, globals, state = fixture()
state.trainer = true
globals.GoldWiseTrainerProbe_Sample()
assert(client.output[2]:find("Fixture recipe requires Fixture profession 35", 1, true))
assert(last(client):find("spell candidate ready", 1, true) and state.trainerReads == 1)
state.trainer, state.crafting, state.localMode = false, true, false
globals.GoldWiseTrainerProbe_Match()
assert(last(client):find("local crafting window unavailable", 1, true) and state.recipeReads == 0)
state.localMode, state.at = true, 400
globals.GoldWiseTrainerProbe_Match()
assert(last(client):find("matched a recipe", 1, true) and state.recipeReads == 1)
globals.GoldWiseTrainerProbe_Match()
assert(last(client):find("no trainer sample", 1, true) and state.recipeReads == 1)
print("PASS trainer probe compares one spell candidate in the matching local skill line and consumes it")

client, globals, state = fixture()
state.trainer, state.restricted = true, 35
globals.GoldWiseTrainerProbe_Sample()
assert(last(client):find("selected skill requirement unavailable", 1, true))
state.restricted, state.tooltipType = 77, 2
globals.GoldWiseTrainerProbe_Sample()
assert(last(client):find("recipe identity candidate unavailable", 1, true))
state.tooltipType = 1
globals.GoldWiseTrainerProbe_Sample()
assert(last(client):find("recipe identity candidate unavailable", 1, true))
state.crafting = true
globals.GoldWiseTrainerProbe_Match()
assert(last(client):find("no trainer sample", 1, true) and state.recipeReads == 0)
print("PASS secret rank, non-spell tooltip, and secret identity remain unavailable")

client, globals, state = fixture()
state.trainer = true
globals.GoldWiseTrainerProbe_Sample()
state.trainer, state.crafting, state.at = false, true, 401
globals.GoldWiseTrainerProbe_Match()
assert(last(client):find("expired", 1, true) and state.recipeReads == 0)
state.trainer, state.recipeName = true, "Different recipe"
globals.GoldWiseTrainerProbe_Sample()
state.trainer = false
globals.GoldWiseTrainerProbe_Match()
assert(last(client):find("could not be verified", 1, true) and state.recipeReads == 1)
print("PASS expired and mismatched trainer samples cannot establish a recipe identity")

client, globals, state = fixture("70888")
state.trainer = true
globals.GoldWiseTrainerProbe_Sample()
assert(client.output[1]:find("testing build 70888 (interface 16001)", 1, true))
assert(last(client):find("spell candidate ready", 1, true) and state.trainerReads == 1)
state.trainer, state.crafting = false, true
globals.GoldWiseTrainerProbe_Match()
assert(last(client):find("matched a recipe", 1, true) and state.recipeReads == 1)
print("PASS trainer probe reports the 70888 target build and exercises both guarded commands")

client, globals, state = fixture("70889")
state.trainer = true
globals.GoldWiseTrainerProbe_Sample()
assert(last(client):find("client build unverified", 1, true) and state.trainerReads == 0)
client, globals, state = fixture("70888", 16002)
state.trainer = true
globals.GoldWiseTrainerProbe_Sample()
assert(last(client):find("client build unverified", 1, true) and state.trainerReads == 0)
print("PASS trainer probe rejects unexpected builds and interfaces")
