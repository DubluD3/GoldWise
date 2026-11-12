local _, addon = ...
local Goals = {}
local MAX_COPPER = 9007199254740991
local MAX_SKILL = 2147483647

local function integer(n, minimum, maximum)
    return type(n) == "number" and n % 1 == 0 and n >= minimum and n <= maximum
end
local function key(s)
    return type(s) == "string" and #s > 0 and #s <= 128
end

-- Session-only pure goal state: no invented market data, skill-up probabilities
-- or automatic gold-making actions. The player sets explicit targets.
function Goals.new(request)
    if type(request) ~= "table" or not key(request.id) or not key(request.characterScope)
        or not key(request.build) then
        return nil, "invalid-goal-identity"
    end
    local gold = request.goldTargetCopper
    local skill = request.professionTargetSkill
    if gold == nil and skill == nil then
        return nil, "missing-goal-target"
    end
    if gold ~= nil and not integer(gold, 1, MAX_COPPER) then
        return nil, "invalid-gold-target"
    end
    if skill ~= nil and not integer(skill, 1, MAX_SKILL) then
        return nil, "invalid-profession-target"
    end
    if skill ~= nil and not integer(request.professionId, 1, MAX_SKILL) then
        return nil, "invalid-profession-identity"
    end
    return {
        id = request.id, characterScope = request.characterScope, build = request.build,
        goldTargetCopper = gold, professionTargetSkill = skill,
        professionId = skill and request.professionId or nil,
    }
end

local function observe(input, goal, now, maxAge)
    return type(input) == "table" and input.characterScope == goal.characterScope
        and input.build == goal.build and integer(input.observedAt, 1, MAX_COPPER)
        and input.observedAt <= now and now - input.observedAt <= maxAge
end

-- Always recalculate from supplied snapshots. Do not store derived progress or
-- interpret gold deltas as realized sales.
function Goals.evaluate(goal, evidence)
    if type(goal) ~= "table" or type(evidence) ~= "table"
        or not integer(evidence.now, 1, MAX_COPPER)
        or not integer(evidence.maxAge, 1, MAX_COPPER) then
        return { status = "unknown", reason = "Observation clock or goal unavailable." }
    end

    local result = { id = goal.id, status = "pending", gold = nil, profession = nil, nextSteps = {} }
    local complete = true
    local reached = true

    if goal.goldTargetCopper ~= nil then
        local balance = evidence.money
        if not observe(balance, goal, evidence.now, evidence.maxAge)
            or not integer(balance.balanceCopper, 0, MAX_COPPER) then
            result.gold = { status = "unknown", reason = "Current character balance is missing or stale." }
            result.nextSteps[#result.nextSteps+1] = "Sample current character balance manually."
            complete, reached = false, false
        else
            local remaining = math.max(0, goal.goldTargetCopper - balance.balanceCopper)
            result.gold = {
                status = remaining == 0 and "met" or "in-progress",
                currentCopper = balance.balanceCopper, targetCopper = goal.goldTargetCopper,
                remainingCopper = remaining, observedAt = balance.observedAt,
                source = "observed-character-balance",
            }
            if remaining > 0 then
                reached = false
                result.nextSteps[#result.nextSteps+1] =
                    "Review your available inventory and professions; make gameplay decisions manually."
            end
        end
    end

    if goal.professionTargetSkill ~= nil then
        local snap = evidence.profession
        if not observe(snap, goal, evidence.now, evidence.maxAge)
            or snap.professionId ~= goal.professionId
            or not integer(snap.skill, 0, MAX_SKILL) then
            result.profession = { status = "unknown", reason = "Matching profession skill is missing or stale." }
            result.nextSteps[#result.nextSteps+1] =
                "Open the matching crafting profession and scan its observed skill."
            complete, reached = false, false
        else
            local remaining = math.max(0, goal.professionTargetSkill - snap.skill)
            result.profession = {
                status = remaining == 0 and "met" or "in-progress",
                currentSkill = snap.skill, targetSkill = goal.professionTargetSkill,
                remainingSkill = remaining, observedAt = snap.observedAt,
                source = "observed-open-profession",
            }
            if remaining > 0 then
                reached = false
                result.nextSteps[#result.nextSteps+1] =
                    "Review learned recipes and required materials; skill-up chance is unknown."
            end
        end
    end

    if not complete then result.status = "incomplete"
    elseif reached then result.status = "met"
    else result.status = "in-progress" end
    return result
end

if addon then addon.goalPlanner = Goals end
return Goals
