local globals = setmetatable({ type = type, ipairs = ipairs, table = { remove = table.remove } }, {
    __index = function(_, key)
        error("ledger read an unexpected global: " .. key)
    end,
})
local Ledger = setfenv(assert(loadfile("data/Ledger.lua")), globals)()

local function sample(observedAt, balanceCopper)
    return {
        build = "70862", characterScope = "fixture:character",
        observedAt = observedAt, balanceCopper = balanceCopper, source = "wow-character-money",
    }
end

local state = assert(Ledger.new("70862", "fixture:character"))
local id, status = Ledger.observe(state, sample(100, 0), 60)
assert(id == nil and status == "baseline" and #state.entries == 0)
local incoming = sample(160, 1200)
id, status = Ledger.observe(state, incoming, 60)
assert(id == 160 and status == "recorded")
incoming.balanceCopper = 0
local entry = state.entries[1]
assert(entry.kind == "balance-change" and entry.deltaCopper == 1200)
assert(entry.fromObservedAt == 100 and entry.observedAt == 160 and entry.source == "wow-character-money")
assert(entry.category == "unclassified" and entry.confidence == "unknown")
id, status = Ledger.observe(state, sample(161, 1200), 60)
assert(id == nil and status == "unchanged" and #state.entries == 1)
print("PASS signed net balance changes carry timestamps and no inferred transaction type")

local categorized
categorized, status = Ledger.categorize(state, 160, "purchase")
assert(not categorized and status == "category-direction-mismatch")
assert(Ledger.categorize(state, 160, "sale"))
assert(entry.category == "sale" and entry.confidence == "user-reported" and entry.kind == "balance-change")
assert(Ledger.categorize(state, 160, "unclassified"))
assert(entry.category == "unclassified" and entry.confidence == "unknown" and entry.deltaCopper == 1200)
categorized, status = Ledger.categorize(state, 160, "confirmed-sale")
assert(not categorized and status == "invalid-category")
assert(Ledger.observe(state, sample(162, 1198), 60) == 162)
assert(Ledger.categorize(state, 162, "purchase") and state.entries[2].deltaCopper == -2)
print("PASS manual attribution is reversible and cannot mark a delta as a confirmed sale")

assert(Ledger.new("70863", "fixture:character") == nil)
id, status = Ledger.observe(state, nil, 60)
assert(id == nil and status == "unavailable")
local other = sample(163, 20)
other.characterScope = "fixture:other"
id, status = Ledger.observe(state, other, 60)
assert(id == nil and status == "scope-unavailable")
other.characterScope = "fixture:character"
other.build = "70863"
id, status = Ledger.observe(state, other, 60)
assert(id == nil and status == "scope-unavailable")
id, status = Ledger.observe(state, sample(162, 1), 60)
assert(id == nil and status == "out-of-order")
id, status = Ledger.observe(state, sample(163, -1), 60)
assert(id == nil and status == "unavailable" and state.latest.observedAt == 162)
id, status = Ledger.observe(state, sample(223, 1000), 60)
assert(id == nil and status == "stale-baseline" and #state.entries == 2)
assert(Ledger.observe(state, sample(224, 1002), 60) == 224)
assert(state.entries[3].deltaCopper == 2 and state.entries[3].fromObservedAt == 223)
print("PASS invalid and mismatched samples preserve the baseline and a stale interval starts a new one")

state = assert(Ledger.new("70862", "fixture:character"))
Ledger.observe(state, sample(100, 0), 1)
for index = 1, 65 do
    assert(Ledger.observe(state, sample(100 + index, index), 1))
end
assert(#state.entries == 64 and state.entries[1].observedAt == 102 and state.entries[64].observedAt == 165)
categorized, status = Ledger.categorize(state, 101, "other")
assert(not categorized and status == "entry-unavailable")
print("PASS the session retains only the most recent 64 balance changes")
