local Model = dofile("data/MarketCompanionSummary.lua")
local character = { scopeKey = "fixture:one" }
local observation = {
    source = "wow-ah-browse-cache", characterScope = "fixture:one",
    observedAt = 1000, status = "partial", reportedRows = 5,
    rows = {
        { itemId=23, itemLevel=1, itemSuffix=0, battlePetSpeciesId=0, minimumCopper=78, reportedQuantity=2 },
        { itemId=11, itemLevel=1, itemSuffix=0, battlePetSpeciesId=0, minimumCopper=40, reportedQuantity=3 },
        { itemId=34, itemLevel=1, itemSuffix=0, battlePetSpeciesId=0, minimumCopper=55, reportedQuantity=5 },
        { itemId=99, itemLevel=1, itemSuffix=0, battlePetSpeciesId=0, minimumCopper=77, reportedQuantity=8 },
    },
}
local text = assert(Model.evaluate(observation, character, 1020))
assert(text:find("4 readable of 5 reported rows", 1, true))
assert(text:find("Item 23 | min 78 copper | qty 2", 1, true))
assert(text:find("Plus 1 other observed rows.", 1, true))
assert(not text:find("Item 99", 1, true))
assert(text:find("NOT sale proceeds", 1, true))
assert(text:find("No fee, profit, per-unit or market identity verified", 1, true))
print("PASS manual browse cache summary is bounded and avoids profitability claims")

assert(Model.evaluate(observation, {scopeKey="other"}, 1020) == nil)
assert(Model.evaluate(observation, character, 1301) == nil)
assert(Model.evaluate(observation, character, 999) == nil)
observation.rows[1].minimumCopper = "restricted"
assert(Model.evaluate(observation, character, 1020) == nil)
observation.rows[1].minimumCopper = 78
observation.rows[1].reportedQuantity = -2
assert(Model.evaluate(observation, character, 1020) == nil)
observation.rows[1].reportedQuantity = 2
observation.status = "complete"
assert(Model.evaluate(observation, character, 1020) == nil)
observation.status = "partial"
observation.reportedRows = 2
assert(Model.evaluate(observation, character, 1020) == nil)
observation.reportedRows = 5
observation.rows[999] = observation.rows[1]
assert(Model.evaluate(observation, character, 1020) == nil)
print("PASS stale, wrong-scope, corrupt and sparse browse cache are rejected")
