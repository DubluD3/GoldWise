local addonName = ...
local ok, version, build, _, interface = pcall(GetBuildInfo)
if not ok or version ~= "1.60.1" or build ~= "70862" or interface ~= 16001 then
    print("GoldWise storage probe: client build unverified")
    return
end

local function reportMarker()
    if GoldWiseStorageProbeMarker == "gw005" then
        print("GoldWise storage probe: marker present at ADDON_LOADED")
    else
        print("GoldWise storage probe: marker missing at ADDON_LOADED")
    end
end

local registered = type(EventUtil) == "table"
    and pcall(EventUtil.RegisterOnceFrameEventAndCallback, "ADDON_LOADED", reportMarker, addonName)
if not registered then
    print("GoldWise storage probe: ADDON_LOADED registration unavailable")
end
