local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")
local probe = "tests/probes/GoldWiseInventoryProbe/Probe.lua"
local readBuild = ForeverClient.build("1.60.1", "70862", 16001)

local function fixture(build)
    local client = ForeverClient.new(build or readBuild)
    local globals = client.globals
    globals.issecretvalue = function(value) return value == "restricted fixture value" end
    globals.Enum = { BagIndex = { Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5 } }
    globals.GetServerTime = function() return 1794220000 end
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
    client:load("data/InventorySnapshot.lua", "GoldWiseInventoryProbe", addon)
    client:load(probe, "GoldWiseInventoryProbe", addon)
    assert(#client.output == 1 and infoReads == 0, "probe must wait for manual request")
    return client, function() return infoReads end
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
