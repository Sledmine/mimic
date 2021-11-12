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
local glue = require "glue"
local split = glue.string.split

-- Halo Custom Edition modules
local blam = require "blam"
local isNull = blam.isNull
local core = require "mimic.core"
local coop = require "mimic.coop"
local toSentenceCase = core.toSentenceCase

-- Settings
DebugMode = false
local syncRadius = 30
local syncRate = 120
local bspIndexAddress = 0x40002CD8
local passwordAddress
local failMessageAddress
local serverRcon

-- State
local aiList = {}
local aiCollection = {}
local mapBipedTags = {}
local customPlayerBipeds = {}
local upcomingAiSpawn = {}
VehiclesList = {}
DeviceMachinesList = {}
IsGameOnCinematic = false
local allowCustomBipeds = true
local aiCount = 0
VotesList = {}
CoopStarted = false
LastSyncCommand = ""
local currentBspIndex
local currentScenario

function Broadcast(message)
    for playerIndex = 1, 16 do
        if (player_present(playerIndex)) then
            rprint(playerIndex, message)
        end
    end
end

function Send(playerIndex, message)
    rprint(playerIndex, message)
end

function SyncHSC(_, hscMimicCommand)
    if (hscMimicCommand ~= "nd" and LastSyncCommand ~= hscMimicCommand) then
        LastSyncCommand = hscMimicCommand
        local syncCommand = core.adaptHSC(hscMimicCommand)
        if (syncCommand) then
            console_out(hscMimicCommand)
            Broadcast(hscMimicCommand)
        end
        -- Uncommenting this probably will be required for very specific hsc specific script cases
        -- execute_command("set sync_hsc_command \"\"")
    end
end

function CleanBipeds(strServerObjectId)
    local serverObjectId = tonumber(strServerObjectId)
    -- console_out("Cleaning biped " .. serverObjectId)
    aiCollection[serverObjectId] = nil
    aiList[serverObjectId] = nil
    return false
end

function SyncAIData(playerIndex)
    -- Sync all the available AI
    -- TODO Add async function for this
    for objectId in pairs(aiList) do
        local ai = blam.biped(get_object(objectId))
        -- FIXME We need a better way to determine if a biped is DEAD for sure, server works differently
        if (ai and not ai.isHealthEmpty) then
            Send(playerIndex, core.positionPacket(objectId, ai))
        end
    end
    for objectId, group in pairs(DeviceMachinesList) do
        local device = blam.deviceMachine(get_object(objectId))
        if (device) then
            -- Only sync device machines that are name based due to mimic client limitations
            if (not blam.isNull(device.nameIndex)) then
                local name = currentScenario.objectNames[device.nameIndex + 1]
                if (name) then
                    Send(playerIndex, "sync_device_set_power " .. name .. " " ..
                             DeviceMachinesList[objectId].power)
                    Send(playerIndex, "sync_device_set_position_immediate " .. name .. " " ..
                             DeviceMachinesList[objectId].position)
                end
            end
        end
    end
end

function SyncDeadAI()
    local playersCount = tonumber(get_var(0, "$pn"))
    if (playersCount > 0) then
        for serverObjectId, tagId in pairs(aiList) do
            local ai = blam.biped(get_object(serverObjectId))
            if (ai) then
                if (blam.isNull(ai.nameIndex)) then
                    -- Biped is alive, we need to sync it
                    if (ai.isHealthEmpty) then
                        -- Biped is dead, sync dead packet, then remove it from the sync list
                        local killPacket = core.deletePacket(serverObjectId)
                        Broadcast(killPacket)
                        if (not aiCollection[serverObjectId]) then
                            local mostRecentDamagerPlayer = ai.mostRecentDamagerPlayer
                            if (not blam.isNull(mostRecentDamagerPlayer)) then
                                local playerIndex = core.getIndexById(mostRecentDamagerPlayer) + 1
                                local playerName = get_var(playerIndex, "$name")
                                local player = blam.player(get_player(playerIndex))
                                if (player) then
                                    for tagName, tag in pairs(mapBipedTags) do
                                        if (tag.id == ai.tagId) then
                                            say_all(
                                                playerName .. " killed " .. toSentenceCase(tagName))
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
                            timer(150, "CleanBipeds", serverObjectId)
                        end
                    end
                end
            else
                -- This biped does not exist anymore on the server, erase it from the list
                aiList[serverObjectId] = nil
            end
        end
    end
end

function SyncUpdateAI()
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
            if (ai) then
                if (blam.isNull(ai.nameIndex)) then
                    -- Biped is alive, we need to sync it
                    if (not ai.isHealthEmpty) then
                        -- Only sync bsps inside the same bsp as the players
                        if (not ai.isOutSideMap) then
                            for playerIndex = 1, 16 do
                                local player = blam.biped(get_dynamic_player(playerIndex))
                                if (player) then
                                    if (blam.isNull(player.vehicleObjectId)) then
                                        if (core.objectIsNearTo(player, ai, syncRadius)) then
                                            -- FIXME Some times packet is nil, debug this
                                            local updatePacket =
                                                core.updatePacket(serverObjectId, ai)
                                            if (updatePacket) then
                                                Send(playerIndex, updatePacket)
                                            end
                                        end
                                    else
                                        local vehicle = blam.object(get_object(
                                                                        player.vehicleObjectId))
                                        if (vehicle and core.objectIsNearTo(vehicle, ai, syncRadius)) then
                                            -- FIXME Some times packet is nil, debug this
                                            local updatePacket =
                                                core.updatePacket(serverObjectId, ai)
                                            if (updatePacket) then
                                                Send(playerIndex, updatePacket)
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
                    end
                end
            end
        end
    end
    return true
end

function SyncState(playerIndex)
    -- Sync current bsp
    if (currentBspIndex) then
        Send(playerIndex, "sync_switch_bsp " .. currentBspIndex)
    end
    local currentMapName = get_var(0, "$map")
    if (currentMapName:find("coop_evolved")) then
        -- Specifiy client to allow going trough bipeds
        Send(playerIndex, "disable_biped_collision")
        Broadcast("@i," .. coop.getRequiredVotes() .. ",4")
        if (not CoopStarted) then
            Send(playerIndex, "sync_camera_control 1")
            Send(playerIndex, "sync_camera_set insertion_1a 0")
            Send(playerIndex, "sync_camera_set index_drop_1a 0")
            Send(playerIndex, "sync_camera_set insertion_1 0")
            Send(playerIndex, "open_coop_menu")
        end
    else
        -- Prevent going trough bipeds
        Send(playerIndex, "enable_biped_collision")
    end
end

function OnPlayerJoin(playerIndex)
    -- Set players on the same team for coop purposes
    execute_script("st " .. playerIndex .. " red")
    timer(30, "SyncState", playerIndex)
    timer(300, "SyncAIData", playerIndex)
end

function OnPlayerLeave(playerIndex)
    -- Disabled because some maps need multiple rejoining along the game
    --[[
    if (allowCustomBipeds) then
        customPlayerBipeds[playerIndex] = nil
    end
    ]]
    if (not CoopStarted) then
        VotesList[playerIndex] = nil
    end
    coop.findNewSpawn(playerIndex)
end

function OnPlayerDead(deadPlayerIndex)
    local currentGameType = get_var(0, "$mode")
    if (currentGameType:find("survival")) then
        IncreaseAIHealth()
        -- local playerDeadTimes = 0
        -- local playersCount = tonumber(get_var(0, "$pn"))
        -- local player = blam.player(get_player(deadPlayerIndex))
        -- if (playerDeadTimes == playersCount) then
        --    say_all("Game over, AI wins...")
        --    local currentMapName = get_var(0, "$map")
        --    execute_script("sv_map " .. currentMapName .. " " .. currentGameType)
        -- end
    end
    coop.findNewSpawn(deadPlayerIndex)
end

function IncreaseAIHealth()
    for serverObjectId, tagId in pairs(aiList) do
        local biped = blam.biped(get_object(serverObjectId))
        if (biped and not biped.isHealthEmpty) then
            biped.health = biped.health + 0.5
        end
    end
    say_all("Increasing AI health...")
    return true
end

function ResetState()
    CoopStarted = false
    aiList = {}
    VehiclesList = {}
    mapBipedTags = {}
    customPlayerBipeds = {}
    VotesList = {}
end

function OnGameEnd()
    ResetState()
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

function OnCommand(playerIndex, command, environment, rconPassword)
    local playerAdminLevel = tonumber(get_var(playerIndex, "$lvl"))
    if (environment == 1) then
        if (rconPassword == "coup") then
            if (command:find("@")) then
                local data = split(command, ",")
                local packetType = data[1]
                if (packetType == "@r") then
                    if (not CoopStarted) then
                        Broadcast(core.infoPacket(coop.registerVote(playerIndex), 4))
                    end
                    return false
                elseif (packetType == "@b") then
                    if (allowCustomBipeds) then
                        local desiredBipedTagId = tonumber(data[2])
                        for bipedName, bipedTag in pairs(mapBipedTags) do
                            if (bipedTag.id == desiredBipedTagId) then
                                Send(playerIndex, "New biped selected!")
                                customPlayerBipeds[playerIndex] = bipedTag
                                local player = blam.player(get_player(playerIndex))
                                local playerBiped = blam.biped(get_object(player.objectId))
                                if (playerBiped) then
                                    delete_object(player.objectId)
                                end
                                return false
                            end
                        end
                    else
                        Send(playerIndex, "Custom bipeds are not allowed!")
                    end
                    return false
                end
            end
            execute_script("sv_kick " .. playerIndex)
            return false
        end
        if (playerAdminLevel == 4) then
            if (command:find("mdis")) then
                local data = split(command:gsub("\"", ""), " ")
                local newRadius = tonumber(data[2])
                if (newRadius) then
                    syncRadius = newRadius
                end
                say_all("AI Count: " .. aiCount)
                say_all("Mimic synchronization radius: " .. syncRadius)
                return false
            elseif (command:find("mrate")) then
                local data = split(command:gsub("\"", ""), " ")
                local newRate = tonumber(data[2])
                if (newRate) then
                    syncRate = newRate
                end
                say_all("Mimic synchronization rate: " .. syncRate)
                return false
            elseif (command:find("mspawn")) then
                coop.enableSpawn(true)
                say_all("Enabling all spawns by force!")
                return false
            elseif (command:find("mbullshit")) then
                local data = split(command:gsub("\"", ""), " ")
                local serverId = tonumber(data[2])
                local biped = blam.getObject(serverId)
                local tag = blam.getTag(biped.tagId)
                if (biped) then
                    Send(playerIndex, tag.path .. " - HP: " .. biped.health)
                else
                    Send(playerIndex, "Warning, biped does not exist on the server.")
                end
                return false
            end
        end
    end
end

function OnTick()
    -- Check for BSP Changes
    local bspIndex = read_byte(bspIndexAddress)
    if (bspIndex ~= currentBspIndex) then
        currentBspIndex = bspIndex
        console_out("New bsp index detected: " .. currentBspIndex)
        coop.findNewSpawn()
        Broadcast("sync_switch_bsp " .. currentBspIndex)
    end
    SyncDeadAI()
    if (currentScenario) then
        -- Check for device machine changes
        for objectId, group in pairs(DeviceMachinesList) do
            local device = blam.deviceMachine(get_object(objectId))
            if (device) then
                -- Only sync device machines that are name based due to mimic client limitations
                if (not blam.isNull(device.nameIndex)) then
                    local name = currentScenario.objectNames[device.nameIndex + 1]
                    if (name) then
                        local currentPower = blam.getDeviceGroup(device.powerGroupIndex)
                        local currentPosition = blam.getDeviceGroup(device.positonGroupIndex)
                        if (currentPower ~= group.power) then
                            DeviceMachinesList[objectId].power = currentPower
                            Broadcast("sync_device_set_power " .. name .. " " .. currentPower)
                            core.log(("Sync device \"%s\" new power: %s"):format(name, currentPower))
                        end
                        if (currentPosition ~= group.position) then
                            DeviceMachinesList[objectId].position = currentPosition
                            Broadcast("sync_device_set_position " .. name .. " " .. currentPosition)
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
            local player = blam.player(get_player(playerIndex))
            if (not isNull(playerBiped.mostRecentDamagerPlayer)) then
                local player = blam.player(get_player(playerIndex))
                -- Just force AI damager if the player did not damaged himself
                if (playerBiped.mostRecentDamagerPlayer ~= player.objectId) then
                    -- Force server to tell this player was damaged by AI
                    playerBiped.mostRecentDamagerPlayer = 0xFFFFFFFF
                end
            end
            blam.bipedTag(playerBiped.tagId).disableCollision = true
            if (playerBiped.isOutSideMap) then
                if (not IsGameOnCinematic and player) then
                    if (isNull(playerBiped.vehicleObjectId)) then
                        delete_object(player.objectId)
                    else
                        exit_vehicle(playerIndex)
                        delete_object(player.objectId)
                    end
                end
            end
        end
    end
    upcomingAiSpawn = core.dispatchAISpawn(upcomingAiSpawn)
end

function OnScriptLoad()
    passwordAddress = read_dword(sig_scan("7740BA??????008D9B000000008A01") + 0x3)
    failMessageAddress = read_dword(sig_scan("B8????????E8??000000A1????????55") + 0x1)
    if (passwordAddress and failMessageAddress) then
        -- Remove "rcon command failure" message
        safe_write(true)
        write_byte(failMessageAddress, 0x0)
        safe_write(false)
        -- Read current rcon in the server
        serverRcon = read_string(passwordAddress)
        if (serverRcon) then
            cprint("Server rcon password is: \"" .. serverRcon .. "\"")
        else
            cprint("Error, at getting server rcon, please set and enable rcon on the server.")
        end
    else
        cprint("Error, at obtaining rcon patches, please check SAPP version.")
    end
    ResetState()
    -- Set hsc callback to follow actions requesting synchronization
    harmonySapp.set_hs_globals_set_callback(function()
        execute_command("inspect sync_hsc_command", 0, true)
    end)
    -- Netcode does not sync AI projectiles, force it with this
    -- execute_script("allow_client_side_weapon_projectiles 0")
    -- Start syncing AI every amount of seconds
    FindNewSpawn = coop.findNewSpawn
    timer(syncRate, "SyncUpdateAI")
    timer(20000, "FindNewSpawn")
    -- Set server callback
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
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
                upcomingAiSpawn[objectId] = tagId
            else
                local customBipedTag = customPlayerBipeds[playerIndex]
                if (customBipedTag) then
                    return true, customBipedTag.id
                end
            end
        elseif (tag.class == blam.tagClasses.vehicle) then
            VehiclesList[objectId] = tagId
        elseif (tag.class == blam.tagClasses.deviceMachine) then
            DeviceMachinesList[objectId] = {power = -1, position = -1}
        end
    end
    return true
end

-- Cleanup
function OnScriptUnload()
    if (failMessageAddress) then
        -- Restore "rcon command failure" message
        safe_write(true)
        write_byte(rcon.failMessageAddress, 0x72)
        safe_write(false)
    end
end

-- Log traceback for debug purposes
function OnError(message)
    print(message)
    local tb = debug.traceback()
    print(tb)
    say_all("An error is ocurring on the server side, contact an admin!")
end
