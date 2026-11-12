local Summary = dofile("data/InventoryCompanionSummary.lua")
local character = { scopeKey = "fixture:char" }
local bags = {}
for i = 1, 6 do bags[i] = { status = "complete" } end
local snapshot = {
    characterScope = "fixture:char", observedAt = 1000, status = "complete",
    bags = bags, totals = { [23] = 4, [11] = 2, [55] = 5, [44] = 3 },
}
local good = assert(Summary.evaluate(snapshot, character, 1010))
assert(good:find("4 item types | 14 total units", 1, true))
assert(good:find("Item 11: 2 carried", 1, true))
assert(good:find("Item 23: 4 carried", 1, true))
assert(good:find("Item 44: 3 carried", 1, true))
assert(not good:find("Item 55:", 1, true))
assert(good:find("Plus 1 other item types", 1, true))
assert(good:find("Bank, mail and other characters: unknown", 1, true))
print("PASS inventory overview shows bounded deterministic carried-only totals")

assert(Summary.evaluate(snapshot, {scopeKey="other"}, 1010) == nil)
assert(Summary.evaluate(snapshot, character, 1901) == nil)
snapshot.status = "partial"
assert(Summary.evaluate(snapshot, character, 1010) == nil)
snapshot.status = "complete"
bags[1].status = "partial"
assert(Summary.evaluate(snapshot, character, 1010) == nil)
bags[1].status = "complete"
snapshot.totals[23] = -1
assert(Summary.evaluate(snapshot, character, 1010) == nil)
snapshot.totals[23] = 2147483648
assert(Summary.evaluate(snapshot, character, 1010) == nil)
snapshot.totals[23] = 2147483647
assert(Summary.evaluate(snapshot, character, 1010) == nil)
snapshot.totals[23] = 4
print("PASS stale, partial, wrong-scope and corrupt inventory fail closed")
