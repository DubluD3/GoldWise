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
    function object:SetColorTexture(...) self.color = { ... } end
    function object:SetTextColor(...) self.textColor = { ... } end
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

globals.math, globals.unpack, globals.next, globals.tonumber = math, unpack, next, tonumber
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
local function visibleButton(label)
    for _, candidate in ipairs(widgets) do
        if candidate.shown and candidate.label and candidate.label.value == label then
            return candidate
        end
    end
end
local function hasPagerLabel(label)
    for _, candidate in ipairs(widgets) do
        if candidate.label and candidate.label.value == label then return true end
    end
end
local function activeTab(label, other)
    local selected = assert(visibleButton(label), "missing selected tab " .. label)
    local inactive = assert(visibleButton(other), "missing inactive tab " .. other)
    assert(selected.background and inactive.background)
    assert(selected.background.color[1] ~= inactive.background.color[1],
        "selected tab must be visually distinct")
    assert(selected.label.textColor[1] ~= inactive.label.textColor[1],
        "selected tab label must have visual emphasis")
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
activeTab("Overview", "Inventory")
globals.SlashCmdList.GOLDWISE("goal gold 25000")
assert(hasText("GoldWise  /  My Goals") and hasText("Gold: unknown"))
assert(hasText("Custom session target set"))
globals.SlashCmdList.GOLDWISE("goal gold -1")
assert(hasText("Invalid goal command") and hasText("Gold: unknown"))
globals.SlashCmdList.GOLDWISE("goal skill 75")
assert(hasText("Scan your open profession first") and hasText("Gold: unknown"))
globals.SlashCmdList.GOLDWISE("goal clear")
assert(hasText("No active goal"))
click("Overview")
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
for _ = addon.guidePreferences.step, 8 do click("Next step") end
assert(hasText("Recipe plans and reservations"))
click("Finish guide")
assert(addon.guidePreferences.finished and hasText("GoldWise  /  Overview"))
click("Sample balance")
assert(hasText("Ledger · 0 recorded changes"))
click("Goals")
assert(hasText("No active goal"))
click("Gold +1g")
assert(hasText("Gold: 500 / 10500 copper, 10000 remaining"))
assert(hasText("Combined goal: in-progress"))
click("Back to plan")
assert(hasText("GoldWise  /  My Plan"))
click("Overview")
click("Quick test")
assert(hasText("GoldWise  /  Quick Test"))
assert(hasText("Bags: NEEDS SCAN") and hasText("Professions: NEEDS SCAN"))
assert(hasText("Balance: manually sampled") and hasText("Reagent plan: PENDING"))
click("Scan bags")
assert(hasText("Bags: observed (complete)") and reads == 1)
click("Scan profession")
assert(hasText("Professions: observed (filtered view)"))
click("Sample balance")
assert(hasText("Balance: manually sampled"))
click("Choose recipe")
assert(hasText("GoldWise  /  Professions"))
click("Overview")
click("Quick test")
assert(hasText("GoldWise  /  Quick Test") and hasText("Bags: observed (complete)"))
click("Back to Overview")
assert(hasText("GoldWise  /  Overview"))
print("PASS quick-test page provides a guided manual scan and navigation path")
globals.ContainerFrame1 = { IsVisible = visible }
click("Inventory")
activeTab("Inventory", "Overview")
assert(hasPagerLabel("Next item") and hasPagerLabel("Previous item"))
click("Scan bags")
assert(reads == 2 and vendorReads == 0 and hasText("Fixture hide") and not hasText("Action unavailable"))
assert(visibleButton("GoldWise Bags"))
click("GoldWise Bags")
assert(hasText("GoldWise | Carried Bags"))
assert(hasText("1 item types | 4 total units"))
assert(hasText("Item 78: 4 carried"))
assert(hasText("Bank, mail and other characters: unknown."))
click("Hide")
globals.GoldWiseOpen("inventory")
assert(hasText("GoldWise  /  Inventory"))
print("PASS optional bag-frame companion displays manual carried-only data and dashboard fallback")

click("Check vendor value")
assert(vendorReads == 1 and hasText("29 copper"))
click("Review materials")
assert(hasText("Material Review") and hasText("4 carried, 0 held, 4 manual-review"))
assert(hasText("Not a sell recommendation"))
assert(vendorReads == 1)
click("Back to bags")
assert(hasText("GoldWise  /  Inventory"))
clock = clock + 901
globals.GoldWiseOpen()
globals.GoldWiseOpen()
assert(hasText("Stale") and hasText("Refresh bag counts"))
print("PASS dashboard opens lazily, renders inventory, and reads vendor info only on request")

click("Scan bags")
click("Professions")
activeTab("Professions", "Inventory")
assert(hasPagerLabel("Next recipe") and hasPagerLabel("Previous recipe"))
click("Scan profession")
assert(addon.professionCompanion.isCurrent())
assert(visibleButton("GoldWise"))
click("GoldWise")
assert(hasText("GoldWise | Profession") and hasText("Plan: unavailable."))
click("Open GoldWise")
assert(hasText("GoldWise  /  Professions"))
click("GoldWise")
click("GoldWise")
assert(hasText("Plan: unavailable."))
click("Hide")
print("PASS optional profession-attached companion shows manual-scanned evidence and opens native dashboard")

globals.SlashCmdList.GOLDWISE("goal gold 10000")
assert(hasText("Gold: unknown") and hasText("Custom session target set"))
globals.SlashCmdList.GOLDWISE("goal skill 35")
assert(hasText("Profession: 30 / 35 skill, 5 remaining"))
assert(hasText("Gold: unknown"))
globals.SlashCmdList.GOLDWISE("goal skill 99")
assert(hasText("target must not exceed") and hasText("Profession: 30 / 35"))
globals.SlashCmdList.GOLDWISE("goal clear")
assert(hasText("No active goal"))
click("Professions")
click("More crafts")
click("Plan reagents")
assert(plans == 1 and hasText("GoldWise  /  My Plan") and hasText("Missing 2"))
click("GoldWise")
assert(hasText("Plan: 2 missing units across 1 items."))
assert(hasText("Recipe: 2 x Fixture recipe"))
assert(hasText("Missing: Item 78 x 2"))
click("Hide")
print("PASS profession companion reads only the current manually created reagent plan")
click("Direct capacity")
assert(hasText("GoldWise  /  Direct Capacity"))
assert(hasText("Up to 1 runs covered by observed direct reagents"))
assert(hasText("4 free of 3 needed per run"))
assert(hasText("Not a guaranteed craft or skill-up estimate"))
click("Back to plan")
assert(hasText("GoldWise  /  My Plan"))
click("Review progression")
assert(hasText("GoldWise  /  Profession Review"))
assert(hasText("Observed skill 30 / 60"))
assert(hasText("No matching skill target"))
assert(hasText("Current recipe plan lacks 2 carried reagent units"))
assert(hasText("no guaranteed leveling route"))
click("Back to plan")
assert(hasText("GoldWise  /  My Plan"))
click("Goals")
click("Skill +10")
assert(hasText("Profession: 30 / 40 skill, 10 remaining"))
assert(not hasText("Gold: unknown")) -- cleared prior goal; quick skill action sets only skill
click("Back to plan")
click("Reserve carried reagents")
assert(hasText("This recipe has a session reservation."))
assert(addon.recipePlan.build == addon.clientBuild)
click("Direct capacity")
assert(hasText("Up to 1 runs covered by observed direct reagents"))
click("Back to plan")
click("Inventory")
assert(hasText("Keep 4 for My Plan") and hasText("4 reserved across session plans"))
click("Review materials")
assert(hasText("4 carried, 4 held, 0 manual-review"))
assert(hasText("hold-and-review"))
click("Back to bags")
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
assert(visibleButton("GoldWise Market"))
click("GoldWise Market")
assert(hasText("GoldWise | Market Observation"))
assert(hasText("1 readable of 1 reported rows"))
assert(hasText("Item 78 | min 80 copper | qty 2"))
assert(hasText("No fee, profit, per-unit or market identity verified."))
click("Market details")
assert(hasText("GoldWise  /  Market"))
click("Hide")
print("PASS market companion uses only explicit cache observation and links to dashboard")
click("Overview")
click("Sample balance")
click("Goals")
click("Gold +1g")
assert(hasText("Gold: 500 / 10500 copper"))
clock = clock + 901
globals.GoldWiseOpen()
globals.GoldWiseOpen()
assert(hasText("Combined goal: incomplete") and hasText("Gold: unknown"))
assert(hasText("Profession: unknown"))
click("Clear goals")
assert(hasText("No active goal"))
click("Back to plan")
print("PASS dashboard connects profession, reagent, manual market and expiring goal flows")
click("Inventory")
click("Scan bags")
click("Professions")
click("Scan profession")
click("Plan reagents")
assert(hasText("GoldWise  /  My Plan") and hasText("Reagent plan"))
click("Professions")
click("Scan profession")
assert(addon.professionCompanion.isCurrent())
click("My Plan")
assert(hasText("Choose a learned recipe under Professions"))
assert(not hasText("Reagent plan ·"))
print("PASS new manual profession scan invalidates prior plan presentation")
globals.SlashCmdList.GOLDWISE("guide")
assert(hasText("Recipe plans and reservations"))
assert(hasText("State: Pending"))
assert(hasText("No observation in this session"))
click("Exit guide")
print("PASS scan guide never certifies an old plan after a profession rescan")

click("Inventory")
local held = addon.reservationsFor(addon.inventorySnapshot)
held[999] = { [999] = 1 }
click("Inventory")
assert(hasText("Reservation counts unavailable"))
click("Professions")
click("Plan reagents")
assert(hasText("Reservation state invalid"))
assert(addon.recipePlan == nil)
held[999] = nil
print("PASS corrupted reservation availability fails closed in inventory and planning")


local unavailable = Fixture.new()
unavailable:load("adapters/Dashboard.lua", "GoldWise", { supportedClient = true })
unavailable.globals.GoldWiseOpen()
assert(unavailable.output[1]:find("dashboard unavailable", 1, true))
print("PASS missing UI primitives leave the dashboard unavailable without a Lua error")
