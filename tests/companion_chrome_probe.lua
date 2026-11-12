local Fixture = dofile("tests/fixtures/ForeverClient.lua")
local client = Fixture.new()
local g = client.globals
local addon = {}
local created = {}
local function node(kind, hidden)
    local obj = { kind = kind, shown = not hidden }
    function obj:SetText(value) self.value = value end
    function obj:SetTextColor(...) self.textColor = { ... } end
    function obj:SetColorTexture(...) self.color = { ... } end
    function obj:SetJustifyH(value) self.justify = value end
    function obj:SetJustifyV() end
    function obj:SetWordWrap(value) self.wrap = value end
    function obj:SetAllPoints() end
    function obj:SetSize(w, h) self.width, self.height = w, h end
    function obj:SetPoint(...) self.point = { ... } end
    function obj:ClearAllPoints() self.point = nil end
    function obj:GetWidth() return self.width end
    function obj:GetHeight() return self.height end
    function obj:GetLeft() return self.left end
    function obj:GetRight() return self.right end
    function obj:GetTop() return self.top end
    function obj:GetBottom() return self.bottom end
    function obj:GetEffectiveScale() return self.scale or 1 end
    function obj:SetScript(event, callback)
        assert(event == "OnClick")
        self.click = callback
    end
    function obj:CreateTexture() return node("texture") end
    function obj:CreateFontString() return node("font") end
    function obj:Hide() self.shown = false end
    function obj:Show() self.shown = true end
    function obj:IsShown() return self.shown end
    created[#created + 1] = obj
    return obj
end
g.unpack = unpack
g.math = math
g.pcall = pcall
g.UIParent = node("screen")
g.UIParent:SetSize(1280, 720)
g.CreateFrameWithOptions = function(spec)
    assert(spec.frameType == "Frame" or spec.frameType == "Button")
    return node(spec.frameType, spec.hidden)
end
client:load("ui/CompanionChrome.lua", "GoldWise", addon)
local chrome = assert(addon.companionChrome)
local native = node("native")
native.left, native.right, native.top, native.bottom = 200, 640, 600, 120
local hits = 0
local btn = chrome.button(native, "Test Companion", 120, 4, -7, function() hits = hits + 1 end)
assert(btn.label.value == "Test Companion" and btn.width == 120 and btn.height == 26)
assert(btn.label.justify == "CENTER" and btn.label.textColor[1] == 0.91)
assert(btn.point[1] == "TOPLEFT" and btn.point[2] == native)
btn.click()
assert(hits == 1)
local panel = chrome.panel(native, 280, 200, "right")
assert(panel.shown == false and panel.width == 280 and panel.height == 200)
assert(panel.point[2] == native and panel.point[3] == "TOPRIGHT")
assert(panel.point[4] == 8 and panel.point[5] == -38)
assert(chrome.position(panel, native, 280, 200, "right"))
assert(panel.point[1] == "TOPLEFT")
native.left, native.right = 800, 1220
assert(chrome.position(panel, native, 280, 200, "right"))
assert(panel.point[1] == "TOPRIGHT" and panel.point[3] == "TOPLEFT")
native.left, native.right = 490, 790
g.UIParent:SetSize(900, 720)
assert(not chrome.placement(native, 460, 200, "right"))
assert(not chrome.position(panel, native, 460, 200, "right"))
g.UIParent:SetSize(1280, 720)
native.scale = 1.25
assert(not chrome.placement(native, 280, 200, "right"))
native.scale = 1
native.top, native.bottom = 300, 50
assert(chrome.position(panel, native, 280, 200, "right"))
assert(panel.point[5] == -92)
native.top, native.bottom = 600, 120
local label = chrome.label(panel, "GameFontNormalSmall", "text")
assert(label.textColor[1] == 0.92 and label.wrap)
local panelTexture = chrome.fill(panel, "panel")
assert(panelTexture.color[1] == 0.09 and panelTexture.color[4] == 0.97)
local buttonTexture = chrome.fill(btn, "button")
assert(buttonTexture.color[1] == 0.22 and buttonTexture.color[4] == 1)
print("PASS shared companion chrome uses uniform visual roles and no implicit game actions")
