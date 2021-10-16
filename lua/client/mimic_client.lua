------------------------------------------------------------------------------
-- Mimic Client
-- Sledmine (https://github.com/Sledmine)
-- Client side synchronization feature for AI
------------------------------------------------------------------------------
clua_version = 2.056

local blam = require "blam"
objectClasses = blam.objectClasses
tagClasses = blam.tagClasses
local harmony = require "mods.harmony"
local core = require "mimic.core"
local coop = require "mimic.coop"
local hsc = require "mimic.hsc"
local scriptVersion = require "mimic.version"

local glue = require "glue"
local split = glue.string.split
local append = glue.append

local color = require "ncolor"

local concat = table.concat

-- Script setting variables (do not modify them manually)
DebugMode = false
local lastMapName
local enableSync = false
local asyncMode = false
local disablePlayerCollision = false
local bipedCleaner = true
local bipedCleanerCycle = 20 * 1000 -- Milliseconds
local orphanBipedsSecondsThreshold = 3
local gameStarted = false

-- State
local queuePackets = {}
local aiList = {}
local aiCollection = {}
local availableBipeds = {}

function dprint(message, ...)
    if (DebugMode) then
        if (...) then
            console_out(string.format(message, ...))
            return
        end
        console_out(message)
        return
    end
end

function OnMapLoad()
    gameStarted = false
    CoopStarted = false
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

---@class aiData
---@field tagId number
---@field objectId number
---@field objectIndex number
---@field lastUpdateAt number

function ProcessPacket(message, packetType, packet)
    -- Enable synchronization only when the server sent a mimic packet
    if (not enableSync) then
        enableSync = true
        -- As this is now syncing, we need to stop projectiles duplication on the client
        -- FIXME Create a packet to ask the client to stop creating projectiles
    end
    local time = os.time()
    -- dprint("Packet %s size: %s", packetType, #message)
    if (packetType == "@s") then
        -- TODO Add some kind of validation to prevent spamming this commands
        execute_script("ai_erase_all")
        local tagId = tonumber(packet[2])
        local serverId = packet[3]
        aiList[serverId] = {
            tagId = tagId,
            -- objectId = nil,
            -- objectIndex = nil,
            -- TODO Add biped removal after a large amount of time without an update
            lastUpdateAt = time
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
        local hexColor = packet[10]
        local r, g, b = color.hexToDec(hexColor)
        local invisible = tonumber(packet[11])

        local data = aiList[serverId]
        if (data) then
            local tagId = data.tagId
            local objectId = data.objectId
            if (objectId) then
                if (not core.updateBiped(objectId, x, y, z, vX, vY, animation, animationFrame, r, g,
                                         b, invisible)) then
                    core.log("Warning, server biped %s, &s update mismatch!", serverId, objectId)
                    aiList[serverId].objectId = core.syncBiped(tagId, x, y, z, vX, vY, animation,
                                                               animationFrame, r, g, b, invisible)
                end
            else
                aiList[serverId].objectId = core.syncBiped(tagId, x, y, z, vX, vY, animation,
                                                           animationFrame, r, g, b, invisible)
            end
            data.lastUpdateAt = time
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
                    biped.invisible = false
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
    elseif (packetType == "@i") then
        local votesLeft = packet[2]
        local difficulty = packet[3]
        coop.updateCoopInfo(votesLeft, difficulty)
    else
        for actionName, action in pairs(hsc) do
            if (packetType == action.packetType) then
                dprint(message)
                local syncCommand = {action.name}
                for argumentIndex, arg in pairs(action.arguments) do
                    local outputValue = packet[argumentIndex + 1]
                    if (arg.value and arg.class) then
                        outputValue = blam.getTag(tonumber(outputValue))[arg.value]
                    end
                    append(syncCommand, outputValue)
                end
                execute_script(concat(syncCommand, " "))
            end
        end
        
    end
    -- dprint("Packet processed, elapsed time: %.6f\n", os.clock() - time)
end

---@param object blamObject
---@return aiData
local function isSyncedBiped(object)
    for serverId, data in pairs(aiList) do
        if (data.objectId) then
            local aiObject = blam.object(get_object(data.objectId))
            if (aiObject and object and aiObject.address == object.address) then
                return data, serverId
            end
        end
    end
    return nil
end

local function onGameStart()
    gameStarted = true
    if (map:find("coop_evolved")) then
        availableBipeds = coop.loadCoopMenu()
    end
end

function OnTick()
    if (not gameStarted) then
        onGameStart()
    end
    if (lastMapName ~= map) then
        lastMapName = map
        if (lastMapName == "ui") then
            disablePlayerCollision = false
            dprint("Restoring client side projectiles...")
            execute_script("allow_client_side_weapon_projectiles 1")
        end
    end
    -- Start removing the server created bipeds only when the server aks for it
    if (blam.isGameDedicated()) then
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
                    if (object.health > 0 and blam.isNull(object.playerId) and
                        blam.isNull(object.nameIndex)) then
                        -- Check if this object is already being synced
                        local serverBiped, serverBipedId = isSyncedBiped(object)
                        if (not serverBiped) then
                            object.zVel = 0
                            object.x = 0
                            object.y = 0
                            object.z = -5
                            object.isFrozen = true
                            object.isGhost = true
                        else
                            local currentTime = os.time()
                            local timeSinceLastUpdate = currentTime - serverBiped.lastUpdateAt
                            if (serverBiped.objectId and timeSinceLastUpdate >
                                orphanBipedsSecondsThreshold) then
                                -- dprint("Erasing orphan biped, last update at %s", serverBiped.lastUpdateAt)
                                local biped = blam.biped(get_object(serverBiped.objectId))
                                if (biped) then
                                    delete_object(serverBiped.objectId)
                                end
                                serverBiped.objectId = nil
                            end
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

local function clientSideProjectiles(enable)
    if (enable) then
        dprint("ENABLING client side projectiles...")
        execute_script("allow_client_side_weapon_projectiles 1")
        return true
    end
    dprint("DISABLING client side projectiles...")
    execute_script("allow_client_side_weapon_projectiles 0")
    return false
end

function OnPacket(message)
    local packet = (glue.string.split(message, ","))
    -- This is a packet sent from the server script for
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
        if (command:find("camera_set")) then
            local params = glue.string.split(command, " ")
            local cutsceneCameraPoint = params[2]
            dprint("Unlocking cinematic camera: " .. cutsceneCameraPoint)
            execute_script("object_pvs_set_camera " .. cutsceneCameraPoint)
        end
        return false
    elseif (message == "disable_biped_collision") then
        disablePlayerCollision = true
        return false
    elseif (message == "enable_biped_collision") then
        disablePlayerCollision = false
        return false
    elseif (message == "disable_client_side_projectiles") then
        clientSideProjectiles(false)
        return false
    elseif (message == "enable_client_side_weapon_projectiles") then
        clientSideProjectiles(true)
        return false
    elseif (message == "open_coop_menu") then
        availableBipeds = coop.loadCoopMenu(true)
        return false
    end
end

function OnCommand(command)
    if (command == "mdebug") then
        DebugMode = not DebugMode
        console_out("Debug mode: " .. tostring(DebugMode))
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
    elseif (command == "mversion") then
        console_out(scriptVersion)
        return false
    elseif (command == "mspawn") then
        coop.enableSpawn()
        coop.loadCoopMenu(true)
        return false
    end
end

function OnMenuAccept(widgetTagId)
    if (map:find("coop")) then
        local widgetTag = blam.getTag(widgetTagId)
        if (widgetTag) then
            if (widgetTag.path:find("ready_button", 1, true)) then
                local rconCommand = "rcon coup @r,1"
                dprint(rconCommand)
                execute_script(rconCommand)
            elseif (widgetTag.path:find("biped_buttons", 1, true)) then
                local tagSplit = split(widgetTag.path, "\\")
                local buttonTagName = tagSplit[#tagSplit]
                local desiredBipedIndex = tonumber(split(buttonTagName, "biped_")[2])
                if (blam.isGameDedicated()) then
                    local rconCommand = "rcon coup @b," .. availableBipeds[desiredBipedIndex].id
                    dprint(rconCommand)
                    execute_script(rconCommand)
                else
                    local globals = blam.globalsTag()
                    if (globals) then
                        local player = blam.player(get_player())
                        local mpInfo = globals.multiplayerInformation
                        mpInfo[1].unit = coop.loadCoopMenu(false)[desiredBipedIndex].id
                        console_out("Replacing biped...")
                        globals.multiplayerInformation = mpInfo
                        delete_object(player.objectId)
                    end
                end
            end
        end
    end
    return true
end

function OnUnload()
    if (ticks() > 0) then
        disablePlayerCollision = false
        clientSideProjectiles(true)
    end
    harmony.unload()
end

set_callback("map load", "OnMapLoad")
set_callback("unload", "OnUnload")
set_callback("command", "OnCommand")
set_callback("tick", "OnTick")
set_callback("rcon message", "OnPacket")
harmony.set_callback("menu accept", "OnMenuAccept")
