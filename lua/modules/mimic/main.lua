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
package.preload["luna"] = nil
package.loaded["luna"] = nil
require "luna"
local append = table.insert
local color = require "ncolor"
local concat = table.concat
local memoize = require "memoize"
local tonumber = memoize(tonumber)
local balltze = Balltze
local engine = Engine

-- Script settings variables
DisablePlayerCollision = false
local lastMapName
local enableSync = false
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

function OnLoad()
    logger:info("Loading main")
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
    enableSync = true
    -- local currentTime = os.time()
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
            if DebugLevel >= 2 then
                logger:debug("Received color packet: {}", message)
            end
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
            engine.hsc.executeScript("ai_erase_all")

            local syncedIndex = tonumber(packet[2])
            assert(syncedIndex, "Error, synced index is not valid")

            local x = core.decode("f", packet[3])
            local y = core.decode("f", packet[4])
            local z = core.decode("f", packet[5])
            local animationTagIndex = tonumber(packet[6])
            local animationIndex = tonumber(packet[7])
            local animationFrame = tonumber(packet[8])
            local yaw = core.decode("f", packet[9])
            local pitch = core.decode("f", packet[10])
            local roll = core.decode("f", packet[11])

            local objectId = blam.getObjectIdBySyncedIndex(syncedIndex)
            if objectId then
                if objectId and not isNull(get_object(objectId)) then
                    local object = blam.getObject(objectId)
                    if object then
                        if object.isOutSideMap then
                            if DebugMode and DebugLevel >= 2 then
                                logger:warning("Object with sync index {} is outside map",
                                               syncedIndex)
                            end
                        end
                        core.virtualizeObject(object)
                        core.updateObject(objectId, x, y, z, yaw, pitch, roll, animationIndex,
                                          animationFrame, animationTagIndex)
                    end
                else
                    logger:error(
                        "Update packet for object with sync index {} does not exist in client",
                        syncedIndex)
                end
            end
        elseif packetType == "@o" then
            if DebugLevel >= 2 then
                logger:debug("Received object packet: {}", message)
            end
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
                -- game by default syncs bipeds exiting vehicles but not entering, we are
                -- covered in that part thanks to balltze.
                -- 
                -- However vehicles do not sync exiting other units so after making them enter
                -- they will be stuck inside the other vehicle
                return
            end
            if parentObjectSyncedIndex and parentSeatIndex then
                local parentObjectId = blam.getObjectIdBySyncedIndex(parentObjectSyncedIndex)
                if parentObjectId then
                    logger:debug("Unit with sync index {} is entering vehicle with sync index {}",
                                 syncedIndex, parentObjectSyncedIndex)
                    engine.gameState.unitEnterVehicle(objectId, parentObjectId, parentSeatIndex)
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
            local isApparentlyDead = tonumber(packet[6]) == 1

            biped.flashlight = flashlight
            -- Keep in mind this will kill the biped on our client side, making this not ideal
            -- for bipeds that can fake death, like floods
            -- TODO Also if biped just got created we will able to see a dying animation, we should
            -- try to find the proper dead animation and force it to apply in the last frame
            -- TODO Remove fake dead chance for all bipeds on the client side so we can stick to
            -- thrusting this value as true death
            biped.isApparentlyDead = isApparentlyDead

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

        else
            local hscCommand = core.parseHscPacket(message)
            assert(hscCommand, "Error, hsc command is not valid")
            if DebugMode then
                -- if DebugLevel >= 2 then
                logger:debug("Executing HSC command: {}", hscCommand)
                -- end
            end
            engine.hsc.executeScript(hscCommand)
            if hscCommand:includes("camera_set") then
                local params = hscCommand:split " "
                local cutsceneCameraPoint = params[2]
                if DebugMode then
                    if DebugLevel >= 2 then
                        logger:debug("Unlocking cinematic camera: {}", cutsceneCameraPoint)
                    end
                end
                engine.hsc.executeScript("object_pvs_set_camera " .. cutsceneCameraPoint)
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
    core.disablePlayerCollision(DisablePlayerCollision)
    -- Start removing the server created bipeds only when the server aks for it
    if blam.isGameDedicated() then
        if enableSync and gameStarted then
            -- Constantly erase locally created AI bipeds
            engine.hsc.executeScript("ai_erase_all")
        end
        if DebugMode then
            if engine.gameState.getPlayer() then
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
    end
end

--- OnPacket
---@param message string
---@return boolean?
function OnPacket(message)
    if not IsSyncEnabled then
        return false
    end
    if DebugMode and DebugLevel >= 4 then
        logger:debug("Received packet: {}", message)
    end
    local packet = message:split(",")
    -- This is a packet sent from the server script for
    if packet and packet[1]:includes("@") then
        local packetType = packet[1]
        processPacket(message, packetType, packet)
        return false
    elseif message:includes("sync_") then
        local data = message:split "sync_"
        local command = data[2]:replace("'", "\""):trim()
        if DebugMode then
            if DebugLevel >= 2 then
                logger:debug("Command: {}", command)
            end
            packetCount = packetCount + 1
        end
        engine.hsc.executeScript(command)
        if command:includes("camera_set") then
            local params = command:split " "
            local cutsceneCameraPoint = params[2]
            if DebugMode then
                if DebugLevel >= 2 then
                    logger:debug("Unlocking cinematic camera: {}", cutsceneCameraPoint)
                end
            end
            engine.hsc.executeScript("object_pvs_set_camera " .. cutsceneCameraPoint)
        end
        return false
    elseif message == "disable_biped_collision" then
        DisablePlayerCollision = true
        return false
    elseif message == "enable_biped_collision" then
        DisablePlayerCollision = false
        return false
    end
end

function OnUnload()
    if engine.core.getTickCount() > 0 then
        DisablePlayerCollision = false
    end
end

function OnPreFrame()
    if DebugMode then
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

local onTickEvent = balltze.event.tick.subscribe(function(event)
    if event.time == "before" then
        OnTick()
    end
end)
local onRconMessageEvent = balltze.event.rconMessage.subscribe(function(event)
    if event.time == "before" then
        if OnPacket(event.context:message()) == false then
            event:cancel()
        end
    end
end)
local onFrame = balltze.event.frame.subscribe(function(event)
    if event.time == "before" then
        OnPreFrame()
    end
end)

OnLoad()

return {
    unload = function()
        logger:warning("Unloading main")
        onTickEvent:remove()
        onRconMessageEvent:remove()
        onFrame:remove()
        OnUnload()
    end
}
