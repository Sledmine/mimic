local luna = require "luna"
local scriptVersion = require "mimic.version"

return {
    debug = {
        description = "Enable or disable debug mode",
        help = "<enable> [<level>]",
        execute = function(enable, level)
            DebugMode = luna.bool(enable)
            DebugLevel = tonumber(level) or 1
            logger:muteDebug(not DebugMode)
            logger:info("Debug mode " .. (DebugMode and "enabled" or "disabled"))
        end
    },
    sync = {
        description = "Enable or disable sync mode",
        help = "<enable>",
        execute = function(enable)
            IsSyncEnabled = luna.bool(enable)
            logger:info("Sync mode " .. (IsSyncEnabled and "enabled" or "disabled"))
        end
    },
    collision = {
        description = "Enable or disable bipeds collision",
        help = "<enable>",
        execute = function(enable)
            DisablePlayerCollision = luna.bool(enable)
            logger:info("Bipeds collision " .. (DisablePlayerCollision and "disabled" or "enabled"))
        end
    },
    version = {
        description = "Prints the current version of Mimic",
        help = "",
        execute = function()
            console_out("Mimic version " .. scriptVersion)
        end
    }
}