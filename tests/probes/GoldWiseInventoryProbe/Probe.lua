local _, addon = ...
local ok, version, build, _, interface = pcall(GetBuildInfo)
local supportedBuild = ok and version == "1.60.1" and build == "70862" and interface == 16001
local expectedBagIds = { Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5 }

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

function GoldWiseInventoryProbe_Run()
    if not supportedBuild then
        print("GoldWise inventory probe: client build unverified.")
        return
    end
    if type(issecretvalue) ~= "function" or type(C_Container) ~= "table"
        or type(Enum) ~= "table" or type(Enum.BagIndex) ~= "table" then
        print("GoldWise inventory probe: bag APIs or secret-value guard unavailable.")
        return
    end
    local containers = C_Container
    if type(containers.GetContainerNumSlots) ~= "function" or type(containers.HasContainerItem) ~= "function"
        or type(containers.GetContainerItemInfo) ~= "function" then
        print("GoldWise inventory probe: bag APIs unavailable.")
        return
    end

    local bagIds = {}
    for name, expectedId in pairs(expectedBagIds) do
        local id = readable(Enum.BagIndex[name])
        if id == expectedId then
            bagIds[name] = id
        end
    end

    local labels = {}
    local reader = {}
    function reader.slotCount(name)
        local bagId = bagIds[name]
        if bagId ~= nil then
            return read(containers.GetContainerNumSlots, bagId)
        end
    end

    function reader.stack(name, slot)
        local bagId = bagIds[name]
        local occupied = read(containers.HasContainerItem, bagId, slot)
        if occupied == false then
            return false
        end
        if occupied ~= true then
            return nil
        end

        local info = read(containers.GetContainerItemInfo, bagId, slot)
        if type(info) ~= "table" then
            return nil
        end
        local itemId = readable(info.itemID)
        local quantity = readable(info.stackCount)
        local label = readable(info.itemName)
        if type(itemId) == "number" and itemId >= 1 and itemId < 2 ^ 53
            and type(label) == "string" and #label > 0 and #label <= 128 then
            labels[itemId] = label
        end
        return itemId, quantity
    end

    local snapshot, reason = addon.inventorySnapshotModel.capture("probe-session", read(GetServerTime), reader)
    if not snapshot then
        print("GoldWise inventory probe: " .. reason .. ".")
        return
    end

    local status = {}
    local sample
    local sampleBag
    for _, bag in ipairs(snapshot.bags) do
        status[#status + 1] = bag.name .. "=" .. bag.status
        if not sample and bag.stacks[1] then
            sample = bag.stacks[1]
            sampleBag = bag.name
        end
    end
    print("GoldWise inventory probe: bags=" .. snapshot.status .. ", bank=unobserved, alts=unobserved.")
    print("GoldWise inventory probe: " .. table.concat(status, " "))
    if sample then
        local label = labels[sample.itemId] or "item ID " .. sample.itemId
        print("GoldWise inventory probe: sample " .. label .. " (" .. sampleBag .. " slot " .. sample.slot
            .. "), stack=" .. sample.quantity .. ", carried total=" .. snapshot.totals[sample.itemId] .. ".")
    end
end

print("GoldWise inventory probe loaded. Run /run GoldWiseInventoryProbe_Run() after login.")
