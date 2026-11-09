local _, addon = ...
local ok, version, build, _, interface = pcall(GetBuildInfo)
local supportedBuild = ok and version == "1.60.1" and build == "70862" and interface == 16001
local run = addon.auctionCapture.new("GoldWise Auction probe: ")

function GoldWiseAuctionProbe_Run()
    run(supportedBuild, "probe-session")
end

print("GoldWise Auction probe loaded. Run /run GoldWiseAuctionProbe_Run() in the Auction House browse view.")
