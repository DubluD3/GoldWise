local ok, version, build, _, interface = pcall(GetBuildInfo)
local supportedBuild = ok and version == "1.60.1" and build == "70862" and interface == 16001

local function read(api, ...)
    local succeeded, value = pcall(api, ...)
    if succeeded then
        local checked, secret = pcall(issecretvalue, value)
        if checked and secret == false then
            return value
        end
    end
end

local function usableText(value)
    return type(value) == "string" and #value > 0 and #value <= 64
end

local function comparisonTag(value)
    if not usableText(value) then
        return "unavailable"
    end

    local tag = 0
    for index = 1, #value do
        tag = (tag * 33 + string.byte(value, index)) % 2147483647
    end
    return string.format("%08x", tag)
end

local function integerStatus(value)
    if type(value) == "number" and value >= 1 and value < 2 ^ 53 and value % 1 == 0 then
        return "ok"
    end
    return "unavailable"
end

local function report(entry)
    if not supportedBuild then
        print("GoldWise character probe: client build unverified")
        return
    end
    if type(issecretvalue) ~= "function" then
        print("GoldWise character probe: secret-value guard unavailable")
        return
    end

    local character = comparisonTag(read(UnitGUID, "player"))
    local realm = comparisonTag(read(GetRealmName))
    local faction = usableText(read(UnitFactionGroup, "player")) and "ok" or "unavailable"
    local region = integerStatus(read(GetCurrentRegion))
    local timestamp = integerStatus(read(GetServerTime))

    print("GoldWise character probe: entry=" .. entry .. " character=" .. character .. " realm=" .. realm
        .. " faction=" .. faction .. " region=" .. region .. " time=" .. timestamp)
end

function GoldWiseCharacterProbe_Run()
    report("manual")
end

print("GoldWise character probe v2 loaded. Manual check: /run GoldWiseCharacterProbe_Run()")
if not supportedBuild or type(issecretvalue) ~= "function" then
    report("load")
    return
end

local function onEnteringWorld(initialLogin, reloading)
    if initialLogin then
        report("login")
    elseif reloading then
        report("reload")
    else
        print("GoldWise character probe: unexpected entry event")
    end
end

local registered = type(EventUtil) == "table"
    and pcall(EventUtil.RegisterOnceFrameEventAndCallback, "PLAYER_ENTERING_WORLD", onEnteringWorld)
if not registered then
    print("GoldWise character probe: entry event registration unavailable")
end
