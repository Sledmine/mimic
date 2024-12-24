local balltze = Balltze
local engine = Engine
package.preload["luna"] = nil
package.loaded["luna"] = nil
require "luna"
local commands = require "mimic.commands"

local main

function PluginMetadata()
    return {
        name = "Mimic",
        author = "Sledmine",
        version = "3.0.7",
        targetApi = "1.2.0",
        reloadable = true
    }
end

local isChimeraLoaded = false

local function loadChimeraCompatibility()
    -- Load Chimera compatibility
    for k, v in pairs(balltze.chimera) do
        if not k:includes "timer" and not k:includes "execute_script" and
            not k:includes "set_callback" then
            _G[k] = v
        end
    end
    server_type = engine.netgame.getServerType()

    -- Replace Chimera functions with Balltze functions
    write_bit = balltze.memory.writeBit
    write_byte = balltze.memory.writeInt8
    write_word = balltze.memory.writeInt16
    write_dword = balltze.memory.writeInt32
    write_int = balltze.memory.writeInt32
    write_float = balltze.memory.writeFloat
    write_string = function(address, value)
        for i = 1, #value do
            write_byte(address + i - 1, string.byte(value, i))
        end
        if #value == 0 then
            write_byte(address, 0)
        end
    end
    execute_script = engine.hsc.executeScript
end

DebugMode = false
DebugLevel = 1
local isNewMap = true
local main

function PluginLoad()
    logger = balltze.logger.createLogger("Mimic")
    logger:muteDebug(not DebugMode)

    balltze.event.mapLoad.subscribe(function(event)
        if event.time == "before" then
            isNewMap = true
        end
    end)

    balltze.event.tick.subscribe(function(event)
        if event.time == "after" then
            if not isChimeraLoaded and balltze.chimera then
                logger:debug("Chimera compatibility loaded")
                loadChimeraCompatibility()
                isChimeraLoaded = true
            end
            if isChimeraLoaded then
                if isNewMap then
                    if engine.map.getCurrentMapHeader().name == "ui" then
                        logger:debug("Restoring client side weapon projectiles")
                        engine.hsc.executeScript("allow_client_side_weapon_projectiles 1")
                    end
                    if main then
                        main.unload()
                        package.loaded["mimic.main"] = nil
                        -- Reset memoized values to prevent memory leaks
                        package.loaded["memoize"] = nil
                        for k, v in pairs(package.loaded) do
                            if k:startswith "mimic" then
                                package.loaded[k] = nil
                            end
                        end
                        main = nil
                    end
                    if not main then
                        main = require "mimic.main"
                    end
                    isNewMap = false
                end
            end
        end
    end)

    -- Register plugin commands
    for command, data in pairs(commands) do
        balltze.command.registerCommand(command, command, data.description, data.help, false,
                                        data.minArgs or 0, data.maxArgs or 0, false, true,
                                        function(...)
            local success, result = pcall(data.execute, table.unpack(...))
            if not success then
                logger:error("Error executing command '{}': {}", command, result)
                return false
            end
            return true
        end)
    end

    return true
end

function PluginUnload()
end
