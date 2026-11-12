local Guide = dofile("data/ScanGuide.lua")
assert(#Guide.steps == 9)
local function step(key)
    for _, item in ipairs(Guide.steps) do if item.key == key then return item end end
    error("missing step " .. key)
end
local prefs, status = Guide.open(nil)
assert(status == "created" and prefs.step == 1 and not prefs.finished)
assert(Guide.setStep(prefs, 6) and prefs.step == 6)
assert(Guide.skip(prefs, "auction") and prefs.skipped.auction)
assert(not Guide.skip(prefs, "nonexistent"))
assert(Guide.finish(prefs) and prefs.finished)
local clone, result = Guide.open(prefs)
assert(result == "current" and clone ~= prefs and clone.skipped ~= prefs.skipped and clone.skipped.auction)
print("PASS versioned preferences and skip/finish round-trip")
local bad = {
    { schemaVersion = 2, finished = false, step = 1, skipped = {} },
    { schemaVersion = 1, finished = 1, step = 1, skipped = {} },
    { schemaVersion = 1, finished = false, step = 0, skipped = {} },
    { schemaVersion = 1, finished = false, step = 10, skipped = {} },
    { schemaVersion = 1, finished = false, step = 1, skipped = { imaginary = true } },
    { schemaVersion = 1, finished = false, step = 1, skipped = { bags = false } },
    { schemaVersion = 1, finished = false, step = 1, skipped = {}, unexpected = true },
}
for _, value in ipairs(bad) do
    local opened, reason = Guide.open(value)
    assert(opened == nil and reason == "corrupt")
end
print("PASS malformed saved preferences do not become valid state")
local source = { scope = "realmA", observedAt = 1000, complete = true }
local function check(key, observed, now, ttl, scope, supported, expected)
    local state = Guide.evaluate(step(key), observed, now, ttl, scope, supported)
    assert(state == expected, key .. ": expected " .. expected .. " got " .. state)
end
check("character", source, 1020, 900, "realmA", true, "Last observed")
check("bags", source, 1020, 900, "realmA", true, "Last observed")
check("bags", nil, 1020, 900, "realmA", true, "Pending")
check("bags", source, 1020, 900, "realmB", true, "Pending")
check("bags", source, 999, 900, "realmA", true, "Pending")
check("bags", source, nil, 900, "realmA", true, "Pending")
check("bags", { scope="realmA", observedAt=1000, complete=false }, 1020, 900, "realmA", true, "Partial")
check("bags", source, 1901, 900, "realmA", true, "Stale")
check("auction", source, 1301, 300, "realmA", true, "Stale")
check("bank", source, 1020, 900, "realmA", true, "Unsupported")
check("character", source, 1020, 900, "realmA", false, "Unsupported")
print("PASS source statuses, scope, freshness, partial and unsupported cases")
for _, candidate in ipairs(Guide.steps) do
    assert(candidate.title ~= "" and candidate.instruction ~= "" and candidate.why ~= "")
    assert(candidate.method == "Automatic" or candidate.method == "Player action required"
        or candidate.method == "Unsupported")
end
print("PASS every guide step has a safe method, instruction, and explanation")
