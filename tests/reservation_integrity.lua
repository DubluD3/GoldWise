local Reservations = dofile("data/MaterialReservations.lua")
local function expectRejected(held, recipe, request, stock)
    local copies = {}
    for id, rows in pairs(held) do
        local inner = {}
        if type(rows) == "table" then
            for item, qty in pairs(rows) do inner[item] = qty end
        else inner = rows end
        copies[id] = inner
    end
    local ok, reason = Reservations.reserve(held, recipe, request, stock)
    assert(ok == false and type(reason) == "string" and #reason > 0)
    for id, rows in pairs(copies) do
        if type(rows) == "table" then
            assert(held[id] and type(held[id]) == "table")
            for item, qty in pairs(rows) do assert(held[id][item] == qty) end
        else
            assert(held[id] == rows)
        end
    end
    for id in pairs(held) do assert(copies[id] ~= nil) end
end

local inventory = { [100] = 10, [101] = 5 }
local held = { [11] = { [100] = 4 }, [12] = { [100] = 3, [101] = 2 } }
assert(Reservations.reserve(held, 11, { [100] = 7 }, inventory))
assert(held[11][100] == 7 and held[12][100] == 3)
expectRejected(held, 11, { [100] = 8 }, inventory)
assert(held[11][100] == 7)
assert(Reservations.reserve(held, 11, { [100] = 2, [101] = 3 }, inventory))
assert(held[11][100] == 2 and held[11][101] == 3)
print("PASS same recipe can atomically replace holds while preserving other recipes")

local cases = {
    { [11] = { [100] = 6 }, [12] = { [100] = 5 } },
    { [11] = { [999] = 1 } },
    { [11] = { [100] = -1 } },
    { [11] = { [100] = 1.5 } },
    { [11] = { [100] = 0 } },
    { [11] = {} },
    { [11] = "not a table" },
    { ["recipe"] = { [100] = 1 } },
    { [11] = { ["item"] = 1 } },
}
for _, corrupt in ipairs(cases) do
    expectRejected(corrupt, 13, { [100] = 1 }, inventory)
end
expectRejected({}, 12, { [100] = 1 }, { [100] = -1 })
expectRejected({}, 12, { [100] = 1 }, { [100] = 1.5 })
expectRejected({}, 12, { [100] = 1 }, { ["id"] = 7 })
expectRejected({}, 12, { [999] = 1 }, inventory)
expectRejected({}, 12, { [100] = -1 }, inventory)
expectRejected({}, 12, { [100] = 1.5 }, inventory)
expectRejected({}, 0, { [100] = 1 }, inventory)
expectRejected({}, "invalid", { [100] = 1 }, inventory)
print("PASS corrupt old holds, invalid stock, phantom items and malformed new requests fail closed")

local capped = {}
for i = 1, 8 do capped[i] = { [101] = 1 } end
expectRejected(capped, 9, { [100] = 1 }, { [100] = 10, [101] = 8 })
assert(Reservations.reserve(capped, 1, { [100] = 1 }, { [100] = 10, [101] = 8 }))
local oversized = {}
for i = 1, 9 do oversized[i] = { [101] = 1 } end
expectRejected(oversized, 1, { [101] = 1 }, { [101] = 9 })
print("PASS maximum eight plans and existing allocation cap are checked before replacement")
