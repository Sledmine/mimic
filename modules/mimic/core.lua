local glue = require "glue"

local core = {}

local concat = table.concat

-- Mimic constants
local spawnPacketTemplate = "@s,%s,%s"

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

return core
