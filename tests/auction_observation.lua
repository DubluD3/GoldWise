local globals = setmetatable({ type = type }, {
    __index = function(_, key)
        error("auction model read an unexpected global: " .. key)
    end,
})
local Observation = setfenv(assert(loadfile("data/AuctionObservation.lua")), globals)()

local row = {
    itemId = 100, itemLevel = 0, itemSuffix = -2, battlePetSpeciesId = 0,
    minimumCopper = 12345, reportedQuantity = 5,
}
local raw = { row }
local complete = true
local reads = 0
local reader = {
    rows = function() return raw end,
    full = function() return complete end,
    rowAt = function(rows, index)
        reads = reads + 1
        return rows[index]
    end,
}

local observed = assert(Observation.capture(1794220000, reader))
assert(observed.status == "complete" and observed.reportedRows == 1 and reads == 1)
assert(observed.rows[1].minimumCopper == 12345 and observed.rows[1].itemSuffix == -2)
assert(observed.source == "wow-ah-browse-cache" and observed.observedAt == 1794220000)
print("PASS browse minimum and item-key dimensions are preserved")

complete = false
raw = { row, { minimumCopper = 2 ^ 53 } }
local partial = assert(Observation.capture(1794220000, reader))
assert(partial.status == "partial" and partial.reportedRows == 2 and #partial.rows == 1)
complete = nil
raw = { row }
assert(Observation.capture(1794220000, reader).status == "partial")
print("PASS incomplete, unreadable, and unknown-completeness rows remain partial")

raw = {}
complete = true
local empty = assert(Observation.capture(1794220000, reader))
assert(empty.status == "complete" and empty.reportedRows == 0 and #empty.rows == 0)
raw = nil
local unavailable, reason = Observation.capture(1794220000, reader)
assert(unavailable == nil and reason == "browse cache unavailable")
unavailable, reason = Observation.capture(nil, reader)
assert(unavailable == nil and reason == "timestamp unavailable")
print("PASS an observed empty result differs from an unavailable cache")

raw = {}
for index = 1, 129 do
    raw[index] = row
end
reads = 0
local bounded = assert(Observation.capture(1794220000, reader))
assert(bounded.status == "partial" and bounded.reportedRows == 129 and #bounded.rows == 128 and reads == 128)
print("PASS cache processing stops at the project row limit")
