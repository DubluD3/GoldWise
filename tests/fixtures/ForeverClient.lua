local ForeverClient = {}

function ForeverClient.build(version, build, interface)
    return function()
        return version, build, "fixture build date", interface
    end
end

function ForeverClient.new(readBuild, registration)
    local client = { output = {}, buildReads = 0 }
    local subscriptions = {}
    local globals = {
        ipairs = ipairs,
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
                assert(subscriptions[event] == nil, "duplicate fixture event registration")
                subscriptions[event] = { callback = callback, argument = argument }
            end,
        }
    end

    function client:load(path, addonName, namespace)
        setfenv(assert(loadfile(path)), globals)(addonName, namespace)
    end

    function client:loadToc(path, addonName, namespace)
        for line in io.lines(path) do
            if line:match("^[^#%s]") then
                self:load(line:gsub("\\", "/"), addonName, namespace)
            end
        end
    end

    function client:fire(event, ...)
        local subscription = subscriptions[event]
        if subscription == nil then
            return false
        end
        if subscription.argument ~= nil and subscription.argument ~= select(1, ...) then
            return false
        end

        subscriptions[event] = nil
        subscription.callback(...)
        return true
    end

    return client
end

return ForeverClient
