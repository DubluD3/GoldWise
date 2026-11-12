local _, addon = ...
local tabs = { "Overview", "Inventory", "Professions", "Market", "My Plan" }
local colors = {
    background = { 21 / 255, 26 / 255, 34 / 255, 0.98 },
    surface = { 34 / 255, 43 / 255, 56 / 255, 1 },
    text = { 243 / 255, 245 / 255, 248 / 255 },
    muted = { 169 / 255, 181 / 255, 199 / 255 },
    gold = { 232 / 255, 193 / 255, 90 / 255 },
    selected = { 93 / 255, 71 / 255, 37 / 255, 1 },
    primary = { 64 / 255, 83 / 255, 101 / 255, 1 },
}
local pageSize = 6
local snapshotAge = 900
local marketAge = 300
local view
local tab, page, selection, crafts = 1, 1, 1, 1
local feedback
local vendor
local guideStep
local guideOffered = false
-- Goal targets exist only for this addon session; never persisted or sent externally.
local activeGoal
local goalPanel = false
local materialsPanel = false
local professionReviewPanel = false
local capacityPanel = false
local testPanel = false

local function now()
    local ok, value = pcall(GetServerTime)
    local checked, secret = pcall(issecretvalue, value)
    if ok and checked and secret == false and type(value) == "number"
        and value >= 1 and value < 2 ^ 53 and value % 1 == 0 then
        return value
    end
end

local function scoped(snapshot)
    local character = addon.characterSnapshot
    if addon.supportedClient and character and snapshot and snapshot.characterScope == character.scopeKey then
        return snapshot
    end
end

local function age(snapshot, time, limit)
    if not snapshot or not time or time < snapshot.observedAt then
        return "Time unavailable", false
    end
    local seconds = time - snapshot.observedAt
    local fresh = seconds <= limit
    return string.format("%s%.0f min ago", fresh and "" or "Stale · ", math.floor(seconds / 60)), fresh
end

local function name(itemId)
    local inventory = scoped(addon.inventorySnapshot)
    return (inventory and inventory.labels and inventory.labels[itemId]) or string.format("Item %.0f", itemId)
end

local function sortedKeys(map)
    local keys = {}
    for key in pairs(map) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

local function showRows(rows, count, renderRow)
    local pages = math.max(1, math.ceil(count / pageSize))
    page = math.max(1, math.min(page, pages))
    local first = (page - 1) * pageSize + 1
    for index = first, math.min(count, first + pageSize - 1) do
        rows[#rows + 1] = renderRow(index)
    end
    if pages > 1 then
        rows[#rows + 1] = string.format("Page %d of %d", page, pages)
    end
    return page > 1, page < pages
end


local function showGuide()
    local prefs = addon.guidePreferences
    guideStep = prefs and prefs.step or 1
end

local function guidePage()
    local model = addon.scanGuideModel
    local step = model.steps[guideStep]
    if not step then guideStep = 1; step = model.steps[1] end
    local character = addon.characterSnapshot
    local scope = character and character.scopeKey
    local snap
    local complete = true
    if step.key == "character" then
        snap = character
    elseif step.key == "bags" then
        snap = scoped(addon.inventorySnapshot)
        complete = snap and snap.status == "complete"
    elseif step.key == "professions" then
        snap = scoped(addon.professionSnapshot)
        -- Filtered learned recipes never establish a complete recipe catalog.
        complete = false
    elseif step.key == "auction" then
        snap = scoped(addon.auctionObservation)
        -- Live market identity and full scan scope are still unverified.
        complete = false
    elseif step.key == "ledger" then
        local ledger = addon.ledgerView and addon.ledgerView()
        if ledger and ledger.characterScope == scope and ledger.build == addon.clientBuild then
            snap = ledger.latest
        end
    elseif step.key == "plan" then
        local plan = scoped(addon.recipePlan)
        local profession = scoped(addon.professionSnapshot)
        if plan and profession and plan.professionSnapshot == profession
            and plan.build == addon.clientBuild then
            snap = plan
        end
    end
    -- A ledger's latest sample has no own scope: its parent session already
    -- passed the explicit character/build gate above. Never infer scopes for
    -- other source types, including invalid/old plans.
    local sourceScope = step.key == "ledger" and snap and scope
        or snap and (snap.characterScope or snap.scopeKey)
    local source = snap and {
        scope = sourceScope,
        observedAt = snap.observedAt,
        complete = complete,
    }
    local status, detail = model.evaluate(step, source, now(), step.key == "auction" and marketAge or snapshotAge,
        scope, addon.supportedClient)
    local result = { rows = {
        "GoldWise stays on this device. No account, uploads, or automated gameplay actions.",
        string.format("Step %d of %d  -  %s", guideStep, #model.steps, step.title),
        "Method: " .. step.method .. "  |  State: " .. status,
        detail,
        "WHAT TO DO: " .. step.instruction,
        "WHY: " .. step.why,
    }, actions = {} }
    local actions = result.actions
    if addon.guidePreferencesError then
        result.rows[#result.rows + 1] = "Guide preferences invalid; left untouched. Steps cannot be saved."
    end
    if addon.guidePreferences and addon.guidePreferences.skipped[step.key] then
        result.rows[#result.rows + 1] = "Previously skipped. Skipping does not mean data was collected."
    end
    local function advance(index)
        guideStep = index
        if addon.guidePreferences then model.setStep(addon.guidePreferences, index) end
    end
    if guideStep > 1 then
        actions[1] = { "Previous step", function() advance(guideStep - 1) end }
    end
    if guideStep < #model.steps then
        actions[2] = { "Next step", function() advance(guideStep + 1) end }
        actions[3] = { "Skip this step", function()
            if addon.guidePreferences then model.skip(addon.guidePreferences, step.key) end
            advance(guideStep + 1)
        end }
    else
        actions[5] = { "Finish guide", function()
            if addon.guidePreferences then model.finish(addon.guidePreferences) end
            guideStep = nil
            return "Guide complete. Missing scans remain pending until observed."
        end }
    end
    if step.key == "bags" then
        actions[4] = { "Scan bags", GoldWiseInventoryScan }
    elseif step.key == "professions" then
        actions[4] = { "Scan profession", GoldWiseProfessionScan }
    elseif step.key == "auction" then
        actions[4] = { "Observe browse", function()
            view.frame:Hide()
            GoldWiseAuctionObserve()
        end }
    elseif step.key == "ledger" then
        actions[4] = { "Sample balance", GoldWiseLedgerSample }
    end
    actions[6] = { "Exit guide", function() guideStep = nil end }
    return result
end

local function applyCustomGoal(request)
    if request.kind == "help" then
        return "Use /goldwise goal gold <copper>, /goldwise goal skill <level>, or /goldwise goal clear."
    end
    if request.kind == "clear" then
        activeGoal = nil
        return "Session goals cleared."
    end
    local character = addon.characterSnapshot
    local scope = character and character.scopeKey
    local buildId = addon.clientBuild
    if not addon.supportedClient or type(scope) ~= "string" or #scope == 0
        or type(buildId) ~= "string" then
        return "Character identity or supported build unavailable."
    end
    if activeGoal and (activeGoal.characterScope ~= scope or activeGoal.build ~= buildId) then
        activeGoal = nil
    end
    local target = {
        id = "session-goal", characterScope = scope, build = buildId,
        goldTargetCopper = activeGoal and activeGoal.goldTargetCopper,
        professionId = activeGoal and activeGoal.professionId,
        professionTargetSkill = activeGoal and activeGoal.professionTargetSkill,
    }
    if request.kind == "gold" then
        target.goldTargetCopper = request.target
    elseif request.kind == "skill" then
        local profession = scoped(addon.professionSnapshot)
        local time = now()
        if not profession or not time or type(profession.observedAt) ~= "number"
            or profession.observedAt > time or time - profession.observedAt > snapshotAge
            or type(profession.cap) ~= "number" or profession.cap % 1 ~= 0
            or type(profession.professionId) ~= "number"
            or request.target > profession.cap then
            return "Scan your open profession first; target must not exceed its observed cap."
        end
        target.professionId = profession.professionId
        target.professionTargetSkill = request.target
    else
        return "Unknown goal command."
    end
    local created, reason = addon.goalPlanner.new(target)
    if not created then return "Goal unavailable: " .. (reason or "invalid target") end
    activeGoal = created
    return "Custom session target set. Observe fresh character data to track progress."
end

local function goalPage(time, ledger, profession)
    local result = { rows = {
        "Session goals only. Targets are private and reset on reload or character change.",
        "Gold +1g and Skill +10 create explicit targets from your last fresh manual observations.",
        "Custom: /goldwise goal gold 25000 (copper) or /goldwise goal skill 75.",
        "No projected earnings, skill-up chance, automatic selling or crafting.",
    }, actions = {} }
    local rows, actions = result.rows, result.actions
    local character = addon.characterSnapshot
    local scope = character and character.scopeKey
    local buildId = addon.clientBuild
    if activeGoal and (activeGoal.characterScope ~= scope or activeGoal.build ~= buildId) then
        activeGoal = nil
    end

    local money
    if ledger and ledger.latest then
        money = {
            characterScope = ledger.characterScope, build = ledger.build,
            observedAt = ledger.latest.observedAt, balanceCopper = ledger.latest.balanceCopper,
        }
    end
    local professionData
    if profession then
        professionData = {
            characterScope = profession.characterScope, build = buildId,
            observedAt = profession.observedAt, professionId = profession.professionId,
            skill = profession.skill,
        }
    end
    local evidence = { now = time, maxAge = snapshotAge, money = money, profession = professionData }
    local function validMoney()
        if not money or type(time) ~= "number" or money.characterScope ~= scope
            or money.build ~= buildId or type(money.observedAt) ~= "number"
            or money.observedAt > time or time - money.observedAt > snapshotAge
            or type(money.balanceCopper) ~= "number" or money.balanceCopper < 0
            or money.balanceCopper % 1 ~= 0 or money.balanceCopper > 2 ^ 53 - 1 - 10000 then
            return false
        end
        return true
    end
    local function validProfession()
        if not professionData or type(time) ~= "number" or professionData.characterScope ~= scope
            or type(professionData.observedAt) ~= "number"
            or professionData.observedAt > time or time - professionData.observedAt > snapshotAge
            or type(professionData.skill) ~= "number" or professionData.skill % 1 ~= 0
            or type(profession.cap) ~= "number" or profession.cap % 1 ~= 0
            or profession.cap <= professionData.skill or professionData.skill < 0
            or professionData.professionId == nil then
            return false
        end
        return true
    end
    local function setTarget(which)
        if type(scope) ~= "string" or #scope == 0 then
            return "Character identity unavailable. Reopen after login."
        end
        local goal = activeGoal
        local target = {
            id = "session-goal", characterScope = scope, build = buildId,
            goldTargetCopper = goal and goal.goldTargetCopper,
            professionId = goal and goal.professionId,
            professionTargetSkill = goal and goal.professionTargetSkill,
        }
        if which == "gold" then
            if not validMoney() then return "Sample a current gold balance first." end
            target.goldTargetCopper = money.balanceCopper + 10000
        else
            if not validProfession() then return "Scan a current profession below its cap first." end
            target.professionId = professionData.professionId
            target.professionTargetSkill = math.min(profession.cap, professionData.skill + 10)
        end
        local created, reason = addon.goalPlanner.new(target)
        if not created then return "Goal unavailable: " .. (reason or "invalid target") end
        activeGoal = created
        return "Session target updated from current observed data."
    end

    if activeGoal then
        local progress = addon.goalPlanner.evaluate(activeGoal, evidence)
        rows[#rows + 1] = "Combined goal: " .. progress.status
        if progress.gold then
            if progress.gold.status == "unknown" then
                rows[#rows + 1] = "Gold: unknown (sample a fresh character balance)"
            else
                rows[#rows + 1] = string.format("Gold: %.0f / %.0f copper, %.0f remaining (%s)",
                    progress.gold.currentCopper, progress.gold.targetCopper,
                    progress.gold.remainingCopper, progress.gold.status)
            end
        end
        if progress.profession then
            if progress.profession.status == "unknown" then
                rows[#rows + 1] = "Profession: unknown (rescan the matching open profession)"
            else
                rows[#rows + 1] = string.format("Profession: %.0f / %.0f skill, %.0f remaining (%s)",
                    progress.profession.currentSkill, progress.profession.targetSkill,
                    progress.profession.remainingSkill, progress.profession.status)
            end
        end
        if progress.nextSteps then
            for _, instruction in ipairs(progress.nextSteps) do
                rows[#rows + 1] = instruction
            end
        end
        actions[3] = { "Clear goals", function()
            activeGoal = nil
            return "Session goals cleared."
        end }
    else
        rows[#rows + 1] = "No active goal. Take manual samples before choosing a target."
    end
    actions[1] = { "Gold +1g", function() return setTarget("gold") end }
    actions[2] = { "Skill +10", function() return setTarget("skill") end }
    actions[4] = { "Back to plan", function() goalPanel = false end }
    actions[5] = { "Sample balance", GoldWiseLedgerSample }
    actions[6] = { "Scan profession", GoldWiseProfessionScan }
    return result
end

local function professionReviewPage(time, profession, inventory, plan)
    local result = { rows = {
        "Profession review uses only your observed open crafting view.",
        "Craft count is NOT a predicted skill-point gain; no skill-up probabilities verified.",
    }, actions = {} }
    local rows, actions = result.rows, result.actions
    local character = addon.characterSnapshot
    local scope = character and character.scopeKey
    local goal = activeGoal
    if goal and (goal.characterScope ~= scope or goal.build ~= addon.clientBuild) then
        goal = nil
    end
    local summary = addon.professionGoalReview.evaluate({
        characterScope = scope, build = addon.clientBuild, now = time,
        maxAge = snapshotAge, profession = profession, goal = goal,
        plan = plan, inventory = inventory,
    })
    if summary.status == "unknown" then
        rows[#rows + 1] = summary.reason
        rows[#rows + 1] = "Open your crafting profession and scan it manually."
    else
        rows[#rows + 1] = string.format("Observed skill %.0f / %.0f; %.0f learned recipes in %s view.",
            summary.skill, summary.cap, summary.observedLearnedCount, summary.observedCoverage)
        if summary.goalStatus == "remaining" then
            rows[#rows + 1] = string.format("Target %.0f skill: %.0f points remain (number of crafts unknown).",
                summary.goalTarget, summary.remainingSkill)
        elseif summary.goalStatus == "reached" then
            rows[#rows + 1] = "Observed skill meets the selected profession target."
        elseif summary.goalStatus == "different-profession" then
            rows[#rows + 1] = "Target belongs to another profession. No progress comparison."
        else
            rows[#rows + 1] = "No matching skill target. Set one in My Goals."
        end
        if summary.materialStatus == "missing-carried-inputs" then
            rows[#rows + 1] = string.format("Current recipe plan lacks %.0f carried reagent units across %.0f items.",
                summary.missingUnits, summary.missingKinds)
        elseif summary.materialStatus == "carried-inputs-observed" then
            rows[#rows + 1] = "Current recipe plan's material inputs are observed in carried bags."
        else
            rows[#rows + 1] = "Recipe material coverage: " .. summary.materialStatus .. "."
        end
        rows[#rows + 1] = "Learned-recipe list may be filtered; no guaranteed leveling route."
    end
    actions[1] = { "Scan profession", GoldWiseProfessionScan }
    actions[2] = { "Back to plan", function() professionReviewPanel = false end }
    actions[3] = { "My Goals", function()
        professionReviewPanel, goalPanel, tab = false, true, 5
    end }
    return result
end

local function capacityPage(time, inventory, plan)
    local result = { rows = {
        "Direct-reagent capacity ONLY. Not a guaranteed craft or skill-up estimate.",
    }, actions = {} }
    local rows, actions = result.rows, result.actions
    local character = addon.characterSnapshot
    local status = addon.craftCapacity.evaluate({
        scope = character and character.scopeKey,
        now = time, maxAge = snapshotAge,
        recipe = plan and plan.recipeSchematic, inventory = inventory,
        reservations = inventory and addon.reservationsFor(inventory) or {},
    })
    if status.status ~= "direct-reagent-coverage" then
        rows[#rows + 1] = status.reason
        rows[#rows + 1] = "Re-scan complete bags and plan a fixed-output recipe manually."
    else
        rows[#rows + 1] = string.format("Up to %.0f runs covered by observed direct reagents.", status.maxDirectCrafts)
        rows[#rows + 1] = "Nested crafting, costs, skill-up odds, and execution requirements are unverified."
        result.previous, result.next = showRows(rows, #status.rows, function(index)
            local item = status.rows[index]
            return string.format("%s: %.0f free of %.0f needed per run (covers %.0f)",
                name(item.itemId), item.available, item.perCraft, item.craftCount)
        end)
    end
    actions[1] = { "Back to plan", function() capacityPanel, page = false, 1 end }
    actions[2] = { "Scan bags", function() GoldWiseInventoryScan(); page = 1 end }
    actions[3] = { "Professions", function() capacityPanel, tab, page = false, 3, 1 end }
    return result
end

local function materialsPage(time, inventory, plan)
    local result = { rows = {
        "Carried materials review: manual decisions only. Not a sell recommendation.",
    }, actions = {} }
    local rows, actions = result.rows, result.actions
    local character = addon.characterSnapshot
    local observed = addon.materialReview.evaluate({
        inventory = inventory, plan = plan, reservations = inventory and addon.reservationsFor(inventory) or {},
        characterScope = character and character.scopeKey,
        now = time, maxAge = snapshotAge,
    })
    if observed.status == "unknown" then
        rows[#rows + 1] = observed.reason
        rows[#rows + 1] = "Scan complete carried bags again. Recalculate your current reagent plan."
    else
        rows[#rows + 1] = "Active plan: " .. observed.planStatus .. ". Holds are counted conservatively."
        rows[#rows + 1] = "No bank, alt, future profession or actual market demand is included."
        if #observed.rows == 0 then
            rows[#rows + 1] = "No readable item stacks in this complete bag observation."
        else
            result.previous, result.next = showRows(rows, #observed.rows, function(index)
                local item = observed.rows[index]
                return string.format("%s: %.0f carried, %.0f held, %.0f manual-review (%s)",
                    name(item.itemId), item.carried, item.hold, item.reviewQuantity, item.status)
            end)
        end
    end
    actions[1] = { "Scan bags", function() GoldWiseInventoryScan(); page = 1 end }
    actions[2] = { "Back to bags", function() materialsPanel, page = false, 1 end }
    actions[3] = { "My Plan", function() materialsPanel, tab, page = false, 5, 1 end }
    return result
end

-- A short, visible route through the first player-controlled validation steps.
-- Status only reflects same-character, fresh session observations.
local function testingPage(time, inventory, profession, ledger, plan)
    local result = { rows = {
        "QUICK TEST | GoldWise is a QA candidate, not a release.",
        "Follow the steps below. Actions only observe or navigate; nothing is crafted, bought or moved.",
    }, actions = {} }
    local rows, actions = result.rows, result.actions
    local _, bagsFresh = age(inventory, time, snapshotAge)
    local _, professionFresh = age(profession, time, snapshotAge)
    local _, planFresh = age(plan, time, snapshotAge)
    local readyBags = inventory and inventory.status == "complete" and bagsFresh
    local readyProfession = profession and professionFresh
    local readyPlan = plan and planFresh and readyBags
        and plan.inventory == inventory and plan.professionSnapshot == profession
        and plan.build == addon.clientBuild
    local moneyFresh = ledger and ledger.latest
        and ledger.characterScope == (addon.characterSnapshot and addon.characterSnapshot.scopeKey)
        and ledger.build == addon.clientBuild
        and age(ledger.latest, time, snapshotAge) ~= "Time unavailable"
    if moneyFresh then
        local _, fresh = age(ledger.latest, time, snapshotAge)
        moneyFresh = fresh
    end
    rows[#rows + 1] = "1. Bags: " .. (readyBags and "observed (complete)" or "NEEDS SCAN - open bags, click Scan bags")
    rows[#rows + 1] = "2. Professions: " .. (readyProfession and "observed (filtered view)"
        or "NEEDS SCAN - open a crafting window, click Scan profession")
    rows[#rows + 1] = "3. Balance: " .. (moneyFresh and "manually sampled" or "NEEDS SAMPLE - click Sample balance")
    rows[#rows + 1] = "4. Reagent plan: " .. (readyPlan and "available in My Plan"
        or "PENDING - choose a learned recipe in Professions and Plan reagents")
    rows[#rows + 1] = "5. Market: OPTIONAL - inspect only after a native Auction House search."
    rows[#rows + 1] = "To report a failure: note the client build, action and Lua error (remove private identifiers)."
    actions[1] = { "Scan bags", GoldWiseInventoryScan }
    actions[2] = { "Scan profession", GoldWiseProfessionScan }
    actions[3] = { "Sample balance", GoldWiseLedgerSample }
    actions[4] = { "Choose recipe", function() testPanel, tab, page = false, 3, 1 end }
    actions[5] = { "My Plan", function() testPanel, tab, page = false, 5, 1 end }
    actions[6] = { "Back to Overview", function() testPanel, tab, page = false, 1, 1 end }
    return result
end

local function state()
    if guideStep then return guidePage() end
    local result = { rows = {}, actions = {} }
    local rows, actions = result.rows, result.actions
    local time = now()
    local inventory = scoped(addon.inventorySnapshot)
    local profession = scoped(addon.professionSnapshot)
    local market = scoped(addon.auctionObservation)
    local ledger = addon.ledgerView and addon.ledgerView()
    local plan = scoped(addon.recipePlan)
    -- A plan belongs to the exact manual profession scan that created it.
    -- Switching or re-scanning a profession never silently carries the plan forward.
    if plan and (not profession or plan.professionSnapshot ~= profession) then plan = nil end

    if not addon.supportedClient then
        rows[1] = "This client build needs verification."
        return result
    end

    if tab == 1 then
        if testPanel then return testingPage(time, inventory, profession, ledger, plan) end
        rows[1] = inventory and ("Bags · " .. inventory.status .. " · " .. age(inventory, time, snapshotAge)) or "Bags · Scan to see carried items"
        rows[2] = profession and (profession.professionName .. " · " .. profession.skill .. " / " .. profession.cap .. " · " .. age(profession, time, snapshotAge))
            or "Professions · Open a crafting window and scan"
        rows[3] = market and ("Auction House · " .. market.status .. " · " .. age(market, time, marketAge)) or "Auction House · No browse observation"
        rows[4] = ledger and ("Ledger · " .. #ledger.entries .. " recorded changes this session") or "Ledger · Take a balance sample"
        if ledger and #ledger.entries > 0 then
            local entry = ledger.entries[#ledger.entries]
            rows[5] = string.format("Latest change · %+.0f copper · %s (%s)", entry.deltaCopper, entry.category, entry.confidence)
            actions[2] = { "Label other", function() GoldWiseLedgerCategorize(entry.observedAt, "other") end }
            actions[3] = { "Clear label", function() GoldWiseLedgerCategorize(entry.observedAt, "unclassified") end }
        end
        actions[1] = { "Sample balance", GoldWiseLedgerSample }
        actions[4] = { "Update my data", showGuide }
        actions[5] = { "Goals", function() tab, page, goalPanel = 5, 1, true end }
        actions[6] = { "Quick test", function() testPanel = true end }
    elseif tab == 2 then
        if materialsPanel then return materialsPage(time, inventory, plan) end
        actions[3] = { "Review materials", function() materialsPanel, page = true, 1 end }
        actions[1] = { "Scan bags", function()
            vendor, page = nil, 1
            GoldWiseInventoryScan()
        end }
        if not inventory then
            rows[1] = "No carried-bag observation yet. Open your bags, then choose Scan bags."
            return result
        end
        local recency, fresh = age(inventory, time, snapshotAge)
        rows[1] = "Carried bags · " .. inventory.status .. " · " .. recency
        rows[2] = "Bank and alts unobserved"
        local keys = sortedKeys(inventory.totals)
        if #keys == 0 then
            rows[3] = "No readable item stacks."
            return result
        end
        page = math.max(1, math.min(page, #keys))
        local id = keys[page]
        rows[3] = string.format("Item %d of %d · %s · %.0f observed in bags", page, #keys, name(id), inventory.totals[id])
        result.previous, result.next = page > 1, page < #keys
        if not fresh then
            rows[4] = "Bag observation expired. Choose Scan bags to refresh before planning."
            return result
        end
        local _, planFresh = age(plan, time, snapshotAge)
        local needed = planFresh and plan.inventory == inventory and plan.used[id]
        if needed and needed > 0 then
            rows[4] = string.format("Keep %.0f for My Plan · The current reagent plan uses these items.", needed)
        else
            rows[4] = "Plan use unknown · Review the item before selling."
        end
        if vendor and vendor.id == id and vendor.inventory == inventory then
            rows[5] = vendor.copper and string.format("Base vendor reference · %.0f copper · Item info", vendor.copper)
                or "Base vendor reference unavailable."
        end
        local free = addon.materialReservations.available(addon.reservationsFor(inventory), inventory.totals)
        if not free then
            rows[#rows + 1] = "Reservation counts unavailable. Clear holds or rescan bags."
        else
            local reserved = inventory.totals[id] - (free[id] or 0)
            if reserved > 0 then
                rows[#rows + 1] = string.format("%.0f reserved across session plans", reserved)
            end
        end
        actions[2] = { "Check vendor value", function()
            vendor = { id = id, inventory = inventory, copper = addon.vendorReference(id) }
        end }
    elseif tab == 3 then
        actions[1] = { "Scan profession", function()
            selection = 1
            GoldWiseProfessionScan()
        end }
        if addon.clientBuild == "70888" then
            actions[2] = { "Read trainer", GoldWiseTrainerSample }
            actions[3] = { "Match recipe", GoldWiseTrainerMatch }
        end
        if not profession then
            rows[1] = "No profession observation yet. Open native crafting, then choose Scan profession."
            return result
        end
        rows[1] = profession.professionName .. " · " .. profession.skill .. " / " .. profession.cap
        rows[2] = "Crafting window · " .. profession.recipeStatus .. " · " .. age(profession, time, snapshotAge)
        local requirement = scoped(addon.trainerRequirement)
        if requirement and addon.recipeCatalog then
            local viewOfRecipe = addon.recipeCatalogModel.read(addon.recipeCatalog, {
                build = addon.clientBuild, characterScope = profession.characterScope,
                professionId = profession.professionId, recipeId = requirement.recipeId,
                now = time, maxAge = snapshotAge,
            }, requirement)
            if viewOfRecipe and viewOfRecipe.trainer then
                local recency = age(viewOfRecipe.trainer, time, snapshotAge)
                rows[3] = string.format("Trainer · %s requires %s %.0f · %s", requirement.recipeName,
                    requirement.skillName, requirement.requiredSkill, recency)
            end
        end
        local recipes = profession.knownRecipes
        if #recipes == 0 then
            rows[#rows + 1] = "No learned recipes observed in this view."
            return result
        end
        selection = math.max(1, math.min(selection, #recipes))
        local recipe = recipes[selection]
        rows[#rows + 1] = string.format("Recipe %d of %d · %s", selection, #recipes, recipe.name or ("Recipe " .. recipe.id))
        rows[#rows + 1] = string.format("Plan for %d %s", crafts, crafts == 1 and "craft" or "crafts")
        result.previous, result.next = selection > 1, selection < #recipes
        if crafts > 1 then
            actions[4] = { "Fewer crafts", function() crafts = crafts - 1 end }
        end
        if crafts < 20 then
            actions[5] = { "More crafts", function() crafts = crafts + 1 end }
        end
        actions[6] = { "Plan reagents", function()
            local message = GoldWisePlanRecipe(recipe.id, crafts)
            if scoped(addon.recipePlan) then
                tab, page = 5, 1
            end
            return message
        end }
    elseif tab == 4 then
        if not market then
            actions[1] = { "Observe browse", function()
                view.frame:Hide()
                GoldWiseAuctionObserve()
            end }
            rows[1] = "Open the native Buy tab and choose Observe browse."
            rows[2] = "After GoldWise arms, run one native search."
            rows[3] = "Open GoldWise again and choose Observe browse within 60 seconds."
            return result
        end
        local recency, fresh = age(market, time, marketAge)
        rows[1] = "Browse cache · " .. market.status .. " · " .. recency
        rows[2] = "Asking prices · Sale proceeds and fees unavailable"
        if not fresh then
            rows[3] = "Browse cache is stale. /reload, then use Observe browse and a new native search."
            return result
        end
        if #market.rows == 0 then
            rows[3] = "No readable results in the observed cache."
        end
        rows[#rows + 1] = "Reload to collect another browse observation."
        result.previous, result.next = showRows(rows, #market.rows, function(index)
            local row = market.rows[index]
            return string.format("%s · level %.0f · minimum %.0f copper · qty %.0f", name(row.itemId),
                row.itemLevel, row.minimumCopper, row.reportedQuantity)
        end)
    elseif tab == 5 then
        if goalPanel then return goalPage(time, ledger, profession) end
        if professionReviewPanel then return professionReviewPage(time, profession, inventory, plan) end
        if capacityPanel then return capacityPage(time, inventory, plan) end
        actions[4] = { "Review progression", function() professionReviewPanel = true end }
        actions[3] = { "Goals", function() goalPanel = true end }
        actions[5] = { "Direct capacity", function() capacityPanel, page = true, 1 end }
        if not plan then
            rows[1] = "No current reagent plan. Open Professions, choose a learned recipe, then Plan reagents."
            actions[1] = { "Go to Professions", function()
                tab, selection, page = 3, 1, 1
            end }
            return result
        end
        local recency, fresh = age(plan, time, snapshotAge)
        rows[1] = "Reagent plan · " .. recency
        if not fresh or not inventory or inventory ~= plan.inventory then
            rows[2] = "Bag data changed or expired. Re-scan bags, then re-plan in Professions."
            actions[1] = { "Go to Inventory", function()
                tab, page = 2, 1
            end }
            actions[2] = { "Go to Professions", function()
                tab, selection, page = 3, 1, 1
            end }
            return result
        end
        local steps = {}
        for _, key in ipairs(sortedKeys(plan.missing)) do
            steps[#steps + 1] = string.format("Missing %.0f · %s", plan.missing[key], name(key))
        end
        if #steps == 0 then
            rows[2] = "All required reagents available for this plan."
        else
            rows[2] = "Acquire missing reagents before crafting."
        end
        for _, step in ipairs(plan.crafts) do
            steps[#steps + 1] = string.format("Craft %.0f × %s", step.count, step.name)
        end
        local byRecipe = addon.reservationsFor(inventory)
        if byRecipe[plan.recipeId] then
            rows[#rows + 1] = "This recipe has a session reservation."
        end
        for _, quantity in pairs(plan.used) do
            if quantity > 0 then
                actions[1] = { "Reserve carried reagents", function()
                    local _, current = age(plan, now(), snapshotAge)
                    if not current or not scoped(plan) then
                        return "Plan expired. Refresh your bags and recalculate."
                    end
                    return addon.reserveRecipePlan(plan)
                end }
                break
            end
        end
        if next(byRecipe) then
            actions[2] = { "Clear reservations", addon.clearReservations }
        end
        result.previous, result.next = showRows(rows, #steps, function(index) return steps[index] end)
    end
    return result
end

local function render()
    local content = state()
    view.title:SetText("GoldWise  /  " .. (guideStep and "Scan & Setup Guide" or goalPanel and "My Goals" or materialsPanel and "Material Review" or professionReviewPanel and "Profession Review" or capacityPanel and "Direct Capacity" or testPanel and "Quick Test" or tabs[tab]))
    local body = table.concat(content.rows, "\n"):gsub("|", "||")
    view.body:SetText(body)
    local message = (feedback or ""):gsub("|", "||")
    view.status:SetText(message)
    -- Selection must be visible; previously every tab used the same color.
    for index, control in ipairs(view.tabs) do
        control.background:SetColorTexture(unpack(index == tab and colors.selected or colors.surface))
        control.label:SetTextColor(unpack(index == tab and colors.gold or colors.text))
    end
    local navigationLabel = tab == 3 and "recipe"
        or tab == 2 and not materialsPanel and "item" or "page"
    view.previous.label:SetText("Previous " .. navigationLabel)
    view.next.label:SetText("Next " .. navigationLabel)
    if content.previous then view.previous:Show() else view.previous:Hide() end
    if content.next then view.next:Show() else view.next:Hide() end
    for index, button in ipairs(view.actions) do
        local action = content.actions[index]
        button.action = action and action[2]
        if action then
            button.label:SetText(action[1])
            -- Give the first contextual action visual priority without
            -- introducing unverified button templates or secure actions.
            button.background:SetColorTexture(unpack(index == 1 and colors.primary or colors.surface))
            button:Show()
        else
            button:Hide()
        end
    end
end

local function fill(parent, color)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(parent)
    texture:SetColorTexture(unpack(color))
    return texture
end

local function text(parent, template, color, horizontal, vertical)
    local label = parent:CreateFontString(nil, "OVERLAY", template)
    label:SetTextColor(unpack(color))
    label:SetJustifyH(horizontal)
    label:SetJustifyV(vertical)
    label:SetWordWrap(true)
    return label
end

local function button(parent, label, width, x, y, action)
    local control = CreateFrameWithOptions({ frameType = "Button", parent = parent })
    control:SetSize(width, 24)
    control:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    control.background = fill(control, colors.surface)
    control.label = text(control, "GameFontNormalSmall", colors.text, "CENTER", "MIDDLE")
    control.label:SetAllPoints(control)
    control.label:SetText(label)
    control.action = action
    control:SetScript("OnClick", function()
        if control.action then
            local ok, message = pcall(control.action)
            if ok then
                feedback = message
            else
                feedback = "Action unavailable. See chat for existing command status."
            end
            if parent:IsShown() then
                local rendered = pcall(render)
                if not rendered then
                    parent:Hide()
                    print("GoldWise dashboard unavailable.")
                end
            end
        end
    end)
    return control
end

local function build()
    local width = math.min(684, GetScreenWidth() - 24)
    local height = math.min(520, GetScreenHeight() - 24)
    if width < 430 or height < 420 then
        return nil
    end
    local frame = CreateFrameWithOptions({ frameType = "Frame", parent = UIParent, hidden = true })
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    fill(frame, colors.background)

    local title = text(frame, "GameFontNormalLarge", colors.gold, "LEFT", "MIDDLE")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12)
    title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -144, -38)
    button(frame, "Guide", 56, width - 132, -12, showGuide)
    button(frame, "Close", 56, width - 68, -12, function() frame:Hide() end)

    local tabWidth = (width - 48) / #tabs
    local tabButtons = {}
    for index, label in ipairs(tabs) do
        tabButtons[index] = button(frame, label, tabWidth, 16 + (index - 1) * (tabWidth + 4), -49, function()
            guideStep, tab, page, goalPanel, materialsPanel, professionReviewPanel, capacityPanel, testPanel = nil, index, 1, false, false, false, false, false
        end)
    end

    local body = text(frame, "GameFontNormal", colors.text, "LEFT", "TOP")
    body:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -88)
    body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 121)
    local status = text(frame, "GameFontNormalSmall", colors.muted, "LEFT", "TOP")
    status:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 16, 113)
    status:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 89)

    local function move(delta)
        if tab == 3 then
            selection = selection + delta
        else
            page = page + delta
        end
    end
    local previous = button(frame, "Previous", 106, 16, -(height - 83), function() move(-1) end)
    local following = button(frame, "Next", 106, 130, -(height - 83), function() move(1) end)
    local actions = {}
    local actionWidth = (width - 48) / 3
    for index = 1, 6 do
        local column = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        actions[index] = button(frame, "", actionWidth, 16 + column * (actionWidth + 8),
            -(height - 55 + row * 28))
    end
    return { frame = frame, title = title, body = body, status = status, tabs = tabButtons, actions = actions, previous = previous, next = following }
end

function GoldWiseOpen(command)
    local isGoalCommand = type(command) == "string"
        and (command == "goal" or command:match("^%s*goal%s+") ~= nil)
    if isGoalCommand then
        guideStep, goalPanel, materialsPanel, professionReviewPanel, capacityPanel, testPanel, tab, page = nil, true, false, false, false, false, 5, 1
        local request, reason = addon.goalCommands.parse(command)
        feedback = request and applyCustomGoal(request)
            or ("Invalid goal command (" .. (reason or "unknown") .. "). Use /goldwise goal help.")
    elseif command == "market" then
        guideStep, tab, page, goalPanel, materialsPanel, professionReviewPanel, capacityPanel, testPanel = nil, 4, 1, false, false, false, false, false
    elseif command == "inventory" then
        guideStep, tab, page, goalPanel, materialsPanel, professionReviewPanel, capacityPanel, testPanel = nil, 2, 1, false, false, false, false, false
    elseif command == "profession" then
        guideStep, tab, page, goalPanel, materialsPanel, professionReviewPanel, capacityPanel, testPanel = nil, 3, 1, false, false, false, false, false
    elseif command == "guide" then
        showGuide()
    elseif not guideOffered and addon.guidePreferences and not addon.guidePreferences.finished then
        showGuide()
    end
    guideOffered = true
    if not addon.supportedClient then
        print("GoldWise dashboard unavailable on this client build.")
        return
    end
    if not view then
        local ok, dashboard = pcall(build)
        if not ok or not dashboard then
            print("GoldWise dashboard unavailable. Existing chat commands are available.")
            return
        end
        view = dashboard
    end
    if view.frame:IsShown() and command ~= "guide" and command ~= "profession" and command ~= "inventory" and command ~= "market" and not isGoalCommand then
        view.frame:Hide()
        return
    end
    if pcall(render) then
        view.frame:Show()
    else
        print("GoldWise dashboard unavailable.")
    end
end

if type(SlashCmdList) == "table" and SlashCmdList.GOLDWISE == nil and SLASH_GOLDWISE1 == nil then
    SLASH_GOLDWISE1 = "/goldwise"
    SlashCmdList.GOLDWISE = GoldWiseOpen
end
