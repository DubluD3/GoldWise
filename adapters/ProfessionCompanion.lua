local _, addon = ...
-- Optional read-only companion attached to the already verified crafting frame.
-- No hooks, polling, protected overrides, or implicit game-data reads.
local attached
local lastSnapshot

local function allowedFrame()
    if not addon.supportedClient or type(issecretvalue) ~= "function"
        or type(CreateFrameWithOptions) ~= "function" then return end
    local ok, frame = pcall(function() return ProfessionsFrame end)
    if not ok or not frame then return end
    local checked, secret = pcall(issecretvalue, frame)
    if not checked or secret ~= false then return end
    local visible, shown = pcall(function()
        return frame.CraftingPage and frame.CraftingPage:IsVisible()
    end)
    if not visible or shown ~= true then return end
    return frame
end

local chrome = addon.companionChrome

local function create(frame)
    local tab = chrome.button(frame, "GoldWise", 90, 10, -36, function()
        if attached.panel:IsShown() then
            attached.panel:Hide()
        else
            -- Refresh only on a player click, never by polling the game.
            if not addon.professionCompanion.refresh() then return end
            attached.panel:Show()
        end
    end)
    -- Position relative to the native window. Never reparent, move or resize
    -- Blizzard's protected frames. Users may hide this optional companion.
    local panel = chrome.panel(frame, 288, 288, "TOPLEFT", "TOPRIGHT", 8, -38)
    local header = chrome.label(panel, "GameFontNormal", "gold")
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
    header:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -8, -36)
    header:SetText("GoldWise | Profession")
    local details = chrome.label(panel, "GameFontNormalSmall", "text")
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -46)
    details:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 65)
    details:SetWordWrap(true)
    local open = chrome.button(panel, "Open GoldWise", 126, 10, -252, function()
        if type(GoldWiseOpen) == "function" then GoldWiseOpen("profession") end
    end)
    local close = chrome.button(panel, "Hide", 82, 194, -252, function() panel:Hide() end)
    return { frame = frame, tab = tab, panel = panel, details = details, open = open, close = close }
end

local function current(snapshot)
    local character = addon.characterSnapshot
    return snapshot and addon.supportedClient and character
        and addon.professionSnapshot == snapshot
        and snapshot.characterScope == character.scopeKey
end

local Companion = {}
function Companion.invalidate()
    lastSnapshot = nil
    if attached then attached.panel:Hide() end
end

function Companion.show(snapshot)
    if not current(snapshot) then return false end
    local frame = allowedFrame()
    if not frame then return false end
    if attached and attached.frame ~= frame then attached = nil end
    if not attached then
        local ok, created = pcall(create, frame)
        if not ok then return false end
        attached = created
    end
    lastSnapshot = snapshot
    -- A newly scanned profession remains accessible even if another source
    -- is unknown; a plan is displayed only when all snapshots agree.
    return Companion.refresh()
end

function Companion.refresh()
    if not attached or not lastSnapshot or not current(lastSnapshot) then
        if attached then attached.panel:Hide() end
        return false
    end
    if allowedFrame() ~= attached.frame then
        attached.panel:Hide()
        return false
    end
    if type(GetServerTime) ~= "function" or type(issecretvalue) ~= "function" then
        attached.panel:Hide()
        return false
    end
    local okTime, time = pcall(GetServerTime)
    local guardOk, secret = pcall(issecretvalue, time)
    if not okTime or not guardOk or secret ~= false then
        attached.panel:Hide()
        return false
    end
    local text = addon.professionCompanionSummary.evaluate(lastSnapshot,
        addon.inventorySnapshot, addon.recipePlan, addon.characterSnapshot,
        addon.clientBuild, time)
    if not text then
        attached.panel:Hide()
        return false
    end
    local ok = pcall(function() attached.details:SetText(text) end)
    return ok
end

function Companion.isCurrent()
    return lastSnapshot ~= nil and current(lastSnapshot) or false
end

addon.professionCompanion = Companion
