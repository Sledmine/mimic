clua_version = 2.056

blam = require "blam"
objectClasses = blam.objectClasses
local core = require "mimic.core"

inspect = require "inspect"
local glue = require "glue"

-- Script config and variables
local blockServerBipeds = true
playerBipedTagId = nil
local aiList = {}
local aiSync = {}
local aiPending = {}
local debugMode = true

function OnMapLoad()
    aiList = {}
    aiSync = {}
    aiPending = {}
end

function printd(message, ...)
    if (debugMode) then
        if (not ...) then
            console_out(message)
        else
            console_out(string.format(message, ...))
        end
    end
end

function OnTick()
    local player = blam.biped(get_dynamic_player())
    if (player) then
        -- TODO Move this to a on load event or something
        playerBipedTagId = player.tagId
        -- console_out("P: " .. player.x .. " " .. player.y .. " " .. player.z)
    end
    for serverId, ai in pairs(aiPending) do
        local objectIndexCandidate = core.findSyncCandidate(ai, aiSync)
        if (objectIndexCandidate) then
            aiSync[objectIndexCandidate].synced = true
            aiList[serverId] = objectIndexCandidate
            printd("Found sync candidate for %s as %s", serverId, objectIndexCandidate)
            aiPending[serverId] = nil
        else
            printd("Error syncing %s", serverId)
        end
    end
    -- TODO Add validation for existing encounters on this map
    if (blockServerBipeds) then
        -- Filtering for objects that are being synced from the server
        for _, objectIndex in pairs(blam.getObjects()) do
            local object = blam.object(get_object(objectIndex))
            if (object) then
                if (object.type == objectClasses.biped and blam.isNull(object.playerId)) then
                    -- Prevent biped legs from being removed
                    -- This requires that no other AI uses the same biped as the player
                    local serverBipedObjectId = glue.index(aiList)[objectIndex]
                    if (object.tagId ~= playerBipedTagId and not serverBipedObjectId) then
                        -- object.isGhost = true
                        if (not aiSync[objectIndex]) then
                            aiSync[objectIndex] =
                                {x = object.x, y = object.y, z = object.z}
                        end
                        object.x = tonumber(aiSync[objectIndex].x)
                        object.y = tonumber(aiSync[objectIndex].y)
                        object.z = tonumber(aiSync[objectIndex].z)
                        -- printd("%s %s %s", object.x, object.y, object.z)
                        -- TODO Find a better way to hide bipeds from server
                        --[[object.x = 0
                        object.y = 0
                        object.z = 0]]
                    end
                end
            else
                aiSync[objectIndex] = nil
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
            printd(inspect(packet))
            printd("Packet %s size: %s", packetType, #message)
            local serverId = packet[2]
            local x = packet[3]
            local y = packet[4]
            local z = packet[5]
            local objectIndex = aiList[serverId]
            if (not objectIndex) then
                local objectIndexCandidate = core.findSyncCandidate({x = x, y = y, z = z})
                if (objectIndexCandidate) then
                    aiList[serverId] = objectIndexCandidate
                    printd("Found sync candidate for %s as %s", serverId,
                           objectIndexCandidate)
                else
                    aiPending[serverId] = {x = x, y = y, z = z}
                    printd("Error syncing %s", serverId)
                end
                --[[else
                local objectIndex = aiList[serverId]
                delete_object(objectIndex)
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
                printd("Respawning %s", tag.path)]]
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
                    biped.isGhost = false
                    biped.x = x
                    biped.y = y
                    biped.z = z
                    biped.vX = vX
                    biped.vY = vY
                    biped.animation = animation
                    biped.animationFrame = animationFrame
                    biped.zVel = 0.00001
                end
            else
                --printd("Biped %s does not exist", serverId)
            end
        elseif (packetType == "@k") then
            printd("Death")
            local serverId = packet[2]

            local objectIndex = aiList[serverId]
            if (objectIndex) then
                local biped = blam.biped(get_object(objectIndex))
                if (biped) then
                    biped.isGhost = true
                    biped.isHealthEmpty = true
                    biped.health = 0
                end
                delete_object(objectIndex)
                aiSync[objectIndex] = nil
            end

            -- FIXME A better way to stop tracking this object should be added
            -- Cleanup
            aiList[serverId] = nil
        end

        -- printd("Packet %s size: %s", packetType, #message)
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
