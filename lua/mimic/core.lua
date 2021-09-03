local glue = require "glue"
local blam = require "blam"
local color = require "ncolor"

local core = {}
local lastLog = ""

local concat = table.concat

---@class aiData
---@field tagId number
---@field objectId number
---@field objectIndex number
---@field timeSinceLastUpdate number

-- Mimic constants
local spawnPacketTemplate = "@s,%s,%s"
local updatePacketTemplate = "@u,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s"
local deletePacketTemplate = "@k,%s"

function core.log(message, ...)
    if (debugMode) then
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
    return glue.string.tohex(string.pack(format, value))
end

function core.decode(format, value)
    return string.unpack(format, glue.string.fromhex(value))
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

---Create a packet string to spawn an AI
---@param tagId number
---@param serverId number
---@return string spawnPacket
function core.spawnPacket(tagId, serverId)
    local tagIndex = core.getIndexById(tagId)
    return spawnPacketTemplate:format(tagId, serverId)
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
        
        return updatePacketTemplate:format(serverId, core.encode("f", biped.x),
                                           core.encode("f", biped.y), core.encode("f", biped.z),
                                           biped.animation, biped.animationFrame,
                                           core.encode("f", biped.vX), core.encode("f", biped.vY), color.decToHex(biped.redA, biped.greenA, biped.blueA), invisible)
    else
        local vehicle = blam.object(get_object(biped.vehicleObjectId))
        if (vehicle) then
            updatePacketTemplate:format(serverId, core.encode("f", vehicle.x),
                                        core.encode("f", vehicle.y), core.encode("f", vehicle.z),
                                        biped.animation, biped.animationFrame,
                                        core.encode("f", biped.vX), core.encode("f", biped.vY), color.decToHex(biped.redA, biped.greenA, biped.blueA), invisible)
        end
    end
end

function core.deletePacket(serverId)
    return deletePacketTemplate:format(serverId)
end

function core.positionPacket(player)
    return ("%s,%s,%s,%s"):format("@p", core.encode("f", player.xVel),
                                  core.encode("f", player.yVel), core.encode("f", player.zVel))
end

--- Check if player is near by to an object
---@param target blamObject
---@param sensitivity number
function core.objectIsNearTo(player, target, sensitivity)
    -- local player = blam.object(get_dynamic_player())
    if (target and player) then
        local distance = math.sqrt((target.x - player.x) ^ 2 + (target.y - player.y) ^ 2 +
                                       (target.z - player.z) ^ 2)
        if (math.abs(distance) < sensitivity) then
            return true
        end
    end
    return false
end

function core.syncBiped(tagId, x, y, z, vX, vY, animation, animationFrame, r, g, b, invisible)
    local objectId = spawn_object(tagId, x, y, z)
    if (objectId) then
        dprint("Syncing biped...")
        local biped = blam.biped(get_object(objectId))
        if (biped) then
            biped.x = x
            biped.y = y
            biped.z = z
            biped.vX = vX
            biped.vY = vY
            biped.animation = animation
            biped.animationFrame = animationFrame
            biped.isNotDamageable = true
            biped.zVel = 0.00001
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
        if (biped) then
            biped.x = x
            biped.y = y
            biped.z = z
            biped.vX = vX
            biped.vY = vY
            biped.animation = animation
            biped.animationFrame = animationFrame
            biped.isNotDamageable = true
            biped.isHealthEmpty = false
            biped.zVel = 0.00001
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

return core
