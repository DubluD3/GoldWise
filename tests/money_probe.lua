local Fixture = assert(loadfile("tests/fixtures/ForeverClient.lua"))()
local manifest = "tests/probes/GoldWiseMoneyProbe/GoldWiseMoneyProbe.toc"
local verified = Fixture.build("1.60.1", "70862", 16001)

local function load(readBuild)
    local client = Fixture.new(readBuild, "missing")
    local globals = client.globals
    local reads = { balance = 0, time = 0 }
    globals.GetMoney = function()
        reads.balance = reads.balance + 1
        return 12345
    end
    globals.GetServerTime = function()
        reads.time = reads.time + 1
        return 100
    end
    globals.issecretvalue = function() return false end
    client:loadToc(manifest, "GoldWiseMoneyProbe", {})
    assert(reads.balance == 0 and reads.time == 0 and client.buildReads == 0 and #client.output == 0)
    return client, globals, reads
end

local client, globals, reads = load(verified)
globals.GoldWiseMoneyProbe_Run()
assert(reads.balance == 1 and reads.time == 1 and client.buildReads == 1)
assert(client.output[1] == "GoldWise money probe: balance=12345 copper, timestamp readable")
globals.GetMoney = function() return 0 end
globals.GoldWiseMoneyProbe_Run()
assert(client.output[2]:find("balance=0 copper", 1, true))
print("PASS the disposable manifest reads once on request and accepts zero copper")

client, globals, reads = load(Fixture.build("1.60.1", "70863", 16001))
globals.GoldWiseMoneyProbe_Run()
assert(reads.balance == 0 and reads.time == 0 and client.output[1]:find("client build unverified", 1, true))
client, globals, reads = load(verified)
globals.issecretvalue = nil
globals.GoldWiseMoneyProbe_Run()
assert(reads.balance == 0 and reads.time == 0 and client.output[1]:find("guard unavailable", 1, true))
print("PASS the disposable probe skips money reads on an unsupported build or missing guard")

client, globals, reads = load(verified)
globals.issecretvalue = function(value) return value == 12345 end
globals.GoldWiseMoneyProbe_Run()
assert(reads.balance == 1 and reads.time == 0 and client.output[1]:find("balance unavailable", 1, true))
globals.issecretvalue = function() error("fixture guard failure") end
globals.GoldWiseMoneyProbe_Run()
assert(client.output[2]:find("balance unavailable", 1, true))
globals.issecretvalue = function() return false end
for _, value in ipairs({ -1, 1.5, "0", 2 ^ 53 }) do
    globals.GetMoney = function() return value end
    globals.GoldWiseMoneyProbe_Run()
    assert(client.output[#client.output]:find("balance unavailable", 1, true))
end
globals.GetMoney = nil
globals.GoldWiseMoneyProbe_Run()
assert(client.output[#client.output]:find("balance unavailable", 1, true) and reads.time == 0)
print("PASS restricted, invalid and missing balance reads produce no amount")

client, globals, reads = load(verified)
globals.GetServerTime = function() return nil end
globals.GoldWiseMoneyProbe_Run()
assert(reads.balance == 1 and client.output[1] == "GoldWise money probe: timestamp unavailable")
print("PASS a missing timestamp suppresses the reported balance")
