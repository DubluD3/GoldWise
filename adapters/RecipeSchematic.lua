local _, addon = ...
local RecipeSchematic = {}

local function readable(value)
    local ok, secret = pcall(issecretvalue, value)
    if ok and secret == false then
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
    return type(value) == "number" and value > 0 and value <= 2147483647 and value % 1 == 0
end

function RecipeSchematic.capture(recipeId, profession)
    if type(issecretvalue) ~= "function" or not integer(recipeId) then
        return nil, "recipe unavailable"
    end

    local visible = read(function()
        local frame = readable(ProfessionsFrame)
        local page = frame and readable(frame.CraftingPage)
        return page and page:IsVisible()
    end)
    local trades = C_TradeSkillUI
    if visible ~= true or type(Professions) ~= "table"
        or read(Professions.InLocalCraftingMode) ~= true or type(trades) ~= "table" then
        return nil, "open your own crafting profession"
    end

    local info = read(trades.GetChildProfessionInfo)
    if type(info) == "table" and readable(info.professionID) == 0 then
        info = read(trades.GetBaseProfessionInfo)
    end
    if type(info) ~= "table" or readable(info.professionID) ~= profession
        or read(trades.IsRecipeInSkillLine, recipeId, profession) ~= true then
        return nil, "recipe is unavailable in this profession"
    end
    local recipe = read(trades.GetRecipeInfo, recipeId)
    if type(recipe) ~= "table" or readable(recipe.recipeID) ~= recipeId or readable(recipe.learned) ~= true then
        return nil, "recipe is unavailable or unlearned"
    end

    local schematic = read(trades.GetRecipeSchematic, recipeId, false)
    local itemType = read(function() return Enum.TradeskillRecipeType.Item end)
    if type(schematic) ~= "table" or type(itemType) ~= "number"
        or readable(schematic.recipeType) ~= itemType
        or readable(schematic.isRecraft) ~= false or readable(schematic.recipeID) ~= recipeId then
        return nil, "recipe materials unavailable"
    end

    local itemId = readable(schematic.outputItemID)
    local quantity = readable(schematic.quantityMin)
    local name = readable(schematic.name)
    local slots = readable(schematic.reagentSlotSchematics)
    if not integer(itemId) or not integer(quantity) or quantity ~= readable(schematic.quantityMax)
        or type(slots) ~= "table" or #slots > 16 then
        return nil, "fixed output or reagent list unavailable"
    end

    local basic = read(function() return Enum.CraftingReagentType.Basic end)
    local reagentSlot = read(function() return Enum.TradeskillSlotDataType.Reagent end)
    if type(basic) ~= "number" or type(reagentSlot) ~= "number" then
        return nil, "reagent types unavailable"
    end

    local reagents = {}
    for index = 1, #slots do
        local slot = readable(slots[index])
        local required = type(slot) == "table" and readable(slot.required)
        if type(slot) ~= "table" or type(required) ~= "boolean" then
            return nil, "reagent slot unavailable"
        end
        if required then
            local options = readable(slot.reagents)
            local variable = readable(slot.variableQuantities)
            local needed = readable(slot.quantityRequired)
            if readable(slot.hiddenInCraftingForm) ~= false or readable(slot.reagentType) ~= basic
                or readable(slot.dataSlotType) ~= reagentSlot or type(options) ~= "table"
                or #options ~= 1 or type(variable) ~= "table" or next(variable) ~= nil or not integer(needed) then
                return nil, "recipe has unsupported required reagents"
            end
            local option = readable(options[1])
            local reagentId = type(option) == "table" and readable(option.itemID)
            if not integer(reagentId) or readable(option.currencyID) ~= nil then
                return nil, "required reagent item unavailable"
            end
            reagents[#reagents + 1] = { itemId = reagentId, quantity = needed }
        end
    end

    return {
        recipeId = recipeId, itemId = itemId, quantity = quantity, reagents = reagents,
        name = type(name) == "string" and name or "Recipe " .. recipeId,
    }
end

addon.recipeSchematic = RecipeSchematic
