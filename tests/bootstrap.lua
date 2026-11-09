local ForeverClient = dofile("tests/fixtures/ForeverClient.lua")

local version
local entry
local interface
for line in io.lines("GoldWise.toc") do
    if line:match("^## Version: ") then
        version = line:match("^## Version: (.+)$")
    elseif line:match("^## Interface: ") then
        interface = line:match("^## Interface: (.+)$")
    elseif line == "adapters\\Bootstrap.lua" then
        entry = line:gsub("\\", "/")
    end
end
assert(interface == "16001", "expected the interface observed on build 70862")

local cases = {
    { name = "verified Forever build", getBuildInfo = ForeverClient.build("1.60.1", "70862", 16001), supported = true },
    { name = "new build with same interface", getBuildInfo = ForeverClient.build("1.60.1", "70863", 16001) },
    { name = "different version", getBuildInfo = ForeverClient.build("1.60.2", "70862", 16001) },
    { name = "different interface", getBuildInfo = ForeverClient.build("1.60.1", "70862", 16002) },
    { name = "missing interface", getBuildInfo = ForeverClient.build("1.60.1", "70862") },
    { name = "unexpected build type", getBuildInfo = ForeverClient.build("1.60.1", 70862, 16001) },
    { name = "missing API" },
    { name = "failing API", getBuildInfo = function() error("API unavailable") end },
}

for _, case in ipairs(cases) do
    local addon = {}
    local client = ForeverClient.new(case.getBuildInfo)
    client:load(assert(entry, "missing TOC entry"), "GoldWise", addon)

    assert(addon.version == assert(version, "missing TOC version"), case.name)
    assert(addon.supportedClient == (case.supported == true), case.name)
    assert(addon.features.inventory == false, case.name)
    assert(addon.features.professions == false, case.name)
    assert(addon.features.auctionHouse == false, case.name)
    assert(client.buildReads == (case.getBuildInfo and 1 or 0), case.name)
    local status = case.supported and "loaded on Forever build 70862" or "client build unverified"
    local output = client.output
    assert(#output == 1 and output[1] == "GoldWise " .. version .. ": " .. status .. ". Gameplay features disabled.", case.name)
    print("PASS " .. case.name)
end
