local ForeverClient = {}

function ForeverClient.build(version, build, interface)
    return function()
        return version, build, "fixture build date", interface
    end
end

function ForeverClient.new(readBuild, registration)
    local client = { output = {}, buildReads = 0 }
    local eventCallback
    local registeredEvent
    local expectedArgument
    local globals = {
        pairs = pairs,
        pcall = pcall,
        string = string,
        table = table,
        type = type,
        print = function(message)
            client.output[#client.output + 1] = message
        end,
    }
    client.globals = globals

    if readBuild then
        globals.GetBuildInfo = function()
            client.buildReads = client.buildReads + 1
            return readBuild()
        end
    end
    if registration ~= "missing" then
        globals.EventUtil = {
            RegisterOnceFrameEventAndCallback = function(event, callback, argument)
                assert(event == "ADDON_LOADED" or event == "PLAYER_ENTERING_WORLD", "unexpected fixture event")
                if registration == "fails" then
                    error("registration unavailable")
                end
                assert(eventCallback == nil, "duplicate fixture event registration")
                eventCallback = callback
                registeredEvent = event
                expectedArgument = argument
            end,
        }
    end

    function client:load(path, addonName, namespace)
        setfenv(assert(loadfile(path)), globals)(addonName, namespace)
    end

    function client:fire(event, ...)
        if eventCallback == nil or event ~= registeredEvent then
            return false
        end
        if expectedArgument ~= nil and expectedArgument ~= select(1, ...) then
            return false
        end

        local callback = eventCallback
        eventCallback = nil
        callback(...)
        return true
    end

    return client
end

return ForeverClient
