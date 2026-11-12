local _, addon = ...
local Review = {}
local LIMIT = 2147483647
local EXACT = 9007199254740991
local function integer(x, min, max)
    return type(x) == "number" and x % 1 == 0 and x >= min and x <= max
end
local function fresh(x, scope, now, age)
    return type(x) == "table" and x.characterScope == scope
        and integer(x.observedAt, 1, EXACT) and x.observedAt <= now
        and now - x.observedAt <= age
end
-- All output is advisory, NEVER an estimated skill-up or guaranteed craft.
function Review.evaluate(input)
    local unknown = { status = "unknown", reason = "Fresh, matching profession evidence unavailable." }
    if type(input) ~= "table" or type(input.characterScope) ~= "string"
        or #input.characterScope == 0 or not integer(input.now, 1, EXACT)
        or not integer(input.maxAge, 1, EXACT) then return unknown end
    local profession = input.profession
    if not fresh(profession, input.characterScope, input.now, input.maxAge)
        or not integer(profession.professionId, 1, LIMIT)
        or not integer(profession.skill, 0, LIMIT)
        or not integer(profession.cap, 1, LIMIT)
        or profession.skill > profession.cap
        or type(profession.knownRecipes) ~= "table"
        or (profession.recipeStatus ~= "filtered" and profession.recipeStatus ~= "partial"
            and profession.recipeStatus ~= "unavailable") then return unknown end

    local result = {
        status = "review",
        professionId = profession.professionId,
        skill = profession.skill, cap = profession.cap,
        observedLearnedCount = #profession.knownRecipes,
        observedCoverage = profession.recipeStatus,
        goalStatus = "no-skill-target", materialStatus = "unobserved",
        caution = "Recipes observed in a filtered crafting view are not a complete catalog. No skill-up chance or number of crafts is known.",
    }
    local goal = input.goal
    if goal ~= nil and type(goal) == "table"
        and goal.characterScope == input.characterScope and goal.build == input.build
        and goal.professionTargetSkill ~= nil then
        if not integer(goal.professionId, 1, LIMIT)
            or not integer(goal.professionTargetSkill, 1, LIMIT) then
            result.goalStatus = "invalid-target"
        elseif goal.professionId ~= profession.professionId then
            result.goalStatus = "different-profession"
        else
            result.goalTarget = goal.professionTargetSkill
            result.remainingSkill = math.max(0, goal.professionTargetSkill - profession.skill)
            result.goalStatus = result.remainingSkill == 0 and "reached" or "remaining"
        end
    end

    local plan = input.plan
    if plan ~= nil then
        local bag = input.inventory
        if not fresh(plan, input.characterScope, input.now, input.maxAge)
            or not fresh(bag, input.characterScope, input.now, input.maxAge)
            or bag.status ~= "complete" or plan.inventory ~= bag
            or plan.professionId ~= profession.professionId
            or not integer(plan.recipeId, 1, LIMIT)
            or type(plan.missing) ~= "table" then
            result.materialStatus = "unknown-or-stale"
        else
            local missing, count = 0, 0
            for id, qty in pairs(plan.missing) do
                if not integer(id, 1, EXACT) or not integer(qty, 1, LIMIT)
                    or missing > LIMIT - qty then
                    result.materialStatus = "invalid-plan"
                    return result
                end
                missing, count = missing + qty, count + 1
            end
            result.missingUnits = missing
            result.missingKinds = count
            result.materialStatus = missing == 0 and "carried-inputs-observed"
                or "missing-carried-inputs"
        end
    end
    return result
end
if addon then addon.professionGoalReview = Review end
return Review
