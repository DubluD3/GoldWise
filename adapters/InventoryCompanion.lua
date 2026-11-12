local _, addon = ...
-- Experimental, opt-in companion for a visible ordinary bag frame.
-- Exact Forever ContainerFrame1 support and geometry are NOT live-verified.
-- No automatic scans, hooks, secure UI overrides, or item actions.
local companion
local lastSnapshot
local Companion = {}

local function readable(value)
    if type(issecretvalue) ~= "function" then return false end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret == false
end

local function allowedFrame()
    if not addon.supportedClient or type(CreateFrameWithOptions) ~= "function" then return end
    local ok, frame = pcall(function() return ContainerFrame1 end)
    if not ok or not frame or not readable(frame) then return end
    local shownOk, shown = pcall(function() return frame:IsVisible() end)
    if not shownOk or shown ~= true or not readable(shown) then return end
    return frame
end

local chrome = addon.companionChrome

local function create(frame)
    if not chrome.placement(frame, 260, 222, "left") then return end
    local toggle = chrome.button(frame, "GoldWise Bags", 110, 8, -34, function()
        if companion.panel:IsShown() then
            companion.panel:Hide()
        elseif Companion.refresh() then
            companion.panel:Show()
        end
    end)
    local panel = chrome.panel(frame, 260, 222, "left")
    if not panel then return end
    local heading = chrome.label(panel, "GameFontNormal", "gold")
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -10)
    heading:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -12, -34)
    heading:SetText("GoldWise | Carried Bags")
    local details = chrome.label(panel, "GameFontNormalSmall", "text")
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -42)
    details:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 65)
    local open = chrome.button(panel, "Inventory", 112, 10, -184, function()
        if type(GoldWiseOpen) == "function" then GoldWiseOpen("inventory") end
    end)
    local close = chrome.button(panel, "Hide", 82, 166, -184, function() panel:Hide() end)
    return { frame = frame, toggle = toggle, panel = panel, details = details, open = open, close = close }
end

local function current(snapshot)
    return addon.supportedClient and type(snapshot) == "table"
        and addon.inventorySnapshot == snapshot
        and type(addon.characterSnapshot) == "table"
        and snapshot.characterScope == addon.characterSnapshot.scopeKey
end

function Companion.invalidate()
    lastSnapshot = nil
    if companion then companion.panel:Hide() end
end

function Companion.refresh()
    if not companion or not lastSnapshot or not current(lastSnapshot) then
        if companion then companion.panel:Hide() end
        return false
    end
    if not chrome.position(companion.panel, companion.frame, 260, 222, "left") then
        companion.panel:Hide()
        return false
    end
    if allowedFrame() ~= companion.frame or type(GetServerTime) ~= "function" then
        companion.panel:Hide()
        return false
    end
    local ok, now = pcall(GetServerTime)
    if not ok or not readable(now) then
        companion.panel:Hide()
        return false
    end
    local summary = addon.inventoryCompanionSummary.evaluate(
        lastSnapshot, addon.characterSnapshot, now)
    if not summary then
        companion.panel:Hide()
        return false
    end
    local written = pcall(function() companion.details:SetText(summary) end)
    if not written then companion.panel:Hide() end
    return written
end

function Companion.show(snapshot)
    if not current(snapshot) then return false end
    local frame = allowedFrame()
    if not frame then return false end
    if companion and companion.frame ~= frame then
        companion.panel:Hide()
        companion = nil
    end
    if not companion then
        local ok, created = pcall(create, frame)
        if not ok or not created then return false end
        companion = created
    end
    lastSnapshot = snapshot
    return Companion.refresh()
end

addon.inventoryCompanion = Companion
