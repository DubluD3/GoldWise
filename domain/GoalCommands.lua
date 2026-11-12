local _, addon = ...
local Commands = {}
local MAX_COPPER = 9007199254740991
local MAX_SKILL = 2147483647

local function positiveDecimal(raw, maximum)
    if type(raw) ~= "string" or #raw == 0 or #raw > 16
        or not raw:match("^[1-9]%d*$") then return nil end
    local number = tonumber(raw)
    if type(number) ~= "number" or number < 1 or number > maximum
        or number % 1 ~= 0 then return nil end
    -- Only numbers that round-trip exactly are accepted (avoids precision loss).
    if string.format("%.0f", number) ~= raw:gsub("^0+", "") then
        return nil
    end
    return number
end

-- Explicit player chat input, with copper (not gold) as the monetary unit.
-- No game API, text box, network, or automatic gameplay interaction.
function Commands.parse(command)
    if type(command) ~= "string" or #command > 80 then
        return nil, "invalid-goal-command"
    end
    local words = {}
    for part in command:gmatch("%S+") do
        words[#words+1] = part
        if #words > 4 then return nil, "invalid-goal-command" end
    end
    if words[1] ~= "goal" then return nil, "not-goal-command" end
    if #words == 1 or (#words == 2 and words[2] == "help") then
        return {kind="help"}
    end
    if #words == 2 and words[2] == "clear" then
        return {kind="clear"}
    end
    if #words ~= 3 then return nil, "invalid-goal-command" end
    if words[2] == "gold" then
        local amount = positiveDecimal(words[3], MAX_COPPER)
        if not amount then return nil, "invalid-copper-target" end
        return {kind="gold", target=amount}
    end
    if words[2] == "skill" then
        local level = positiveDecimal(words[3], MAX_SKILL)
        if not level then return nil, "invalid-skill-target" end
        return {kind="skill", target=level}
    end
    return nil, "invalid-goal-command"
end

if addon then addon.goalCommands = Commands end
return Commands
