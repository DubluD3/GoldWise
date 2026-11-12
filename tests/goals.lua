local Goals = dofile("domain/Goals.lua")
local function copy(x)
    local a = {}
    for k,v in pairs(x) do a[k]=v end
    return a
end
local goal = assert(Goals.new({
    id = "fictional-1", characterScope = "fictional-scope", build = "70888",
    goldTargetCopper = 50000, professionId = 9, professionTargetSkill = 100
}))
local data = {
    now = 1000, maxAge = 300,
    money = { characterScope="fictional-scope", build="70888", observedAt=990, balanceCopper=25000 },
    profession = { characterScope="fictional-scope", build="70888", observedAt=990, professionId=9, skill=80 },
}
local first = Goals.evaluate(goal, data)
assert(first.status == "in-progress")
assert(first.gold.remainingCopper == 25000 and first.profession.remainingSkill == 20)
assert(#first.nextSteps == 2)
data.money = copy(data.money)
data.profession = copy(data.profession)
data.money.balanceCopper=52000
data.profession.skill=100
local final = Goals.evaluate(goal, data)
assert(final.status == "met" and final.gold.remainingCopper == 0)
assert(final.profession.remainingSkill == 0 and #final.nextSteps == 0)
assert(first.gold.remainingCopper == 25000) -- original result unchanged
print("PASS independent combined goal recalculation uses only observed snapshots")
local noMoney = { now=1000, maxAge=300, profession=data.profession }
local partial = Goals.evaluate(goal,noMoney)
assert(partial.status=="incomplete" and partial.gold.status=="unknown"
    and partial.profession.status=="met" and partial.gold.currentCopper==nil)
local stale = {now=1400,maxAge=300,money=data.money,profession=data.profession}
local expired = Goals.evaluate(goal,stale)
assert(expired.status=="incomplete" and expired.gold.status=="unknown"
    and expired.profession.status=="unknown")
local mismatched = {now=1000,maxAge=300,money=copy(data.money),profession=copy(data.profession)}
mismatched.money.characterScope="other"
mismatched.profession.professionId=100
local wrong = Goals.evaluate(goal,mismatched)
assert(wrong.status=="incomplete" and wrong.gold.status=="unknown"
    and wrong.profession.status=="unknown")
print("PASS absent, stale and cross-character/profession data abstain safely")
local goldOnly = assert(Goals.new({id="g", characterScope="s", build="b", goldTargetCopper=1}))
local professionOnly = assert(Goals.new({id="p", characterScope="s", build="b", professionId=4, professionTargetSkill=5}))
assert(goldOnly.professionId==nil and professionOnly.goldTargetCopper==nil)
local invalid = {
    {id="",characterScope="s",build="b",goldTargetCopper=1},
    {id="g",characterScope="s",build="b"},
    {id="g",characterScope="s",build="b",goldTargetCopper=-1},
    {id="g",characterScope="s",build="b",goldTargetCopper=1.5},
    {id="g",characterScope="s",build="b",professionTargetSkill=2},
    {id="g",characterScope="s",build="b",professionId=1,professionTargetSkill=1/0},
}
for _,request in ipairs(invalid) do assert(Goals.new(request)==nil) end
assert(Goals.evaluate(nil, data).status=="unknown")
print("PASS malformed targets and absent evidence never imply successful goals")
