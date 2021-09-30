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
local split = glue.string.split

-- Halo Custom Edition modules
local blam = require "blam"
local core = require "mimic.core"
local toSentenceCase = core.toSentenceCase

-- Settings
DebugMode = true
local syncRadius = 20
local syncRate = 120
local bspIndexAddress = 0x40002CD8

-- State
local aiList = {}
local aiCollection = {}
local mapBipedTags = {}
local customPlayerBipeds = {}
local vehiclesList = {}
local deviceMachinesList = {}
local isGameOnCinematic = false
local allowCustomBipeds = false
local aiCount = 0
local votesList = {}
local coopStarted = false
local syncCmd = ""
local currentBspIndex

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

local function findNewSpawn(deadPlayerIndex)
    local playerUsedForSpawn
    if (not isGameOnCinematic) then
        for playerIndex = 1, 16 do
            if (player_present(playerIndex)) then
                local player = blam.biped(get_dynamic_player(playerIndex))
                if (player) then
                    if (not player.isOutSideMap) then
                        if (player.health > 0 and player.isOnGround and playerIndex ~=
                            deadPlayerIndex) then
                            local scenario = blam.scenario(0)
                            if (scenario) then
                                local playerName = get_var(playerIndex, "$name")
                                local playerSpawns = scenario.spawnLocationList
                                -- Update second player spawn point on the scenario
                                -- Usually the first spawn point is for local/campaign purposes only
                                -- TODO Check if a vehicle can use the is on ground flag as well
                                if (blam.isNull(player.vehicleObjectId)) then
                                    playerUsedForSpawn = playerName
                                    for spawnIndex, spawn in pairs(playerSpawns) do
                                        playerSpawns[spawnIndex].x = player.x
                                        playerSpawns[spawnIndex].y = player.y
                                        playerSpawns[spawnIndex].z = player.z + 0.2
                                    end
                                else
                                    local vehicle = blam.object(get_object(player.vehicleObjectId))
                                    if (vehicle) then
                                        playerUsedForSpawn = playerName
                                        for spawnIndex, spawn in pairs(playerSpawns) do
                                            playerSpawns[spawnIndex].x = vehicle.x
                                            playerSpawns[spawnIndex].y = vehicle.y
                                            playerSpawns[spawnIndex].z = vehicle.z + 0.2
                                        end
                                    end
                                end
                                -- Update player spawns list on the scenario
                                scenario.spawnLocationList = playerSpawns
                                break
                            end
                        end
                    end
                end
            end
        end
        if (playerUsedForSpawn) then
            say_all("Using " .. playerUsedForSpawn .. " as respawn point..")
        else
            say_all("No respawn candidate was found!")
        end
    else
        --say_all("Game is on cinematic, respawn will not be updated!")
    end
    return true
end

function SyncHSC(_, sHscCmd)
    if (sHscCmd ~= "nd" and syncCmd ~= sHscCmd) then
        syncCmd = sHscCmd
        console_out(syncCmd)
        -- Check if the map is trying to get a player on a vehicle
        if (syncCmd:find("unit_enter_vehicle") and syncCmd:find("player")) then
            local params = glue.string.split(syncCmd, " ")
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
                            -- console_out(inspect(params))
                            console_out(playerIndex)
                            console_out(objectName)
                            console_out(seatIndex)
                            enter_vehicle(vehicleObjectId, playerIndex, seatIndex)
                        end
                    end
                end
            end
        elseif (syncCmd:find("object_create")) then
            -- Prevent object creation only if server creates a non biped/vehicle object
            local params = glue.string.split(syncCmd, " ")
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
        -- elseif (syncCommand:find("switch_bsp")) then
            -- Deprecating this as there is a new bsp sync feature OnTick
            -- findNewSpawn()
            -- currentBspIndex = tonumber(glue.string.split(command, " ")[2])
            -- say_all("Saving new bsp index...")
        elseif (syncCmd:find("object_teleport") and syncCmd:find("player")) then
            -- Prevent object teleport desync on client
            return
        elseif (syncCmd:find("nav_point")) then
            -- FIXME This is not working for some reason
            for playerIndex = 0, 15 do
                broadcast(syncCmd:gsub("player0", "player" .. playerIndex))
            end
            return
        elseif (syncCmd:find("camera_control")) then
            -- TODO Add cinematic_start and cinematic_stop for accurate cinematic determination
            local params = glue.string.split(syncCmd, " ")
            isGameOnCinematic = params[2] == "true"
            if (isGameOnCinematic) then
                say_all("Warning, game is on cinematic!")
            else
                say_all("Done, cinematic has ended!")
            end
        end
        broadcast(syncCmd)
        -- This is not really required, needs testing as it triggers twice the set callback
        -- FIXME Improve testing on this
        -- execute_command([[set sync_hsc_command ""]])
    end
end

function CleanBipeds(strServerObjectId)
    local serverObjectId = tonumber(strServerObjectId)
    -- console_out("Cleaning biped " .. serverObjectId)
    aiCollection[serverObjectId] = nil
    aiList[serverObjectId] = nil
    return false
end

local function syncAITags(playerIndex)
    -- Sync all the available AI
    -- TODO Add async function for this
    for objectId, tagId in pairs(aiList) do
        local spawnPacket = core.spawnPacket(tagId, objectId)
        send(playerIndex, spawnPacket)
    end
    return false
end

local function syncUpdateAI()
    local newAiCount = #glue.keys(aiList)
    if (aiCount ~= newAiCount) then
        aiCount = newAiCount
        -- syncRadius = aiCount * 0.35
        -- core.log("Syncing %s bipeds...", aiCount)
        -- core.log("Radius %s", syncRadius)
    end
    local playersCount = tonumber(get_var(0, "$pn"))
    if (playersCount > 0) then
        for serverObjectId, tagId in pairs(aiList) do
            local ai = blam.biped(get_object(serverObjectId))
            if (ai and blam.isNull(ai.nameIndex)) then
                -- Biped is alive, we need to sync it
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
                                -- This was disabled as this forces every biped to be synced
                                -- Resulting on really low performance
                                -- local updatePacket = core.updatePacket(serverObjectId, ai)
                                -- send(playerIndex, updatePacket)
                            end
                        end
                    end
                else
                    -- Biped is dead, sync dead packet, then remove it from the sync list
                    local killPacket = core.deletePacket(serverObjectId)
                    broadcast(killPacket)
                    if (not aiCollection[serverObjectId]) then
                        local mostRecentDamagerPlayer = ai.mostRecentDamagerPlayer
                        if (not blam.isNull(mostRecentDamagerPlayer)) then
                            local playerIndex = core.getIndexById(mostRecentDamagerPlayer) + 1
                            local playerName = get_var(playerIndex, "$name")
                            local player = blam.player(get_player(playerIndex))
                            if (player) then
                                for tagName, tag in pairs(mapBipedTags) do
                                    if (tag.id == ai.tagId) then
                                        say_all(playerName .. " killed " .. toSentenceCase(tagName))
                                        break
                                    end
                                end
                                player.kills = player.kills + 1
                            end
                        end
                        -- Biped is now dead, remove it from the list
                        -- Set that this biped already has a timer asigned for removal
                        aiCollection[serverObjectId] = true
                        -- Set collector, it helps to keep sending kill packet to player
                        timer(350, "CleanBipeds", serverObjectId)
                    end
                end
            else
                -- This biped does not exist anymore on the server, erase it from the list
                aiList[serverObjectId] = nil
            end
        end
    end
    return true
end

function OnPlayerPreSpawn(playerIndex)
    -- Find new spawn candidates, tell client to allow going trough bipeds
    send(playerIndex, "disable_biped_collision")
    if (currentBspIndex) then
        send(playerIndex, "sync_switch_bsp " .. currentBspIndex)
    end
    timer(30, "SyncAITags", playerIndex)
end

function OnPlayerJoin(playerIndex)
    -- Set players on the same team for coop purposes
    execute_script("st " .. playerIndex .. " red")
end

function OnPlayerLeave(playerIndex)
    votesList[playerIndex] = nil
    if (allowCustomBipeds) then
        customPlayerBipeds[playerIndex] = nil
    end
    findNewSpawn(playerIndex)
end

function OnPlayerDead(deadPlayerIndex)
    local deaths = 0
    local playersCount = tonumber(get_var(0, "$pn"))
    ---- FIXME Sometimes this events gets triggered when there is just one player alive
    -- local playerDeaths = tonumber(get_var(deadPlayerIndex, "$deaths"))
    -- if (playerDeaths > 0) then
    --    deaths = deaths + 1
    -- end
    findNewSpawn(deadPlayerIndex)
    if (deaths == playersCount) then
        say_all("Game over, AI wins...")
        -- execute_script("sv_map_next")
    end
end

function IncreaseAIHealth()
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
    votesList = {}
end

function OnGameStart()
    currentScenario = blam.scenario(0)
    -- Register available bipeds on the map
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
    local playerName = get_var(playerIndex, "$name")
    local playerAdminLevel = tonumber(get_var(playerIndex, "$lvl"))
    if (environment == 2) then
        if (command == "blist") then
            glue.map(mapBipedTags, function(bipedName)
                rprint(playerIndex, bipedName)
            end)
            return false
        elseif (command == "ready" or command == "rdy") then
            if (not coopStarted) then
                local playersCount = tonumber(get_var(0, "$pn"))
                local requiredVotes = 2
                if (playersCount > 2) then
                    requiredVotes = glue.floor(playersCount / 2)
                end
                votesList[playerIndex] = true
                local votesCount = #glue.keys(votesList)
                say_all(playerName .. " is ready for coop! (" .. votesCount .. " / " ..
                            requiredVotes .. ")")
                if (votesCount >= requiredVotes) then
                    coopStarted = true
                    local currentMapName = get_var(0, "$map")
                    local splitName = glue.string.split(currentMapName, "_")
                    local baseNoCoopName = splitName[1]
                    execute_script("wake main_" .. baseNoCoopName)
                end
                return false
            end
        else
            if (allowCustomBipeds) then
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
        end
    elseif (environment == 0 or playerAdminLevel == 4) then
        if (command:find("mdis")) then
            local data = glue.string.split(command:gsub("\"", ""), " ")
            local newRadius = tonumber(data[2])
            if (newRadius) then
                syncRadius = newRadius
            end
            say_all("AI Count: " .. aiCount)
            say_all("Mimic synchronization radius: " .. syncRadius)
            return false
        elseif (command:find("mrate")) then
            local data = glue.string.split(command:gsub("\"", ""), " ")
            local newRate = tonumber(data[2])
            if (newRate) then
                syncRate = newRate
            end
            say_all("Mimic synchronization rate: " .. syncRate)
            return false
        elseif (command:find("mspawn")) then
            findNewSpawn()
            return false
        elseif (command:find("mbipeds")) then
            local data = glue.string.split(command:gsub("\"", ""), " ")
            local desiredBiped = data[2]
            for currentPlayerIndex = 1, 16 do
                for bipedName, bipedTag in pairs(mapBipedTags) do
                    if (desiredBiped == bipedName) then
                        customPlayerBipeds[currentPlayerIndex] = bipedTag
                        local player = blam.player(get_player(currentPlayerIndex))
                        if (player) then
                            delete_object(player.objectId)
                        end
                        break
                    end
                end
            end
            return false
        end
    end
end

function OnTick()
    -- Check for BSP Changes
    local bspIndex = read_byte(bspIndexAddress)
    if (bspIndex ~= currentBspIndex) then
        currentBspIndex = bspIndex
        console_out("New bsp index detected: " .. currentBspIndex)
        findNewSpawn()
        broadcast("sync_switch_bsp " .. currentBspIndex)
    end
    if (currentScenario) then
        -- Check for device machine changes
        for objectId, group in pairs(deviceMachinesList) do
            local device = blam.deviceMachine(get_object(objectId))
            if (device) then
                -- Only sync device machines that are name based due to mimic client limitations
                if (not blam.isNull(device.nameIndex)) then
                    local name = currentScenario.objectNames[device.nameIndex + 1]
                    if (name) then
                        local currentPower = blam.getDeviceGroup(device.powerGroupIndex)
                        local currentPosition = blam.getDeviceGroup(device.positonGroupIndex)
                        if (currentPower ~= group.power) then
                            deviceMachinesList[objectId].power = currentPower
                            broadcast("sync_device_set_power " .. name .. " " .. currentPower)
                            core.log(("Sync device \"%s\" new power: %s"):format(name, currentPower))
                        end
                        if (currentPosition ~= group.position) then
                            deviceMachinesList[objectId].position = currentPosition
                            broadcast("sync_device_set_position " .. name .. " " .. currentPosition)
                            core.log(("Sync device \"%s\" new position: %s"):format(name,
                                                                                    currentPosition))
                        end
                    end
                end
            end
        end
    end
    for playerIndex = 1, 16 do
        local playerBiped = blam.biped(get_dynamic_player(playerIndex))
        if (playerBiped) then
            blam.bipedTag(playerBiped.tagId).disableCollision = true
            if (playerBiped.isOutSideMap) then
                local player = blam.player(get_player(playerIndex))
                if (not isGameOnCinematic and player) then
                    delete_object(player.objectId)
                end
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
    --execute_script("allow_client_side_weapon_projectiles 0")
    -- Start syncing AI every amount of seconds
    SyncUpdateAI = syncUpdateAI
    FindNewSpawn = findNewSpawn
    SyncAITags = syncAITags
    timer(syncRate, "SyncUpdateAI")
    timer(20000, "FindNewSpawn")
    -- Set server callback
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_GAME_END"], "ResetState")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
    register_callback(cb["EVENT_PRESPAWN"], "OnPlayerPreSpawn")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
    register_callback(cb["EVENT_LEAVE"], "OnPlayerLeave")
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb["EVENT_DIE"], "OnPlayerDead")
    register_callback(cb["EVENT_ECHO"], "SyncHSC")
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
        elseif (tag.class == blam.tagClasses.deviceMachine) then
            deviceMachinesList[objectId] = {power = 1, position = 0}
        end
    end
    return true
end

-- Cleanup
function OnScriptUnload()
end

-- Log traceback for debug purposes
function OnError(Message)
    local tb = debug.traceback()
    print(tb)
    say_all("An error is ocurring on the server side, contact an admin!")
end
