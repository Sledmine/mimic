local glue = require "glue"
local blam = require "blam"

local core = {}

local concat = table.concat

-- Mimic constants
local spawnPacketTemplate = "@s,%s,%s"
local updatePacketTemplate = "@u,%s,%s,%s,%s,%s,%s,%s,%s"
local deletePacketTemplate = "@k,%s"

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
    return updatePacketTemplate:format(serverId, core.encode("f", biped.x),
                                       core.encode("f", biped.y), core.encode("f", biped.z),
                                       biped.animation, biped.animationFrame,
                                       core.encode("f", biped.vX), core.encode("f", biped.vY))
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

function core.syncBiped(tagId, x, y, z, vX, vY, animation, animationFrame)
    local objectId = spawn_object(tagId, x, y, z)
    if (objectId) then
        dprint("Syncing biped...")
        local biped = blam.object(get_object(objectId))
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
            return objectId
        end
    else
        dprint("Error, at trying to create new sync biped.")
    end
    return false
end

function core.updateBiped(objectId, x, y, z, vX, vY, animation, animationFrame)
    if (objectId) then
        local biped = blam.object(get_object(objectId))
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
            return true
        end
    else
        dprint("Error, at trying to sync biped.")
    end
    return false
end

return core
