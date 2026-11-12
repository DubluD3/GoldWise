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

local function label(parent, style, r, g, b)
    local text = parent:CreateFontString(nil, "OVERLAY", style)
    text:SetTextColor(r, g, b)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    return text
end

local function control(parent, caption, width, x, y, onClick)
    local button = CreateFrameWithOptions({ frameType = "Button", parent = parent })
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(button)
    background:SetColorTexture(0.22, 0.26, 0.32, 1)
    local title = label(button, "GameFontNormalSmall", 0.91, 0.77, 0.37)
    title:SetAllPoints(button)
    title:SetJustifyH("CENTER")
    title:SetText(caption)
    button:SetScript("OnClick", onClick)
    return button
end

local function create(frame)
    local tab = control(frame, "GoldWise", 90, -98, -36, function()
        attached.panel:SetShown(not attached.panel:IsShown())
    end)
    -- Position relative to the native window. Never reparent, move or resize
    -- Blizzard's protected frames. Users may hide this optional companion.
    local panel = CreateFrameWithOptions({ frameType = "Frame", parent = frame, hidden = true })
    panel:SetSize(244, 176)
    panel:SetPoint("TOPLEFT", frame, "TOPRIGHT", 8, -38)
    local backing = panel:CreateTexture(nil, "BACKGROUND")
    backing:SetAllPoints(panel)
    backing:SetColorTexture(0.09, 0.12, 0.17, 0.97)
    local header = label(panel, "GameFontNormal", 0.91, 0.77, 0.37)
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
    header:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -8, -36)
    header:SetText("GoldWise | Profession")
    local details = label(panel, "GameFontNormalSmall", 0.92, 0.92, 0.90)
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -46)
    details:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 65)
    details:SetWordWrap(true)
    local open = control(panel, "Open GoldWise", 126, 10, -140, function()
        if type(GoldWiseOpen) == "function" then GoldWiseOpen("profession") end
    end)
    local close = control(panel, "Hide", 82, 150, -140, function() panel:Hide() end)
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
    local count = type(snapshot.knownRecipes) == "table" and #snapshot.knownRecipes or 0
    local text = string.format("%s  |  %.0f / %.0f skill\n%.0f learned recipes in the scanned view.\nSnapshot only; rescan after changes.",
        snapshot.professionName, snapshot.skill, snapshot.cap, count)
    local ok = pcall(function() attached.details:SetText(text) end)
    return ok
end

function Companion.isCurrent()
    return lastSnapshot ~= nil and current(lastSnapshot) or false
end

addon.professionCompanion = Companion
