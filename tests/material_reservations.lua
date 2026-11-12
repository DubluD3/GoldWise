local Reservations = dofile("data/MaterialReservations.lua")
local owned = { [100] = 5, [101] = 2 }
local byRecipe = {}
assert(Reservations.reserve(byRecipe, 41, { [100] = 3 }, owned))
assert(Reservations.available(byRecipe, owned)[100] == 2)
assert(Reservations.available(byRecipe, owned, 41)[100] == 5)
assert(Reservations.reserve(byRecipe, 42, { [100] = 2, [101] = 1 }, owned))
local before = byRecipe[42]
assert(not Reservations.reserve(byRecipe, 42, { [100] = 3, [101] = 2 }, owned))
assert(byRecipe[42] == before and Reservations.available(byRecipe, owned)[101] == 1)
assert(Reservations.reserve(byRecipe, 41, { [100] = 1 }, owned))
assert(Reservations.available(byRecipe, owned)[100] == 2 and owned[100] == 5)
print("PASS competing reservations never exceed bag counts and failed overrides are atomic")

byRecipe = {}
local many = { [100] = 20 }
for recipe = 1, 8 do
    assert(Reservations.reserve(byRecipe, recipe, { [100] = 1 }, many))
end
assert(not Reservations.reserve(byRecipe, 9, { [100] = 1 }, many))
assert(not Reservations.reserve(byRecipe, 1, { [100] = 0 }, many))
assert(Reservations.available(byRecipe, many)[100] == 12)
print("PASS reservations cap the number of plans and preserve existing allocations")

local malformed = {
    { [1] = { [100] = 6 }, [2] = { [100] = 6 } },
    { [1] = { [999] = 1 } },
    { [1] = { [100] = -1 } },
    { [1] = { [100] = 0 } },
    { [1] = {} },
    { ["bad"] = { [100] = 1 } },
    { [1] = { [100] = 1.5 } },
}
for _, held in ipairs(malformed) do
    local free, reason = Reservations.available(held, { [100] = 10 }, 1)
    assert(free == nil and type(reason) == "string")
end
local free, reason = Reservations.available({}, { [100] = -1 })
assert(free == nil and type(reason) == "string")
free, reason = Reservations.available({}, { ["bad"] = 1 })
assert(free == nil and type(reason) == "string")
free, reason = Reservations.available({}, { [100] = 3 }, 0)
assert(free == nil and type(reason) == "string")
local observed = { [100] = 10, [101] = 3 }
local holds = { [1] = { [100] = 4 }, [2] = { [100] = 2, [101] = 1 } }
free = assert(Reservations.available(holds, observed))
assert(free[100] == 4 and free[101] == 2)
free = assert(Reservations.available(holds, observed, 1))
assert(free[100] == 8 and free[101] == 2)
assert(holds[1][100] == 4 and observed[100] == 10)
print("PASS read-only availability fails closed on invalid holds while preserving safe same-recipe exclusions")
