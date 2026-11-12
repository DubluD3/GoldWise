local Review = dofile("domain/MaterialReview.lua")
local bag={characterScope="char-A",status="complete",observedAt=950,totals={[10]=20,[11]=8,[12]=3}}
local plan={characterScope="char-A",observedAt=970,inventory=bag,recipeId=21,used={[10]=5,[11]=3},missing={}}
local function run(extra)
    local v={inventory=bag,characterScope="char-A",now=1000,maxAge=900,
        reservations={[21]={[10]=5},[22]={[10]=4,[11]=2}},plan=plan}
    if extra then for k,x in pairs(extra) do v[k]=x end end
    return Review.evaluate(v)
end
local result=run()
assert(result.status=="observed-plan" and #result.rows==3)
assert(result.rows[1].itemId==10 and result.rows[1].hold==9
    and result.rows[1].reviewQuantity==11 and result.rows[1].status=="hold-and-review")
assert(result.rows[2].itemId==11 and result.rows[2].hold==5 and result.rows[2].reviewQuantity==3)
assert(result.rows[3].itemId==12 and result.rows[3].hold==0 and result.rows[3].reviewQuantity==3
    and result.rows[3].status=="review-only")
assert(result.caution:find("not safe-to-sell",1,true))
assert(bag.totals[10]==20 and plan.used[10]==5)
print("PASS same-recipe holds counted once; inventory left untouched")
local noPlan=run({plan=false})
assert(noPlan.status=="review-only" and noPlan.planStatus=="unavailable-or-stale"
    and noPlan.rows[1].hold==9)
local noReservations=run({reservations={}})
assert(noReservations.rows[1].hold==5 and noReservations.rows[2].hold==3)
assert(run({characterScope="char-B"}).status=="unknown")
assert(run({now=1900}).status=="unknown")
assert(run({inventory={characterScope="char-A",status="partial",observedAt=950,totals={}}}).status=="unknown")
assert(run({reservations={[21]={[10]=21}}}).status=="unknown")
assert(run({reservations={[21]={[999]=1}}}).status=="unknown")
assert(run({reservations={[21]={[10]=-1}}}).status=="unknown")
assert(run({reservations={[21]={[10]=1.5}}}).status=="unknown")
assert(run({reservations={[21]={[10]=20},[22]={[10]=1}}}).status=="unknown")
print("PASS no plan, stale, partial, cross-character and impossible reservations")
local bad={characterScope="char-A",observedAt=970,inventory=bag,recipeId=21,used={[10]=21},missing={}}
assert(run({plan=bad}).status=="unknown")
local expired=run({plan={characterScope="char-A",observedAt=99,inventory=bag,recipeId=21,
    used={[10]=5},missing={}}})
assert(expired.status=="review-only" and expired.planStatus=="unavailable-or-stale")
print("PASS invalid and expired plans cannot invent availability")
