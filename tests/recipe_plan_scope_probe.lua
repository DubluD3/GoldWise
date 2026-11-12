local Fixture = dofile("tests/fixtures/ForeverClient.lua")
local client = Fixture.new()
local g = client.globals
g.math, g.next, g.tonumber = math, next, tonumber
local clock = 1000
g.GetServerTime = function() return clock end
g.issecretvalue = function(x) return x == "secret" end
local addon = {
    supportedClient=true, clientBuild="70888",
    characterSnapshot={scopeKey="A"},
    professionSnapshot={characterScope="A",professionId=21,observedAt=990},
    inventorySnapshot={characterScope="A",status="complete",observedAt=990,totals={[500]=0}},
}
local templates = {
    [101]={ professionId=21, recipeId=101, itemId=500, name="Synthetic component",quantity=1,reagents={{itemId=600,quantity=2}} },
    [102]={ professionId=21, recipeId=102, itemId=700, name="Synthetic A output",quantity=1,reagents={{itemId=500,quantity=1}} },
    [202]={ professionId=22, recipeId=202, itemId=800, name="Synthetic B output",quantity=1,reagents={{itemId=500,quantity=1}} },
}
local captures, observed = 0, {}
addon.recipeSchematic={ capture=function(id,professionId)
    local source=templates[id]
    if not source or source.professionId ~= professionId then return nil, "not learned" end
    captures=captures+1
    local fresh={}
    for k,v in pairs(source) do fresh[k]=v end
    return fresh
end }
addon.materialReservations={available=function(_,stock) return stock end}
addon.reservationsFor=function() return {} end
addon.recipeMaterials={plan=function(root,crafts,free,producers)
    local found=producers[500]
    observed[#observed+1]={root=root.recipeId,producer=found and found.recipeId or nil}
    return {used={}, missing={}, crafts={{recipeId=root.recipeId,name=root.name,count=crafts}}}
end}
client:load("adapters/RecipePlan.lua","GoldWise",addon)
local plan=g.GoldWisePlanRecipe
assert(plan(101,1)=="Reagent plan ready.")
assert(plan(102,1)=="Reagent plan ready.")
assert(observed[2].producer==101 and addon.recipePlan.professionId==21)
assert(addon.recipePlan.recipeSchematic.professionId==21)
print("PASS same manually scanned profession can reuse its verified cached producer")

-- Even the same profession rescanned is a new evidence boundary.
clock=1001
addon.professionSnapshot={characterScope="A",professionId=21,observedAt=clock}
assert(plan(102,1)=="Reagent plan ready.")
assert(observed[3].producer==nil)
assert(plan(101,1)=="Reagent plan ready.")
assert(plan(102,1)=="Reagent plan ready.")
assert(observed[5].producer==101)
print("PASS same-profession rescans reset old producer evidence")

clock=1002
addon.professionSnapshot={characterScope="A",professionId=22,observedAt=clock}
assert(plan(202,1)=="Reagent plan ready.")
assert(observed[6].producer==nil)
assert(addon.recipePlan.professionId==22 and addon.recipePlan.recipeSchematic.professionId==22)
print("PASS other professions never reuse foreign producer schematics")

clock=1003
addon.professionSnapshot={characterScope="A",professionId=21,observedAt=clock}
assert(plan(102,1)=="Reagent plan ready.")
assert(observed[7].producer==nil)
addon.clientBuild="70862"
assert(plan(102,1)=="Reagent plan ready.")
assert(observed[8].producer==nil)
clock=1004
addon.characterSnapshot={scopeKey="B"}
addon.professionSnapshot={characterScope="B",professionId=21,observedAt=clock}
addon.inventorySnapshot={characterScope="B",status="complete",observedAt=clock,totals={[500]=0}}
assert(plan(102,1)=="Reagent plan ready.")
assert(observed[9].producer==nil and addon.recipePlan.characterScope=="B")
print("PASS build and character switches invalidate cached producer sources")

clock=2000
local previous=captures
assert(plan(102,1):find("Profession scan is stale",1,true))
assert(captures==previous and addon.recipePlan==nil)
addon.professionSnapshot.observedAt=clock+1
assert(plan(102,1):find("Profession scan is stale",1,true))
assert(captures==previous)
addon.professionSnapshot.observedAt=clock
addon.inventorySnapshot.observedAt=1000
assert(plan(102,1):find("Bag counts are stale",1,true))
assert(captures==previous)
print("PASS stale/future profession and stale bag observations fail before schematic reads")
