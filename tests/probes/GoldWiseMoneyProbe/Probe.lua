local prefix = "GoldWise money probe: "

local function readInteger(api, minimum)
    local ok, value = pcall(api)
    if not ok then
        return nil
    end
    local checked, secret = pcall(issecretvalue, value)
    if checked and secret == false and type(value) == "number"
        and value >= minimum and value < 2 ^ 53 and value % 1 == 0 then
        return value
    end
end

function GoldWiseMoneyProbe_Run()
    local ok, version, build, _, interface = pcall(GetBuildInfo)
    if not ok or version ~= "1.60.1" or build ~= "70862" or interface ~= 16001 then
        print(prefix .. "client build unverified")
        return
    end
    if type(issecretvalue) ~= "function" then
        print(prefix .. "secret-value guard unavailable")
        return
    end

    local balance = readInteger(GetMoney, 0)
    if balance == nil then
        print(prefix .. "balance unavailable")
        return
    end
    if not readInteger(GetServerTime, 1) then
        print(prefix .. "timestamp unavailable")
        return
    end
    print(prefix .. string.format("balance=%.0f copper, timestamp readable", balance))
end
