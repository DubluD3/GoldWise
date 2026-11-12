local Materials = dofile("data/RecipeMaterials.lua")
local Choices = dofile("domain/ItemChoices.lua")
local C, B, O, D = 1001, 1002, 1003, 1004 -- FICTIONAL IDs: never live data.
local stock = { [C] = 100 }
local values = { [C] = 1, [B] = 3, [O] = 25, [D] = 4 } -- FICTIONAL copper.
local bolt = { recipeId = 1, name = "Synthetic bolt", itemId = B, quantity = 1,
    reagents = { { itemId = C, quantity = 2 } } }
local outfit = { recipeId = 2, name = "Synthetic outfit", itemId = O, quantity = 1,
    reagents = { { itemId = B, quantity = 5 } } }
local bandage = { recipeId = 3, name = "Synthetic bandage", itemId = D, quantity = 1,
    reagents = { { itemId = C, quantity = 2 } } }
local raw = Choices.vendor(100, values[C])
assert(raw.status == "vendor-reference" and raw.grossCopper == 100)
local crafted = Choices.craftVendor(outfit, 10, stock, {}, { [B] = bolt }, values, Materials.plan)
assert(crafted.status == "vendor-comparison-only")
assert(crafted.outputCount == 10 and crafted.plan.used[C] == 100)
assert(crafted.outputVendorReferenceCopper == 250 and crafted.consumedBagVendorReferenceCopper == 100)
assert(crafted.differenceVersusVendingInputsCopper == 150)
assert(next(crafted.plan.missing) == nil and #crafted.plan.crafts == 2)
local bandages = Choices.craftVendor(bandage, 50, stock, {}, {}, values, Materials.plan)
assert(bandages.outputCount == 50 and bandages.plan.used[C] == 100)
assert(bandages.differenceVersusVendingInputsCopper == 100)
local less = Choices.craftVendor(outfit, 9, stock, {}, { [B] = bolt }, values, Materials.plan)
assert(less.plan.used[C] == 90 and less.outputCount == 9)
print("PASS synthetic 100-cloth raw/vendor, bolt/downstream and bandage alternatives")
local blocked = Choices.craftVendor(outfit, 10, stock, { [C] = 20 }, { [B] = bolt }, values, Materials.plan)
assert(blocked.status == "missing-materials" and blocked.plan.missing[C] == 20)
assert(blocked.differenceVersusVendingInputsCopper == nil)
local invalid = Choices.craftVendor(outfit, 10, stock, { [C] = 101 }, { [B] = bolt }, values, Materials.plan)
assert(invalid.status == "unknown" and invalid.plan == nil)
print("PASS reservations block double allocation; excess reservations fail closed")
local noPrice = Choices.craftVendor(outfit, 10, stock, {}, { [B] = bolt }, { [C] = 1 }, Materials.plan)
assert(noPrice.status == "unknown" and noPrice.differenceVersusVendingInputsCopper == nil)
local cycle = { recipeId = 4, name = "Synthetic cycle", itemId = 555, quantity = 1,
    reagents = { { itemId = 556, quantity = 1 } } }
local reverse = { recipeId = 5, name = "Reverse synthetic cycle", itemId = 556, quantity = 1,
    reagents = { { itemId = 555, quantity = 1 } } }
assert(Choices.craftVendor(cycle, 1, stock, {}, { [556] = reverse, [555] = cycle },
    values, Materials.plan).status == "unknown")
print("PASS missing prices and cyclic recipes cannot produce fabricated margin")
local ctx = { marketKey = "fixture-market-A", now = 1000, maxAge = 300 }
local p = { marketKey = ctx.marketKey, source = "synthetic fixture", observedAt = 990,
    basis = "verified-per-unit-ask", unitCopper = 2000, complete = false }
local ask = Choices.auctionAsk(2, p, ctx)
assert(ask.status == "ask-only" and ask.grossAskCopper == 4000)
assert(ask.coverage == "partial observed results" and ask.hypotheticalAfterFeesCopper == nil)
local afterFees = Choices.auctionAsk(2, p, ctx,
    { verified = true, cutBasisPoints = 500, depositCopper = 40, listings = 1 })
assert(afterFees.hypotheticalAfterFeesCopper == 3760 and afterFees.cutCopper == 200)
assert(afterFees.totalDepositsCopper == 40 and afterFees.status == "ask-only")
assert(Choices.auctionAsk(2, p, ctx, { cutBasisPoints = 500, depositCopper = 40, listings = 1 })
    .hypotheticalAfterFeesCopper == nil)
print("PASS asking prices are not sale predictions; fee math requires explicit verified inputs")
local changed = { marketKey = "fixture-market-B", now = 1000, maxAge = 300 }
assert(Choices.auctionAsk(2, p, changed).status == "unknown")
assert(Choices.auctionAsk(2, p, { marketKey=ctx.marketKey, now=1400, maxAge=300 }).status == "unknown")
p.basis = "unverified browse minimum"
assert(Choices.auctionAsk(2, p, ctx).status == "unknown")
assert(Choices.vendor(2, nil).status == "unknown")
assert(Choices.vendor(2147483647, 9007199254740991).status == "unknown")
print("PASS cross-market, stale, unverified unit basis, missing prices and overflow fail closed")
