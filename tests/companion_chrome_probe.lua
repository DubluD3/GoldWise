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
g.CreateFrameWithOptions = function(spec)
    assert(spec.frameType == "Frame" or spec.frameType == "Button")
    return node(spec.frameType, spec.hidden)
end
client:load("ui/CompanionChrome.lua", "GoldWise", addon)
local chrome = assert(addon.companionChrome)
local native = node("native")
local hits = 0
local btn = chrome.button(native, "Test Companion", 120, 4, -7, function() hits = hits + 1 end)
assert(btn.label.value == "Test Companion" and btn.width == 120 and btn.height == 26)
assert(btn.label.justify == "CENTER" and btn.label.textColor[1] == 0.91)
assert(btn.point[1] == "TOPLEFT" and btn.point[2] == native)
btn.click()
assert(hits == 1)
local panel = chrome.panel(native, 280, 200, "TOPLEFT", "TOPRIGHT", 8, -20)
assert(panel.shown == false and panel.width == 280 and panel.height == 200)
assert(panel.point[2] == native and panel.point[3] == "TOPRIGHT")
assert(panel.point[4] == 8 and panel.point[5] == -20)
local label = chrome.label(panel, "GameFontNormalSmall", "text")
assert(label.textColor[1] == 0.92 and label.wrap)
local panelTexture = chrome.fill(panel, "panel")
assert(panelTexture.color[1] == 0.09 and panelTexture.color[4] == 0.97)
local buttonTexture = chrome.fill(btn, "button")
assert(buttonTexture.color[1] == 0.22 and buttonTexture.color[4] == 1)
print("PASS shared companion chrome uses uniform visual roles and no implicit game actions")
