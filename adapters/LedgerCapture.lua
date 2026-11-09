local _, addon = ...
local prefix = "GoldWise ledger: "
local MAX_SAMPLE_INTERVAL = 300
local ledger

local sampleMessages = {
    baseline = "baseline recorded.",
    unchanged = "balance unchanged.",
    ["stale-baseline"] = "previous baseline expired. New baseline recorded.",
    ["out-of-order"] = "sample time did not advance. Try again after one second.",
    unavailable = "balance or timestamp unavailable.",
}

local categoryMessages = {
    ["invalid-category"] = "use sale, purchase, other, or unclassified.",
    ["category-direction-mismatch"] = "category does not match the direction of the change.",
    ["entry-unavailable"] = "entry unavailable in this session.",
}

local function currentScope()
    if not addon.supportedClient then
        ledger = nil
        print(prefix .. "client build unverified.")
        return nil
    end
    local character = addon.characterSnapshot
    if not character then
        ledger = nil
        print(prefix .. "character snapshot unavailable.")
        return nil
    end
    if ledger and (ledger.build ~= addon.clientBuild or ledger.characterScope ~= character.scopeKey) then
        ledger = nil
    end
    return character.scopeKey
end

local function read(api)
    local ok, value = pcall(api)
    if ok then
        local checked, secret = pcall(issecretvalue, value)
        if checked and secret == false then
            return value
        end
    end
end

function GoldWiseLedgerSample()
    local scope = currentScope()
    if not scope then
        return
    end
    if type(issecretvalue) ~= "function" then
        print(prefix .. "secret-value guard unavailable.")
        return
    end
    ledger = ledger or addon.ledgerModel.new(addon.clientBuild, scope)
    if not ledger then
        print(prefix .. "ledger scope unavailable.")
        return
    end

    local id, status = addon.ledgerModel.observe(ledger, {
        build = addon.clientBuild,
        characterScope = scope,
        source = "wow-character-money",
        balanceCopper = read(GetMoney),
        observedAt = read(GetServerTime),
    }, MAX_SAMPLE_INTERVAL)
    if id then
        local entry = ledger.entries[#ledger.entries]
        print(prefix .. string.format("entry=%.0f, net change=%+.0f copper, unclassified.", id, entry.deltaCopper))
    else
        print(prefix .. (sampleMessages[status] or "sample unavailable."))
    end
end

function GoldWiseLedgerCategorize(id, category)
    if not currentScope() then
        return
    end
    if not ledger then
        print(prefix .. "entry unavailable in this session.")
        return
    end
    local ok, reason = addon.ledgerModel.categorize(ledger, id, category)
    if not ok then
        print(prefix .. categoryMessages[reason])
    elseif category == "unclassified" then
        print(prefix .. "classification cleared.")
    else
        print(prefix .. "net change labeled " .. category .. " (user-reported).")
    end
end
