local _, addon = ...
local prefix = "GoldWise trainer: "

local function scope()
    if addon.clientBuild == "70888" and addon.characterSnapshot then
        return addon.characterSnapshot.scopeKey
    end
    print(prefix .. "trainer observation unavailable for this client or character.")
end

function GoldWiseTrainerSample()
    local character = scope()
    if character then
        addon.trainerCapture.sample(prefix, character)
    end
end

function GoldWiseTrainerMatch()
    local character = scope()
    if character then
        addon.trainerRequirement = addon.trainerCapture.match(prefix, character)
    end
end
