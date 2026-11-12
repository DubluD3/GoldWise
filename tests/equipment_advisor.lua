local Advisor = dofile("domain/EquipmentAdvisor.lua")
-- Entirely FICTIONAL item, characters, transfer route and restrictions.
local function clone(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = clone(v) end
    return out
end
local context = { build="70888", now=1000, maxAge=300 }
local owner = { scope="fictional-source", build="70888", realm="demo", faction="demo", observedAt=900 }
local target = {
    scope="fictional-alt", build="70888", realm="demo", faction="demo", observedAt=950,
    className="Mage", raceName="Human", level=30, proficiencies={ Cloth=true },
    equipmentObserved=true, knownItemIds={}
}
local item = {
    itemId=101, ownerScope=owner.scope, observedAt=940,
    binding="bind-on-equip", bound=false, requiredLevel=20,
    allowedClasses={"Mage"}, allowedRaces={"Human"}, requiredProficiency="Cloth", unique=false,
}
local transfer = {
    allowed=true, evidenceClass="OBSERVED-IN-GAME", evidenceReference="synthetic transfer fixture",
    fromScope=owner.scope, toScope=target.scope, build="70888", realm="demo", faction="demo", observedAt=940,
}
local function check(name, expected, mutate)
    local i, o, t, r, c=clone(item),clone(owner),clone(target),clone(transfer),clone(context)
    mutate(i,o,t,r,c)
    local verdict=Advisor.evaluate(i,o,t,r,c)
    assert(verdict.status==expected, name..": got "..tostring(verdict.status))
    return verdict
end
local good = check("known eligibility remains only potential", "potential-upgrade-review", function() end)
assert(good.certainty=="not-a-confirmed-upgrade" and good.lastSeenAt==950)
assert(good.action:find("review",1,true) and not good.confirmedUpgrade)
print("PASS source and alt constraints yield only a potential-review candidate")
for _,binding in ipairs({"soulbound","bind-on-pickup","quest"}) do
    check(binding, "blocked", function(i) i.binding=binding end)
end
check("BoE already bound", "blocked", function(i) i.bound=true end)
check("unidentified binding", "unknown", function(i) i.binding="unknown" end)
check("unverified bound status", "unknown", function(i) i.bound=nil end)
check("missing explicit transfer route", "unknown", function(i,o,t,r) r.allowed=false end)
check("unverified transfer route evidence", "unknown", function(i,o,t,r) r.evidenceClass="INFERRED" end)
check("transfer route owner mismatch", "unknown", function(i,o,t,r) r.toScope="other" end)
check("transfer route timestamp expired", "unknown", function(i,o,t,r) r.observedAt=1 end)
check("wrong source owner", "unknown", function(i) i.ownerScope="other" end)
print("PASS binding and unsupported transfer routes fail closed")
check("cross-realm", "blocked", function(i,o,t) t.realm="another" end)
check("cross-faction", "blocked", function(i,o,t) t.faction="another" end)
check("cross-build", "blocked", function(i,o,t) t.build="unverified" end)
check("same character", "unknown", function(i,o,t) t.scope=o.scope end)
check("stale target", "unknown", function(i,o,t) t.observedAt=100 end)
check("stale owner", "unknown", function(i,o) o.observedAt=100 end)
check("future item clock", "unknown", function(i) i.observedAt=1100 end)
print("PASS explicit build, realm, faction, provenance and age isolation")
check("level requirement", "blocked", function(i) i.requiredLevel=40 end)
check("unknown target level", "unknown", function(i,o,t) t.level=nil end)
check("wrong class", "blocked", function(i) i.allowedClasses={"Warrior"} end)
check("wrong race", "blocked", function(i) i.allowedRaces={"Orc"} end)
check("unverified class", "unknown", function(i) i.allowedClasses=nil end)
check("unverified race", "unknown", function(i) i.allowedRaces=nil end)
check("proficiency absent", "unknown", function(i,o,t) t.proficiencies.Cloth=nil end)
check("proficiency unknown", "unknown", function(i) i.requiredProficiency=nil end)
check("unique already held", "blocked", function(i,o,t) i.unique=true; t.knownItemIds[101]=true end)
check("unique unknown", "unknown", function(i) i.unique=true end)
check("unknown unique", "unknown", function(i) i.unique=nil end)
check("unobserved gear", "unknown", function(i,o,t) t.equipmentObserved=false end)
print("PASS eligibility, unique items and missing gear never claim a factual upgrade")
