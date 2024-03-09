local glue = require "glue"
local luna = require "luna"
local inspect = require "inspect"
local split = luna.string.split
local tohex = glue.string.tohex
local fromhex = glue.string.fromhex
local append = glue.append
local shift = glue.shift
local trim = glue.string.trim
local escape = glue.string.esc
local starts = luna.string.startswith
local sqrt = math.sqrt
local abs = math.abs
local floor = math.floor
local memoize = require "memoize"
local strpack = string.pack
local strunpack = string.unpack
local concat = table.concat
local blam = require "blam"
local isNull = blam.isNull
local color = require "ncolor"

local hsc = require "mimic.hsc"

local core = {}
local lastLog = ""
local packetSeparator = ","

function core.debug(message, ...)
    if (DebugMode) then
        if (...) then
            local formattedMessage = string.format(message, ...)
            if (lastLog ~= formattedMessage) then
                lastLog = formattedMessage
                console_out(formattedMessage)
            end
            return
        end
        if (lastLog ~= message) then
            lastLog = message
            console_out(message)
        end
        return
    end
end

local function encodeU(format, value)
    -- TODO We might want to memoize this to improve performance
    return tohex(strpack(format, value))
end
local encode = memoize(encodeU)
core.encode = encode

local function decodeU(format, value)
    -- TODO We might want to memoize this to improve performance
    return strunpack(format, fromhex(value))
end
local decode = memoize(decodeU)
core.decode = decode

--- Create an object color packet string
---@param syncedIndex number
---@param object blamObject
---@return string
function core.objectColorPacket(syncedIndex, object)
    local packet = concat({
        "@c",
        syncedIndex,
        color.decToHex(object.colorAUpperRed, object.colorAUpperGreen, object.colorAUpperBlue),
        color.decToHex(object.colorBUpperRed, object.colorBUpperGreen, object.colorBUpperBlue),
        color.decToHex(object.colorCUpperRed, object.colorCUpperGreen, object.colorCUpperBlue),
        color.decToHex(object.colorDUpperRed, object.colorDUpperGreen, object.colorDUpperBlue),
        object.shaderPermutationIndex

    }, packetSeparator)
    assert(#packet <= 64, "Packet size is too big")
    return packet
end

---Create an object update packet string
---@param syncedIndex number
---@param object blamObject
---@return string? updatePacket
function core.updateObjectPacketNoParent(syncedIndex, object)
    local yaw, pitch, roll = blam.getObjectRotation(object)
    return concat({
        "@u",
        syncedIndex,
        encode("f", object.x),
        encode("f", object.y),
        encode("f", object.z),
        object.animation,
        object.animationFrame,
        encode("f", yaw),
        encode("f", pitch),
        encode("f", roll)
    }, packetSeparator)
end

---Create an object update packet string
---@param syncedIndex number
---@param object blamObject
---@return string? updatePacket
function core.updateObjectPacket(syncedIndex, object)
    local yaw, pitch, roll = blam.getObjectRotation(object)
    local packet = {
        "@u",
        syncedIndex,
        encode("f", object.x),
        encode("f", object.y),
        encode("f", object.z),
        object.animation,
        object.animationFrame,
        encode("f", yaw),
        encode("f", pitch),
        encode("f", roll)
    }
    -- Send absolute object coordinates for vehicles until we can sync parented objects
    local isVehicle = object.class == blam.objectClasses.vehicle
    if isVehicle then
        local absolute = blam.getAbsoluteObjectCoordinates(object)
        packet[3] = encode("f", absolute.x)
        packet[4] = encode("f", absolute.y)
        packet[5] = encode("f", absolute.z)
    end
    return concat(packet, packetSeparator)
end

function core.infoPacket(votesLeft, difficulty)
    return concat({"@i", votesLeft, difficulty}, packetSeparator)
end

--- Create a packet string to define object properties
---@param syncedIndex number
---@param unit unit
function core.unitProperties(syncedIndex, unit)
    local parentSeatIndex
    local parentObjectSyncedIndex = core.getSyncedIndexByObjectId(unit.parentObjectId)
    if not isNull(unit.parentSeatIndex) then
        parentSeatIndex = unit.parentSeatIndex
    end
    local packet = concat({
        "@o",
        syncedIndex,
        -- concat({
        unit.regionPermutation1,
        unit.regionPermutation2,
        unit.regionPermutation3,
        unit.regionPermutation4,
        unit.regionPermutation5,
        unit.regionPermutation6,
        unit.regionPermutation7,
        unit.regionPermutation8,
        -- }),
        unit.isCamoActive and 1 or 0,
        parentObjectSyncedIndex or "",
        parentSeatIndex or "",
        unit.team
    }, packetSeparator)
    assert(#packet <= 64, "Packet size is too big")
    return packet
end

--- Create a packet string to define biped properties
---@param syncedIndex number
---@param biped biped
function core.bipedProperties(syncedIndex, biped)
    local packet = concat({
        "@b",
        syncedIndex,
        core.getSyncedIndexByObjectId(biped.firstWeaponObjectId) or "",
        core.getSyncedIndexByObjectId(biped.secondWeaponObjectId) or "",
        biped.flashlight and 1 or 0
    }, packetSeparator)
    assert(#packet <= 64, "Packet size is too big")
    return packet
end

--- Check if biped is near by to an object
---@param biped blamObject
---@param target blamObject
---@param sensitivity number
function core.objectIsNearTo(biped, target, sensitivity)
    if target and biped then
        local distance = sqrt((target.x - biped.x) ^ 2 + (target.y - biped.y) ^ 2 +
                                  (target.z - biped.z) ^ 2)
        if abs(distance) < sensitivity then
            return true
        end
    end
    return false
end

function core.updateObject(objectId, x, y, z, yaw, pitch, roll, animation, animationFrame)
    if objectId then
        local object = blam.object(get_object(objectId))
        -- NOTES:
        -- 1. Apparently dead bipeds might not have to be updated
        -- 2. Objects outside the map lag the game when updated for some reason
        if not object then
            return false
        end
        if object.isOutSideMap then
            return false
        end
        if object.isApparentlyDead then
            return false
        end
        local isBiped = object.class == blam.objectClasses.biped
        local isVehicle = object.class == blam.objectClasses.vehicle
        object.x = x
        object.y = y
        object.z = z
        object.zVel = 0
        blam.rotateObject(object, yaw, pitch, roll)

        if isBiped then
            object.animation = animation
            object.animationFrame = animationFrame
        end
        -- if isShooting and not isNull(unit.firstWeaponObjectId) then
        --    local weapon = blam.weapon(get_object(unit.firstWeaponObjectId))
        --    if weapon then
        --        weapon.primaryTriggerState = isShooting
        --    end
        -- end
        return true
    end
    return false
end

--- "Virtualize" biped object, applies required transformations for easier network sync
---@param biped blamObject
function core.virtualizeObject(biped)
    -- Do not make biped ghost if it has a parent object
    if isNull(biped.parentObjectId) then
        biped.isGhost = false
    end
    -- biped.isOutSideMap = false
    biped.isNotDamageable = true
    -- biped.isNotAffectedByGravity = true
    -- biped.isCollideable = true
    -- biped.hasNoCollision = false
end

--- Hide biped object from the game, apply transformations to somehow hide the specifed biped
---@param biped blamObject
function core.hideBiped(biped)
    biped.isGhost = true
    biped.isNotDamageable = true
    biped.isNotAffectedByGravity = true
    biped.isCollideable = false
    biped.hasNoCollision = true
end

--- Revert virtualization transformations
---@param biped blamObject
function core.revertBipedVirtualization(biped)
    biped.isGhost = false
    biped.isNotDamageable = false
    biped.isNotAffectedByGravity = false
    biped.isCollideable = true
    biped.hasNoCollision = false
end

--- Normalize any map name or snake case name to a name with sentence case
---@param name string
function core.toSentenceCase(name)
    return string.gsub(" " .. name:gsub("_", " "), "%W%l", string.upper):sub(2)
end

---Parse and strip any hsc command into individual parts
---@param hscCommand string
---@return string[]
function core.parseHSC(hscCommand)
    local parsedCommand = trim(hscCommand)
    -- Get words only inside '' with one or more characters from the set [a-Z,0-9, ,-,_,\\]
    for word in hscCommand:gmatch("'[%w%- _\\]+'") do
        local fixed = word:gsub("'", ""):gsub(" ", "%%20")
        parsedCommand = parsedCommand:gsub(escape(word), escape(fixed))
    end
    local commandData = split(parsedCommand, " ")
    -- Get just parameters from the entire command, remove space escaping
    ---@type string[]
    local params = table.map(commandData, function(parameter)
        -- return parameter:gsub("%%20", " ")
        return parameter:replace("%20", " ")
    end)
    return params
end

--- Process HSC code from the Harmony hook
---@param hscCommand string
---@return string?
function core.adaptHSC(hscCommand)
    -- Check if the map is trying to get a player on a vehicle
    if starts(hscCommand, "sync_unit_enter_vehicle") and hscCommand:find("player") then
        local params = core.parseHSC(hscCommand)
        local unitName = params[2]
        local begin, last = unitName:find("player")
        local playerIndex = to_player_index(tonumber(unitName:sub(last + 1, last + 2), 10))
        local objectName = params[3]
        local seatIndex = tonumber(params[4], 10)
        for vehicleObjectId, vehicleTagId in pairs(VehiclesList) do
            local vehicle = blam.object(get_object(vehicleObjectId))
            if vehicle and not isNull(vehicle.nameIndex) then
                local scenario = blam.scenario(0)
                local objectScenarioName = scenario.objectNames[vehicle.nameIndex + 1]
                if objectName == objectScenarioName then
                    if player_present(playerIndex) then
                        console_debug("Player " .. playerIndex .. " will enter vehicle " ..
                                          vehicleObjectId .. " on seat " .. seatIndex)
                        enter_vehicle(vehicleObjectId, playerIndex, seatIndex)
                    end
                end
            end
        end
        return
    elseif starts(hscCommand, "sync_object_create ") or
        starts(hscCommand, "sync_object_create_anew ") then
        -- Only sync object creation if object is not a vehicle
        local params = core.parseHSC(hscCommand)
        local objectName = params[2]
        for vehicleObjectId, vehicleTagId in pairs(VehiclesList) do
            local vehicle = blam.object(get_object(vehicleObjectId))
            if vehicle and not isNull(vehicle.nameIndex) then
                local scenario = blam.scenario(0)
                assert(scenario, "Failed to load scenario tag")
                local objectScenarioName = scenario.objectNames[vehicle.nameIndex + 1]
                if (objectName == objectScenarioName) then
                    return
                end
            end
        end
    elseif (starts(hscCommand, "sync_object_teleport") and hscCommand:find("player")) then
        -- Cancel player teleport on client to prevent desync
        -- TODO Remove sync for this from the Mimic adapter, it will prevent crashes on client
        return
    elseif (starts(hscCommand, "sync_unit_suspended") and hscCommand:find("player")) then
        local params = core.parseHSC(hscCommand)
        local unitName = params[2]
        local begin, last = unitName:find("player")
        local playerIndex = to_player_index(tonumber(unitName:sub(last + 1, last + 2), 10))
        local playerBiped = blam.biped(get_dynamic_player(playerIndex))
        if (playerBiped and not isNull(playerBiped.vehicleObjectId)) then
            say_all("Erasing player vehicle...")
            delete_object(playerBiped.vehicleObjectId)
        end
        return
    elseif (hscCommand:find("nav_point")) then
        -- FIXME This is not working for some reason
        for playerIndex = 0, 15 do
            Broadcast(hscCommand:gsub("player0", "player" .. playerIndex))
        end
        return
    else
        for actionName, action in pairs(hsc) do
            -- Check if command has parameters
            if starts(hscCommand, "sync_" .. actionName .. " ") then
                -- Escape spaces and quotes
                console_debug("Raw command: " .. hscCommand)

                local params = core.parseHSC(hscCommand)
                params = shift(params, 1, -1)

                -- Structure that holds command data
                local syncPacketData = {action.packetType}

                -- Transform parameters into blam terms, IDs, indexes, etc
                for parameterIndex, parameter in pairs(action.parameters) do
                    local argumentValue = params[parameterIndex]
                    if argumentValue then
                        if parameter.value and parameter.class then
                            argumentValue = tostring(blam.getTag(argumentValue, parameter.class).id)
                        end
                        append(syncPacketData, argumentValue)
                    end
                end

                local syncPacket = concat(syncPacketData, ",")
                return syncPacket
            end
        end
    end
    return hscCommand
end

--- Get the synced network index of an object by object id
---@param localObjectId number
---@return number?
function core.getSyncedIndexByObjectId(localObjectId)
    for index = 0, 509 do
        local objectId = blam.getObjectIdBySyncedIndex(index)
        if objectId and objectId == localObjectId then
            return index
        end
    end
    return nil
end

--- Check if player is looking at object main frame
---@param mainObject? number
---@param target number
---@param sensitivity number
---@param zOffset number
---@param maximumDistance number
function core.objectIsLookingAt(mainObject, target, sensitivity, zOffset, maximumDistance)
    -- Minimum amount for distance scaling
    local baselineSensitivity = 0.012
    local function read_vector3d(Address)
        return read_float(Address), read_float(Address + 0x4), read_float(Address + 0x8)
    end
    local targetObject = get_object(target)
    -- Both objects must exist
    if (targetObject and mainObject) then
        local playerX, playerY, playerZ = read_vector3d(mainObject + 0xA0)
        local cameraX, cameraY, cameraZ = read_vector3d(mainObject + 0x230)
        -- Target location 2
        local targetX, targetY, targetZ = read_vector3d(targetObject + 0x5C)
        -- 3D distance
        local distance = sqrt((targetX - playerX) ^ 2 + (targetY - playerY) ^ 2 +
                                  (targetZ - playerZ) ^ 2)
        local localX = targetX - playerX
        local localY = targetY - playerY
        local localZ = (targetZ + (zOffset or 0)) - playerZ
        local pointX = 1 / distance * localX
        local pointY = 1 / distance * localY
        local pointZ = 1 / distance * localZ
        local xDiff = abs(cameraX - pointX)
        local yDiff = abs(cameraY - pointY)
        local zDiff = abs(cameraZ - pointZ)
        local average = (xDiff + yDiff + zDiff) / 3
        local scaler = 0
        if distance > 10 then
            scaler = floor(distance) / 1000
        end
        local aimMagnetisim = sensitivity - scaler
        if aimMagnetisim < baselineSensitivity then
            aimMagnetisim = baselineSensitivity
        end
        if average < aimMagnetisim and distance < (maximumDistance or 15) then
            return true
        end
    end
    return false
end

--- Get the synced biped ids
---@return number[]
function core.getSyncedBipedIds()
    local syncedBipedIds = {}
    for index = 0, 509 do
        local objectId = blam.getObjectIdBySyncedIndex(index)
        if objectId then
            local object = blam.object(get_object(objectId))
            if object and object.class == blam.objectClasses.biped then
                -- table.insert(syncedBipedIds, objectId)
                syncedBipedIds[index] = objectId
            end
        end
    end
    return syncedBipedIds
end

--- Get the synced biped ids
---@return number[]
function core.getSyncedObjectsIds()
    local syncedObjectsIds = {}
    for index = 0, 509 do
        local objectId = blam.getObjectIdBySyncedIndex(index)
        if objectId then
            local object = blam.object(get_object(objectId))
            if object then
                table.insert(syncedObjectsIds, objectId)
            end
        end
    end
    return syncedObjectsIds
end

---Validate if a biped is syncable
---@param object blamObject
---@param objectId number
function core.isObjectSynceable(object, objectId)
    -- Filter server bipeds that are already synced
    for playerIndex = 1, 16 do
        local playerObjectAdress = get_dynamic_player(playerIndex)
        local unit = blam.unit(playerObjectAdress)
        if unit and unit.parentObjectId == objectId then
            return false
        end
        local aiObjectAddress = get_object(objectId)
        -- AI is the same as the player, do not sync
        if playerObjectAdress == aiObjectAddress then
            return false
        end
    end
    -- Only sync ai inside the same bsp as the players
    if object.isOutSideMap then
        return false
    end
    if isNull(object.nameIndex) then
        -- return false
    end
    return true
end

local synceableObjectProperties = {
    "regionPermutation1",
    "regionPermutation2",
    "regionPermutation3",
    "regionPermutation4",
    "regionPermutation5",
    "regionPermutation6",
    "regionPermutation7",
    "regionPermutation8",
    "parentObjectId",
    "parentSeatIndex"
}

--- Check if unit should be synced
---@param unit unit
---@param lastObjectProperties table
---@return boolean
function core.unitPropertiesShouldBeSynced(unit, lastObjectProperties)
    for _, property in pairs(synceableObjectProperties) do
        if unit[property] ~= lastObjectProperties[property] then
            return true
        end
    end
    return false
end

local synceableBipedProperties = {
    "isCamoActive",
    "firstWeaponObjectId",
    "secondWeaponObjectId",
    "flashlight"
}

--- Check if biped should be synced
---@param biped biped
---@param lastBipedProperties table
---@return boolean
function core.bipedShouldBeSynced(biped, lastBipedProperties)
    for _, property in pairs(synceableBipedProperties) do
        if biped[property] ~= lastBipedProperties[property] then
            return true
        end
    end
    return false
end

local setDisconnectedFlagAddress = 0x004cbbb0 + 0x1
local stockTimeout = 15000
local expandedTimeout = 45000
function core.patchPlayerConnectionTimeout(revert)
    safe_write(true)
    -- Increase player connection timeout
    if revert then
        write_word(setDisconnectedFlagAddress, stockTimeout)
        safe_write(false)
        return
    end
    write_word(setDisconnectedFlagAddress, expandedTimeout)
    safe_write(false)
end

return core
