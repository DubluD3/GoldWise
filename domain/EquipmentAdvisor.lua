local _, addon = ...
local EquipmentAdvisor = {}
local LIMIT = 9007199254740991

local function integer(n, min)
    return type(n) == "number" and n >= min and n <= LIMIT and n % 1 == 0
end

local function text(s)
    return type(s) == "string" and #s > 0 and #s <= 128
end

local function fail(state, reason)
    return { status = state, reason = reason, action = "Review in game; GoldWise takes no actions." }
end

local function fresh(s, now, maxAge)
    return type(s) == "table" and integer(s.observedAt, 1)
        and s.observedAt <= now and now - s.observedAt <= maxAge
end

local function contains(values, candidate)
    if type(values) ~= "table" then return nil end
    local count = 0
    for key, value in pairs(values) do
        if not integer(key, 1) or not text(value) then return nil end
        count = count + 1
        if count > 64 then return nil end
    end
    if count == 0 then return nil end
    for _, value in ipairs(values) do
        if value == candidate then return true end
    end
    return false
end

-- The contract consumes only externally normalized, explicitly evidenced data;
-- it does not call WoW globals or infer transfer permissions from realm alone.
-- A synthetic test may supply validated fields; no live adapter exists yet.
function EquipmentAdvisor.evaluate(item, owner, target, transfer, context)
    if type(context) ~= "table" or not integer(context.now, 1) or not integer(context.maxAge, 1)
        or not text(context.build) or type(item) ~= "table"
        or not integer(item.itemId, 1) or type(owner) ~= "table" or type(target) ~= "table" then
        return fail("unknown", "Verified item and character observations unavailable.")
    end
    if not text(owner.scope) or not text(target.scope) or owner.scope == target.scope
        or not text(owner.realm) or not text(target.realm)
        or not text(owner.faction) or not text(target.faction)
        or item.ownerScope ~= owner.scope then
        return fail("unknown", "Source and target character identity cannot be reconciled.")
    end
    if owner.build ~= context.build or target.build ~= context.build
        or owner.realm ~= target.realm or owner.faction ~= target.faction then
        return fail("blocked", "Cross-build, cross-realm or cross-faction transfer is not verified.")
    end
    if not fresh(owner, context.now, context.maxAge)
        or not fresh(target, context.now, context.maxAge)
        or not fresh(item, context.now, context.maxAge) then
        return fail("unknown", "Character or item snapshot is missing or stale.")
    end

    -- Bind-on-pickup and already-bound items must never become suggested mail.
    if item.binding == "soulbound" or item.binding == "bind-on-pickup"
        or item.binding == "quest" or item.bound == true then
        return fail("blocked", "Binding restriction prohibits a transfer recommendation.")
    end
    if item.binding ~= "unbound" and item.binding ~= "bind-on-equip" then
        return fail("unknown", "Binding type has not been verified.")
    end
    if item.bound ~= false then
        return fail("unknown", "Unbound state has not been verified.")
    end
    if type(transfer) ~= "table" or transfer.allowed ~= true
        or transfer.evidenceClass ~= "OBSERVED-IN-GAME"
        or not text(transfer.evidenceReference)
        or transfer.fromScope ~= owner.scope or transfer.toScope ~= target.scope
        or transfer.build ~= context.build or transfer.realm ~= target.realm
        or transfer.faction ~= target.faction
        or not fresh(transfer, context.now, context.maxAge) then
        return fail("unknown", "An explicitly verified character-to-character transfer route is missing.")
    end

    if not integer(target.level, 1) then
        return fail("unknown", "Target character level has not been observed.")
    end
    if not integer(item.requiredLevel, 1) then
        return fail("unknown", "Minimum equipment level requirement is unknown.")
    end
    if item.requiredLevel > target.level then
        return fail("blocked", "Target character does not meet the verified level requirement.")
    end
    local classEligible = contains(item.allowedClasses, target.className)
    local raceEligible = contains(item.allowedRaces, target.raceName)
    if classEligible == false or raceEligible == false then
        return fail("blocked", "Verified class or race restriction prevents equipping.")
    end
    if classEligible == nil or raceEligible == nil then
        return fail("unknown", "Class or race restrictions are not fully verified.")
    end
    if not text(item.requiredProficiency) or type(target.proficiencies) ~= "table"
        or target.proficiencies[item.requiredProficiency] ~= true then
        return fail("unknown", "Required armor/weapon proficiency is unavailable or unverified.")
    end

    if item.unique == true then
        if type(target.knownItemIds) ~= "table" or target.knownItemIds[item.itemId] == nil then
            return fail("unknown", "Target inventory and unique-item restriction are not fully observed.")
        end
        if target.knownItemIds[item.itemId] == true then
            return fail("blocked", "Target is already known to hold this unique item.")
        end
    elseif item.unique ~= false then
        return fail("unknown", "Unique-equipped restrictions are unverified.")
    end
    if target.equipmentObserved ~= true then
        return fail("unknown", "Target equipment has not been observed on this character.")
    end
    -- Never claim a statistical upgrade: no verified role/stat evaluator.
    return {
        status = "potential-upgrade-review",
        itemId = item.itemId, fromScope = owner.scope, toScope = target.scope,
        lastSeenAt = target.observedAt,
        reason = "Transfer and basic equipment eligibility are evidenced; relative performance is not.",
        action = "Potential upgrade - review role, stats and the actual in-game item tooltip. Transfer manually only if permitted.",
        certainty = "not-a-confirmed-upgrade",
        transferEvidence = transfer.evidenceReference,
    }
end

if addon then addon.equipmentAdvisor = EquipmentAdvisor end
return EquipmentAdvisor
