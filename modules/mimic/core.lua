local glue = require "glue"

local core = {}

local concat = table.concat

-- Mimic constants
local spawnPacketTemplate = "@s,%s,%s,%s,%s"
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

function core.spawnObject(tagId, x, y, z)

end

---Create a packet string to spawn an AI
---@param tagId number
---@param serverId number
---@return string spawnPacket
function core.spawnPacket(serverId, ai)
    return spawnPacketTemplate:format(serverId, ai.x, ai.y, ai.z)
end

---Create a packet string to spawn an AI
---@param serverId number
---@param biped biped
---@return string updatePacket
function core.updatePacket(serverId, biped)
    return updatePacketTemplate:format(serverId, core.encode("f", biped.x),
                                       core.encode("f", biped.y),
                                       core.encode("f", biped.z), biped.animation,
                                       biped.animationFrame, core.encode("f", biped.vX),
                                       core.encode("f", biped.vY))
end

function core.deletePacket(serverId)
    return deletePacketTemplate:format(serverId)
end

local function isAround(a, b, threshold)
    threshold = 0.5
    local diff = math.abs(a - b) -- Absolute value of difference
    printd("Diff: %s", diff)
    local result = diff < threshold
    printd("result: %s", tostring(result))
    return result
end

function core.findSyncCandidate(syncAi)
    for _, objectIndex in pairs(blam.getObjects()) do
        local object = blam.object(get_object(objectIndex))
        if (object) then
            if (object.type == objectClasses.biped and blam.isNull(object.playerId)) then
                if (object.tagId ~= playerBipedTagId) then
                    if (object and not object.isHealthEmpty and object.health > 0 and isAround(syncAi.x, object.x) and
                        isAround(syncAi.y, object.y) and isAround(syncAi.z, object.z)) then
                        return objectIndex
                    end
                end
            end
        end
    end
    return nil
end

return core
