local _, addon = ...
local Guide = {}

-- Pure source descriptions. Unsupported sources are never silently marked complete.
Guide.steps = {
    { key = "character", title = "Character identity", method = "Automatic",
      why = "Scopes observations to the current character, realm and faction.",
      instruction = "Log into your character. GoldWise observes identity on login." },
    { key = "bags", title = "Carried bags", method = "Player action required",
      why = "Shows your carried materials and avoids using imagined bank stock.",
      instruction = "Open your bags, then choose Scan bags below." },
    { key = "equipment", title = "Equipped gear", method = "Unsupported",
      why = "Gear advice needs reliable, scoped equipment and binding evidence.",
      instruction = "No equipped-slot capture is available in this build." },
    { key = "professions", title = "Professions and recipes", method = "Player action required",
      why = "Provides observed skill and learned recipes for reagent planning.",
      instruction = "Open your own crafting window, select a profession, then choose Scan profession." },
    { key = "bank", title = "Bank inventory", method = "Unsupported",
      why = "Bank contents must never be inferred from carried items.",
      instruction = "Bank capture is not verified; use your bags only." },
    { key = "auction", title = "Auction House browse results", method = "Player action required",
      why = "Collects observed asking-price rows, not sales, demand or guaranteed proceeds.",
      instruction = "Open AH Buy. Choose Observe browse, perform one native Search, then reopen GoldWise and Observe browse within 60 seconds." },
    { key = "alts", title = "Alternate characters", method = "Unsupported",
      why = "Other characters are not available live, and persistent alt caches are not yet supported.",
      instruction = "Log into each alt to inspect it separately. Do not assume transfer eligibility." },
    { key = "ledger", title = "Gold balance ledger", method = "Player action required",
      why = "Records local balance observations; a gold delta is not a confirmed sale.",
      instruction = "Outside trade with no coins on the cursor, choose Sample balance. Repeat after at least one second." },
    { key = "plan", title = "Recipe plans and reservations", method = "Player action required",
      why = "Prevents double allocation of carried reagents across session plans.",
      instruction = "Scan bags and a crafting profession, choose a learned recipe, then Plan reagents in Professions. Review My Plan." },
}

local known = {}
for _, step in ipairs(Guide.steps) do
    known[step.key] = true
end

local function integer(value, minimum)
    return type(value) == "number" and value >= minimum and value < 2 ^ 53 and value % 1 == 0
end

function Guide.open(saved)
    if saved == nil then
        return { schemaVersion = 1, finished = false, step = 1, skipped = {} }, "created"
    end
    if type(saved) ~= "table" or saved.schemaVersion ~= 1 or type(saved.finished) ~= "boolean"
        or not integer(saved.step, 1) or saved.step > #Guide.steps or type(saved.skipped) ~= "table" then
        return nil, "corrupt"
    end
    for key in pairs(saved) do
        if key ~= "schemaVersion" and key ~= "finished" and key ~= "step" and key ~= "skipped" then
            return nil, "corrupt"
        end
    end
    local skipped = {}
    local count = 0
    for key, value in pairs(saved.skipped) do
        count = count + 1
        if count > #Guide.steps or not known[key] or value ~= true then
            return nil, "corrupt"
        end
        skipped[key] = true
    end
    return { schemaVersion = 1, finished = saved.finished, step = saved.step, skipped = skipped }, "current"
end

function Guide.setStep(preferences, index)
    if type(preferences) ~= "table" or not integer(index, 1) or index > #Guide.steps then
        return false
    end
    preferences.step = index
    return true
end

function Guide.skip(preferences, key)
    if type(preferences) ~= "table" or not known[key] or type(preferences.skipped) ~= "table" then
        return false
    end
    preferences.skipped[key] = true
    return true
end

function Guide.finish(preferences)
    if type(preferences) ~= "table" then return false end
    preferences.finished = true
    return true
end

-- A method is a capability, not proof of completed capture. Never use the
-- presence of a SavedVariables timestamp as proof of current snapshot content.
function Guide.evaluate(step, source, currentTime, maxAge, expectedScope, supportedClient)
    if supportedClient ~= true then
        return "Unsupported", "This exact client build is not verified."
    end
    if step.method == "Unsupported" then
        return "Unsupported", "No verified reader for this source."
    end
    if type(source) ~= "table" then
        return "Pending", "No observation in this session."
    end
    if expectedScope and source.scope ~= expectedScope then
        return "Pending", "Observation is from another or unknown character scope."
    end
    if not integer(source.observedAt, 1) or not integer(currentTime, 1)
        or not integer(maxAge, 1) or currentTime < source.observedAt then
        return "Pending", "Timestamp is unavailable or inconsistent."
    end
    local minutes = math.floor((currentTime - source.observedAt) / 60)
    local stamp = string.format("Last observed at server time %.0f (%d min ago).", source.observedAt, minutes)
    if currentTime - source.observedAt > maxAge then
        return "Stale", stamp .. " Refresh before using this data."
    end
    if source.complete == false then
        return "Partial", stamp .. " Only observed content is usable."
    end
    return "Last observed", stamp
end

if addon then addon.scanGuideModel = Guide end
return Guide
