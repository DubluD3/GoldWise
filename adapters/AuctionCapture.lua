local _, addon = ...
local AuctionCapture = {}
local MAX_OBSERVATION_SECONDS = 60

local function readable(value)
    local checked, secret = pcall(issecretvalue, value)
    if checked and secret == false then
        return value
    end
end

local function read(api, ...)
    local succeeded, value = pcall(api, ...)
    if succeeded then
        return readable(value)
    end
end

local function browseVisible()
    local frame = readable(AuctionHouseFrame)
    local browse = frame and readable(frame.BrowseResultsFrame)
    return frame and browse and frame:IsVisible() and browse:IsVisible()
end

local function rowAt(rows, index)
    local info = readable(rows[index])
    if type(info) ~= "table" then
        return nil
    end
    local key = readable(info.itemKey)
    if type(key) ~= "table" then
        return nil
    end
    return {
        itemId = readable(key.itemID),
        itemLevel = readable(key.itemLevel),
        itemSuffix = readable(key.itemSuffix),
        battlePetSpeciesId = readable(key.battlePetSpeciesID),
        minimumCopper = readable(info.minPrice),
        reportedQuantity = readable(info.totalQuantity),
    }
end

function AuctionCapture.new(prefix, onObservation)
    local state = "idle"
    local armedAt
    local armedScope

    local function arm(now, characterScope)
        if type(EventUtil) ~= "table" then
            print(prefix .. "browse event registration unavailable.")
            return
        end
        local register = EventUtil.RegisterOnceFrameEventAndCallback
        local updated = pcall(register, "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", function()
            if state == "armed" then
                state = "updated"
                print(prefix .. "browse update observed. Run the command again once the results are visible.")
            end
        end)
        local failed = pcall(register, "AUCTION_HOUSE_BROWSE_FAILURE", function()
            if state == "armed" or state == "updated" then
                state = "failed"
                print(prefix .. "browse failed. Observation cancelled.")
            end
        end)
        local closed = pcall(register, "AUCTION_HOUSE_CLOSED", function()
            if state == "armed" or state == "updated" then
                state = "closed"
                print(prefix .. "Auction House closed. Observation cancelled.")
            end
        end)
        if updated and failed and closed then
            armedAt = now
            armedScope = characterScope
            state = "armed"
            print(prefix .. "armed, ready=yes. Make one search using Blizzard's Search button.")
        else
            state = "unavailable"
            print(prefix .. "browse event registration unavailable.")
        end
    end

    local function run(supportedBuild, characterScope)
        if not supportedBuild then
            print(prefix .. "client build unverified.")
            return
        end
        if type(characterScope) ~= "string" or #characterScope == 0 then
            print(prefix .. "character snapshot unavailable.")
            return
        end
        if type(issecretvalue) ~= "function" then
            print(prefix .. "secret-value guard unavailable.")
            return
        end
        if read(browseVisible) ~= true then
            print(prefix .. "browse window unavailable.")
            return
        end
        if state ~= "idle" and state ~= "armed" and state ~= "updated" then
            print(prefix .. "observation ended (" .. state .. "). Reload the UI to start another.")
            return
        end
        local auctions = C_AuctionHouse
        if type(auctions) ~= "table" then
            print(prefix .. "Auction House APIs unavailable.")
            return
        end
        local ready = read(auctions.IsThrottledMessageSystemReady)
        if ready ~= true then
            local status = ready == false and "no" or "unavailable"
            print(prefix .. "ready=" .. status .. ".")
            return
        end

        local now = read(GetServerTime)
        if type(now) ~= "number" or now < 1 or now >= 2 ^ 53 or now % 1 ~= 0 then
            print(prefix .. "timestamp unavailable.")
            return
        end
        if state == "idle" then
            arm(now, characterScope)
            return
        end
        if characterScope ~= armedScope then
            state = "scope changed"
            print(prefix .. "character scope changed. Observation cancelled.")
            return
        end
        if now < armedAt or now - armedAt > MAX_OBSERVATION_SECONDS then
            state = "expired"
            print(prefix .. "observation window expired.")
            return
        end
        if state == "armed" then
            print(prefix .. "waiting for a browse update.")
            return
        end

        state = "read"
        local observation, reason = addon.auctionObservationModel.capture(now, {
            rows = function() return read(auctions.GetBrowseResults) end,
            full = function() return read(auctions.HasFullBrowseResults) end,
            rowAt = rowAt,
        })
        if not observation then
            print(prefix .. reason .. ".")
            return
        end

        if onObservation then
            observation.characterScope = characterScope
            onObservation(observation)
        end

        print(prefix .. "ready=yes, cache=" .. observation.status .. ", rows=" .. observation.reportedRows
            .. ", observed rows=" .. #observation.rows .. ". Source: current browse cache.")
        local sample = observation.rows[1]
        if sample then
            print(prefix .. "sample browse minimum=" .. sample.minimumCopper .. " copper, reported quantity="
                .. sample.reportedQuantity .. ".")
        end
    end

    return run
end

addon.auctionCapture = AuctionCapture
