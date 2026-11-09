local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")
local probe = "tests/probes/GoldWiseAuctionProbe/Probe.lua"
local update = "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED"
local closed = "AUCTION_HOUSE_CLOSED"
local failed = "AUCTION_HOUSE_BROWSE_FAILURE"

local function fixture(build, registration)
    local client = ForeverClient.new(ForeverClient.build("1.60.1", build or "70862", 16001), registration)
    local globals = client.globals
    local state = { visible = false, ready = true, now = 1794220000, reads = 0 }
    globals.issecretvalue = function(value) return value == "restricted fixture value" end
    globals.GetServerTime = function() return state.now end
    local function visible() return state.visible end
    globals.AuctionHouseFrame = { IsVisible = visible, BrowseResultsFrame = { IsVisible = visible } }
    globals.C_AuctionHouse = {
        IsThrottledMessageSystemReady = function() return state.ready end,
        HasFullBrowseResults = function() return true end,
        GetBrowseResults = function()
            state.reads = state.reads + 1
            return {
                { itemKey = { itemID = 100, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 },
                    minPrice = 12345, totalQuantity = 5 },
                { itemKey = { itemID = 101, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 },
                    minPrice = "restricted fixture value", totalQuantity = 1 },
            }
        end,
    }
    local addon = {}
    client:load("data/AuctionObservation.lua", "GoldWiseAuctionProbe", addon)
    client:load(probe, "GoldWiseAuctionProbe", addon)
    assert(#client.output == 1 and state.reads == 0)
    return client, state, globals.GoldWiseAuctionProbe_Run
end

local client, state, run = fixture()
run()
assert(client.output[#client.output]:match("browse window unavailable") and state.reads == 0)
state.visible = true
state.ready = false
run()
assert(client.output[#client.output]:match("ready=no") and not client:fire(update))
state.ready = nil
run()
assert(client.output[#client.output]:match("ready=unavailable") and not client:fire(update))
print("PASS closed, throttled, and unknown readiness cannot arm or read")

state.ready = true
run()
assert(client.output[#client.output]:match("armed, ready=yes"))
run()
assert(client.output[#client.output]:match("waiting for a browse update") and state.reads == 0)
assert(client:fire(update))
assert(client.output[#client.output]:match("browse update observed") and state.reads == 0)
state.ready = false
run()
assert(client.output[#client.output]:match("ready=no") and state.reads == 0)
state.ready = true
run()
assert(client.output[#client.output - 1]:match("cache=partial, rows=2, observed rows=1"))
assert(client.output[#client.output]:match("sample browse minimum=12345 copper, reported quantity=5"))
run()
assert(client.output[#client.output]:match("observation ended %(read%)") and state.reads == 1)
print("PASS observed update permits one manual read and suppresses a restricted price")

for _, event in ipairs({ closed, failed }) do
    local aborted, abortedState, abortRun = fixture()
    abortedState.visible = true
    abortRun()
    assert(aborted:fire(update) and aborted:fire(event))
    abortRun()
    assert(abortedState.reads == 0 and aborted.output[#aborted.output]:match("observation ended"))
end
print("PASS close and failure cancel before any cache read")

local expired, expiredState, expiryRun = fixture()
expiredState.visible = true
expiryRun()
assert(expired:fire(update))
expiredState.now = expiredState.now + 61
expiryRun()
assert(expiredState.reads == 0 and expired.output[#expired.output]:match("observation window expired"))
print("PASS an expired observation window prevents a stale read")

local unsupported, unsupportedState, unsupportedRun = fixture("70863")
unsupportedState.visible = true
unsupportedRun()
assert(unsupportedState.reads == 0 and unsupported.output[#unsupported.output]:match("client build unverified"))
local missing, missingState, missingRun = fixture(nil, "missing")
missingState.visible = true
missingRun()
assert(missingState.reads == 0 and missing.output[#missing.output]:match("browse event registration unavailable"))
print("PASS unsupported builds and missing event helper cannot read")
