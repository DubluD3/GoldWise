local _, addon = ...
local ProfessionCapture = {}

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

function ProfessionCapture.capture(characterScope)
    if type(issecretvalue) ~= "function" then
        return nil, "secret-value guard unavailable"
    end

    local frame = readable(ProfessionsFrame)
    local visible = read(function()
        local page = frame and readable(frame.CraftingPage)
        return page and page:IsVisible()
    end)
    if visible ~= true then
        return nil, "crafting window unavailable"
    end
    if type(Professions) ~= "table" or read(Professions.InLocalCraftingMode) ~= true then
        return nil, "local crafting mode unavailable"
    end
    local trades = C_TradeSkillUI
    if type(trades) ~= "table" then
        return nil, "profession APIs unavailable"
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

    return addon.professionSnapshotModel.capture(characterScope, read(GetServerTime), reader)
end

function ProfessionCapture.report(prefix, snapshot)
    local summary = snapshot.professionName .. ", skill=" .. snapshot.skill .. "/" .. snapshot.cap
        .. ", recipes=" .. snapshot.recipeStatus
    if snapshot.recipeStatus ~= "unavailable" then
        summary = summary .. ", observed learned=" .. #snapshot.knownRecipes
    end
    print(prefix .. summary .. " (read from the open crafting window).")
    local sample = snapshot.knownRecipes[1]
    if sample then
        print(prefix .. "sample learned " .. (sample.name or "recipe ID " .. sample.id) .. ".")
    end
end

addon.professionCapture = ProfessionCapture
