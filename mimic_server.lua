-- SAPP Lua Script Boilerplate
-- Version 1.0
-- Every function uses lower camel case, be careful about naming conventions
-- Api version must be declared at the top
-- It helps lua-blam to detect if the script is made for SAPP or Chimera
api_version = "1.12.0.0"
-- Bring compatibility with Lua 5.3
require "compat53"
print("Compatibility with Lua 5.3 has been loaded!")

-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Halo Custom Edition specific libraries
local blam = require "blam"

-- Mimic specific variables & depenencies
local core = require "mimic.core"

local aiList = {}
local tickClock = 0

-- On tick function provided by default if needed
-- Be careful at handling data here, things can be messy
function OnTick(playerIndex)
    local player = blam.biped(get_dynamic_player(1))
    if (player and player.flashlightKey) then
        execute_script("ai_kill encounter")
        -- execute_script("ai_place encounter")
        aiList = {}
    end

    if (tickClock == 5) then
        for index, objectId in pairs(aiList) do
            local biped = blam.biped(get_object(objectId))
            if (biped) then
                local bipedXEncoded = glue.string.tohex(string.pack("f", biped.x))
                rprint(1, "@u" .. bipedXEncoded .. biped.y .. biped.z)
            end
        end
        tickClock = 0
    end

    tickClock = tickClock + 1
end

-- Put initialization code here
function OnScriptLoad()
    -- We can set up our event callbacks, like the onTick callback
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
end

-- Change biped tag =id from players and store their object ids
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    local tempTag = blam.getTag(tagId)
    if (tempTag and tempTag.class == blam.tagClasses.biped and playerIndex == 0) then
        print("playerIndex: " .. playerIndex)
        print("tagPath: " .. tempTag.path)
        print("objectId: " .. objectId)
        glue.append(aiList, objectId)
        local spawnPacket = core.spawnPacket(tagId, objectId)
        rprint(1, spawnPacket)
    end
    return true
end

-- Put cleanup code here
function OnScriptUnload()
end

-- This function is not mandatory, but if you want to log errors, use this
function OnError(Message)
    print(debug.traceback())
end
