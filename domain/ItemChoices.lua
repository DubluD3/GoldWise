local _, addon = ...
local Choices = {}
local LIMIT = 2147483647
local EXACT = 9007199254740991

local function integer(value, minimum, maximum)
    return type(value) == "number" and value % 1 == 0 and value >= minimum
        and value <= (maximum or EXACT)
end

local function mul(a, b)
    if not integer(a, 0) or not integer(b, 0) or (a > 0 and b > math.floor(EXACT / a)) then
        return nil
    end
    return a * b
end

function Choices.vendor(quantity, unitCopper)
    if not integer(quantity, 1, LIMIT) or not integer(unitCopper, 0) then
        return { status = "unknown", reason = "verified unit vendor reference unavailable" }
    end
    local amount = mul(quantity, unitCopper)
    if not amount then return { status = "unknown", reason = "amount overflow" } end
    return {
        status = "vendor-reference", basis = "unit vendor price reference",
        quantity = quantity, grossCopper = amount,
        caution = "Compare the actual vendor quote before selling. GoldWise will not sell items.",
    }
end

-- The current Forever browse cache has NOT established a reliable per-unit
-- price basis, market discriminator, or fee model; it must not feed this path.
-- This contract is available for synthetic fixtures and future verified adapters.
function Choices.auctionAsk(quantity, observation, context, fees)
    local unknown = { status = "unknown", reason = "validated, scoped, fresh per-unit ask unavailable" }
    if not integer(quantity, 1, LIMIT) or type(observation) ~= "table"
        or type(context) ~= "table" or type(observation.source) ~= "string" or #observation.source == 0
        or observation.basis ~= "verified-per-unit-ask"
        or type(context.marketKey) ~= "string" or #context.marketKey == 0
        or observation.marketKey ~= context.marketKey
        or not integer(context.now, 1) or not integer(context.maxAge, 1)
        or not integer(observation.observedAt, 1) or observation.observedAt > context.now
        or context.now - observation.observedAt > context.maxAge
        or not integer(observation.unitCopper, 1) then
        return unknown
    end

    local gross = mul(quantity, observation.unitCopper)
    if not gross then return { status = "unknown", reason = "amount overflow" } end
    local result = {
        status = "ask-only", source = observation.source,
        observedAt = observation.observedAt, marketKey = context.marketKey,
        coverage = observation.complete == true and "observed results" or "partial observed results",
        quantity = quantity, grossAskCopper = gross,
        hypotheticalAfterFeesCopper = nil,
        caution = "Asking prices do not establish a sale, buyer demand, or expected proceeds.",
    }

    if type(fees) == "table" and fees.verified == true
        and integer(fees.cutBasisPoints, 0, 10000) and integer(fees.depositCopper, 0)
        and integer(fees.listings, 1, LIMIT) then
        local product = mul(gross, fees.cutBasisPoints)
        local deposits = mul(fees.depositCopper, fees.listings)
        if product and deposits then
            local cut = math.ceil(product / 10000)
            local remaining = gross - cut - deposits
            result.cutCopper, result.totalDepositsCopper = cut, deposits
            result.hypotheticalAfterFeesCopper = remaining
            result.feeNote = "Hypothetical if every listed item sells; no sale probability modeled."
        end
    end
    return result
end

local function available(owned, reserved)
    if type(owned) ~= "table" or type(reserved) ~= "table" then
        return nil, "stock or reservations unavailable"
    end
    local free = {}
    for item, count in pairs(owned) do
        if not integer(item, 1) or not integer(count, 0, LIMIT) then
            return nil, "invalid observed stock"
        end
        free[item] = count
    end
    for item, count in pairs(reserved) do
        if not integer(item, 1) or not integer(count, 0, LIMIT) or count > (free[item] or 0) then
            return nil, "invalid or excessive reservation"
        end
        free[item] = free[item] - count
    end
    return free
end

-- Uses the existing bounded recipe graph; recipes and unit prices must be
-- supplied by a verified source (or synthetic tests). No client APIs here.
function Choices.craftVendor(root, crafts, owned, reserved, producers, vendorUnits, planner)
    local result = { status = "unknown", reason = "verified recipe and values unavailable" }
    if type(root) ~= "table" or not integer(root.itemId, 1)
        or not integer(root.quantity, 1, LIMIT) or type(root.reagents) ~= "table"
        or not integer(crafts, 1, LIMIT) or type(producers) ~= "table"
        or type(vendorUnits) ~= "table" or type(planner) ~= "function" then
        return result
    end
    local free, reason = available(owned, reserved)
    if not free then return { status = "unknown", reason = reason } end
    local ok, plan, err = pcall(planner, root, crafts, free, producers)
    if not ok or not plan then
        return { status = "unknown", reason = ok and (err or "recipe planning unavailable") or "recipe planning error" }
    end
    for _, quantity in pairs(plan.missing) do
        if quantity > 0 then
            return { status = "missing-materials", plan = plan,
                reason = "Some inputs are unavailable after reservations. No margin is calculated." }
        end
    end
    local productCount = mul(root.quantity, crafts)
    local output = productCount and Choices.vendor(productCount, vendorUnits[root.itemId])
    if not output or output.status ~= "vendor-reference" then
        return { status = "unknown", plan = plan, reason = "output vendor reference unavailable" }
    end
    local cost = 0
    for id, quantity in pairs(plan.used) do
        if quantity > 0 then
            local alternative = Choices.vendor(quantity, vendorUnits[id])
            if alternative.status ~= "vendor-reference" or cost + alternative.grossCopper > EXACT then
                return { status = "unknown", plan = plan,
                    reason = "material vendor opportunity cost unavailable" }
            end
            cost = cost + alternative.grossCopper
        end
    end
    return {
        status = "vendor-comparison-only", plan = plan,
        outputItemId = root.itemId, outputCount = productCount,
        outputVendorReferenceCopper = output.grossCopper,
        consumedBagVendorReferenceCopper = cost,
        differenceVersusVendingInputsCopper = output.grossCopper - cost,
        caution = "A reference comparison, not realized profit; excludes effort and unverified costs.",
    }
end

if addon then addon.itemChoices = Choices end
return Choices
