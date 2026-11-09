local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")

local savedVariable
for line in io.lines("GoldWise.toc") do
    if line:match("^## SavedVariables: ") then
        savedVariable = line:match("^## SavedVariables: (.+)$")
    end
end
assert(savedVariable == "GoldWiseDB", "unexpected SavedVariables declaration")

local function loadAddon(build, saved, registration)
    local addon = {}
    local client = ForeverClient.new(ForeverClient.build("1.60.1", build, 16001), registration)

    client:loadToc("GoldWise.toc", "GoldWise", addon)
    local globals = client.globals
    assert(globals.GoldWiseDB == nil and addon.storageState == nil, "storage touched before ADDON_LOADED")

    globals.GoldWiseDB = saved
    assert(not client:fire("ADDON_LOADED", "OtherAddon", false), "storage must wait for GoldWise")
    local registered = client:fire("ADDON_LOADED", "GoldWise", false)
    assert(not client:fire("ADDON_LOADED", "GoldWise", false), "storage callback should run once")
    return globals.GoldWiseDB, addon.storageState, client.output, registered
end

local saved, state, messages, registered = loadAddon("70862")
assert(registered and saved == state and saved.schemaVersion == 1 and next(saved.lastObservedAt) == nil)
assert(#messages == 2 and messages[2] == "GoldWise local storage created (schema 1).")
print("PASS first load creates schema v1 after ADDON_LOADED")

local existing = { schemaVersion = 1, lastObservedAt = { ["test scope"] = 100 } }
saved, state, messages = loadAddon("70862", existing)
assert(saved == state and saved.lastObservedAt["test scope"] == 100 and saved ~= existing)
assert(#messages == 2 and messages[2] == "GoldWise local storage current (schema 1).")
print("PASS reload opens existing state")

local legacy = { schemaVersion = 0, lastSeen = { ["test scope"] = 10 } }
saved, state, messages = loadAddon("70862", legacy)
assert(saved == state and saved.schemaVersion == 1 and saved.lastObservedAt["test scope"] == 10)
assert(legacy.schemaVersion == 0 and legacy.lastSeen["test scope"] == 10)
assert(#messages == 2 and messages[2] == "GoldWise local storage migrated (schema 1).")
print("PASS migration replaces the global after validation")

local rejected = {
    { saved = { schemaVersion = 1 }, reason = "corrupt" },
    { saved = { schemaVersion = 2 }, reason = "unsupported-version" },
}
for _, case in ipairs(rejected) do
    saved, state, messages = loadAddon("70862", case.saved)
    assert(saved == case.saved and state == nil)
    assert(#messages == 2 and messages[2] == "GoldWise local storage disabled (" .. case.reason .. ").")
    print("PASS " .. case.reason .. " saved data left untouched")
end

saved, state, messages, registered = loadAddon("70863", existing)
assert(saved == existing and state == nil and not registered and #messages == 1)
print("PASS unverified build leaves saved data untouched")

for _, registration in ipairs({ "missing", "fails" }) do
    saved, state, messages, registered = loadAddon("70862", existing, registration)
    assert(saved == existing and state == nil and not registered)
    assert(messages[2] == "GoldWise local storage disabled (ADDON_LOADED registration unavailable).")
    print("PASS " .. registration .. " registration leaves saved data untouched")
end
