local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")
local probe = "tests/probes/GoldWiseInventoryProbe/Probe.lua"
local readBuild = ForeverClient.build("1.60.1", "70862", 16001)

local function fixture(build, product)
    local client = ForeverClient.new(build or readBuild)
    local globals = client.globals
    globals.issecretvalue = function(value) return value == "restricted fixture value" end
    globals.Enum = { BagIndex = { Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5 } }
    globals.GetServerTime = function() return 1794220000 end
    globals.UnitGUID = function() return "fixture:one" end
    globals.GetRealmName = function() return "Fixture Realm" end
    globals.UnitFactionGroup = function() return "Fixture Faction" end
    globals.GetCurrentRegion = function() return 3 end
    local infoReads = 0
    globals.C_Container = {
        GetContainerNumSlots = function(bag)
            assert(bag >= 0 and bag <= 5)
            if bag == 0 then return 2 end
            return bag == 5 and 1 or 0
        end,
        HasContainerItem = function(bag, slot)
            assert(bag == 0 or bag == 5)
            return slot == 1
        end,
        GetContainerItemInfo = function(bag, slot)
            assert(slot == 1, "probe requested item info for an empty slot")
            infoReads = infoReads + 1
            return { itemID = 101, stackCount = bag == 0 and 3 or 4, itemName = "Fixture Material" }
        end,
    }
    local addon = {}
    if product then
        client:loadToc("GoldWise.toc", "GoldWise", addon)
    else
        client:load("data/InventorySnapshot.lua", "GoldWiseInventoryProbe", addon)
        client:load("adapters/BagCapture.lua", "GoldWiseInventoryProbe", addon)
        client:load(probe, "GoldWiseInventoryProbe", addon)
    end
    assert(#client.output == 1 and infoReads == 0, "probe must wait for manual request")
    return client, function() return infoReads end, addon
end

local client, reads = fixture()
client.globals.GoldWiseInventoryProbe_Run()
assert(reads() == 2)
assert(client.output[2]:match("bags=complete, bank=unobserved, alts=unobserved"))
assert(client.output[3]:match("ReagentBag=complete"))
assert(client.output[4]:match("sample Fixture Material %(Backpack slot 1%), stack=3, carried total=7"))
print("PASS manual probe reports carried counts and skips empty slots")

local partial = fixture()
partial.globals.Enum.BagIndex.ReagentBag = 0
partial.globals.C_Container.GetContainerItemInfo = function()
    return { itemID = 101, stackCount = "restricted fixture value" }
end
partial.globals.GoldWiseInventoryProbe_Run()
assert(partial.output[2]:match("bags=partial"))
assert(partial.output[3]:match("Backpack=partial") and partial.output[3]:match("ReagentBag=unavailable"))
assert(#partial.output == 3)
print("PASS restricted counts and mismatched enum entries stay unavailable")

local unsupported, unsupportedReads = fixture(ForeverClient.build("1.60.1", "70863", 16001))
unsupported.globals.GoldWiseInventoryProbe_Run()
assert(unsupportedReads() == 0 and unsupported.output[2]:match("client build unverified"))
local missing, missingReads = fixture()
missing.globals.C_Container.HasContainerItem = nil
missing.globals.GoldWiseInventoryProbe_Run()
assert(missingReads() == 0 and missing.output[2]:match("bag APIs unavailable"))
print("PASS unsupported builds and missing APIs stop the scan")

local product, productReads, addon = fixture(nil, true)
product.globals.GoldWiseInventoryScan()
assert(productReads() == 0 and addon.inventorySnapshot == nil)
assert(product.output[#product.output]:match("character snapshot unavailable"))
assert(product:fire("ADDON_LOADED", "GoldWise", false))
assert(product:fire("PLAYER_ENTERING_WORLD", true, false))
assert(productReads() == 0 and addon.inventorySnapshot == nil)
product.globals.GoldWiseInventoryScan()
assert(productReads() == 2 and addon.features.inventory)
assert(addon.inventorySnapshot.characterScope == addon.characterSnapshot.scopeKey)
assert(addon.inventorySnapshot.totals[101] == 7 and addon.inventorySnapshot.observedAt == 1794220000)
assert(next(product.globals.GoldWiseDB.lastObservedAt) == nil)
assert(product.output[#product.output]:match("carried total=7"))
print("PASS product manual scan uses the active character and leaves SavedVariables untouched")

product.globals.C_Container.GetContainerItemInfo = function(bag)
    if bag == 0 then
        return { itemID = 101, stackCount = 3, itemName = "Fixture Material" }
    end
end
product.globals.GoldWiseInventoryScan()
assert(addon.inventorySnapshot.status == "partial" and not addon.features.inventory)
assert(addon.inventorySnapshot.totals[101] == 3)
assert(product.output[#product.output]:match("observed carried total=3"))
product.globals.C_Container.GetContainerNumSlots = function() return nil end
product.globals.GoldWiseInventoryScan()
assert(addon.inventorySnapshot == nil and not addon.features.inventory)
assert(product.output[#product.output - 1]:match("bags=unavailable"))
print("PASS partial results show observed counts and unavailable refresh clears the snapshot")

local otherBuild, otherReads, otherAddon = fixture(ForeverClient.build("1.60.1", "70863", 16001), true)
otherBuild.globals.GoldWiseInventoryScan()
assert(otherReads() == 0 and otherAddon.inventorySnapshot == nil)
assert(otherBuild.output[#otherBuild.output]:match("client build unverified"))
print("PASS product skips bag reads on unverified builds")
