local AuctionObservation = {}
local MAX_ROWS = 128
local MAX_INTEGER = 2 ^ 53 - 1

local function integer(value, minimum)
    return type(value) == "number" and value >= minimum and value <= MAX_INTEGER and value % 1 == 0
end

local function usable(row)
    return type(row) == "table"
        and integer(row.itemId, 1)
        and integer(row.itemLevel, 0)
        and integer(row.itemSuffix, -MAX_INTEGER)
        and integer(row.battlePetSpeciesId, 0)
        and integer(row.minimumCopper, 1)
        and integer(row.reportedQuantity, 1)
end

-- The caller establishes the visible browse context, readiness, and user trigger.
function AuctionObservation.capture(observedAt, reader)
    if not integer(observedAt, 1) then
        return nil, "timestamp unavailable"
    end

    local rows = reader.rows()
    if type(rows) ~= "table" then
        return nil, "browse cache unavailable"
    end
    local full = reader.full()
    local observation = {
        source = "wow-ah-browse-cache",
        observedAt = observedAt,
        reportedRows = #rows,
        rows = {},
        status = "partial",
    }
    local count = #rows
    if count > MAX_ROWS then
        count = MAX_ROWS
    elseif full == true then
        observation.status = "complete"
    end

    for index = 1, count do
        local row = reader.rowAt(rows, index)
        if usable(row) then
            observation.rows[#observation.rows + 1] = row
        else
            observation.status = "partial"
        end
    end
    return observation
end

function AuctionObservation.copyForHistory(observation)
    if type(observation) ~= "table" or observation.source ~= "wow-ah-browse-cache"
        or not integer(observation.observedAt, 1) or not integer(observation.reportedRows, 0)
        or (observation.status ~= "partial" and observation.status ~= "complete")
        or type(observation.rows) ~= "table" then
        return nil
    end

    local rows = observation.rows
    local count = #rows
    if count > MAX_ROWS or count > observation.reportedRows
        or (observation.status == "complete" and count ~= observation.reportedRows) then
        return nil
    end
    for index in pairs(rows) do
        if not integer(index, 1) or index > count then
            return nil
        end
    end

    local copy = {
        source = observation.source,
        observedAt = observation.observedAt,
        reportedRows = observation.reportedRows,
        status = observation.status,
        rows = {},
    }
    for index = 1, count do
        local row = rows[index]
        if not usable(row) then
            return nil
        end
        copy.rows[index] = {
            itemId = row.itemId,
            itemLevel = row.itemLevel,
            itemSuffix = row.itemSuffix,
            battlePetSpeciesId = row.battlePetSpeciesId,
            minimumCopper = row.minimumCopper,
            reportedQuantity = row.reportedQuantity,
        }
    end
    return copy
end

local _, addon = ...
if addon then
    addon.auctionObservationModel = AuctionObservation
end

return AuctionObservation
