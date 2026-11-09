local RecipeCatalog = {}
local SCHEMA_VERSION = 1
local VERIFIED_BUILD = "70862"
local MAX_RECIPES = 1024 -- Matches the GW-009 snapshot's collection bound.

local function integer(value, minimum)
    return type(value) == "number" and value >= minimum and value < 2 ^ 53 and value % 1 == 0
end

local function nonempty(value)
    return type(value) == "string" and #value > 0
end

---@class ProfessionSnapshotInput
---@field characterScope string
---@field observedAt integer
---@field source "wow-client"
---@field professionId integer
---@field professionName string
---@field skill integer
---@field cap integer
---@field recipeStatus "filtered"|"partial"|"unavailable"
---@field knownRecipes {id: integer, name: string?}[]

-- The caller supplies the verified build of the snapshot, not the current build at read time.
---@param build string
---@param snapshot ProfessionSnapshotInput?
function RecipeCatalog.fromSnapshot(build, snapshot)
    if build ~= VERIFIED_BUILD then
        return nil, "unsupported-build"
    end
    if type(snapshot) ~= "table" or snapshot.source ~= "wow-client"
        or not nonempty(snapshot.characterScope) or not integer(snapshot.observedAt, 1)
        or not integer(snapshot.professionId, 1) or not nonempty(snapshot.professionName)
        or not integer(snapshot.skill, 0) or not integer(snapshot.cap, 1) or snapshot.skill > snapshot.cap then
        return nil, "invalid-snapshot"
    end

    local coverage = snapshot.recipeStatus
    local rows = snapshot.knownRecipes
    if (coverage ~= "filtered" and coverage ~= "partial" and coverage ~= "unavailable")
        or type(rows) ~= "table" then
        return nil, "invalid-recipes"
    end
    local count = #rows
    if count > MAX_RECIPES or (coverage == "unavailable" and count ~= 0) then
        return nil, "invalid-recipes"
    end
    for index in pairs(rows) do
        if not integer(index, 1) or index > count then
            return nil, "invalid-recipes"
        end
    end
    local recipes = {}
    for index = 1, count do
        local row = rows[index]
        if type(row) ~= "table" or not integer(row.id, 1) or recipes[row.id]
            or (row.name ~= nil and type(row.name) ~= "string") then
            return nil, "invalid-recipes"
        end
        recipes[row.id] = { id = row.id, name = row.name }
    end

    return {
        schemaVersion = SCHEMA_VERSION,
        build = build,
        characterScope = snapshot.characterScope,
        observedAt = snapshot.observedAt,
        professionId = snapshot.professionId,
        professionName = snapshot.professionName,
        skill = snapshot.skill,
        cap = snapshot.cap,
        coverage = coverage,
        knownRecipes = recipes,
    }
end

---@class RecipeCatalogQuery
---@field build string
---@field characterScope string
---@field professionId integer
---@field recipeId integer
---@field now integer
---@field maxAge integer

-- Read a catalog produced by fromSnapshot. Time limits are supplied by the consumer.
---@param query RecipeCatalogQuery
function RecipeCatalog.read(catalog, query)
    if type(catalog) ~= "table" or catalog.schemaVersion ~= SCHEMA_VERSION then
        return nil, "unavailable"
    end
    if type(query) ~= "table" or query.build ~= VERIFIED_BUILD or query.build ~= catalog.build
        or query.characterScope ~= catalog.characterScope or query.professionId ~= catalog.professionId
        or not integer(query.recipeId, 1) then
        return nil, "scope-unavailable"
    end
    if not integer(query.now, 1) or not integer(query.maxAge, 1) or query.now < catalog.observedAt then
        return nil, "freshness-unavailable"
    end
    if query.now - catalog.observedAt > query.maxAge then
        return nil, "stale"
    end

    local row = catalog.knownRecipes[query.recipeId]
    local status = catalog.coverage == "unavailable" and "unavailable" or "unknown"
    if row then
        status = "known"
    end
    return {
        recipe = row and { id = row.id, name = row.name } or nil,
        recipeStatus = status,
        coverage = catalog.coverage,
        professionId = catalog.professionId,
        professionName = catalog.professionName,
        skill = catalog.skill,
        cap = catalog.cap,
        build = catalog.build,
        characterScope = catalog.characterScope,
        observedAt = catalog.observedAt,
        source = "wow-client",
        attribution = "Blizzard local crafting view",
        licenseStatus = "redistribution-unverified",
        trainerStatus = "unavailable",
    }
end

return RecipeCatalog
