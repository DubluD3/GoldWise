local _, addon = ...
local BagCapture = {}

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

function BagCapture.capture(characterScope)
    if type(issecretvalue) ~= "function" or type(C_Container) ~= "table"
        or type(Enum) ~= "table" or type(Enum.BagIndex) ~= "table" then
        return nil, "bag APIs or secret-value guard unavailable"
    end
    local containers = C_Container
    if type(containers.GetContainerNumSlots) ~= "function" or type(containers.HasContainerItem) ~= "function"
        or type(containers.GetContainerItemInfo) ~= "function" then
        return nil, "bag APIs unavailable"
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

    local snapshot, reason = addon.inventorySnapshotModel.capture(characterScope, read(GetServerTime), reader)
    if not snapshot then
        return nil, reason
    end
    return snapshot, labels
end

function BagCapture.report(prefix, snapshot, labels)
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
    print(prefix .. ": bags=" .. snapshot.status .. ", bank=" .. snapshot.bank .. ", alts=" .. snapshot.alts .. ".")
    print(prefix .. ": " .. table.concat(status, " "))
    if sample then
        local label = labels[sample.itemId] or "item ID " .. sample.itemId
        local totalLabel = snapshot.status == "complete" and "carried total" or "observed carried total"
        print(prefix .. ": sample " .. label .. " (" .. sampleBag .. " slot " .. sample.slot
            .. "), stack=" .. sample.quantity .. ", " .. totalLabel .. "=" .. snapshot.totals[sample.itemId] .. ".")
    end
end

addon.bagCapture = BagCapture
