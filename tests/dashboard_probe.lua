local Fixture = dofile("tests/fixtures/ForeverClient.lua")
local client = Fixture.new(Fixture.build("1.60.1", "70888", 16001))
local globals = client.globals
local addon = {}
local reads, vendorReads, plans = 0, 0, 0
local widgets, labels = {}, {}
local clock = 1800

local function widget(kind, hidden)
    local object = { kind = kind, shown = not hidden }
    for _, method in ipairs({ "SetPoint", "SetAllPoints", "SetSize", "SetColorTexture", "SetTextColor",
        "SetJustifyH", "SetJustifyV", "SetWordWrap" }) do
        object[method] = function() end
    end
    function object:SetText(value) self.value = value end
    function object:CreateTexture() return widget("Texture") end
    function object:CreateFontString()
        local label = widget("FontString")
        labels[#labels + 1] = label
        return label
    end
    function object:SetScript(event, callback) assert(event == "OnClick"); self.click = callback end
    function object:Show() self.shown = true end
    function object:Hide() self.shown = false end
    function object:IsShown() return self.shown end
    return object
end

globals.math, globals.unpack, globals.next = math, unpack, next
globals.SlashCmdList = {}
globals.UIParent = widget("UIParent")
globals.GetScreenWidth = function() return 1280 end
globals.GetScreenHeight = function() return 720 end
globals.CreateFrameWithOptions = function(options)
    assert(options.frameType == "Frame" or options.frameType == "Button")
    local object = widget(options.frameType, options.hidden)
    widgets[#widgets + 1] = object
    return object
end
globals.GetServerTime = function() return clock end
globals.issecretvalue = function(value) return value == "restricted" end
globals.C_Item = {
    GetItemInfo = function(id)
        assert(id == 78)
        vendorReads = vendorReads + 1
        return "Fixture hide", nil, nil, nil, nil, nil, nil, nil, nil, nil, 29
    end,
}
globals.UnitGUID = function() return "fixture:character" end
globals.GetRealmName = function() return "Fixture Realm" end
globals.UnitFactionGroup = function() return "Fixture Faction" end
globals.GetCurrentRegion = function() return 3 end
globals.GetMoney = function() return 500 end
globals.Enum = {
    BagIndex = { Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5 },
    TradeskillRecipeType = { Item = 1 }, CraftingReagentType = { Basic = 1 },
    TradeskillSlotDataType = { Reagent = 1 },
}
globals.C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 1 or 0 end,
    HasContainerItem = function() return true end,
    GetContainerItemInfo = function()
        reads = reads + 1
        return { itemID = 78, stackCount = 4, itemName = "Fixture hide" }
    end,
}
local function visible() return true end
globals.ProfessionsFrame = { CraftingPage = { IsVisible = visible } }
globals.Professions = { InLocalCraftingMode = visible }
globals.C_TradeSkillUI = {
    GetChildProfessionInfo = function()
        return { professionID = 21, professionName = "Fixture profession", skillLevel = 30, maxSkillLevel = 60 }
    end,
    GetFilteredRecipeIDs = function() return { 9 } end,
    IsRecipeInSkillLine = function(id, profession) return id == 9 and profession == 21 end,
    GetRecipeInfo = function(id) return { recipeID = id, name = "Fixture recipe", learned = true } end,
    GetRecipeSchematic = function(id, recraft)
        assert(id == 9 and recraft == false)
        plans = plans + 1
        return {
            recipeID = 9, recipeType = 1, isRecraft = false, outputItemID = 79, name = "Fixture recipe",
            quantityMin = 1, quantityMax = 1, reagentSlotSchematics = {
                { required = true, hiddenInCraftingForm = false, reagentType = 1, dataSlotType = 1,
                    reagents = { { itemID = 78 } }, quantityRequired = 3, variableQuantities = {} },
            },
        }
    end,
}
globals.AuctionHouseFrame = { IsVisible = visible, BrowseResultsFrame = { IsVisible = visible } }
globals.C_AuctionHouse = {
    IsThrottledMessageSystemReady = visible,
    HasFullBrowseResults = function() return false end,
    GetBrowseResults = function()
        return { { itemKey = { itemID = 78, itemLevel = 1, itemSuffix = 0, battlePetSpeciesID = 0 },
            minPrice = 80, totalQuantity = 2 } }
    end,
}

local function hasText(fragment)
    for _, label in ipairs(labels) do
        if label.value and label.value:find(fragment, 1, true) then return true end
    end
end
local function click(label)
    for _, candidate in ipairs(widgets) do
        if candidate.shown and candidate.label and candidate.label.value == label then
            return candidate.click()
        end
    end
    error("missing visible button " .. label)
end

client:loadToc("GoldWise.toc", "GoldWise", addon)
assert(client:fire("ADDON_LOADED", "GoldWise") and globals.GoldWiseDB.schemaVersion == 1)
assert(client:fire("PLAYER_ENTERING_WORLD", true, false) and addon.characterSnapshot)
assert(globals.SLASH_GOLDWISE1 == "/goldwise" and #widgets == 0 and reads == 0)
globals.SlashCmdList.GOLDWISE()
assert(widgets[1].shown and hasText("Scan & Setup Guide"))
click("Exit guide")
assert(hasText("GoldWise  /  Overview"))
click("Guide")
assert(hasText("Character identity"))
click("Next step")
assert(hasText("Carried bags"))
click("Skip this step")
assert(addon.guidePreferences.skipped.bags and hasText("Equipped gear"))
click("Exit guide")
assert(hasText("GoldWise  /  Overview"))
globals.SlashCmdList.GOLDWISE("guide")
assert(hasText("Scan & Setup Guide"))
for _ = 1, 8 do click("Next step") end
assert(hasText("Recipe plans and reservations"))
click("Finish guide")
assert(addon.guidePreferences.finished and hasText("GoldWise  /  Overview"))
click("Sample balance")
assert(hasText("Ledger · 0 recorded changes"))
click("Inventory")
click("Scan bags")
assert(reads == 1 and vendorReads == 0 and hasText("Fixture hide") and not hasText("Action unavailable"))
click("Check vendor value")
assert(vendorReads == 1 and hasText("29 copper"))
clock = clock + 901
globals.GoldWiseOpen()
globals.GoldWiseOpen()
assert(hasText("Stale") and hasText("Refresh bag counts"))
print("PASS dashboard opens lazily, renders inventory, and reads vendor info only on request")

click("Scan bags")
click("Professions")
click("Scan profession")
click("More crafts")
click("Plan reagents")
assert(plans == 1 and hasText("GoldWise  /  My Plan") and hasText("Missing 2"))
click("Reserve carried reagents")
assert(hasText("This recipe has a session reservation."))
click("Inventory")
assert(hasText("Keep 4 for My Plan") and hasText("4 reserved across session plans"))
click("My Plan")
click("Clear reservations")
assert(hasText("Session reservations cleared"))
click("Market")
click("Observe browse")
assert(not widgets[1].shown)
assert(client:fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED"))
globals.GoldWiseOpen()
click("Observe browse")
assert(not widgets[1].shown and addon.auctionObservation)
globals.GoldWiseOpen()
assert(hasText("minimum 80 copper") and hasText("Sale proceeds and fees unavailable"))
print("PASS dashboard connects profession, reagent, and manual market flows")

local unavailable = Fixture.new()
unavailable:load("adapters/Dashboard.lua", "GoldWise", { supportedClient = true })
unavailable.globals.GoldWiseOpen()
assert(unavailable.output[1]:find("dashboard unavailable", 1, true))
print("PASS missing UI primitives leave the dashboard unavailable without a Lua error")
