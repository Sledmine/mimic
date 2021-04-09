clua_version = 2.056

local blam = require "blam"
objectClasses = blam.objectClasses
local core = require "mimic.core"

local inspect = require "inspect"
local glue = require "glue"

-- Script config and variables
local debugMode = false
local playerBipedTagId
local aiList = {}
local garbageCollectorCycle = 20000

function OnMapLoad()
    aiList = {}
end

function CleanBiped(serverId)
    console_out("Cleaning biped " .. serverId)
    local objectIndex = aiList[serverId]
    if (objectIndex and get_object(objectIndex)) then
        delete_object(objectIndex)
    end
    aiList[serverId] = nil
    return false
end

function OnTick()
    -- TODO Add validation for existing encounters on this map
    if (server_type == "dedicated") then
        local player = blam.biped(get_dynamic_player())
        if (player) then
            -- TODO Move this to a on load event or something
            playerBipedTagId = player.tagId
            -- console_out("P: " .. player.x .. " " .. player.y .. " " .. player.z)
        end
        -- Filtering for objects that are being synced from the server
        for _, objectIndex in pairs(blam.getObjects()) do
            local object = blam.object(get_object(objectIndex))
            if (object) then
                if (object.type == objectClasses.biped and blam.isNull(object.playerId)) then
                    -- Check if this object is already being synced
                    local serverBipedObjectId = glue.index(aiList)[objectIndex]
                    -- Prevent biped legs from being removed
                    -- This requires that no other AI uses the same biped as the player
                    if (object.tagId ~= playerBipedTagId) then
                        if (not serverBipedObjectId) then
                            -- TODO Find a better way to hide bipeds from server
                            object.x = 0
                            object.y = 0
                            object.z = 0
                            object.zVel = 0.00001
                            object.isGhost = true
                        end
                    end
                end
            end
        end
    end
end

function OnRcon(message)
    local packet = (glue.string.split(message, ","))
    -- This is a packet sent from the server script
    if (packet and packet[1]:find("@")) then
        local packetType = packet[1]
        if (packetType == "@s") then
            console_out(string.format("Packet %s size: %s", packetType, #message))

            local tagId = tonumber(packet[2])
            local serverId = packet[3]
            local tag = blam.getTag(tagId)
            if (not aiList[serverId]) then
                -- TODO Get somehow safe spawn coordinates 
                local player = blam.biped(get_dynamic_player()) or {x = 0, y = 0, z = 0}
                local bipedObjectId = spawn_object(tagId, player.x, player.y, player.z)
                if (bipedObjectId) then
                    -- Apply changes for AI
                    local biped = blam.biped(get_object(bipedObjectId))
                    if (biped) then
                        biped.x = 0
                        biped.y = 0
                        biped.z = 0
                        biped.isNotDamageable = true
                        local bipedObjectIndex = core.getIndexById(bipedObjectId)
                        aiList[serverId] = bipedObjectIndex
                    end
                end
                console_out(string.format("Spawning %s", tag.path))
            else
                local objectId = aiList[serverId]
                if (not get_object(objectId)) then
                    -- TODO Get somehow safe spawn coordinates 
                    local player = blam.biped(get_dynamic_player()) or
                                       {x = 0, y = 0, z = 0}
                    local bipedObjectId =
                        spawn_object(tagId, player.x, player.y, player.z)
                    if (bipedObjectId) then
                        console_out(string.format("Re-Spawning %s", tag.path))
                        -- Apply changes for AI
                        local biped = blam.biped(get_object(bipedObjectId))
                        if (biped and get_object(bipedObjectId) ~= get_dynamic_player()) then
                            biped.x = 0
                            biped.y = 0
                            biped.z = 0
                            biped.isNotDamageable = true
                            local bipedObjectIndex = core.getIndexById(bipedObjectId)
                            aiList[serverId] = bipedObjectIndex
                        end
                    end
                end

            end
        elseif (packetType == "@u") then
            local serverId = packet[2]

            local x = core.decode("f", packet[3])
            local y = core.decode("f", packet[4])
            local z = core.decode("f", packet[5])
            local animation = tonumber(packet[6])
            local animationFrame = tonumber(packet[7])
            local vX = core.decode("f", packet[8])
            local vY = core.decode("f", packet[9])

            local objectIndex = aiList[serverId]
            if (objectIndex) then
                local biped = blam.biped(get_object(objectIndex))
                if (biped) then
                    biped.x = x
                    biped.y = y
                    biped.z = z
                    biped.vX = vX
                    biped.vY = vY
                    biped.animation = animation
                    biped.animationFrame = animationFrame
                    biped.zVel = 0.00001
                end
            end
        elseif (packetType == "@k") then
            local serverId = packet[2]

            local objectIndex = aiList[serverId]
            if (objectIndex) then
                local biped = blam.biped(get_object(objectIndex))
                if (biped) then
                    biped.health = 0
                    biped.shield = 0
                    biped.isNotDamageable = false
                    biped.isHealthEmpty = true
                end
            end
            -- Cleanup
            set_timer(garbageCollectorCycle, "CleanBiped", serverId)
        end

        if (debugMode) then
            console_out(string.format("Packet %s size: %s", packetType, #message))
        end
        return false
    end
end

function OnCommand(command)
    if (command == "mdebug") then
        debugMode = not debugMode
        return false
    end
end

set_callback("map load", "OnMapLoad")
set_callback("command", "OnCommand")
set_callback("tick", "OnTick")
set_callback("rcon message", "OnRcon")
