local _, addon = ...
local prefix = "GoldWise profession: "

function GoldWiseProfessionScan()
    if addon.professionCompanion then addon.professionCompanion.invalidate() end
    addon.professionSnapshot = nil
    addon.recipeCatalog = nil
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
    addon.recipeCatalog = addon.recipeCatalogModel.fromSnapshot(addon.clientBuild, snapshot)
    addon.features.professions = snapshot.recipeStatus == "filtered"
    addon.professionCapture.report(prefix, snapshot)
    if addon.professionCompanion then addon.professionCompanion.show(snapshot) end
end
