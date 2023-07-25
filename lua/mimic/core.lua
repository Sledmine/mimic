local glue = require "glue"
local inspect = require "inspect"
local split = glue.string.split
local tohex = glue.string.tohex
local fromhex = glue.string.fromhex
local append = glue.append
local shift = glue.shift
local map = glue.map
local trim = glue.string.trim
local escape = glue.string.esc
local starts = glue.string.starts

local blam = require "blam"
local isNull = blam.isNull
local color = require "ncolor"

local strpack = string.pack
local strunpack = string.unpack
local concat = table.concat

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

function core.encode(format, value)
    return tohex(strpack(format, value))
end
local encode = core.encode

function core.decode(format, value)
    return strunpack(format, fromhex(value))
end

--- Get index value from an id value type
---@param id number
---@return number index
function core.getIndexById(id)
    local hex = glue.string.tohex(id)
    local bytes = {}
    for i = 5, #hex, 2 do
        glue.append(bytes, hex:sub(i, i + 1))
    end
    return tonumber(concat(bytes, ""), 16)
end

--- Create a position data packet
---@param biped blamObject
---@param serverId number
---@return string
function core.positionPacket(serverId, biped)
    return concat({
        "@p",
        serverId,
        biped.tagId,
        encode("f", biped.x),
        encode("f", biped.y),
        encode("f", biped.z)
    }, packetSeparator)
end

---Create a packet string to spawn an AI
---@param serverId number
---@param biped biped
---@return string updatePacket
function core.updatePacket(serverId, biped)
    local invisible = 0
    if (biped.invisible) then
        invisible = 1
    end
    if (blam.isNull(biped.vehicleObjectId)) then
        return concat({
            "@u",
            serverId,
            encode("f", biped.x),
            encode("f", biped.y),
            encode("f", biped.z),
            biped.animation,
            biped.animationFrame,
            encode("f", biped.vX),
            encode("f", biped.vY),
            color.decToHex(biped.redA, biped.greenA, biped.blueA),
            invisible
        }, packetSeparator)
    else
        local vehicle = blam.object(get_object(biped.vehicleObjectId))
        if vehicle then
            -- TODO Check if this somehow works cause it used to be not returned from the function
            return concat({
                "@u",
                serverId,
                encode("f", vehicle.x),
                encode("f", vehicle.y),
                encode("f", vehicle.z),
                biped.animation,
                biped.animationFrame,
                encode("f", biped.vX),
                encode("f", biped.vY),
                color.decToHex(biped.redA, biped.greenA, biped.blueA),
                invisible
            }, packetSeparator)
        end
    end
end

function core.deletePacket(serverId)
    return concat({"@k", serverId}, packetSeparator)
end

function core.infoPacket(votesLeft, difficulty)
    return concat({"@i", votesLeft, difficulty}, packetSeparator)
end

--- Check if biped is near by to an object
---@param biped blamObject
---@param target blamObject
---@param sensitivity number
function core.objectIsNearTo(biped, target, sensitivity)
    if (target and biped) then
        local distance = math.sqrt((target.x - biped.x) ^ 2 + (target.y - biped.y) ^ 2 +
                                       (target.z - biped.z) ^ 2)
        if (math.abs(distance) < sensitivity) then
            return true
        end
    end
    return false
end

function core.syncBiped(tagId, x, y, z, vX, vY, animation, animationFrame, r, g, b, invisible)
    local objectId = spawn_object(tagId, x, y, z)
    if (objectId) then
        local biped = blam.biped(get_object(objectId))
        if (biped) then
            biped.x = x
            biped.y = y
            biped.z = z
            biped.vX = vX
            biped.vY = vY
            biped.animation = animation
            biped.animationFrame = animationFrame
            -- biped.zVel = 0.00001
            biped.isNotDamageable = true
            biped.redA = r
            biped.greenA = g
            biped.blueA = b
            biped.invisible = invisible
            return objectId
        end
    else
        dprint("Error, at trying to create new sync biped.")
    end
    return false
end

function core.updateBiped(objectId, x, y, z, vX, vY, animation, animationFrame, r, g, b, invisible)
    if (objectId) then
        local biped = blam.biped(get_object(objectId))
        if (biped and not biped.isHealthEmpty) then
            biped.x = x
            biped.y = y
            biped.z = z
            biped.vX = vX
            biped.vY = vY
            biped.animation = animation
            biped.animationFrame = animationFrame
            biped.zVel = 0
            biped.redA = r
            biped.greenA = g
            biped.blueA = b
            biped.invisible = invisible
            return true
        end
    else
        dprint("Error, at trying to sync biped.")
    end
    return false
end

--- "Virtualize" biped object, applies required transformations for easier network sync
---@param biped blamObject
function core.virtualizeBiped(biped)
    biped.isGhost = false
    biped.isOutSideMap = false
    biped.isNotDamageable = true
    biped.ignoreGravity = true
    biped.isCollideable = true
    biped.hasNoCollision = false
end

--- Hide biped object from the game, apply transformations to somehow hide the specifed biped
---@param biped blamObject
function core.hideBiped(biped)
    biped.isGhost = true
    biped.isNotDamageable = true
    biped.ignoreGravity = true
    biped.isCollideable = false
    biped.hasNoCollision = true
end

--- Revert virtualization transformations
---@param biped blamObject
function core.revertBipedVirtualization(biped)
    biped.isGhost = false
    biped.isNotDamageable = false
    biped.ignoreGravity = false
    biped.isCollideable = true
    biped.hasNoCollision = false
end

--- Normalize any map name or snake case name to a name with sentence case
---@param name string
function core.toSentenceCase(name)
    return string.gsub(" " .. name:gsub("_", " "), "%W%l", string.upper):sub(2)
end

---@class vector3D
---@field x number
---@field y number
---@field z number

--- Covert euler into game rotation array, optional rotation matrix
-- Based on https://www.mecademic.com/en/how-is-orientation-in-space-represented-with-euler-angles
--- @param yaw number
--- @param pitch number
--- @param roll number
--- @return vector3D, vector3D
function core.eulerToRotation(yaw, pitch, roll)
    local yaw = math.rad(yaw)
    local pitch = math.rad(-pitch) -- Negative pitch due to Sapien handling anticlockwise pitch
    local roll = math.rad(roll)
    local matrix = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}

    -- Roll, Pitch, Yaw = a, b, y
    local cosA = math.cos(roll)
    local sinA = math.sin(roll)
    local cosB = math.cos(pitch)
    local sinB = math.sin(pitch)
    local cosY = math.cos(yaw)
    local sinY = math.sin(yaw)

    matrix[1][1] = cosB * cosY
    matrix[1][2] = -cosB * sinY
    matrix[1][3] = sinB
    matrix[2][1] = cosA * sinY + sinA * sinB * cosY
    matrix[2][2] = cosA * cosY - sinA * sinB * sinY
    matrix[2][3] = -sinA * cosB
    matrix[3][1] = sinA * sinY - cosA * sinB * cosY
    matrix[3][2] = sinA * cosY + cosA * sinB * sinY
    matrix[3][3] = cosA * cosB

    local rollVector = {x = matrix[1][1], y = matrix[2][1], z = matrix[3][1]}
    local yawVector = {x = matrix[1][3], y = matrix[2][3], z = matrix[3][3]}
    return rollVector, yawVector, matrix
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
    local params = map(commandData, function(parameter)
        return parameter:gsub("%%20", " ")
    end)
    return params
end

--- Process HSC code from the Harmony hook
---@param hscCommand string
---@return string?
function core.adaptHSC(hscCommand)
    -- Check if the map is trying to get a player on a vehicle
    if (starts(hscCommand, "sync_unit_enter_vehicle") and hscCommand:find("player")) then
        local params = core.parseHSC(hscCommand)
        local unitName = params[2]
        local begin, last = unitName:find("player")
        local playerIndex = to_player_index(tonumber(unitName:sub(last + 1, last + 2), 10))
        local objectName = params[3]
        local seatIndex = tonumber(params[4], 10)
        for vehicleObjectId, vehicleTagId in pairs(VehiclesList) do
            local vehicle = blam.object(get_object(vehicleObjectId))
            if (vehicle and not isNull(vehicle.nameIndex)) then
                local scenario = blam.scenario(0)
                local objectScenarioName = scenario.objectNames[vehicle.nameIndex + 1]
                if (objectName == objectScenarioName) then
                    if (player_present(playerIndex)) then
                        console_out(playerIndex)
                        console_out(objectName)
                        console_out(seatIndex)
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
            if (vehicle and not blam.isNull(vehicle.nameIndex)) then
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
    elseif starts(hscCommand, "sync_camera_control") then
        -- TODO Add cinematic_start and cinematic_stop for accurate cinematic determination
        local params = split(hscCommand, " ")
        IsGameOnCinematic = params[2] == "true"
        if (IsGameOnCinematic) then
            say_all("Warning, game is on cinematic!")
        else
            say_all("Done, cinematic has ended!")
        end
    else
        for actionName, action in pairs(hsc) do
            -- Check if command has parameters
            if starts(hscCommand, "sync_" .. actionName .. " ") then
                -- Escape spaces and quotes
                console_out("Raw command: " .. hscCommand)

                local params = core.parseHSC(hscCommand)
                params = shift(params, 1, -1)

                -- Structure that holds command data
                local syncPacketData = {action.packetType}

                -- Transform parameters into blam terms, IDs, indexes, etc
                for parameterIndex, parameter in pairs(action.parameters) do
                    local argumentValue = params[parameterIndex]
                    if (argumentValue) then
                        if (parameter.value and parameter.class) then
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

function core.dispatchAISpawn(upcomingAiSpawn)
    for objectId, tagId in pairs(upcomingAiSpawn) do
        local ai = blam.biped(get_object(objectId))
        if ai and not ai.isApparentlyDead then
            if blam.isNull(ai.nameIndex) then
                Broadcast(core.positionPacket(objectId, ai))
                upcomingAiSpawn[objectId] = nil
            else
                local bipedName = CurrentScenario.objectNames[ai.nameIndex + 1]
                if (bipedName and bipedName == "captain_keyes" or bipedName == "free_marine_1" or
                    bipedName == "free_marine_2" or bipedName == "free_marine_3") then
                    Broadcast(core.positionPacket(objectId, ai))
                    upcomingAiSpawn[objectId] = nil
                    console_out("Biped " .. bipedName ..
                                    " is an exception that will be synced as AI")
                end
            end
        end
    end
    return upcomingAiSpawn
end

local sqrt = math.sqrt
local abs = math.abs
local floor = math.floor

--- Check if player is looking at object main frame
---@param player number
---@param target number
---@param sensitivity number
---@param zOffset number
---@param maximumDistance number
function core.objectIsLookingAt(player, target, sensitivity, zOffset, maximumDistance)
    -- Minimum amount for distance scaling
    local baselineSensitivity = 0.012
    local function read_vector3d(Address)
        return read_float(Address), read_float(Address + 0x4), read_float(Address + 0x8)
    end
    local mainObject = player
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

return core
