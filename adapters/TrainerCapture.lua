local _, addon = ...
local TrainerCapture = {}
local maxAge = 300
local probeBuilds = { ["70862"] = true, ["70888"] = true }
local pending

local function readable(value)
    local checked, secret = pcall(issecretvalue, value)
    if checked and secret == false then
        return value
    end
end

local function read(api, ...)
    local ok, value = pcall(api, ...)
    if ok then
        return readable(value)
    end
end

local function integer(value)
    return type(value) == "number" and value > 0 and value < 2 ^ 53 and value % 1 == 0
end

local function nonempty(value)
    return type(value) == "string" and #value > 0
end

local function supported(prefix)
    local ok, version, build, _, interface = pcall(GetBuildInfo)
    if not ok or version ~= "1.60.1" or not probeBuilds[build] or interface ~= 16001 then
        print(prefix .. "client build unverified.")
        return false
    end
    if type(issecretvalue) ~= "function" then
        print(prefix .. "secret-value guard unavailable.")
        return false
    end
    return build
end

local function spellCandidate(index)
    local spellType = read(function() return Enum.TooltipDataType.Spell end)
    if type(C_TooltipInfo) ~= "table" or type(spellType) ~= "number" then
        return nil
    end
    local data = read(C_TooltipInfo.GetTrainerService, index)
    if type(data) == "table" and readable(data.type) == spellType then
        local id = readable(data.id)
        if integer(id) then
            return id
        end
    end
end

function TrainerCapture.sample(prefix, scope)
    pending = nil
    local build = supported(prefix)
    if not build then
        return
    end
    print(prefix .. "testing build " .. build .. " (interface 16001).")
    local visible = read(function()
        local frame = readable(ClassTrainerFrame)
        return frame and frame:IsVisible()
    end)
    if visible ~= true then
        print(prefix .. "trainer window unavailable.")
        return
    end
    local tradeskill = read(IsTradeskillTrainer)
    if tradeskill ~= true and tradeskill ~= 1 then
        print(prefix .. "profession trainer unavailable.")
        return
    end
    local index = read(GetTrainerSelectionIndex)
    local count = read(GetNumTrainerServices)
    if not integer(index) or not integer(count) or index > count then
        print(prefix .. "selected service unavailable.")
        return
    end

    local name = read(GetTrainerServiceInfo, index)
    local ok, skill, rank = pcall(GetTrainerServiceSkillReq, index)
    if not ok then
        print(prefix .. "selected skill requirement unavailable.")
        return
    end
    skill, rank = readable(skill), readable(rank)
    if not nonempty(name) or not nonempty(skill) or not integer(rank) then
        print(prefix .. "selected skill requirement unavailable.")
        return
    end
    print(prefix .. string.format("%s requires %s %.0f.", name, skill, rank))

    local id = spellCandidate(index)
    local time = read(GetServerTime)
    if not id or not integer(time) then
        print(prefix .. "recipe identity candidate unavailable.")
        return
    end
    pending = { id = id, name = name, skill = skill, rank = rank, time = time, build = build, scope = scope }
    print(prefix .. "spell candidate ready for recipe check.")
end

function TrainerCapture.match(prefix, scope)
    local build = supported(prefix)
    if not build then
        pending = nil
        return
    end
    if not pending or pending.scope ~= scope or pending.build ~= build then
        pending = nil
        print(prefix .. "no trainer sample to compare.")
        return
    end
    local time = read(GetServerTime)
    if not integer(time) or time < pending.time or time - pending.time > maxAge then
        pending = nil
        print(prefix .. "trainer sample expired or its time is unavailable.")
        return
    end
    local visible = read(function()
        local frame = readable(ProfessionsFrame)
        local page = frame and readable(frame.CraftingPage)
        return page and page:IsVisible()
    end)
    if visible ~= true or type(Professions) ~= "table" or read(Professions.InLocalCraftingMode) ~= true
        or type(C_TradeSkillUI) ~= "table" then
        print(prefix .. "local crafting window unavailable.")
        return
    end

    local sample = pending
    pending = nil
    local trades = C_TradeSkillUI
    local profession = read(trades.GetChildProfessionInfo)
    if type(profession) == "table" and readable(profession.professionID) == 0 then
        profession = read(trades.GetBaseProfessionInfo)
    end
    local professionId = type(profession) == "table" and readable(profession.professionID)
    if not integer(professionId) or readable(profession.professionName) ~= sample.skill
        or read(trades.IsRecipeInSkillLine, sample.id, professionId) ~= true then
        print(prefix .. "recipe identity could not be verified in this profession.")
        return
    end
    local recipe = read(trades.GetRecipeInfo, sample.id)
    if type(recipe) ~= "table" or readable(recipe.recipeID) ~= sample.id
        or readable(recipe.name) ~= sample.name then
        print(prefix .. "recipe identity could not be verified in this profession.")
        return
    end
    print(prefix .. "trainer service matched a recipe in the open profession.")
    return {
        build = build, characterScope = scope, professionId = professionId,
        recipeId = sample.id, recipeName = sample.name, skillName = sample.skill,
        requiredSkill = sample.rank, observedAt = sample.time, source = "wow-trainer-service",
    }
end

addon.trainerCapture = TrainerCapture
