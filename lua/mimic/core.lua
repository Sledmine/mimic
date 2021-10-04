local glue = require "glue"
local split = glue.string.split
local blam = require "blam"
local color = require "ncolor"

local core = {}
local lastLog = ""
local difficulties = {"Easy", "Normal", "Heroic", "Legendary"}

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
    local invisible = 0
    if (biped.invisible) then
        invisible = 1
    end
    if (blam.isNull(biped.vehicleObjectId)) then

        return updatePacketTemplate:format(serverId, core.encode("f", biped.x),
                                           core.encode("f", biped.y), core.encode("f", biped.z),
                                           biped.animation, biped.animationFrame,
                                           core.encode("f", biped.vX), core.encode("f", biped.vY),
                                           color.decToHex(biped.redA, biped.greenA, biped.blueA),
                                           invisible)
    else
        local vehicle = blam.object(get_object(biped.vehicleObjectId))
        if (vehicle) then
            updatePacketTemplate:format(serverId, core.encode("f", vehicle.x),
                                        core.encode("f", vehicle.y), core.encode("f", vehicle.z),
                                        biped.animation, biped.animationFrame,
                                        core.encode("f", biped.vX), core.encode("f", biped.vY),
                                        color.decToHex(biped.redA, biped.greenA, biped.blueA),
                                        invisible)
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

function core.infoPacket(votesLeft, difficulty)
    return concat({"@i", votesLeft, difficulty}, ",")
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

function core.eulerToRotation(matrix)
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
            glue.append(tagsList, {
                id = tag.id,
                path = tag.path,
                index = tag.index,
                class = tag.class,
                indexed = tag.indexed,
                data = tag.data
            })
        end
    end
    return tagsList
end

function core.loadCoopMenu(open)
    local coopMenuTag = core.findTag("coop_menu_screen", tagClasses.uiWidgetDefinition)
    local bipedsListTag = core.findTag("coop_menu\\strings\\buttons", tagClasses.unicodeStringList)
    if (coopMenuTag and bipedsListTag) then
        local bipedTags = core.findTagsList("_mp", tagClasses.biped)
        local bipedsList = blam.unicodeStringList(bipedsListTag.id)
        local newBipeds = bipedsList.stringList
        for index, tag in pairs(bipedTags) do
            local tagPath = tag.path
            local tagSplit = split(tagPath, "\\")
            local bipedName = tagSplit[#tagSplit]:gsub("_mp", ""):gsub("_", " "):upper()
            newBipeds[index + 1] = bipedName
        end
        bipedsList.stringList = newBipeds
        if (open) then
            load_ui_widget(coopMenuTag.path)
        end
        return bipedTags
    end
end

function core.updateCoopInfo(newVotes, difficulty)
    local votesStringsTag = core.findTag("coop_menu\\strings\\votes", tagClasses.unicodeStringList)
    local difficultiesTag = core.findTag("game_difficulties", tagClasses.bitmap)
    if (votesStringsTag and difficultiesTag) then
        local votesStrings = blam.unicodeStringList(votesStringsTag.id)
        local newStringVotes = votesStrings.stringList
        newStringVotes[1] = tostring(newVotes)
        votesStrings.stringList = newStringVotes
        local difficultyBitmap = blam.bitmap(difficultiesTag.id)
        local newSequences = difficultyBitmap.sequences
        newSequences[1].firstBitmapIndex = difficulty - 1
        difficultyBitmap.sequences = newSequences
    end
end

function core.getRequiredVotes()
    if (DebugMode) then
        return 1
    end
    local playersCount = tonumber(get_var(0, "$pn"))
    local requiredVotes = playersCount
    if (playersCount > 5) then
        requiredVotes = glue.floor(playersCount / 2)
    end
    return requiredVotes
end

function core.enableSpawns()
    local scenario = blam.scenario(0)
    if (scenario) then
        local playerSpawns = scenario.spawnLocationList
        --for spawnIndex in pairs(playerSpawns) do
        --    playerSpawns[spawnIndex].type = 12
        --end
        playerSpawns[1].type = 12
        scenario.spawnLocationList = playerSpawns
    end
end

function core.registerVote(playerIndex)
    if (not CoopStarted) then
        local playerName = get_var(playerIndex, "$name")
        local requiredVotes = core.getRequiredVotes()
        VotesList[playerIndex] = true
        local votesCount = #glue.keys(VotesList)
        local remainingVotes = requiredVotes - votesCount
        say_all(playerName .. " is ready for coop! (" .. votesCount .. " / " .. requiredVotes .. ")")
        if (votesCount >= requiredVotes) then
            CoopStarted = true
            local currentMapName = get_var(0, "$map")
            local splitName = glue.string.split(currentMapName, "_")
            local baseNoCoopName = splitName[1]
            core.enableSpawns()
            execute_script("wake main_" .. baseNoCoopName)
        end
        return remainingVotes
    end
end

return core
