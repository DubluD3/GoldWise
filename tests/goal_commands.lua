local Commands = dofile("domain/GoalCommands.lua")
local function good(cmd, kind, target)
    local value, reason = Commands.parse(cmd)
    assert(value and value.kind == kind and value.target == target, cmd .. ": " .. tostring(reason))
end
good("goal gold 25000", "gold", 25000)
good(" goal   gold  25000 ", "gold", 25000)
good("goal skill 75", "skill", 75)
good("goal gold 9007199254740991", "gold", 9007199254740991)
good("goal help", "help")
good("goal", "help")
good("goal clear", "clear")
print("PASS explicit arbitrary copper and skill targets, help and clear")
for _,bad in ipairs({
    "goal gold 0", "goal skill 0", "goal gold -1", "goal gold 1.5",
    "goal gold 1e5", "goal gold 12g", "goal gold 1,000",
    "goal gold 9007199254740992", "goal gold 999999999999999999",
    "goal gold 0001", "goal gold 01", "goal gold 1 2",
    "goal skill 2147483648", "goal skill 999999999999",
    "goal profession 75", "goal gold", "goal clear extra",
    "goal  gold  1  extra", string.rep("x",81),
}) do
    local value = Commands.parse(bad)
    assert(value == nil, "unexpected valid command " .. bad)
end
assert(Commands.parse(nil) == nil)
assert(Commands.parse({}) == nil)
assert(Commands.parse("guide") == nil)
print("PASS ambiguous, overflowing, invalid-unit and malformed input fail closed")
