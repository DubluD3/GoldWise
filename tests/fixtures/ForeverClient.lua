local ForeverClient = {}

function ForeverClient.build(version, build, interface)
    return function()
        return version, build, "fixture build date", interface
    end
end

function ForeverClient.new(readBuild, registration)
    local client = { output = {}, buildReads = 0 }
    local onLoaded
    local expectedName
    local globals = {
        pairs = pairs,
        pcall = pcall,
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
            RegisterOnceFrameEventAndCallback = function(event, callback, addonName)
                assert(event == "ADDON_LOADED", "unexpected fixture event: " .. tostring(event))
                if registration == "fails" then
                    error("registration unavailable")
                end
                assert(onLoaded == nil, "duplicate ADDON_LOADED registration")
                onLoaded = callback
                expectedName = addonName
            end,
        }
    end

    function client:load(path, addonName, namespace)
        setfenv(assert(loadfile(path)), globals)(addonName, namespace)
    end

    function client:fireAddonLoaded(addonName)
        if onLoaded == nil or expectedName ~= addonName then
            return false
        end

        local callback = onLoaded
        onLoaded = nil
        callback(addonName, false)
        return true
    end

    return client
end

return ForeverClient
