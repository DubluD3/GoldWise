local _, addon = ...
local ok, version, build, _, interface = pcall(GetBuildInfo)
local supportedBuild = ok and version == "1.60.1" and build == "70862" and interface == 16001

function GoldWiseInventoryProbe_Run()
    if not supportedBuild then
        print("GoldWise inventory probe: client build unverified.")
        return
    end

    local snapshot, labelsOrReason = addon.bagCapture.capture("probe-session")
    if not snapshot then
        print("GoldWise inventory probe: " .. labelsOrReason .. ".")
        return
    end
    addon.bagCapture.report("GoldWise inventory probe", snapshot, labelsOrReason)
end

print("GoldWise inventory probe loaded. Run /run GoldWiseInventoryProbe_Run() after login.")
