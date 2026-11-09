local _, addon = ...
local ok, version, build, _, interface = pcall(GetBuildInfo)
local supportedBuild = ok and version == "1.60.1" and build == "70862" and interface == 16001
local prefix = "GoldWise profession probe: "

local function readable(value)
    local checked, secret = pcall(issecretvalue, value)
    if checked and secret == false then
        return value
    end
end

local function read(api, ...)
    local succeeded, value = pcall(api, ...)
    if succeeded then
        return readable(value)
    end
end

function GoldWiseProfessionProbe_Run()
    if not supportedBuild then
        print(prefix .. "client build unverified.")
        return
    end
    if type(issecretvalue) ~= "function" then
        print(prefix .. "secret-value guard unavailable.")
        return
    end

    local frame = readable(ProfessionsFrame)
    local visible = read(function()
        local page = frame and readable(frame.CraftingPage)
        return page and page:IsVisible()
    end)
    if visible ~= true then
        print(prefix .. "crafting window unavailable.")
        return
    end
    if type(Professions) ~= "table" or read(Professions.InLocalCraftingMode) ~= true then
        print(prefix .. "local crafting mode unavailable.")
        return
    end
    local trades = C_TradeSkillUI
    if type(trades) ~= "table" then
        print(prefix .. "profession APIs unavailable.")
        return
    end

    local reader = {}
    function reader.profession()
        local info = read(trades.GetChildProfessionInfo)
        if type(info) == "table" and readable(info.professionID) == 0 then
            info = read(trades.GetBaseProfessionInfo)
        end
        if type(info) == "table" then
            return {
                id = readable(info.professionID),
                name = readable(info.professionName),
                skill = readable(info.skillLevel),
                cap = readable(info.maxSkillLevel),
            }
        end
    end

    function reader.recipeIds()
        return read(trades.GetFilteredRecipeIDs)
    end

    function reader.recipeIdAt(ids, index)
        return readable(ids[index])
    end

    function reader.learned(id, professionId)
        local belongs = read(trades.IsRecipeInSkillLine, id, professionId)
        if belongs == false then
            return false
        end
        if belongs ~= true then
            return nil
        end
        local info = read(trades.GetRecipeInfo, id)
        if type(info) == "table" and readable(info.recipeID) == id then
            return readable(info.learned), readable(info.name)
        end
    end

    local snapshot, reason = addon.professionSnapshotModel.capture("probe-session", read(GetServerTime), reader)
    if not snapshot then
        print(prefix .. reason .. ".")
        return
    end

    print(prefix .. snapshot.professionName .. ", skill=" .. snapshot.skill .. "/" .. snapshot.cap
        .. ", recipes=" .. snapshot.recipeStatus .. ", observed learned=" .. #snapshot.knownRecipes .. ".")
    local sample = snapshot.knownRecipes[1]
    if sample then
        print(prefix .. "sample learned " .. (sample.name or "recipe ID " .. sample.id) .. ".")
    end
end

print("GoldWise profession probe loaded. Run /run GoldWiseProfessionProbe_Run() after login.")
