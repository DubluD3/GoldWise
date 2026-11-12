local Fixture = dofile("tests/fixtures/ForeverClient.lua")
local client = Fixture.new()
local g = client.globals
local clock = 1000
g.GetServerTime = function() return clock end
g.issecretvalue = function(v) return v == "restricted" end
local addon = { supportedClient=true, clientBuild="70888" }
local character = { scopeKey="fixture:A" }
local profession = { characterScope="fixture:A", professionId=21, observedAt=990 }
local inventory = { characterScope="fixture:A", status="complete", observedAt=990, totals={[10]=7} }
addon.characterSnapshot=character
addon.professionSnapshot=profession
addon.inventorySnapshot=inventory
local calls=0
local model = dofile("data/MaterialReservations.lua")
addon.materialReservations = {reserve=function(...)
    calls=calls+1
    return model.reserve(...)
end}
client:load("adapters/ReservationSession.lua", "GoldWise", addon)
local plan = {
    build="70888", characterScope="fixture:A", professionSnapshot=profession,
    professionId=21, inventory=inventory, observedAt=995, recipeId=11, used={[10]=3},
}
addon.recipePlan=plan
local function refuse(old)
    local before=calls
    local reservations=addon.reservationsFor(inventory)
    local previous=reservations[11]
    local message=addon.reserveRecipePlan(old or plan)
    assert(type(message)=="string" and message ~= "Carried reagents reserved for this recipe.",message)
    assert(calls==before and reservations[11]==previous,"invalid plan mutated reservations")
end
assert(addon.reserveRecipePlan(plan)=="Carried reagents reserved for this recipe.")
assert(calls==1 and addon.reservationsFor(inventory)[11][10]==3)
print("PASS active current plan can reserve manual carried reagents")
local oldPlan=plan
local newer={} for k,v in pairs(plan) do newer[k]=v end
addon.recipePlan=newer
refuse(oldPlan)
addon.recipePlan=plan
local previous=profession
addon.professionSnapshot={characterScope="fixture:A",professionId=21,observedAt=990}
refuse()
addon.professionSnapshot=previous
addon.clientBuild="70862"
refuse()
addon.clientBuild="70888"
addon.characterSnapshot={scopeKey="fixture:B"}
refuse()
addon.characterSnapshot=character
addon.inventorySnapshot={characterScope="fixture:A",status="complete",observedAt=995,totals={[10]=7}}
refuse()
addon.inventorySnapshot=inventory
inventory.status="partial"
refuse()
inventory.status="complete"
print("PASS wrong active plan, profession scan, build, character and bags cannot reserve")
clock=1896
refuse()
clock=1000
inventory.observedAt=1001
refuse()
inventory.observedAt=990
profession.observedAt=1001
refuse()
profession.observedAt=990
plan.observedAt=1001
refuse()
plan.observedAt=995
g.GetServerTime=function() return "restricted" end
refuse()
g.GetServerTime=function() error("time API unavailable") end
refuse()
g.issecretvalue=nil
refuse()
print("PASS expired, future, secret or unavailable timestamps fail without mutations")
