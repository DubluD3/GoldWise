local _, addon = ...

local run = addon.auctionCapture.new("GoldWise Auction: ", function(observation)
    if addon.marketCompanion then addon.marketCompanion.invalidate() end
    addon.auctionObservation = observation
    addon.features.auctionHouse = observation.status == "complete"
    if addon.marketCompanion then addon.marketCompanion.show(observation) end
end)

function GoldWiseAuctionObserve()
    local character = addon.characterSnapshot
    run(addon.supportedClient, character and character.scopeKey)
end
