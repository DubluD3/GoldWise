local _, addon = ...
local prefix = "GoldWise profession: "

function GoldWiseProfessionScan()
    addon.professionSnapshot = nil
    addon.features.professions = false
    if not addon.supportedClient then
        print(prefix .. "client build unverified.")
        return
    end
    if not addon.characterSnapshot then
        print(prefix .. "character snapshot unavailable.")
        return
    end

    local snapshot, reason = addon.professionCapture.capture(addon.characterSnapshot.scopeKey)
    if not snapshot then
        print(prefix .. reason .. ".")
        return
    end

    addon.professionSnapshot = snapshot
    addon.features.professions = snapshot.recipeStatus == "filtered"
    addon.professionCapture.report(prefix, snapshot)
end
