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

local function client(version, build, interface)
    return function()
        return version, build, "test build date", interface
    end
end

local cases = {
    { name = "verified Forever build", getBuildInfo = client("1.60.1", "70862", 16001), supported = true },
    { name = "new build with same interface", getBuildInfo = client("1.60.1", "70863", 16001) },
    { name = "different version", getBuildInfo = client("1.60.2", "70862", 16001) },
    { name = "different interface", getBuildInfo = client("1.60.1", "70862", 16002) },
    { name = "missing interface", getBuildInfo = client("1.60.1", "70862") },
    { name = "unexpected build type", getBuildInfo = client("1.60.1", 70862, 16001) },
    { name = "missing API" },
    { name = "failing API", getBuildInfo = function() error("API unavailable") end },
}

for _, case in ipairs(cases) do
    local addon = {}
    local output = {}
    local buildReads = 0
    local env = {
        pcall = pcall,
        print = function(message) output[#output + 1] = message end,
    }
    if case.getBuildInfo then
        env.GetBuildInfo = function()
            buildReads = buildReads + 1
            return case.getBuildInfo()
        end
    end

    local chunk = assert(loadfile(assert(entry, "missing TOC entry")))
    setfenv(chunk, env)("GoldWise", addon)

    assert(addon.version == assert(version, "missing TOC version"), case.name)
    assert(addon.supportedClient == (case.supported == true), case.name)
    assert(addon.features.inventory == false, case.name)
    assert(addon.features.professions == false, case.name)
    assert(addon.features.auctionHouse == false, case.name)
    assert(buildReads == (case.getBuildInfo and 1 or 0), case.name)
    local status = case.supported and "loaded on Forever build 70862" or "client build unverified"
    assert(#output == 1 and output[1] == "GoldWise " .. version .. ": " .. status .. ". Gameplay features disabled.", case.name)
    print("PASS " .. case.name)
end
