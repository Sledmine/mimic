local balltze = Balltze
local engine = Engine
package.preload["luna"] = nil
package.loaded["luna"] = nil
require "luna"
local commands = require "mimic.commands"
local script = require "script"

DebugMode = false
DebugLevel = 1
IsSyncEnabled = true

local main
local isNewMap = true

function PluginMetadata()
    return {
        name = "Mimic",
        author = "Sledmine",
        --version = "4.1.0",
        version = require "mimic.version",
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
            script.poll()
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
        balltze.command.registerCommand(command, command, data.description, data.help,
                                        data.save or false, data.minArgs or 0, data.maxArgs or 0,
                                        false, true, function(args)
            -- logger:debug("{}", inspect(args))
            if (args and data.minArgs and data.maxArgs) and (#args < data.minArgs) or
                (#args > data.maxArgs) then
                logger:error("Invalid number of arguments. Usage: {}, Example: {}", data.help,
                             data.example)
                return true
            end
            --data.func(table.unpack(args or {}))
            local ok, message = pcall(data.func, table.unpack(args or {}))
            if not ok then
                logger:error("Error executing command \"{}\": {}", command, message)
            end
            return true
        end)
    end
    balltze.command.loadSettings()

    return true
end

function PluginUnload()
end
