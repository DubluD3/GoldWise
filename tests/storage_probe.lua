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
    local output = {}
    local onLoaded
    local env = {
        pcall = pcall,
        type = type,
        print = function(message) output[#output + 1] = message end,
        GetBuildInfo = function() return "1.60.1", case.build or "70862", "test date", 16001 end,
    }
    if not case.noEvent then
        env.EventUtil = {
            RegisterOnceFrameEventAndCallback = function(event, callback, name)
                assert(event == "ADDON_LOADED" and name == probeName)
                onLoaded = callback
            end,
        }
    end

    setfenv(assert(loadfile(probePath)), env)(probeName)
    if case.noEvent or case.build then
        assert(onLoaded == nil)
    else
        assert(#output == 0, "probe should wait for ADDON_LOADED")
        env.GoldWiseStorageProbeMarker = case.marker
        assert(onLoaded)()
    end
    assert(#output == 1 and output[1] == "GoldWise storage probe: " .. case.message, case.name)
    assert(env.GoldWiseStorageProbeMarker == case.marker, "probe must leave the marker unchanged")
    print("PASS " .. case.name)
end
