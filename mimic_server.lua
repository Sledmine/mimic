-- SAPP Lua Script Boilerplate
-- Version 1.0
-- Every function uses lower camel case, be careful about naming conventions
-- Api version must be declared at the top
-- It helps lua-blam to detect if the script is made for SAPP or Chimera
api_version = "1.12.0.0"

-- Lua libraries
local inspect = require "inspect"
local json = require "json"

-- Halo Custom Edition specific libraries
local blam = require "blam"

-- On tick function provided by default if needed
-- Be careful at handling data here, things can be messy
function OnTick()
end

-- Put initialization code here
function OnScriptLoad()
    -- We can set up our event callbacks, like the onTick callback
    -- register_callback(cb['EVENT_TICK'], "OnTick")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
end

-- Change biped tag id from players and store their object ids
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    local tempTag = blam.getTag(tagId)
    if (tempTag and tempTag.class == blam.tagClasses.biped) then
        print("playerIndex: " .. playerIndex)
        print("tagPath: " .. tempTag.path)
        print("objectId: " .. objectId)
    end
    return true
end

-- Put cleanup code here
function OnScriptUnload()
end

-- This function is not mandatory, but if you want to log errors, use this
function OnError(Message)
end
