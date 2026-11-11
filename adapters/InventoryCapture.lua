local _, addon = ...

function GoldWiseInventoryScan()
    addon.inventorySnapshot = nil
    addon.features.inventory = false
    if not addon.supportedClient then
        print("GoldWise inventory: client build unverified.")
        return
    end
    if not addon.characterSnapshot then
        print("GoldWise inventory: character snapshot unavailable.")
        return
    end

    local snapshot, labelsOrReason = addon.bagCapture.capture(addon.characterSnapshot.scopeKey)
    if not snapshot then
        print("GoldWise inventory: " .. labelsOrReason .. ".")
        return
    end

    if snapshot.status ~= "unavailable" then
        snapshot.labels = labelsOrReason
        addon.inventorySnapshot = snapshot
    end
    addon.features.inventory = snapshot.status == "complete"
    addon.bagCapture.report("GoldWise inventory", snapshot, labelsOrReason)
end
