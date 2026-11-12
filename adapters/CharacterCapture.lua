local _, addon = ...

if not addon.supportedClient then
    return
end

local function read(api, ...)
    local ok, value = pcall(api, ...)
    if ok then
        local checked, secret = pcall(issecretvalue, value)
        if checked and secret == false then
            return value
        end
    end
end

local function capture(initialLogin, reloading)
    if not initialLogin and not reloading then
        return
    end
    -- Character context is about to be replaced; no previously rendered
    -- companion may claim observations from the preceding scope.
    for _, companion in ipairs({
        addon.professionCompanion, addon.inventoryCompanion, addon.marketCompanion,
    }) do
        if companion and companion.invalidate then companion.invalidate() end
    end
    if type(issecretvalue) ~= "function" then
        print("GoldWise character snapshot unavailable (secret-value guard unavailable).")
        return
    end

    local observation = {
        build = addon.clientBuild,
        characterId = read(UnitGUID, "player"),
        reportedRealm = read(GetRealmName),
        faction = read(UnitFactionGroup, "player"),
        region = read(GetCurrentRegion),
        observedAt = read(GetServerTime),
    }
    local snapshot, reason = addon.characterSnapshotModel.fromObservation(observation, addon.storage.scopeKey)
    addon.characterSnapshot = snapshot
    if snapshot then
        print("GoldWise character snapshot ready.")
    else
        print("GoldWise character snapshot unavailable (" .. reason .. ").")
    end
end

local registered = type(EventUtil) == "table"
    and pcall(EventUtil.RegisterOnceFrameEventAndCallback, "PLAYER_ENTERING_WORLD", capture)
if not registered then
    print("GoldWise character snapshot unavailable (entry event registration unavailable).")
end
