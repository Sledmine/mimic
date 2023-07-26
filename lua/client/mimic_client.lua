------------------------------------------------------------------------------
-- Mimic Client
-- Sledmine (https://github.com/Sledmine)
-- Client side synchronization feature for AI
------------------------------------------------------------------------------
clua_version = 2.056

local blam = require "blam"
objectClasses = blam.objectClasses
tagClasses = blam.tagClasses
local isNull = blam.isNull
local harmony = require "mods.harmony"
local core = require "mimic.core"
local coop = require "mimic.coop"
local hsc = require "mimic.hsc"
local scriptVersion = require "mimic.version"
local luna = require "luna"
local split = luna.string.split
local append = table.insert
local starts = luna.string.startswith
local color = require "ncolor"
local concat = table.concat
local constants = require "mimic.constants"

-- Script settings variables (do not modify them manually)
DebugMode = true
DebugLevel = 1
local lastMapName
local enableSync = false
local asyncMode = false
local disablePlayerCollision = false
local bipedCleaner = true
local gameStarted = false

-- Debug draw thing
local nearestAIDetails = ""
local font = "small"
local align = "center"
local bounds = {left = 0, top = 400, right = 640, bottom = 480}
local textColor = {1.0, 0.45, 0.72, 1.0}
local packetCount = 0
local packetsPerSecond = 0
local timeSinceLastPacket = 0

-- State
local queuePackets = {}
---@type aiData[]
local aiList = {}
local aiCollection = {}
local availableBipeds = {}
local frozenBipeds = {}
local lastPlayerTagId

function dprint(message, ...)
    if DebugMode then
        local color = {1, 1, 1}
        if (...) then
            local debugMessage = string.format(message, ...)
            if (debugMessage:find("Warning")) then
                color = {1, 0.556, 0.101}
            elseif (debugMessage:find("Error")) then
                color = {1, 0, 0}
            elseif (debugMessage:find("Success")) then
                color = {0, 1, 0}
            end
            console_out(debugMessage, table.unpack(color))
            return
        end
        if (message:find("Warning")) then
            color = {1, 0.556, 0.101}
        elseif (message:find("Error")) then
            color = {1, 0, 0}
        elseif (message:find("Success")) then
            color = {0, 1, 0}
        end
        console_out(message, table.unpack(color))
        return
    end
end

function OnMapLoad()
    gameStarted = false
    CoopStarted = false
    queuePackets = {}
    aiList = {}
    frozenBipeds = {}
    lastPlayerTagId = nil
end

function CleanBipeds(serverId)
    -- execute_script("ai_erase_all")
    local data = aiList[serverId]
    if data then
        dprint("Cleaning biped %s", serverId)
        local objectId = data.objectId
        if objectId then
            frozenBipeds[objectId] = nil
            if get_object(objectId) then
                delete_object(objectId)
            end
        end
    end
    aiCollection[serverId] = nil
    aiList[serverId] = nil
    return false
end

---@param objectId number
---@return aiData?, number?
local function getAIDataByObjectId(objectId)
    for serverId, aiData in pairs(aiList) do
        if (aiData.objectId) then
            local aiObject = blam.object(get_object(aiData.objectId))
            -- TODO WTFFFF
            if (aiObject and aiData.objectId == objectId) then
                return aiData, serverId
            end
        end
    end
    return nil
end

---@class aiData
---@field tagId number
---@field lastUpdateAt number
---@field objectId? number
---@field objectIndex? number
---@field isLocal boolean
-- @field expectedCoordinates vector3D

function ProcessPacket(message, packetType, packet)
    -- Enable synchronization only when the server sent a mimic packet
    if not enableSync then
        enableSync = true
    end
    local currentTime = os.time()
    if DebugMode then
        packetCount = packetCount + 1
    end
    -- dprint("Packet %s size: %s", packetType, #message)
    if packetType == "@p" then
        -- Erase local AI bipeds
        execute_script("ai_erase_all")

        local syncedIndex = tonumber(packet[2])
        assert(syncedIndex, "Error, synced index is not valid")

        local tagId = tonumber(packet[3])
        assert(tagId, "Error, tag id is not valid")

        local objectId = blam.getObjectIdBySincedIndex(syncedIndex)
        if not objectId then
            error("Error, object id not found for synced index: " .. syncedIndex)
        end
        aiList[syncedIndex] = {
            tagId = tagId,
            lastUpdateAt = currentTime,
            isLocal = false,
            objectId = objectId
        }
    elseif packetType == "@u" then
        execute_script("ai_erase_all")

        local syncedIndex = tonumber(packet[2])
        assert(syncedIndex, "Error, synced index is not valid")

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

        -- Not so sure about this
        local aiData = aiList[syncedIndex]
        if not aiData then
            local objectId = blam.getObjectIdBySincedIndex(syncedIndex)
            if objectId then
                aiList[syncedIndex] = {
                    tagId = blam.object(get_object(objectId)).tagId,
                    lastUpdateAt = currentTime,
                    isLocal = false,
                    objectId = objectId
                }
                aiData = aiList[syncedIndex]
            end
        end

        if aiData and aiData.tagId then
            local tagId = aiData.tagId
            local objectId = aiData.objectId
            if objectId and not isNull(get_object(objectId)) then
                core.updateBiped(objectId, x, y, z, vX, vY, animation, animationFrame, r, g, b,
                                 invisible)
                -- local tag = blam.getTag(tagId)
                -- assert(tag, "Error, tag not found")
                -- dprint("Updating %s -> %s, %s: %s %s %s", syncedIndex, objectId, tag.path, x , y, z)
            else
                error("Error, update packet received for non existing biped: " .. syncedIndex)
            end
            aiData.lastUpdateAt = currentTime
        end
    elseif packetType == "@k" then
        local syncedIndex = tonumber(packet[2])
        if syncedIndex then
            local data = aiList[syncedIndex]
            -- TODO Check if an action needs to be taken if no biped exists at dying
            if data then
                local objectId = data.objectId
                if objectId then
                    local biped = blam.biped(get_object(objectId))
                    if biped then
                        if data.isLocal then
                            core.debug("Killing biped %s", syncedIndex)
                            biped.health = 0
                            biped.shield = 0
                            biped.animationFrame = 0

                            biped.isNotDamageable = false
                            biped.ignoreGravity = false
                            biped.invisible = false

                            -- Force kill prematurely
                            biped.isHealthEmpty = true
                        else
                            core.revertBipedVirtualization(biped)
                            -- local tag = blam.getTag(biped.tagId)
                            -- if (tag.path:find("flood")) then
                            --    biped.isHealthEmpty = true
                            --    core.debug(
                            --        "kill packet from %s -> %s, server sided biped will be killed as it as a Flood biped",
                            --        serverId, objectId)
                            -- else
                            if biped.isHealthEmpty then
                                core.debug(
                                    "Ignoring kill packet from %s -> %s, biped is server sided",
                                    syncedIndex, objectId)
                            else
                                biped.isApparentlyDead = true
                            end

                            -- end
                        end
                    end
                end
                -- Cleanup
                if bipedCleaner then
                    if (not aiCollection[syncedIndex]) then
                        aiCollection[syncedIndex] =
                            set_timer(constants.cleanBipedsEveryMillisecs, "CleanBipeds",
                                      syncedIndex)
                    end
                else
                    CleanBipeds(syncedIndex)
                end
            end
        end
    elseif packetType == "@i" then
        local votesLeft = packet[2]
        local difficulty = packet[3]
        coop.updateCoopInfo(votesLeft, difficulty)
    else
        for actionName, action in pairs(hsc) do
            if (packetType == action.packetType) then
                dprint("Sync packet: " .. message)
                local syncPacket = {action.name}
                for argumentIndex, arg in pairs(action.parameters) do
                    local outputValue = packet[argumentIndex + 1]
                    if (arg.value and arg.class) then
                        outputValue = blam.getTag(tonumber(outputValue))[arg.value]
                    end
                    append(syncPacket, outputValue)
                end
                local localCommand = concat(syncPacket, " ")
                dprint("Local command: " .. localCommand)
                execute_script(localCommand)
            end
        end
    end
    -- dprint("Packet processed, elapsed time: %.6f\n", os.time() - time)
end

local function onGameStart()
    gameStarted = true
    if map:includes("coop_evolved") then
        enableSync = true
        availableBipeds = coop.loadCoopMenu()

    end
end

function OnTick()
    if not gameStarted then
        onGameStart()
    end
    if enableSync and gameStarted then
        -- Constantly erase locally created AI bipeds
        execute_script("ai_erase_all")
        -- Check if map is a coop evolved map
        if map:find("coop_evolved") then
            local playerBiped = blam.biped(get_dynamic_player())
            if (playerBiped) then
                if (lastPlayerTagId ~= playerBiped.tagId) then
                    lastPlayerTagId = playerBiped.tagId
                    coop.swapFirstPerson()
                end
            end
        end
    end
    if lastMapName ~= map then
        lastMapName = map
        if (lastMapName == "ui") then
            disablePlayerCollision = false
            dprint("Restoring client side projectiles...")
            execute_script("allow_client_side_weapon_projectiles 1")
        end
    end
    -- Start removing the server created bipeds only when the server aks for it
    if blam.isGameDedicated() then
        if (disablePlayerCollision) then
            local player = blam.biped(get_dynamic_player())
            if (player) then
                blam.bipedTag(player.tagId).disableCollision = true
            end
        end
        if enableSync then
            -- Filtering for objects that are being synced from the server
            for _, objectIndex in pairs(blam.getObjects()) do
                local _, objectId = blam.getObject(objectIndex)
                assert(objectId, "Error, object id is not valid")
                local object = blam.object(get_object(objectId))
                -- Only process objects that are bipeds
                if object and object.class == objectClasses.biped then
                    local object = blam.biped(get_object(objectId))
                    assert(object, "Error, object is not valid")
                    --[[ Remove bipeds matching these conditions:
                        Is alive (has more than 0 health)
                        Does not belong to a player (it does not have player id)
                        Does not have a name assigned on the scenario (is not a cinematic object)
                    ]]
                    if isNull(object.playerId) and isNull(object.nameIndex) then
                        local isBipedDead = object.isApparentlyDead
                        local tag = blam.getTag(object.tagId)
                        assert(tag, "Error, tag is not valid")
                        if tag.path:includes("flood") or tag.path:includes("monitor") or
                            tag.path:includes("sentinel") then
                            isBipedDead = false
                        end
                        if not isBipedDead then
                            -- Check if this object is already being synced
                            local aiData = getAIDataByObjectId(objectId)
                            if not aiData then
                                -- Freeze biped for assignation purposes later
                                if not frozenBipeds[objectId] then
                                    frozenBipeds[objectId] = {
                                        tagId = object.tagId,
                                        x = object.x,
                                        y = object.y,
                                        z = object.z
                                    }
                                end
                                -- core.hideBiped(object)
                            else
                                if aiData.isLocal then
                                    local currentTime = os.time()
                                    local timeSinceLastUpdate = currentTime - aiData.lastUpdateAt
                                    if aiData.objectId and timeSinceLastUpdate >
                                        constants.considerOrphanBipedAfterSeconds then
                                        local biped = blam.biped(get_object(aiData.objectId))
                                        if biped then
                                            local tag = blam.getTag(biped.tagId)
                                            assert(tag, "Error, tag is not valid")
                                            dprint("Erasing orphan biped %s, last update at %s",
                                                   tag.path, aiData.lastUpdateAt)
                                            delete_object(aiData.objectId)
                                        end
                                        aiData.objectId = nil
                                    else
                                        local currentTime = os.time()
                                        local timeSinceLastUpdate = currentTime -
                                                                        aiData.lastUpdateAt
                                        -- local biped = blam.biped(get_object(aiData.objectId))
                                        -- if (biped) then
                                        --    core.virtualizeBiped(biped)
                                        -- end
                                    end
                                else
                                    core.virtualizeBiped(object)
                                end
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
    local playerBiped = blam.biped(get_dynamic_player())
    if DebugMode then
        if get_player() then
            local currentTime = os.time()
            if (currentTime - timeSinceLastPacket) >= 1 then
                timeSinceLastPacket = currentTime
                packetsPerSecond = packetCount
                packetCount = 0
            end
            nearestAIDetails = ""
            for serverId, aiData in pairs(aiList) do
                if (aiData.objectId) then
                    local ai = blam.biped(get_object(aiData.objectId))
                    -- if (ai and core.objectIsNearTo(ai, playerBiped, candidateThreshold * 4)) then
                    if (ai and
                        core.objectIsLookingAt(get_dynamic_player(), aiData.objectId, 0.5, 0, 10)) then
                        nearestAIDetails =
                            ("%s -> serverId: %s -> localId: %s -> isLocal: %s"):format(
                                blam.getTag(ai.tagId).path, serverId, aiData.objectId,
                                tostring(aiData.isLocal))
                    end
                end
            end
        end
    end
end

local function clientSideProjectiles(enable)
    if enable then
        dprint("ENABLING client side projectiles...")
        execute_script("allow_client_side_weapon_projectiles 1")
        return true
    end
    dprint("DISABLING client side projectiles...")
    execute_script("allow_client_side_weapon_projectiles 0")
    return false
end

--- OnPacket
---@param message string
---@return boolean?
function OnPacket(message)
    local packet = message:split(",")
    -- This is a packet sent from the server script for
    if packet and packet[1]:find("@") then
        local packetType = packet[1]
        if asyncMode then
            table.insert(queuePackets, {message, packetType, packet})
        else
            ProcessPacket(message, packetType, packet)
        end
        return false
    elseif message:find("sync_") then
        local data = message:split "sync_"
        local command = data[2]:gsub("'", "\"")
        dprint("Sync command: %s", command)
        if DebugMode then
            packetCount = packetCount + 1
        end
        execute_script(command)
        if (command:find("camera_set")) then
            local params = command:split " "
            local cutsceneCameraPoint = params[2]
            dprint("Unlocking cinematic camera: " .. cutsceneCameraPoint)
            execute_script("object_pvs_set_camera " .. cutsceneCameraPoint)
        end
        return false
    elseif message == "disable_biped_collision" then
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

--- OnCommand
---@param command string
---@return boolean
function OnCommand(command)
    if starts(command, "mdebug") or starts(command, "mimic_debug") then
        local params = command:split " "
        if (#params > 1 and params[2]) then
            DebugLevel = tonumber(params[2])
        end
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
    if map:find("coop_evolved") then
        local widgetTag = blam.getTag(widgetTagId)
        if widgetTag then
            if widgetTag.path:includes("ready_button") then
                local rconCommand = "rcon coup @r,1"
                dprint(rconCommand)
                execute_script(rconCommand)
            elseif widgetTag.path:includes("biped_buttons") then
                local tagSplit = split(widgetTag.path, "\\")
                local buttonTagName = tagSplit[#tagSplit]
                local desiredBipedIndex = tonumber(split(buttonTagName, "biped_")[2])
                if blam.isGameDedicated() then
                    local rconCommand = "rcon coup @b," .. availableBipeds[desiredBipedIndex].id
                    dprint(rconCommand)
                    execute_script(rconCommand)
                else
                    local globals = blam.globalsTag()
                    if globals then
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
    if ticks() > 0 then
        disablePlayerCollision = false
        clientSideProjectiles(true)
    end
end

function OnPreFrame()
    if (DebugMode and (blam.isGameDedicated() or blam.isGameHost())) then
        draw_text(nearestAIDetails, bounds.left, bounds.top, bounds.right, bounds.bottom, font,
                  align, table.unpack(textColor))
        draw_text(("AI: %s / Packets per second: %s"):format(#table.keys(aiList) -
                                                                 #table.keys(aiCollection),
                                                             packetsPerSecond), bounds.left,
                  bounds.top + 30, bounds.right, bounds.bottom, font, align, table.unpack(textColor))
    end
end

set_callback("map load", "OnMapLoad")
set_callback("unload", "OnUnload")
set_callback("command", "OnCommand")
set_callback("tick", "OnTick")
set_callback("rcon message", "OnPacket")
set_callback("preframe", "OnPreFrame")

harmony.set_callback("menu accept", "OnMenuAccept")
