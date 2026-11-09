local _, addon = ...
local ok, version, build, _, interface = pcall(GetBuildInfo)
local supportedBuild = ok and version == "1.60.1" and build == "70862" and interface == 16001
local prefix = "GoldWise profession probe: "

function GoldWiseProfessionProbe_Run()
    if not supportedBuild then
        print(prefix .. "client build unverified.")
        return
    end

    local snapshot, reason = addon.professionCapture.capture("probe-session")
    if not snapshot then
        print(prefix .. reason .. ".")
        return
    end
    addon.professionCapture.report(prefix, snapshot)
end

print("GoldWise profession probe loaded. Run /run GoldWiseProfessionProbe_Run() after login.")
