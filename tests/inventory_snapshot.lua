local globals = setmetatable({ ipairs = ipairs, type = type }, {
    __index = function(_, key)
        error("inventory model read an unexpected global: " .. key)
    end,
})
local Snapshot = setfenv(assert(loadfile("data/InventorySnapshot.lua")), globals)()

local reader = {}
function reader.slotCount(bag)
    if bag == "Backpack" then
        return 3
    elseif bag == "ReagentBag" then
        return 1
    end
    return 0
end

function reader.stack(bag, slot)
    if bag == "ReagentBag" then
        return 101, 6
    elseif slot == 1 then
        return 101, 4
    elseif slot == 2 then
        return 102, 2
    end
    return false
end

local complete = assert(Snapshot.capture("fixture:one", 1794220000, reader))
assert(complete.status == "complete" and complete.totals[101] == 10 and complete.totals[102] == 2)
assert(complete.characterScope == "fixture:one" and complete.observedAt == 1794220000 and complete.source == "wow-client")
assert(complete.bank == "unobserved" and complete.alts == "unobserved")
assert(#complete.bags == 6 and #complete.bags[1].stacks == 2 and complete.bags[1].unreadableSlots == 0)
assert(complete.bags[2].slots == 0 and complete.bags[2].status == "complete")
print("PASS carried stacks aggregate by item ID and retain ownership and availability")

local partial = assert(Snapshot.capture("fixture:two", 1794220001, {
    slotCount = function(bag)
        if bag == "Backpack" then return 3 end
        if bag == "Bag_1" then return 129 end
        return 0
    end,
    stack = function(bag, slot)
        assert(bag == "Backpack", "invalid capacity must not cause slot reads")
        if slot == 1 then return 101, 2 end
        if slot == 2 then return 101, 0 end
        return nil
    end,
}))
assert(partial.status == "partial" and partial.totals[101] == 2 and complete.totals[101] == 10)
assert(partial.bags[1].status == "partial" and partial.bags[1].unreadableSlots == 2)
assert(partial.bags[2].status == "unavailable" and partial.bags[2].slots == nil)
print("PASS unreadable slots and oversized bags remain partial without inventing counts")

local unavailable = assert(Snapshot.capture("fixture:one", 1794220000, {
    slotCount = function() return 0 end,
    stack = function() error("unexpected slot read") end,
}))
assert(unavailable.status == "unavailable" and unavailable.bags[1].slots == nil and next(unavailable.totals) == nil)
local empty = assert(Snapshot.capture("fixture:one", 1794220000, {
    slotCount = function(bag) return bag == "Backpack" and 1 or 0 end,
    stack = function() return false end,
}))
assert(empty.status == "complete" and next(empty.totals) == nil)
print("PASS observed empty bags are distinct from unavailable inventory")

local result, reason = Snapshot.capture(nil, 1794220000, reader)
assert(result == nil and reason == "missing-character-scope")
result, reason = Snapshot.capture("fixture:one", math.huge, reader)
assert(result == nil and reason == "invalid-timestamp")
print("PASS missing owner or invalid timestamp prevents a snapshot")
