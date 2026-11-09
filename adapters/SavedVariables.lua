local addonName, addon = ...

if not addon.supportedClient then
    return
end

local function openSavedVariables()
    local state, status = addon.storage.open(GoldWiseDB)
    if not state then
        print("GoldWise local storage disabled (" .. status .. ").")
        return
    end

    GoldWiseDB = state
    addon.storageState = state
    print("GoldWise local storage " .. status .. " (schema " .. state.schemaVersion .. ").")
end

local registered = type(EventUtil) == "table"
    and pcall(EventUtil.RegisterOnceFrameEventAndCallback, "ADDON_LOADED", openSavedVariables, addonName)
if not registered then
    print("GoldWise local storage disabled (ADDON_LOADED registration unavailable).")
end
