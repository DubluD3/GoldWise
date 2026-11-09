local _, addon = ...

local run = addon.auctionCapture.new("GoldWise Auction: ", function(observation)
    addon.auctionObservation = observation
    addon.features.auctionHouse = observation.status == "complete"
end)

function GoldWiseAuctionObserve()
    local character = addon.characterSnapshot
    run(addon.supportedClient, character and character.scopeKey)
end
