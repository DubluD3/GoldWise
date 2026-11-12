local Model = dofile("data/ProfessionCompanionSummary.lua")
local scope = { scopeKey = "test:character" }
local profession = {
    characterScope = scope.scopeKey, observedAt = 1000,
    professionName = "Tailoring", skill = 25, cap = 75,
    knownRecipes = { { id = 1 }, { id = 2 } },
}
local inventory = {
    characterScope = scope.scopeKey, observedAt = 1001, status = "complete",
}
local plan = {
    characterScope = scope.scopeKey, build = "70888", observedAt = 1002,
    professionSnapshot = profession, inventory = inventory, missing = { [123] = 4, [456] = 2 },
}
local function summary(prof, bags, currentPlan, currentScope, build, now)
    return Model.evaluate(prof, bags, currentPlan, currentScope, build, now)
end
local baseline = assert(summary(profession, inventory, nil, scope, "70888", 1010))
assert(baseline:find("25 / 75 skill", 1, true))
assert(baseline:find("2 learned recipes", 1, true))
assert(baseline:find("Plan: unavailable", 1, true))
local ready = assert(summary(profession, inventory, plan, scope, "70888", 1010))
assert(ready:find("6 missing units across 2 items", 1, true))
plan.missing = {}
assert(summary(profession, inventory, plan, scope, "70888", 1010):find("no missing carried reagents", 1, true))
print("PASS companion summarizes only current observed plan and reagent shortfall")

plan.missing = { [123] = 4 }
assert(summary(profession, inventory, plan, scope, "70862", 1010):find("Plan: unavailable", 1, true))
assert(summary(profession, inventory, plan, scope, "70888", 1910):find("Plan: unavailable", 1, true) == nil)
local laterProfession = {
    characterScope = scope.scopeKey, observedAt = 1020,
    professionName = "Tailoring", skill = 25, cap = 75, knownRecipes = {},
}
assert(summary(laterProfession, inventory, plan, scope, "70888", 1020):find("Plan: unavailable", 1, true))
inventory.status = "partial"
assert(summary(profession, inventory, plan, scope, "70888", 1020):find("Plan: unavailable", 1, true))
inventory.status = "complete"
local differentScope = { scopeKey = "test:other" }
assert(summary(profession, inventory, plan, differentScope, "70888", 1020) == nil)
print("PASS cross-build, rescan, partial bags and wrong scope fail closed")

plan.missing = { [123] = -1 }
assert(summary(profession, inventory, plan, scope, "70888", 1020):find("Plan: unavailable", 1, true))
plan.missing = { [123] = 2147483647, [456] = 1 }
assert(summary(profession, inventory, plan, scope, "70888", 1020):find("Plan: unavailable", 1, true))
assert(summary(profession, inventory, plan, scope, "70888", nil) == nil)
print("PASS malformed and overflowing missing quantities never become advice")
