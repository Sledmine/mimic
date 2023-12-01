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
local core = require "mimic.core"
local hsc = require "mimic.hsc"
local scriptVersion = require "mimic.version"
local luna = require "luna"
local split = luna.string.split
local append = table.insert
local starts = luna.string.startswith
local color = require "ncolor"
local concat = table.concat
local constants = require "mimic.constants"
local inspect = require "inspect"
local isBalltzeAvailable, balltze = pcall(require, "mods.balltze")

-- Script settings variables (do not modify them manually)
DebugMode = false
DebugLevel = 1
local virtualParentedObjects = {}
local lastMapName
local enableSync = false
local asyncMode = false
local disablePlayerCollision = false
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
    queuePackets = {}
end

---@class aiData
---@field tagId number
---@field lastUpdateAt number
---@field objectId? number
---@field objectIndex? number
---@field isLocal boolean
-- @field expectedCoordinates vector3D

---@param message string
---@param packetType string
---@param packet string[]
local function processPacket(message, packetType, packet)
    -- Enable synchronization only when the server sent a mimic packet
    if not enableSync then
        enableSync = true
    end
    local currentTime = os.time()
    if DebugMode then
        packetCount = packetCount + 1
        if DebugLevel >= 2 then
            if not packetType:startswith "@u" then
                dprint("Received packet %s size %s message: %s", packetType, #message, message)
            end
        end
    end
    if packetType:startswith "@" then
        if packetType == "@c" then
            local syncedIndex = tonumber(packet[2])
            assert(syncedIndex, "Error, synced index is not valid")

            local objectId = blam.getObjectIdBySyncedIndex(syncedIndex)
            if objectId then
                local colorA = packet[3]
                local colorB = packet[4]
                local colorC = packet[5]
                local colorD = packet[6]
                local shaderPermutationIndex = tonumber(packet[7]) or 0

                local object = blam.object(get_object(objectId))
                if object then
                    local r, g, b = color.hexToDec(colorA)
                    object.colorAUpperRed = r
                    object.colorALowerRed = r
                    object.colorAUpperGreen = g
                    object.colorALowerGreen = g
                    object.colorAUpperBlue = b
                    object.colorALowerBlue = b

                    r, g, b = color.hexToDec(colorB)
                    object.colorBUpperRed = r
                    object.colorBLowerRed = r
                    object.colorBUpperGreen = g
                    object.colorBLowerGreen = g
                    object.colorBUpperBlue = b
                    object.colorBLowerBlue = b

                    r, g, b = color.hexToDec(colorC)
                    object.colorCUpperRed = r
                    object.colorCLowerRed = r
                    object.colorCUpperGreen = g
                    object.colorCLowerGreen = g
                    object.colorCUpperBlue = b
                    object.colorCLowerBlue = b

                    r, g, b = color.hexToDec(colorD)
                    object.colorDUpperRed = r
                    object.colorDLowerRed = r
                    object.colorDUpperGreen = g
                    object.colorDLowerGreen = g
                    object.colorDUpperBlue = b
                    object.colorDLowerBlue = b

                    object.shaderPermutationIndex = shaderPermutationIndex
                end
            end
        elseif packetType == "@u" then
            execute_script("ai_erase_all")

            local syncedIndex = tonumber(packet[2])
            assert(syncedIndex, "Error, synced index is not valid")

            local x = core.decode("f", packet[3])
            local y = core.decode("f", packet[4])
            local z = core.decode("f", packet[5])
            local animation = tonumber(packet[6])
            local animationFrame = tonumber(packet[7])
            local yaw = core.decode("f", packet[8])
            local pitch = core.decode("f", packet[9])
            local roll = core.decode("f", packet[10])

            local objectId = blam.getObjectIdBySyncedIndex(syncedIndex)
            if objectId then
                if objectId and not isNull(get_object(objectId)) then
                    local object = blam.getObject(objectId)
                    if object then
                        if object.isOutSideMap then
                            dprint("Warning, Object with sync index " .. syncedIndex ..
                                       " is outside map")
                        end
                        core.virtualizeObject(object)
                        core.updateObject(objectId, x, y, z, yaw, pitch, roll, animation,
                                          animationFrame)
                    end
                else
                    error("Error, update packet received for non existing object: " .. syncedIndex)
                end
            end
        elseif packetType == "@o" then
            local syncedIndex = tonumber(packet[2])
            assert(syncedIndex, "Error, synced index is not valid")

            local objectId = blam.getObjectIdBySyncedIndex(syncedIndex)
            if not objectId then
                return
            end
            local unit = blam.unit(get_object(objectId))
            if not unit then
                return
            end

            local isBiped = unit.class == objectClasses.biped
            local isVehicle = unit.class == objectClasses.vehicle

            if isBiped then
                unit = blam.biped(get_object(objectId))
            elseif isVehicle then
                unit = blam.vehicle(get_object(objectId))
            end
            if not unit then
                return
            end

            local regions = {
                tonumber(packet[3]),
                tonumber(packet[4]),
                tonumber(packet[5]),
                tonumber(packet[6]),
                tonumber(packet[7]),
                tonumber(packet[8]),
                tonumber(packet[9]),
                tonumber(packet[10])
            }

            local isCamoActive = tonumber(packet[11]) == 1
            local parentObjectSyncedIndex = tonumber(packet[12])
            local parentSeatIndex = tonumber(packet[13])
            local team = tonumber(packet[14])

            -- Sync region permutations
            for regionIndex, permutation in pairs(regions) do
                unit["regionPermutation" .. regionIndex] = permutation
            end

            -- Sync unit properties only if it does not belong to a player
            if not isNull(unit.playerId) then
                return
            end

            -- Sync unit properties
            unit.isCamoActive = isCamoActive
            if isCamoActive then
                unit.camoScale = 1
            end

            -- Sync team
            if isBiped then
                unit.team = team or blam.null
            end

            -- Sync parent vehicle
            if isVehicle then
                -- TODO Release new balltze to support exiting vehicles, as of today
                -- game by default syncs bipeds existing vehicles but not entering, we are
                -- covered in that part thanks to balltze.
                -- 
                -- However vehicles do not sync exiting other units so after making them enter
                -- they will be stuck inside the other vehicle
                return
            end
            if parentObjectSyncedIndex and parentSeatIndex then
                local parentObjectId = blam.getObjectIdBySyncedIndex(parentObjectSyncedIndex)
                if parentObjectId then
                    if not isBalltzeAvailable then
                        console_out("Balltze is not available, unit vehicle entering is not supported")
                        return
                    end
                    balltze.unit_enter_vehicle(objectId, parentObjectId, parentSeatIndex)
                end
            end
        elseif packetType == "@b" then
            local syncedIndex = tonumber(packet[2])
            assert(syncedIndex, "Error, synced index is not valid")

            local objectId = blam.getObjectIdBySyncedIndex(syncedIndex)
            if not objectId then
                return
            end
            local biped = blam.biped(get_object(objectId))
            if not biped then
                return
            end

            local firstWeaponObjectSyncedIndex = tonumber(packet[3])
            local secondWeaponObjectSyncedIndex = tonumber(packet[4])
            local flashlight = tonumber(packet[5]) == 1

            biped.flashlight = flashlight

            if not isNull(biped.playerId) then
                return
            end

            if firstWeaponObjectSyncedIndex then
                local weaponObjectId = blam.getObjectIdBySyncedIndex(firstWeaponObjectSyncedIndex)
                if weaponObjectId then
                    local weapon = blam.weapon(get_object(weaponObjectId))
                    if weapon and isNull(weapon.playerId) then
                        biped.firstWeaponObjectId = weaponObjectId
                        weapon.isOutSideMap = false
                        weapon.isInInventory = true
                        -- TODO Check if player or weapon are inside map and both are not ghost
                        -- This caused a crash when player was inside map and weapon was not or something like that
                        -- weapon.isGhost = false
                    end
                end
            end
            -- Theorically AI can not hold a second weapon so this is not needed.. yet it would be
            -- cool to have it later as a feature
            -- if secondWeaponObjectSyncedIndex then
            if false and secondWeaponObjectSyncedIndex then
                local weaponObjectId = blam.getObjectIdBySyncedIndex(secondWeaponObjectSyncedIndex)
                if weaponObjectId then
                    biped.secondWeaponObjectId = weaponObjectId
                    local weapon = blam.weapon(get_object(weaponObjectId))
                    if weapon then
                        weapon.isOutSideMap = false
                        weapon.isInInventory = true
                        weapon.isGhost = false
                    end
                end
            end
        end
    else
        for actionName, action in pairs(hsc) do
            if packetType == action.packetType then
                dprint("Sync packet: " .. message)
                local syncPacket = {action.name}
                for argumentIndex, arg in pairs(action.parameters) do
                    local outputValue = packet[argumentIndex + 1]
                    if arg.value and arg.class then
                        outputValue =
                            blam.getTag(tonumber(outputValue) --[[@as number]] )[arg.value]
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
end

function OnTick()
    if not gameStarted then
        onGameStart()
    end
    if enableSync and gameStarted then
        -- Constantly erase locally created AI bipeds
        execute_script("ai_erase_all")
    end
    if lastMapName ~= map then
        lastMapName = map
        if lastMapName == "ui" then
            disablePlayerCollision = false
            dprint("Restoring client side projectiles...")
            execute_script("allow_client_side_weapon_projectiles 1")
        end
    end
    -- Start removing the server created bipeds only when the server aks for it
    if blam.isGameDedicated() then
        if disablePlayerCollision then
            local biped = blam.biped(get_dynamic_player())
            if biped then
                blam.bipedTag(biped.tagId).disableCollision = true
            end
        end
    end
    if DebugMode then
        if get_player() then
            local currentTime = os.time()
            if (currentTime - timeSinceLastPacket) >= 1 then
                timeSinceLastPacket = currentTime
                packetsPerSecond = packetCount
                packetCount = 0
            end
            nearestAIDetails = ""
            for syncedIndex, objectId in pairs(core.getSyncedBipedIds()) do
                local biped = blam.biped(get_object(objectId))
                if biped and core.objectIsLookingAt(get_dynamic_player(), objectId, 0.5, 0, 10) then
                    local tag = blam.getTag(biped.tagId)
                    assert(tag, "Error, tag not found")
                    nearestAIDetails = ("%s -> serverId: %s -> localId: %s"):format(tag.path,
                                                                                    syncedIndex,
                                                                                    objectId)
                end
            end
        end
    end
    for objectId, parentObjectId in pairs(virtualParentedObjects) do
        local object = blam.object(get_object(objectId))
        if object then
            local parentObject = blam.object(get_object(parentObjectId))
            if parentObject then
                object.x = parentObject.x + object.x
                object.y = parentObject.y + object.y
                object.z = parentObject.z + object.z
            end
        else
            virtualParentedObjects[objectId] = nil
        end
    end
end

--- OnPacket
---@param message string
---@return boolean?
function OnPacket(message)
    local packet = message:split(",")
    -- This is a packet sent from the server script for
    if packet and packet[1]:includes("@") then
        local packetType = packet[1]
        if asyncMode then
            table.insert(queuePackets, {message, packetType, packet})
        else
            processPacket(message, packetType, packet)
        end
        return false
    elseif message:includes("sync_") then
        local data = message:split "sync_"
        local command = data[2]:gsub("'", "\"")
        if DebugMode then
            if DebugLevel >= 2 then
                dprint("Sync command: %s", command)
            end
            packetCount = packetCount + 1
        end
        execute_script(command)
        if command:includes("camera_set") then
            local params = command:split " "
            local cutsceneCameraPoint = params[2]
            dprint("Unlocking cinematic camera: " .. cutsceneCameraPoint)
            execute_script("object_pvs_set_camera " .. cutsceneCameraPoint)
        end
        return false
    elseif message == "disable_biped_collision" then
        disablePlayerCollision = true
        return false
    elseif message == "enable_biped_collision" then
        disablePlayerCollision = false
        return false
    end
end

--- OnCommand
---@param command string
---@return boolean
function OnCommand(command)
    if command:startswith "mdebug" or command:startswith "mimic_debug" then
        local params = command:split " "
        if #params > 1 and params[2] then
            DebugLevel = tonumber(params[2])
        end
        DebugMode = not DebugMode
        console_out("Debug mode: " .. tostring(DebugMode))
        return false
    elseif command == "mimic_async" then
        asyncMode = not asyncMode
        console_out("Async mode: " .. tostring(asyncMode))
        return false
    elseif command == "mimic_version" then
        console_out(scriptVersion)
        return false
    end
    return true
end

function OnUnload()
    if ticks() > 0 then
        disablePlayerCollision = false
    end
end

function OnPreFrame()
    if DebugMode and (blam.isGameDedicated() or blam.isGameHost()) then
        draw_text(nearestAIDetails, bounds.left, bounds.top, bounds.right, bounds.bottom, font,
                  align, table.unpack(textColor))

        local syncDetails = "Network objects: %s / Synced Bipeds: %s / Mimic packets per second: %s"
        local networkObjectsCount = #table.keys(core.getSyncedObjectsIds())
        local syncedBipedsCount = #table.keys(core.getSyncedBipedIds())
        draw_text(syncDetails:format(networkObjectsCount, syncedBipedsCount, packetsPerSecond),
                  bounds.left, bounds.top + 30, bounds.right, bounds.bottom, font, align,
                  table.unpack(textColor))
    end
end

set_callback("map load", "OnMapLoad")
set_callback("unload", "OnUnload")
set_callback("command", "OnCommand")
set_callback("tick", "OnTick")
set_callback("rcon message", "OnPacket")
set_callback("preframe", "OnPreFrame")
