local _, addon = ...
-- Experimental companion for the already-visible native Auction House.
-- Created only after the player explicitly finishes GoldWise's two-stage
-- native browse observation. Never starts a search, sale or purchase.
local attached
local lastObservation
local Companion = {}

local function readable(value)
    if type(issecretvalue) ~= "function" then return false end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret == false
end

local function allowedFrame()
    if not addon.supportedClient or type(CreateFrameWithOptions) ~= "function" then return end
    local ok, frame = pcall(function() return AuctionHouseFrame end)
    if not ok or not frame or not readable(frame) then return end
    local visible, shown = pcall(function() return frame:IsVisible() end)
    if not visible or shown ~= true or not readable(shown) then return end
    local browse, browseShown = pcall(function()
        return frame.BrowseResultsFrame and frame.BrowseResultsFrame:IsVisible()
    end)
    if not browse or browseShown ~= true or not readable(browseShown) then return end
    return frame
end

local chrome = addon.companionChrome

local function create(frame)
    if not chrome.placement(frame, 296, 250, "right") then return end
    local panel = chrome.panel(frame, 296, 250, "right")
    if not panel then return end
    local header = chrome.label(panel, "GameFontNormal", "gold")
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
    header:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -12, -38)
    header:SetText("GoldWise | Market Observation")
    local details = chrome.label(panel, "GameFontNormalSmall")
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -48)
    details:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 65)
    chrome.button(panel, "Market details", 134, 10, -214, function()
        if type(GoldWiseOpen) == "function" then GoldWiseOpen("market") end
    end)
    chrome.button(panel, "Hide", 82, 202, -214, function() panel:Hide() end)
    local toggle = chrome.button(frame, "GoldWise Market", 124, 10, -38, function()
        if attached.panel:IsShown() then
            attached.panel:Hide()
        elseif Companion.refresh() then
            attached.panel:Show()
        end
    end)
    return { frame = frame, toggle = toggle, panel = panel, details = details }
end

local function current(snapshot)
    local character = addon.characterSnapshot
    return addon.supportedClient and type(snapshot) == "table"
        and addon.auctionObservation == snapshot and type(character) == "table"
        and snapshot.characterScope == character.scopeKey
end

function Companion.invalidate()
    if attached and attached.toggle then attached.toggle:Hide() end
    lastObservation = nil
    if attached then attached.panel:Hide() end
end

function Companion.refresh()
    if not attached or not lastObservation or not current(lastObservation) then
        if attached then attached.panel:Hide() end
        return false
    end
    if not chrome.position(attached.panel, attached.frame, 296, 250, "right") then
        attached.panel:Hide()
        return false
    end
    if allowedFrame() ~= attached.frame or type(GetServerTime) ~= "function" then
        attached.panel:Hide()
        return false
    end
    local ok, timestamp = pcall(GetServerTime)
    if not ok or not readable(timestamp) then
        attached.panel:Hide()
        return false
    end
    local summary = addon.marketCompanionSummary.evaluate(
        lastObservation, addon.characterSnapshot, timestamp)
    if not summary then
        attached.panel:Hide()
        return false
    end
    local rendered = pcall(function() attached.details:SetText(summary) end)
    if not rendered then attached.panel:Hide() end
    return rendered
end

function Companion.show(snapshot)
    if not current(snapshot) then return false end
    local frame = allowedFrame()
    if not frame then return false end
    if attached and attached.frame ~= frame then
        attached.panel:Hide()
        if attached.toggle then attached.toggle:Hide() end
        attached = nil
    end
    if not attached then
        local ok, created = pcall(create, frame)
        if not ok or not created then return false end
        attached = created
    end
    if attached.toggle then attached.toggle:Show() end
    lastObservation = snapshot
    return Companion.refresh()
end

addon.marketCompanion = Companion
