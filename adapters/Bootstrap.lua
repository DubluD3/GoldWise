local _, addon = ...

addon.version = "0.1.6-dev"
addon.features = {
    inventory = false,
    professions = false,
    auctionHouse = false,
}

local ok, clientVersion, build, _, interface = pcall(GetBuildInfo)
-- API-001 covers this build. A patch may change behavior without changing the interface number.
addon.supportedClient = ok and clientVersion == "1.60.1" and build == "70862" and interface == 16001

local status = "client build unverified"
if addon.supportedClient then
    addon.clientBuild = build
    status = "loaded on Forever build " .. build
end

print("GoldWise " .. addon.version .. ": " .. status .. ".")
