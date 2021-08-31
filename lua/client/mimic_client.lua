------------------------------------------------------------------------------
-- Mimic Client
-- Sledmine (https://github.com/Sledmine)
-- Client side synchronization feature for AI
------------------------------------------------------------------------------
clua_version = 2.056

local blam = require "blam"
objectClasses = blam.objectClasses
local core = require "mimic.core"

local inspect = require "inspect"
local glue = require "glue"

-- Script setting variables (do not modify them manually)
debugMode = false
local lastMapName
local enableSync = false
local asyncMode = false
local disablePlayerCollision = false
local bipedCleaner = true
local bipedCleanerCycle = 30000

-- State
local queuePackets = {}
local aiList = {}
local aiCollection = {}

function dprint(message, ...)
    if (debugMode) then
        if (...) then
            console_out(string.format(message, ...))
            return
        end
        console_out(message)
        return
    end
end

function OnMapLoad()
    queuePackets = {}
    aiList = {}
end

function CleanBipeds(serverId)
    execute_script("ai_erase_all")
    dprint("Cleaning biped %s", serverId)
    local data = aiList[serverId]
    if (data) then
        local objectId = data.objectId
        if (objectId and get_object(objectId)) then
            delete_object(objectId)
        end
    end
    aiCollection[serverId] = nil
    aiList[serverId] = nil
    return false
end

function ProcessPacket(message, packetType, packet)
    -- Enable synchronization only when the server sent a mimic packet
    if (not enableSync) then
        enableSync = true
        -- As this is now syncing, we need to stop projectiles duplication on the client
        -- FIXME Create a packet to ask the client to stop creating projectiles
    end
    local time = os.clock()
    -- dprint("Packet %s size: %s", packetType, #message)
    if (packetType == "@s") then
    -- TODO Add some kind of validation to prevent spamming this commands
        dprint("Disabling client side projectiles...")
        execute_script("allow_client_side_weapon_projectiles 0")
        execute_script("ai_erase_all")
        local tagId = tonumber(packet[2])
        local serverId = packet[3]
        aiList[serverId] = {
            tagId = tagId,
            objectId = nil,
            objectIndex = nil,
            -- TODO Add biped removal after a large amount of time without an update
            timeSinceLastUpdate = time
        }
        dprint("Registering %s with tagId %s", serverId, tagId)
    elseif (packetType == "@u") then
        local serverId = packet[2]

        local x = core.decode("f", packet[3])
        local y = core.decode("f", packet[4])
        local z = core.decode("f", packet[5])
        local animation = tonumber(packet[6])
        local animationFrame = tonumber(packet[7])
        local vX = core.decode("f", packet[8])
        local vY = core.decode("f", packet[9])

        local data = aiList[serverId]
        if (data) then
            local tagId = data.tagId
            local objectId = data.objectId
            if (objectId) then
                if (not core.updateBiped(objectId, x, y, z, vX, vY, animation, animationFrame)) then
                    core.log("Warning, server biped %s, &s update mismatch!", serverId, objectId)
                    aiList[serverId].objectId = core.syncBiped(tagId, x, y, z, vX, vY, animation,
                                                               animationFrame)
                end
            else
                aiList[serverId].objectId = core.syncBiped(tagId, x, y, z, vX, vY, animation,
                                                           animationFrame)
            end
        end
    elseif (packetType == "@k") then
        local serverId = packet[2]

        local data = aiList[serverId]
        -- TODO Check if an action needs to be taken if no biped exists at dying
        if (data) then
            local objectId = data.objectId
            if (objectId) then
                local biped = blam.biped(get_object(objectId))
                if (biped) then
                    biped.health = 0
                    biped.shield = 0
                    biped.isFrozen = false
                    biped.isNotDamageable = false
                    biped.isHealthEmpty = true
                    -- biped.animationFrame = 0
                end
                dprint("Killing biped %s", serverId)
            end
            -- Cleanup
            if (bipedCleaner) then
                if (not aiCollection[serverId]) then
                    aiCollection[serverId] = set_timer(bipedCleanerCycle, "CleanBipeds", serverId)
                end
            else
                CleanBipeds(serverId)
            end
        end
    end
    -- dprint("Packet processed, elapsed time: %.6f\n", os.clock() - time)
end

---@param object blamObject
local function isSyncedBiped(object)
    for serverId, data in pairs(aiList) do
        if (data.objectId) then
            local aiObject = blam.object(get_object(data.objectId))
            if (aiObject and object and aiObject.address == object.address) then
                return true
            end
        end
    end
    return nil
end

function OnTick()
    if (lastMapName ~= map) then
        lastMapName = map
        if (lastMapName == "ui") then
            disablePlayerCollision = false
            dprint("Restoring client side projectiles...")
            execute_script("allow_client_side_weapon_projectiles 1")
        end
    end
    -- Start removing the server created bipeds only when the server aks for it
    if (server_type == "dedicated") then
        if (disablePlayerCollision) then
            local player = blam.biped(get_dynamic_player())
            if (player) then
                blam.bipedTag(player.tagId).disableCollision = true
            end
        end
        if (enableSync) then
            -- Filtering for objects that are being synced from the server
            for _, objectIndex in pairs(blam.getObjects()) do
                local object = blam.object(get_object(objectIndex))
                -- Only process objects that are bipeds
                if (object and object.type == objectClasses.biped) then
                    --[[ Remove bipeds matching these conditions:
                        Is alive (has more than 0 health)
                        Does not belongs to a player (it does not have player id)
                    ]]
                    if (object.health > 0 and blam.isNull(object.playerId)) then
                        -- Check if this object is already being synced
                        if (not isSyncedBiped(object)) then
                            object.zVel = 0
                            object.x = 0
                            object.y = 0
                            object.z = -5
                            object.isFrozen = true
                            object.isGhost = true
                        end
                    end
                end
            end
            -- "Async" mode functionality, experimental!!
            for i = 1, #queuePackets do
                local pendingPacket = queuePackets[i]
                if (pendingPacket) then
                    ProcessPacket(pendingPacket[1], pendingPacket[2], pendingPacket[3])
                    table.remove(queuePackets, i)
                end
            end
        end
    end
end

function OnPacket(message)
    local packet = (glue.string.split(message, ","))
    -- This is a packet sent from the server script
    if (packet and packet[1]:find("@")) then
        local packetType = packet[1]
        if (asyncMode) then
            glue.append(queuePackets, {message, packetType, packet})
        else
            ProcessPacket(message, packetType, packet)
        end
        return false
    elseif (message:find("sync_")) then
        local data = glue.string.split(message, "sync_")
        local command = data[2]:gsub("'", "\"")
        dprint("Sync command: %s", command)
        execute_script(command)
        return false
    elseif (message == "disable_collision") then
        disablePlayerCollision = true
        return false
    end
end

function OnCommand(command)
    if (command == "mdebug") then
        debugMode = not debugMode
        console_out("Debug mode: " .. tostring(debugMode))
        return false
    elseif (command == "masync") then
        asyncMode = not asyncMode
        console_out("Async mode: " .. tostring(asyncMode))
        return false
    elseif (command == "mcount") then
        local count = 0
        for _, data in pairs(aiList) do
            if (data.objectId and get_object(data.objectId)) then
                count = count + 1
            end
        end
        console_out(count)
        return false
    elseif (command == "mcleaner" or command == "mcl") then
        bipedCleaner = not bipedCleaner
        console_out("Biped cleaner: " .. tostring(bipedCleaner))
        return false
    end
end

function OnUnload()
    if (ticks() > 0) then
        dprint("Restoring client side projectiles...")
        disablePlayerCollision = false
        execute_script("allow_client_side_weapon_projectiles 1")
    end
end

set_callback("map load", "OnMapLoad")
set_callback("unload", "OnUnload")
set_callback("command", "OnCommand")
set_callback("tick", "OnTick")
set_callback("rcon message", "OnPacket")
