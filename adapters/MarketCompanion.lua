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

local function label(parent, style, color)
    local obj = parent:CreateFontString(nil, "OVERLAY", style)
    if color == "gold" then
        obj:SetTextColor(0.91, 0.77, 0.37)
    else
        obj:SetTextColor(0.92, 0.92, 0.90)
    end
    obj:SetJustifyH("LEFT")
    obj:SetJustifyV("MIDDLE")
    obj:SetWordWrap(true)
    return obj
end

local function button(parent, text, width, x, y, action)
    local control = CreateFrameWithOptions({ frameType = "Button", parent = parent })
    control:SetSize(width, 26)
    control:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local background = control:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(control)
    background:SetColorTexture(0.22, 0.26, 0.32, 1)
    local caption = label(control, "GameFontNormalSmall", "gold")
    caption:SetAllPoints(control)
    caption:SetJustifyH("CENTER")
    caption:SetText(text)
    control.label = caption
    control:SetScript("OnClick", action)
    return control
end

local function create(frame)
    local toggle = button(frame, "GoldWise Market", 124, 10, -38, function()
        if attached.panel:IsShown() then
            attached.panel:Hide()
        elseif Companion.refresh() then
            attached.panel:Show()
        end
    end)
    local panel = CreateFrameWithOptions({ frameType = "Frame", parent = frame, hidden = true })
    panel:SetSize(296, 250)
    panel:SetPoint("TOPLEFT", frame, "TOPRIGHT", 8, -38)
    local texture = panel:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(panel)
    texture:SetColorTexture(0.09, 0.12, 0.17, 0.97)
    local header = label(panel, "GameFontNormal", "gold")
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
    header:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -12, -38)
    header:SetText("GoldWise | Market Observation")
    local details = label(panel, "GameFontNormalSmall")
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -48)
    details:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 65)
    button(panel, "Market details", 134, 10, -214, function()
        if type(GoldWiseOpen) == "function" then GoldWiseOpen("market") end
    end)
    button(panel, "Hide", 82, 202, -214, function() panel:Hide() end)
    return { frame = frame, panel = panel, details = details }
end

local function current(snapshot)
    local character = addon.characterSnapshot
    return addon.supportedClient and type(snapshot) == "table"
        and addon.auctionObservation == snapshot and type(character) == "table"
        and snapshot.characterScope == character.scopeKey
end

function Companion.invalidate()
    lastObservation = nil
    if attached then attached.panel:Hide() end
end

function Companion.refresh()
    if not attached or not lastObservation or not current(lastObservation) then
        if attached then attached.panel:Hide() end
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
        attached = nil
    end
    if not attached then
        local ok, created = pcall(create, frame)
        if not ok then return false end
        attached = created
    end
    lastObservation = snapshot
    return Companion.refresh()
end

addon.marketCompanion = Companion
