local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")

local probePath = "tests/probes/GoldWiseStorageProbe/Probe.lua"
local probeName = "GoldWiseStorageProbe"
local cases = {
    { name = "marker restored", marker = "gw005", message = "marker present at ADDON_LOADED" },
    { name = "marker absent", message = "marker missing at ADDON_LOADED" },
    { name = "marker unexpected", marker = "other", message = "marker missing at ADDON_LOADED" },
    { name = "missing event helper", noEvent = true, message = "ADDON_LOADED registration unavailable" },
    { name = "changed build", build = "70863", message = "client build unverified" },
}

for _, case in ipairs(cases) do
    local readBuild = ForeverClient.build("1.60.1", case.build or "70862", 16001)
    local client = ForeverClient.new(readBuild, case.noEvent and "missing" or nil)
    client:load(probePath, probeName)
    local output = client.output
    if case.noEvent or case.build then
        assert(not client:fire("ADDON_LOADED", probeName, false))
    else
        assert(#output == 0, "probe should wait for ADDON_LOADED")
        client.globals.GoldWiseStorageProbeMarker = case.marker
        assert(client:fire("ADDON_LOADED", probeName, false))
    end
    assert(#output == 1 and output[1] == "GoldWise storage probe: " .. case.message, case.name)
    assert(client.globals.GoldWiseStorageProbeMarker == case.marker, "probe must leave the marker unchanged")
    print("PASS " .. case.name)
end
