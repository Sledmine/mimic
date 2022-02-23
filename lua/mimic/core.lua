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
local color = require "ncolor"

local strpack = string.pack
local strunpack = string.unpack
local concat = table.concat

local hsc = require "mimic.hsc"

local core = {}
local lastLog = ""
local packetSeparator = ","

---@class aiData
---@field tagId number
---@field objectId number
---@field objectIndex number
---@field timeSinceLastUpdate number

function core.log(message, ...)
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
        if (vehicle) then
            concat({
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
    -- biped.zVel = 0
    -- biped.xVel = 0
    -- biped.yVel = 0
end

--- Hide biped object from the game, apply transformations to somehow hide the specifed biped
---@param biped blamObject
function core.hideBiped(biped)
    biped.isGhost = true
    biped.isNotDamageable = true
    biped.ignoreGravity = true
    biped.isCollideable = false
    biped.hasNoCollision = true
    -- biped.zVel = 0
    -- biped.xVel = 0
    -- biped.yVel = 0
    -- biped.x = 0
    -- biped.y = 0
    -- biped.z = 0
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

--- Find the path, index and id of a tag given partial name and tag type
---@param partialName string
---@param searchTagType string
---@return tag tag
function core.findTag(partialName, searchTagType)
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tag = blam.getTag(tagIndex)
        if (tag and tag.path:find(partialName) and tag.class == searchTagType) then
            return {
                id = tag.id,
                path = tag.path,
                index = tag.index,
                class = tag.class,
                indexed = tag.indexed,
                data = tag.data
            }
        end
    end
    return nil
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

--- Find the path, index and id of a list of tags given partial name and tag type
---@param partialName string
---@param searchTagType string
---@return tag[] tag
function core.findTagsList(partialName, searchTagType)
    local tagsList
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tag = blam.getTag(tagIndex)
        if (tag and tag.path:find(partialName) and tag.class == searchTagType) then
            if (not tagsList) then
                tagsList = {}
            end
            tagsList[#tagsList + 1] = {
                id = tag.id,
                path = tag.path,
                index = tag.index,
                class = tag.class,
                indexed = tag.indexed,
                data = tag.data
            }
        end
    end
    return tagsList
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
---@return boolean
function core.adaptHSC(hscCommand)
    -- Check if the map is trying to get a player on a vehicle
    if (hscCommand:find("unit_enter_vehicle") and hscCommand:find("player")) then
        local params = core.parseHSC(hscCommand)

        local unitName = params[2]
        -- local playerIndex = to_player_index(tonumber(params[2], 10))
        local playerIndex = to_player_index(tonumber(unitName:gsub("player", ""), 10))
        local objectName = params[3]
        local seatIndex = tonumber(params[4], 10)
        for vehicleObjectId, vehicleTagId in pairs(VehiclesList) do
            local vehicle = blam.object(get_object(vehicleObjectId))
            if (vehicle and not blam.isNull(vehicle.nameIndex)) then
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
    elseif (hscCommand:find("object_create")) then
        -- Prevent client object creation only if server creates a non biped/vehicle object
        local params = core.parseHSC(hscCommand)

        local objectName = params[2]
        for vehicleObjectId, vehicleTagId in pairs(VehiclesList) do
            local vehicle = blam.object(get_object(vehicleObjectId))
            if (vehicle and not blam.isNull(vehicle.nameIndex)) then
                local scenario = blam.scenario(0)
                local objectScenarioName = scenario.objectNames[vehicle.nameIndex + 1]
                if (objectName == objectScenarioName) then
                    return
                end
            end
        end
    elseif (hscCommand:find("object_teleport") and hscCommand:find("player")) then
        -- Cancel player teleport on client to prevent desync
        return
    elseif (hscCommand:find("nav_point")) then
        -- FIXME This is not working for some reason
        for playerIndex = 0, 15 do
            Broadcast(hscCommand:gsub("player0", "player" .. playerIndex))
        end
        return
    elseif (hscCommand:find("camera_control")) then
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
            if (starts(hscCommand, actionName .. " ")) then
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
        if (ai and not ai.isHealthEmpty) then
            if (blam.isNull(ai.nameIndex)) then
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

return core
