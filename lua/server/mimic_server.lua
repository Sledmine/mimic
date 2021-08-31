------------------------------------------------------------------------------
-- Mimic Server
-- Sledmine (https://github.com/Sledmine)
-- Server side synchronization feature for AI
------------------------------------------------------------------------------
-- Declare api version before importing lua-blam
api_version = "1.12.0.0"

-- Bring compatibility with Lua 5.3
require "compat53"
print("Compatibility with Lua 5.3 has been loaded!")

-- External DLL libraries
local ffi = require "ffi"
ffi.cdef [[
void set_hs_globals_set_callback(void (*callback)(void));
]]
local harmonySapp = ffi.load("./harmony_s.dll")

-- Lua modules
local inspect = require "inspect"
local glue = require "glue"

-- Halo Custom Edition modules
local blam = require "blam"
local core = require "mimic.core"

-- Settings
debugMode = true
local syncRadius = 30
local syncCycle = 100

-- State
local aiList = {}
local aiCollection = {}
local mapBipedTags = {}
local customPlayerBipeds = {}
local vehiclesList = {}
local aiCount = 0
local syncCommand = ""

local function broadcast(message)
    for playerIndex = 1, 16 do
        if (player_present(playerIndex)) then
            rprint(playerIndex, message)
        end
    end
end

local function send(playerIndex, message)
    rprint(playerIndex, message)
end

local function hscSetCallback()
    -- Get value from the hsc value we are looking for via echo event
    execute_command("inspect sync_hsc_command", 0, true)
end

function GetSyncCommand(_, command)
    if (command ~= "nd" and syncCommand ~= command) then
        syncCommand = command
        console_out(syncCommand)
        -- Check if the map is trying to get a player on a vehicle
        if (syncCommand:find("unit_enter_vehicle") and syncCommand:find("player")) then
            local params = glue.string.split(syncCommand, " ")
            local unitName = params[2]
            -- local playerIndex = to_player_index(tonumber(params[2], 10))
            local playerIndex = to_player_index(tonumber(unitName:gsub("player", ""), 10))
            local objectName = params[3]
            local seatIndex = tonumber(params[4], 10)
            for vehicleObjectId, vehicleTagId in pairs(vehiclesList) do
                local vehicle = blam.object(get_object(vehicleObjectId))
                if (vehicle and (not blam.isNull(vehicle.nameIndex))) then
                    local scenario = blam.scenario(0)
                    local objectScenarioName = scenario.objectNames[vehicle.nameIndex + 1]
                    if (objectName == objectScenarioName) then
                        if (player_present(playerIndex)) then
                            console_out(inspect(params))
                            console_out(playerIndex)
                            console_out(objectName)
                            console_out(seatIndex)
                            enter_vehicle(vehicleObjectId, playerIndex, seatIndex)
                        end
                    end
                end
            end
        else
            -- Prevent object creation only if maps wants to create a non biped/vehicle object
            if (syncCommand:find("object_create")) then
                local params = glue.string.split(syncCommand, " ")
                local objectName = params[2]
                for vehicleObjectId, vehicleTagId in pairs(vehiclesList) do
                    local vehicle = blam.object(get_object(vehicleObjectId))
                    if (vehicle and (not blam.isNull(vehicle.nameIndex))) then
                        local scenario = blam.scenario(0)
                        local objectScenarioName = scenario.objectNames[vehicle.nameIndex + 1]
                        if (objectName == objectScenarioName) then
                            return
                        end
                    end
                end
            end
            broadcast(syncCommand)
        end
        -- This is not really required, needs testing as it triggers twice the set callback
        -- FIXME Improve testing on this
        execute_command([[set sync_hsc_command ""]])
    end
end

function CleanBipeds(strServerObjectId)
    local serverObjectId = tonumber(strServerObjectId)
    -- console_out("Cleaning biped " .. serverObjectId)
    aiCollection[serverObjectId] = nil
    aiList[serverObjectId] = nil
    return false
end

local function syncUpdateAI()
    local newAiCount = #glue.keys(aiList)
    if (aiCount ~= newAiCount) then
        aiCount = newAiCount
        -- syncRadius = aiCount * 0.35
        core.log("Syncing %s bipeds...", aiCount)
        core.log("Radius %s", syncRadius)
    end
    local playersCount = tonumber(get_var(0, "$pn"))
    if (playersCount > 0) then
        for serverObjectId, tagId in pairs(aiList) do
            local ai = blam.biped(get_object(serverObjectId))
            if (ai) then
                if (ai.health > 0) then
                    for playerIndex = 1, 16 do
                        if (player_present(playerIndex)) then
                            local player = blam.biped(get_dynamic_player(playerIndex))
                            if (player) then
                                if (blam.isNull(player.vehicleObjectId)) then
                                    if (core.objectIsNearTo(player, ai, syncRadius)) then
                                        -- FIXME In some cases packet is nil, review it
                                        local updatePacket = core.updatePacket(serverObjectId, ai)
                                        if (updatePacket) then
                                            send(playerIndex, updatePacket)
                                        end
                                    end
                                else
                                    local vehicle = blam.object(get_object(player.vehicleObjectId))
                                    if (vehicle and core.objectIsNearTo(vehicle, ai, syncRadius)) then
                                        -- FIXME In some cases packet is nil, review it
                                        local updatePacket = core.updatePacket(serverObjectId, ai)
                                        if (updatePacket) then
                                            send(playerIndex, updatePacket)
                                        end
                                    end
                                end
                            else
                                --local updatePacket = core.updatePacket(serverObjectId, ai)
                                --send(playerIndex, updatePacket)
                            end
                        end
                    end
                else
                    local killPacket = core.deletePacket(serverObjectId)
                    broadcast(killPacket)
                    if (not aiCollection[serverObjectId]) then
                        -- Biped is now dead, remove it from the list
                        -- Set that this biped already has a timer asigned for removal
                        aiCollection[serverObjectId] = true
                        -- Set up a collector timer, it helps to ensure players recive this packet
                        timer(1000, "CleanBipeds", serverObjectId)
                    end
                end
            else
                -- This biped does not exist anymore on the server, erase it
                aiList[serverObjectId] = nil
            end
        end
    end
    return true
end

function OnPlayerJoin(playerIndex)
    -- Set players on the same team for coop purposes
    execute_script("st * red")
    send(playerIndex, "disable_collision")
    for objectId, tagId in pairs(aiList) do
        local spawnPacket = core.spawnPacket(tagId, objectId)
        send(playerIndex, spawnPacket)
    end
end

function OnPlayerDead(deadPlayerIndex)
    local deaths = 0
    local playersCount = tonumber(get_var(0, "$pn"))
    for currentPlayerIndex = 1, 16 do
        if (player_present(currentPlayerIndex) and currentPlayerIndex ~= deadPlayerIndex) then
            local player = blam.biped(get_dynamic_player(currentPlayerIndex))
            if (player and player.health > 0 and not player.isOutSideMap and player.isOnGround) then
                local scenario = blam.scenario(0)
                if (scenario) then
                    local playerName = get_var(currentPlayerIndex, "$name")
                    say_all("Using " .. playerName .. " as a respawn point..")
                    local playerSpawns = scenario.spawnLocationList
                    -- Update second player spawn point on the scenario
                    -- Usually the first spawn point is for local/campaign purposes only
                    -- So handle second player spawn point as a standard from now on
                    if (blam.isNull(player.vehicleObjectId)) then
                        for k,v in pairs(playerSpawns) do
                            playerSpawns[k].x = player.x
                            playerSpawns[k].y = player.y
                            playerSpawns[k].z = player.z
                        end
                    else
                        local vehicle = blam.object(get_object(player.vehicleObjectId))
                        if (vehicle) then
                            for k,v in pairs(playerSpawns) do
                                playerSpawns[k].x = vehicle.x
                                playerSpawns[k].y = vehicle.y
                                playerSpawns[k].z = vehicle.z
                            end
                        end
                    end
                    -- Update player spawns list on the scenario
                    scenario.spawnLocationList = playerSpawns
                    break
                end
            end
            -- FIXME Sometimes this events gets triggered when there is just one player alive
            local playerDeaths = tonumber(get_var(currentPlayerIndex, "$deaths"))
            if (playerDeaths > 0) then
                deaths = deaths + 1
            end
        end
    end
    if (deaths == playersCount) then
        say_all("Game over, AI wins...")
        -- execute_script("sv_map_next")
    end
end

function IncreaseHealth()
    for serverObjectId, tagId in pairs(aiList) do
        local biped = blam.biped(get_object(serverObjectId))
        if (biped and biped.health > 0) then
            biped.health = biped.health + 0.5
        end
    end
    say_all("Increasing AI health...")
    return true
end

function ResetState()
    aiList = {}
    vehiclesList = {}
    mapBipedTags = {}
    customPlayerBipeds = {}
end

function OnGameStart()
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tag = blam.getTag(tagIndex)
        if (tag and tag.class == blam.tagClasses.biped) then
            local pathSplit = glue.string.split(tag.path, "\\")
            local tagFileName = pathSplit[#pathSplit]
            mapBipedTags[tagFileName] = tag
        end
    end
end

function OnCommand(playerIndex, command, environment)
    if (environment == 2) then
        if (command == "blist") then
            glue.map(mapBipedTags, function(bipedName) rprint(playerIndex, bipedName) end)
            return false
        else
            for bipedName, bipedTag in pairs(mapBipedTags) do
                if (command == bipedName) then
                    customPlayerBipeds[playerIndex] = bipedTag
                    local player = blam.player(get_player(playerIndex))
                    local playerBiped = blam.biped(get_object(player.objectId))
                    if (playerBiped) then
                        delete_object(player.objectId)
                    end
                    return false
                end
            end
        end
    elseif (environment == 1) then
        if (command:find("mdis")) then
            local data = glue.string.split(command:gsub('"', ""), " ")
            local newRadius = tonumber(data[2])
            if (newRadius) then
                syncRadius = newRadius
                say_all("AI Count: " .. aiCount)
                say_all("New mimic synchronization radius: " .. newRadius)
                return false
            else
                say_all("AI Count: " .. aiCount )
                say_all("Mimic synchronization radius: " .. syncRadius)
                return false
            end
        end
    end
end

function OnTick()
    for playerIndex = 1,16 do
        if (player_present(playerIndex)) then
            local player = blam.biped(get_dynamic_player(playerIndex))
            if (player) then
                blam.bipedTag(player.tagId).disableCollision = true
            end
        end
    end
end

-- Put initialization code here
function OnScriptLoad()
    ResetState()
    -- Set hsc callback to follow actions requesting synchronization
    harmonySapp.set_hs_globals_set_callback(hscSetCallback)
    -- Netcode does not sync AI projectiles, force it with this
    execute_script("allow_client_side_weapon_projectiles 0")
    -- Start syncing AI every amount of seconds
    SyncUpdateAI = syncUpdateAI
    timer(syncCycle, "SyncUpdateAI")
    -- Set server callback
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
    register_callback(cb["EVENT_GAME_END"], "ResetState")
    --register_callback(cb["EVENT_DIE"], "IncreaseHealth")
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb["EVENT_DIE"], "OnPlayerDead")
    register_callback(cb["EVENT_ECHO"], "GetSyncCommand")
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_COMMAND"], "OnCommand")
end

-- Create a list of AI and Vehicles being spawned
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    local tag = blam.getTag(tagId)
    if (tag) then
        if (tag.class == blam.tagClasses.biped) then
            if (playerIndex == 0) then
                aiList[objectId] = tagId
                local spawnPacket = core.spawnPacket(tagId, objectId)
                broadcast(spawnPacket)
            else
                local customBipedTag = customPlayerBipeds[playerIndex]
                if (customBipedTag) then
                    return true, customBipedTag.id
                end
            end
        elseif (tag.class == blam.tagClasses.vehicle) then
            vehiclesList[objectId] = tagId
        end
    end
    return true
end

-- Cleanup
function OnScriptUnload()
    execute_script("allow_client_side_weapon_projectiles 1")
end

-- Log traceback for debug purposes
function OnError(Message)
    local tb = debug.traceback()
    print(tb)
    say_all(tb)
end
