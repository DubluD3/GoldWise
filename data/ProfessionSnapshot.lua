local ProfessionSnapshot = {}
local MAX_RECIPES = 1024

local function integer(value, minimum)
    return type(value) == "number" and value >= minimum and value < 2 ^ 53 and value % 1 == 0
end

function ProfessionSnapshot.capture(characterScope, observedAt, reader)
    if type(characterScope) ~= "string" or #characterScope == 0 then
        return nil, "character scope unavailable"
    end
    if not integer(observedAt, 1) then
        return nil, "timestamp unavailable"
    end
    local profession = reader.profession()
    if type(profession) ~= "table" or not integer(profession.id, 1)
        or type(profession.name) ~= "string" or #profession.name == 0
        or not integer(profession.skill, 0) or not integer(profession.cap, 1)
        or profession.skill > profession.cap then
        return nil, "profession or skill range unavailable"
    end

    local snapshot = {
        characterScope = characterScope,
        observedAt = observedAt,
        source = "wow-client",
        professionId = profession.id,
        professionName = profession.name,
        skill = profession.skill,
        cap = profession.cap,
        recipeStatus = "unavailable",
        knownRecipes = {},
    }
    local ids = reader.recipeIds()
    if type(ids) ~= "table" or #ids == 0 then
        return snapshot
    end

    local count = #ids
    if count > MAX_RECIPES then
        snapshot.recipeStatus = "partial"
        count = MAX_RECIPES
    else
        snapshot.recipeStatus = "filtered"
    end

    local seen = {}
    for index = 1, count do
        local id = reader.recipeIdAt(ids, index)
        if not integer(id, 1) then
            snapshot.recipeStatus = "partial"
        elseif not seen[id] then
            seen[id] = true
            local learned, name = reader.learned(id, profession.id)
            if learned == true then
                snapshot.knownRecipes[#snapshot.knownRecipes + 1] = {
                    id = id,
                    name = type(name) == "string" and name or nil,
                }
            elseif learned ~= false then
                snapshot.recipeStatus = "partial"
            end
        end
    end
    return snapshot
end

local _, addon = ...
if addon then
    addon.professionSnapshotModel = ProfessionSnapshot
end

return ProfessionSnapshot
