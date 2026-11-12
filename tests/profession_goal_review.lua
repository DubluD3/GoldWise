local Model = dofile("domain/ProfessionGoalReview.lua")
local snap={characterScope="A",observedAt=990,professionId=21,skill=30,cap=60,
    recipeStatus="filtered",knownRecipes={{id=9,name="Fixture"}}}
local bag={characterScope="A",observedAt=990,status="complete",totals={[78]=4}}
local plan={characterScope="A",observedAt=995,inventory=bag,professionId=21,recipeId=9,missing={[78]=2}}
local goal={characterScope="A",build="70888",professionId=21,professionTargetSkill=45}
local input={characterScope="A",build="70888",now=1000,maxAge=900,
    profession=snap,inventory=bag,plan=plan,goal=goal}
local result=Model.evaluate(input)
assert(result.status=="review" and result.skill==30 and result.cap==60)
assert(result.observedCoverage=="filtered" and result.observedLearnedCount==1)
assert(result.goalStatus=="remaining" and result.remainingSkill==15)
assert(result.materialStatus=="missing-carried-inputs" and result.missingUnits==2)
assert(result.caution:find("No skill-up chance",1,true))
print("PASS goal and material shortfall distinguished without skill-up predictions")
local function with(changes)
    local x={} for k,v in pairs(input) do x[k]=v end
    for k,v in pairs(changes) do x[k]=v end
    return Model.evaluate(x)
end
assert(with({goal=false}).goalStatus=="no-skill-target")
assert(with({goal={characterScope="A",build="70888",professionId=22,professionTargetSkill=45}}).goalStatus=="different-profession")
assert(with({goal={characterScope="B",build="70888",professionId=21,professionTargetSkill=45}}).goalStatus=="no-skill-target")
assert(with({goal={characterScope="A",build="70888",professionId=21,professionTargetSkill=20}}).goalStatus=="reached")
assert(with({plan=false}).materialStatus=="unobserved")
assert(with({inventory={characterScope="A",observedAt=990,status="partial"}}).materialStatus=="unknown-or-stale")
assert(with({now=1900}).status=="unknown")
assert(with({characterScope="B"}).status=="unknown")
assert(with({plan={characterScope="A",observedAt=995,inventory=bag,professionId=22,recipeId=9,missing={}}}).materialStatus=="unknown-or-stale")
assert(with({plan={characterScope="A",observedAt=995,inventory=bag,professionId=21,recipeId=9,missing={[78]=-1}}}).materialStatus=="invalid-plan")
print("PASS missing, stale, cross-character and mismatched profession fail closed")
