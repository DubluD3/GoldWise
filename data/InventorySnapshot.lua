local InventorySnapshot = {}
local BAG_NAMES = { "Backpack", "Bag_1", "Bag_2", "Bag_3", "Bag_4", "ReagentBag" }
local MAX_SLOTS = 128
local MAX_STACK = 2147483647

local function integerInRange(value, minimum, maximum)
    return type(value) == "number" and value >= minimum and value <= maximum and value % 1 == 0
end

-- The reader returns nil for an unreadable slot, false for an observed empty
-- slot, or a positive item ID followed by its stack quantity.
function InventorySnapshot.capture(characterScope, observedAt, reader)
    if type(characterScope) ~= "string" or #characterScope == 0 then
        return nil, "missing-character-scope"
    end
    if not integerInRange(observedAt, 1, 2 ^ 53 - 1) then
        return nil, "invalid-timestamp"
    end

    local snapshot = {
        characterScope = characterScope,
        observedAt = observedAt,
        source = "wow-client",
        bags = {},
        totals = {},
        bank = "unobserved",
        alts = "unobserved",
    }
    local completeBags = 0
    local knownSlots = 0

    for _, name in ipairs(BAG_NAMES) do
        local bag = { name = name, status = "unavailable", stacks = {}, unreadableSlots = 0 }
        snapshot.bags[#snapshot.bags + 1] = bag
        local minimumSlots = name == "Backpack" and 1 or 0
        local slotCount = reader.slotCount(name)
        if integerInRange(slotCount, minimumSlots, MAX_SLOTS) then
            bag.slots = slotCount
            knownSlots = knownSlots + slotCount
            for slot = 1, slotCount do
                local itemId, quantity = reader.stack(name, slot)
                if integerInRange(itemId, 1, 2 ^ 53 - 1) and integerInRange(quantity, 1, MAX_STACK) then
                    bag.stacks[#bag.stacks + 1] = { slot = slot, itemId = itemId, quantity = quantity }
                    snapshot.totals[itemId] = (snapshot.totals[itemId] or 0) + quantity
                elseif itemId ~= false then
                    bag.unreadableSlots = bag.unreadableSlots + 1
                end
            end
            bag.status = bag.unreadableSlots == 0 and "complete" or "partial"
            if bag.status == "complete" then
                completeBags = completeBags + 1
            end
        end
    end

    if completeBags == #BAG_NAMES then
        snapshot.status = "complete"
    elseif knownSlots > 0 then
        snapshot.status = "partial"
    else
        snapshot.status = "unavailable"
    end
    return snapshot
end

local _, addon = ...
if addon then
    addon.inventorySnapshotModel = InventorySnapshot
end

return InventorySnapshot
