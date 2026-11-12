local _, addon = ...
-- Reusable, deliberately small visual primitives for the three passive
-- companions. No native frame mutation, game-data reads, or UI hooks.
local Chrome = {}
local palette = {
    gold = { 0.91, 0.77, 0.37 },
    text = { 0.92, 0.92, 0.90 },
    button = { 0.22, 0.26, 0.32, 1 },
    panel = { 0.09, 0.12, 0.17, 0.97 },
}

function Chrome.label(parent, style, kind)
    local color = kind == "gold" and palette.gold or palette.text
    local label = parent:CreateFontString(nil, "OVERLAY", style)
    label:SetTextColor(unpack(color))
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(true)
    return label
end

function Chrome.fill(parent, kind)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(parent)
    texture:SetColorTexture(unpack(kind == "panel" and palette.panel or palette.button))
    return texture
end

function Chrome.button(parent, caption, width, x, y, callback)
    local button = CreateFrameWithOptions({ frameType = "Button", parent = parent })
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    Chrome.fill(button, "button")
    button.label = Chrome.label(button, "GameFontNormalSmall", "gold")
    button.label:SetAllPoints(button)
    button.label:SetJustifyH("CENTER")
    button.label:SetText(caption)
    button:SetScript("OnClick", callback)
    return button
end

-- Pass the native parent, not UIParent, so the companion cannot outlive the
-- visibility of its owning interface. Positioning remains a live QA gate.
function Chrome.panel(parent, width, height, point, relativePoint, x, y)
    local panel = CreateFrameWithOptions({ frameType = "Frame", parent = parent, hidden = true })
    panel:SetSize(width, height)
    panel:SetPoint(point, parent, relativePoint, x, y)
    Chrome.fill(panel, "panel")
    return panel
end

addon.companionChrome = Chrome
return Chrome
