local _, addon = ...
local prefix = "GoldWise trainer probe: "

function GoldWiseTrainerProbe_Sample()
    addon.trainerCapture.sample(prefix, "probe-session")
end

function GoldWiseTrainerProbe_Match()
    addon.trainerCapture.match(prefix, "probe-session")
end
