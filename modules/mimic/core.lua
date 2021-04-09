local glue = require "glue"

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
    return spawnPacketTemplate:format(tagIndex, serverId)
end

---Create a packet string to spawn an AI
---@param serverId number
---@param biped biped
---@return string updatePacket
function core.updatePacket(serverId, biped)
    return updatePacketTemplate:format(serverId, core.encode("f", biped.x), core.encode("f", biped.y), core.encode("f", biped.z), biped.animation, biped.animationFrame, core.encode("f", biped.vX), core.encode("f", biped.vY))
end

function core.deletePacket(serverId)
    return deletePacketTemplate:format(serverId)
end


return core