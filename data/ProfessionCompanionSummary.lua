local _, addon = ...
local Summary = {}
local MAX_AGE = 900

local function validTime(value)
    return type(value) == "number" and value % 1 == 0
        and value >= 1 and value < 2 ^ 53
end

local function positive(value)
    return type(value) == "number" and value % 1 == 0
        and value >= 1 and value <= 2147483647
end

local function safeName(value)
    -- Blizzard markup uses pipes; never insert unverified formatting into
    -- an addon font string, even if a recipe label came from a game API.
    if type(value) ~= "string" or #value == 0 or #value > 64
        or value:find("[%c|]") then return nil end
    return value
end

local function fresh(observed, now)
    return validTime(observed) and validTime(now)
        and observed <= now and now - observed <= MAX_AGE
end

-- Only previously observed local snapshots; no game API reads or actions.
function Summary.evaluate(profession, inventory, plan, character, build, now)
    if type(profession) ~= "table" or type(character) ~= "table"
        or type(character.scopeKey) ~= "string" or character.scopeKey == ""
        or type(build) ~= "string" or profession.characterScope ~= character.scopeKey
        or not fresh(profession.observedAt, now)
        or type(profession.professionName) ~= "string"
        or type(profession.skill) ~= "number" or type(profession.cap) ~= "number"
        or profession.skill % 1 ~= 0 or profession.cap % 1 ~= 0
        or profession.skill < 0 or profession.cap < profession.skill
        or type(profession.knownRecipes) ~= "table" then
        return nil, "Profession scan unavailable or stale."
    end

    local lines = {
        string.format("%s | %.0f / %.0f skill", profession.professionName,
            profession.skill, profession.cap),
        string.format("%d learned recipes in scanned view (may be filtered).",
            #profession.knownRecipes),
    }

    local validPlan = type(plan) == "table" and plan.professionSnapshot == profession
        and plan.characterScope == character.scopeKey and plan.build == build
        and fresh(plan.observedAt, now)
        and type(inventory) == "table" and plan.inventory == inventory
        and inventory.characterScope == character.scopeKey
        and inventory.status == "complete" and fresh(inventory.observedAt, now)
        and type(plan.missing) == "table"

    if validPlan then
        local missing, kinds = 0, 0
        for id, count in pairs(plan.missing) do
            if type(id) ~= "number" or id % 1 ~= 0 or id < 1
                or type(count) ~= "number" or count % 1 ~= 0
                or count < 0 or count > 2147483647 or missing + count > 2147483647 then
                validPlan = false
                break
            end
            if count > 0 then
                missing = missing + count
                kinds = kinds + 1
            end
        end
        if validPlan then
            -- The final craft entry is the root selected recipe from the
            -- deterministic dependency planner; never guess a UI selection.
            local crafts = plan.crafts
            local root = type(crafts) == "table" and crafts[#crafts]
            local recipeName = root and safeName(root.name)
            if not root or not positive(root.count) or not positive(root.recipeId)
                or not positive(plan.recipeId) or root.recipeId ~= plan.recipeId
                or not recipeName or #crafts > 32 then
                validPlan = false
            else
                lines[#lines + 1] = string.format("Recipe: %.0f x %s", root.count, recipeName)
                lines[#lines + 1] = missing == 0 and "Plan: no missing carried reagents observed."
                    or string.format("Plan: %.0f missing units across %d items.", missing, kinds)
                -- Show a deterministic, bounded subset rather than flooding
                -- the adjacent panel with an unverified inventory catalog.
                if kinds > 0 then
                    local keys = {}
                    for itemId, count in pairs(plan.missing) do
                        if count > 0 then keys[#keys + 1] = itemId end
                    end
                    table.sort(keys)
                    for index = 1, math.min(2, #keys) do
                        local itemId = keys[index]
                        lines[#lines + 1] = string.format("Missing: Item %.0f x %.0f",
                            itemId, plan.missing[itemId])
                    end
                    if #keys > 2 then
                        lines[#lines + 1] = string.format("Plus %d more missing item types.", #keys - 2)
                    end
                end
            end
        end
    end
    if not validPlan then
        lines[#lines + 1] = "Plan: unavailable. Plan reagents in GoldWise."
    end
    lines[#lines + 1] = "Read-only; bank, alts and future requirements unknown."
    return table.concat(lines, "\n")
end

if addon then addon.professionCompanionSummary = Summary end
return Summary
