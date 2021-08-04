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
local tickJump = 2
local tickClock = 0

local function broadcast(message)
    for playerIndex = 1, 16 do
        if (player_present(playerIndex)) then
            rprint(playerIndex, message)
        end
    end
end

local function send(playerIndex, message)
    rprint(playerIndex, message)
end

function OnTick()
    tickClock = tickClock + 1
    if (tickClock == tickJump) then
        tickClock = 0
        for serverObjectId, tagId in pairs(aiList) do
            local biped = blam.biped(get_object(serverObjectId))
            if (biped) then
                if (biped.health <= 0) then
                    local killPacket = core.deletePacket(serverObjectId)
                    broadcast(killPacket)
                    -- Biped is now dead, remove it from the list
                    aiList[serverObjectId] = nil
                else
                    for playerIndex = 1, 16 do
                        if (player_present(playerIndex)) then
                            local player = blam.biped(get_dynamic_player(playerIndex))
                            if (player) then
                                if (blam.isNull(player.vehicleObjectId)) then
                                    if (core.objectIsNearTo(player, biped, 30)) then
                                        cprint("Sending package to " .. playerIndex)
                                        local updatePacket = core.updatePacket(serverObjectId, biped)
                                        send(playerIndex, updatePacket)
                                    end
                                else
                                    local vehicle = blam.object(get_object(player.vehicleObjectId))
                                    if (vehicle and core.objectIsNearTo(vehicle, biped, 30)) then
                                        cprint("Sending package " .. playerIndex)
                                        local updatePacket = core.updatePacket(serverObjectId, biped)
                                        send(playerIndex, updatePacket)
                                    end
                                end
                            end
                        end
                    end
                end
            else
                -- This biped does not exist anymore on the server, so erase it
                aiList[serverObjectId] = nil
            end
        end
    end
end

function OnPlayerJoin(playerIndex)
    for objectId, tagId in pairs(aiList) do
        local spawnPacket = core.spawnPacket(tagId, objectId)
        rprint(playerIndex, spawnPacket)
    end
end

function OnGameEnd()
    aiList = {}
end

function IncreaseHealth()
    local lastAmount = 0
    for serverObjectId, tagId in pairs(aiList) do
        local biped = blam.biped(get_object(serverObjectId))
        if (biped and biped.health > 0) then
            biped.health = biped.health * 1.3
            lastAmount = biped.health
        end
    end
    say_all("Increasing AI health... " .. lastAmount)
    return true
end

-- Put initialization code here
function OnScriptLoad()
    timer(20000, "IncreaseHealth")
    OnGameEnd()
    -- We can set up our event callbacks, like the onTick callback
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_DIE"], "IncreaseHealth")
end

-- Change biped tag =id from players and store their object ids
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    local tempTag = blam.getTag(tagId)
    if (tempTag and tempTag.class == blam.tagClasses.biped and playerIndex == 0) then
        aiList[objectId] = tagId
        local spawnPacket = core.spawnPacket(tagId, objectId)
        broadcast(spawnPacket)
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
