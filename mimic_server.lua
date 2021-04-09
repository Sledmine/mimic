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
blam = require "blam"

-- Mimic specific variables & depenencies
local core = require "mimic.core"

local aiList = {}
local tickJump = 4
local tickClock = 0

-- On tick function provided by default if needed
-- Be careful at handling data here, things can be messy

function OnTick()
    local player = blam.biped(get_dynamic_player(1))
    if (player and player.flashlightKey) then
        for playerIndex = 1, 4 do
            OnPlayerJoin(playerIndex)
        end
    end
    if (tickClock == tickJump) then
        for objectId, tagId in pairs(aiList) do
            local biped = blam.biped(get_object(objectId))
            if (biped) then
                if (biped.health <= 0) then
                    local killPacket = core.deletePacket(objectId)
                    rprint(1, killPacket)
                    rprint(2, killPacket)
                    rprint(3, killPacket)
                    rprint(4, killPacket)
                    -- Remove it from list
                    aiList[objectId] = nil
                else
                    local updatePacket = core.updatePacket(objectId, biped)
                    rprint(1, updatePacket)
                    rprint(2, updatePacket)
                    rprint(3, updatePacket)
                    rprint(4, updatePacket)
                end
            end
        end
        tickClock = 0
    end

    tickClock = tickClock + 1
end

function OnPlayerJoin(playerIndex)
    for objectId, tagId in pairs(aiList) do
        local spawnPacket = core.spawnPacket(tagId, objectId)
        rprint(playerIndex, spawnPacket)

    end
end

-- Put initialization code here
function OnScriptLoad()
    -- We can set up our event callbacks, like the onTick callback
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
end

-- Change biped tag =id from players and store their object ids
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    local tempTag = blam.getTag(tagId)
    if (tempTag and tempTag.class == blam.tagClasses.biped and playerIndex == 0) then
        --print("playerIndex: " .. playerIndex)
        --print("tagPath: " .. tempTag.path)
        --print("objectId: " .. objectId)
        aiList[objectId] = tagId
        local spawnPacket = core.spawnPacket(tagId, objectId)
        rprint(1, spawnPacket)
        rprint(2, spawnPacket)
        rprint(3, spawnPacket)
        rprint(4, spawnPacket)
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