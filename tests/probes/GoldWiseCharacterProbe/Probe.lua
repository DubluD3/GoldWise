local ok, version, build, _, interface = pcall(GetBuildInfo)
if not ok or version ~= "1.60.1" or build ~= "70862" or interface ~= 16001 then
    print("GoldWise character probe: client build unverified")
    return
end

if type(issecretvalue) ~= "function" then
    print("GoldWise character probe: secret-value guard unavailable")
    return
end

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

local function report(initialLogin, reloading)
    local entry
    if initialLogin then
        entry = "login"
    elseif reloading then
        entry = "reload"
    else
        print("GoldWise character probe: unexpected entry event")
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

local registered = type(EventUtil) == "table"
    and pcall(EventUtil.RegisterOnceFrameEventAndCallback, "PLAYER_ENTERING_WORLD", report)
if not registered then
    print("GoldWise character probe: entry event registration unavailable")
end
