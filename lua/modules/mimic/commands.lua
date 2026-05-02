local luna = require "luna"
local scriptVersion = require "mimic.version"
local core = require "mimic.core"

return {
    debug = {
        description = "Enable or disable debug mode",
        help = "<enable> [<level>]",
        minArgs = 1,
        maxArgs = 2,
        func = function(enable, level)
            DebugMode = luna.bool(enable)
            DebugLevel = tonumber(level) or 1
            logger:muteDebug(not DebugMode)
            logger:info("Debug mode " .. (DebugMode and "enabled" or "disabled"))
        end
    },
    sync = {
        description = "Enable or disable sync mode",
        help = "<enable>",
        minArgs = 1,
        maxArgs = 1,
        func = function(enable)
            IsSyncEnabled = luna.bool(enable)
            logger:info("Sync mode " .. (IsSyncEnabled and "enabled" or "disabled"))
        end
    },
    collision = {
        description = "Enable or disable bipeds collision",
        help = "<enable>",
        minArgs = 1,
        maxArgs = 1,
        func = function(enable)
            DisablePlayerCollision = luna.bool(enable)
            logger:info("Bipeds collision " .. (DisablePlayerCollision and "disabled" or "enabled"))
        end
    },
    version = {
        description = "Prints the current version of Mimic",
        help = "",
        minArgs = 0,
        maxArgs = 0,
        func = function()
            Engine.core.consolePrint("{}", scriptVersion)
        end
    },
    erase_local_objects = {
        description = "Erase all locally created objects",
        help = "",
        minArgs = 0,
        maxArgs = 0,
        func = function()
            core.eraseNotServerControlledObjects()
            logger:info("Erased all locally created objects")
        end
    },
    override_items_system = {
        description = "Enable or disable overriding the items system (experimental)",
        help = "<enable>",
        minArgs = 1,
        maxArgs = 1,
        func = function(enable)
            IsItemsSystemOverridden = luna.bool(enable)
            logger:info("Items system override " .. (IsItemsSystemOverridden and "enabled" or "disabled"))
        end
    }
}