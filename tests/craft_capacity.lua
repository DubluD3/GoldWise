local Model = dofile("domain/CraftCapacity.lua")
local recipe={characterScope="A",observedAt=990,recipeId=7,itemId=90,quantity=1,
    reagents={{itemId=10,quantity=2},{itemId=11,quantity=1},{itemId=10,quantity=1}}}
local bag={characterScope="A",observedAt=990,status="complete",totals={[10]=17,[11]=10}}
local base={scope="A",now=1000,maxAge=900,recipe=recipe,inventory=bag,
    reservations={[7]={[10]=6},[8]={[10]=2,[11]=3}}}
local function check(p)
    local value={}
    for k,v in pairs(base) do value[k]=v end
    for k,v in pairs(p or {}) do value[k]=v end
    return Model.evaluate(value)
end
local a=check()
assert(a.status=="direct-reagent-coverage" and a.maxDirectCrafts==5)
assert(#a.rows==2 and a.rows[1].perCraft==3 and a.rows[1].available==15)
assert(a.rows[2].available==7 and a.caution:find("not craftability",1,true))
assert(bag.totals[10]==17)
print("PASS repeated reagents coalesce, other holds apply, own hold does not double count")
assert(check({reservations={}}).maxDirectCrafts==5)
assert(check({inventory={characterScope="A",observedAt=990,status="partial",totals=bag.totals}}).status=="unknown")
assert(check({scope="B"}).status=="unknown")
assert(check({now=2000}).status=="unknown")
assert(check({reservations={[8]={[10]=18}}}).status=="unknown")
assert(check({reservations={[8]={[999]=1}}}).status=="unknown")
assert(check({reservations={[8]={[10]=-1}}}).status=="unknown")
assert(check({reservations={[8]={[10]=0.5}}}).status=="unknown")
assert(check({recipe={characterScope="A",observedAt=990,recipeId=7,itemId=90,quantity=1,reagents={}}}).status=="unknown")
assert(check({recipe={characterScope="A",observedAt=990,recipeId=7,itemId=90,quantity=1,reagents={{itemId=10,quantity=2147483648}}}}).status=="unknown")
local sparse={characterScope="A",observedAt=990,status="complete",totals={[10]=1,[11]=1}}
assert(check({inventory=sparse}).maxDirectCrafts==0)
print("PASS stale, scope, impossible reservations and unsupported recipe fail closed")
