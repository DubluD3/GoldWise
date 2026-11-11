local _, addon = ...
local tabs = { "Overview", "Inventory", "Professions", "Market", "My Plan" }
local colors = {
    background = { 21 / 255, 26 / 255, 34 / 255, 0.98 },
    surface = { 34 / 255, 43 / 255, 56 / 255, 1 },
    text = { 243 / 255, 245 / 255, 248 / 255 },
    muted = { 169 / 255, 181 / 255, 199 / 255 },
    gold = { 232 / 255, 193 / 255, 90 / 255 },
}
local pageSize = 6
local snapshotAge = 900
local marketAge = 300
local view
local tab, page, selection, crafts = 1, 1, 1, 1
local feedback
local vendor

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

local function state()
    local result = { rows = {}, actions = {} }
    local rows, actions = result.rows, result.actions
    local time = now()
    local inventory = scoped(addon.inventorySnapshot)
    local profession = scoped(addon.professionSnapshot)
    local market = scoped(addon.auctionObservation)
    local ledger = addon.ledgerView and addon.ledgerView()
    local plan = scoped(addon.recipePlan)

    if not addon.supportedClient then
        rows[1] = "This client build needs verification."
        return result
    end

    if tab == 1 then
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
    elseif tab == 2 then
        actions[1] = { "Scan bags", function()
            vendor, page = nil, 1
            GoldWiseInventoryScan()
        end }
        if not inventory then
            rows[1] = "Scan your bags to see carried items."
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
            rows[4] = "Refresh bag counts before using this item in a plan."
            return result
        end
        local _, planFresh = age(plan, time, snapshotAge)
        local needed = planFresh and plan.inventoryAt == inventory.observedAt and plan.used[id]
        if needed and needed > 0 then
            rows[4] = string.format("Keep %.0f for My Plan · The current reagent plan uses these items.", needed)
        else
            rows[4] = "Plan use unknown · Review the item before selling."
        end
        if vendor and vendor.id == id and vendor.at == inventory.observedAt then
            rows[5] = vendor.copper and string.format("Base vendor reference · %.0f copper · Item info", vendor.copper)
                or "Base vendor reference unavailable."
        end
        actions[2] = { "Check vendor value", function()
            vendor = { id = id, at = inventory.observedAt, copper = addon.vendorReference(id) }
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
            rows[1] = "Open your crafting window and scan the profession."
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
            rows[3] = "Reload to collect another browse observation."
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
        if not plan then
            rows[1] = "Choose a learned recipe under Professions and plan its reagents."
            return result
        end
        local recency, fresh = age(plan, time, snapshotAge)
        rows[1] = "Reagent plan · " .. recency
        if not fresh or not inventory or inventory.observedAt ~= plan.inventoryAt then
            rows[2] = "Bag data changed or expired. Recalculate the plan."
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
        result.previous, result.next = showRows(rows, #steps, function(index) return steps[index] end)
    end
    return result
end

local function render()
    local content = state()
    view.title:SetText("GoldWise  /  " .. tabs[tab])
    local body = table.concat(content.rows, "\n"):gsub("|", "||")
    view.body:SetText(body)
    local message = (feedback or ""):gsub("|", "||")
    view.status:SetText(message)
    if content.previous then view.previous:Show() else view.previous:Hide() end
    if content.next then view.next:Show() else view.next:Hide() end
    for index, button in ipairs(view.actions) do
        local action = content.actions[index]
        button.action = action and action[2]
        if action then
            button.label:SetText(action[1])
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
    fill(control, colors.surface)
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
    title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -76, -38)
    button(frame, "Close", 56, width - 68, -12, function() frame:Hide() end)

    local tabWidth = (width - 48) / #tabs
    for index, label in ipairs(tabs) do
        button(frame, label, tabWidth, 16 + (index - 1) * (tabWidth + 4), -49, function()
            tab, page = index, 1
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
    local previous = button(frame, "Previous", 76, 16, -(height - 83), function() move(-1) end)
    local following = button(frame, "Next", 76, 100, -(height - 83), function() move(1) end)
    local actions = {}
    local actionWidth = (width - 48) / 3
    for index = 1, 6 do
        local column = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        actions[index] = button(frame, "", actionWidth, 16 + column * (actionWidth + 8),
            -(height - 55 + row * 28))
    end
    return { frame = frame, title = title, body = body, status = status, actions = actions, previous = previous, next = following }
end

function GoldWiseOpen()
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
    if view.frame:IsShown() then
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
