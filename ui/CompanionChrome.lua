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

-- All measurements must be in comparable UIParent coordinate space. Do
-- not guess a position from screen pixels if a native frame is scaled or
-- unreadable: the standalone dashboard is always the fallback.
local function finite(value)
    return type(value) == "number" and value == value
        and value > -1000000 and value < 1000000
end

function Chrome.placement(parent, width, height, preferred)
    if not finite(width) or not finite(height) or width < 1 or height < 1
        or (preferred ~= "left" and preferred ~= "right")
        or not UIParent then return end
    local ok, screenWidth, screenHeight, left, right, top, bottom = pcall(function()
        return UIParent:GetWidth(), UIParent:GetHeight(), parent:GetLeft(),
            parent:GetRight(), parent:GetTop(), parent:GetBottom()
    end)
    if not ok or not finite(screenWidth) or not finite(screenHeight)
        or not finite(left) or not finite(right) or not finite(top)
        or not finite(bottom) or screenWidth < 1 or screenHeight < 1
        or left < 0 or right > screenWidth or left >= right
        or bottom < 0 or top > screenHeight or bottom >= top
        or height + 16 > screenHeight then return end
    -- Reject mismatched effective scales rather than position in the wrong
    -- coordinate system. A missing scale API is also not evidence.
    local scales, parentScale, screenScale = pcall(function()
        return parent:GetEffectiveScale(), UIParent:GetEffectiveScale()
    end)
    if not scales or not finite(parentScale) or not finite(screenScale)
        or parentScale <= 0 or screenScale <= 0
        or math.abs(parentScale - screenScale) > 0.0001 then return end
    local margin, gap = 8, 8
    local rightFits = right + gap + width + margin <= screenWidth
    local leftFits = left - gap - width >= margin
    local side = preferred
    if side == "right" and not rightFits then side = "left" end
    if side == "left" and not leftFits then side = "right" end
    if (side == "right" and not rightFits) or (side == "left" and not leftFits) then return end
    local targetTop = math.max(height + margin, math.min(top - 38, screenHeight - margin))
    return side == "right" and "TOPLEFT" or "TOPRIGHT",
        side == "right" and "TOPRIGHT" or "TOPLEFT",
        side == "right" and gap or -gap, targetTop - top
end

function Chrome.position(panel, parent, width, height, preferred)
    local point, relative, x, y = Chrome.placement(parent, width, height, preferred)
    if not point then return false end
    local ok = pcall(function()
        panel:ClearAllPoints()
        panel:SetPoint(point, parent, relative, x, y)
    end)
    return ok
end

-- Parent the panel to the native window without moving Blizzard's frame.
-- Fail closed if no side has sufficient unoccluded screen space.
function Chrome.panel(parent, width, height, preferred)
    if not Chrome.placement(parent, width, height, preferred) then return end
    local panel = CreateFrameWithOptions({ frameType = "Frame", parent = parent, hidden = true })
    panel:SetSize(width, height)
    if not Chrome.position(panel, parent, width, height, preferred) then
        panel:Hide()
        return
    end
    Chrome.fill(panel, "panel")
    return panel
end

addon.companionChrome = Chrome
return Chrome
