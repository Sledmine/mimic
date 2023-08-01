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
local luna = require "luna"
local split = luna.string.split
local startswith = string.startswith

-- Halo Custom Edition modules
local blam = require "blam"
local isNull = blam.isNull
local objectClasses = blam.objectClasses
local tagClasses = blam.tagClasses
local core = require "mimic.core"
local coop = require "mimic.coop"
local toSentenceCase = core.toSentenceCase
local constants = require "mimic.constants"
local version = require "mimic.version"

-- Settings
DebugMode = false
local bspIndexAddress = 0x40002CD8
local passwordAddress
local failMessageAddress
local serverRcon

-- State
local aiCollection = {}
local mapBipedTags = {}
local customPlayerBipeds = {}
local upcomingAiSpawn = {}
VehiclesList = {}
DeviceMachinesList = {}
IsGameOnCinematic = false
local allowCustomBipeds = true
VotesList = {}
CoopStarted = false
LastSyncCommand = ""
local currentBspIndex
CurrentScenario = nil

function Broadcast(message)
    for playerIndex = 1, 16 do
        if (player_present(playerIndex)) then
            rprint(playerIndex, message)
        end
    end
    return false
end

function Send(playerIndex, message)
    rprint(playerIndex, message)
    return false
end

function SyncHSC(_, hscMimicCommand)
    if (hscMimicCommand ~= "nd" and LastSyncCommand ~= hscMimicCommand) then
        LastSyncCommand = hscMimicCommand
        local syncCommand = core.adaptHSC(hscMimicCommand)
        if (syncCommand) then
            console_out("Syncing: " .. syncCommand)
            Broadcast(syncCommand)
        end
        -- Uncommenting this probably will be required for very specific hsc specific script cases
        -- execute_command("set sync_hsc_command \"\"")
    end
end

function SyncGameState(playerIndex)
    for objectId, group in pairs(DeviceMachinesList) do
        local device = blam.deviceMachine(get_object(objectId))
        if device then
            -- Only sync device machines that are name based due to mimic client limitations
            if not isNull(device.nameIndex) then
                local name = CurrentScenario.objectNames[device.nameIndex + 1]
                if name then
                    Send(playerIndex, "sync_device_set_power " .. name .. " " ..
                             DeviceMachinesList[objectId].power)
                    Send(playerIndex, "sync_device_set_position_immediate " .. name .. " " ..
                             DeviceMachinesList[objectId].position)
                end
            end
        end
    end
end

--- Syncs all bipeds in the map
---@param ai biped
---@param serverObjectId number
---@param syncedIndex number
local function updateAI(ai, serverObjectId, syncedIndex)
    for playerIndex = 1, 16 do
        local player = blam.biped(get_dynamic_player(playerIndex))
        if player then
            -- Filter server bipeds that are already synced
            for playerIndex = 1, 16 do
                local playerObjectAdress = get_dynamic_player(playerIndex)
                local aiObjectAddress = get_object(serverObjectId)
                -- AI is the same as the player, do not sync
                if playerObjectAdress == aiObjectAddress then
                    return
                end
            end
            -- Prevents AI from running out of ammo
            local aiWeapon = blam.weapon(get_object(ai.firstWeaponObjectId))
            if aiWeapon then
                aiWeapon.totalAmmo = 999
            end
            -- Sync AI biped if it is near to the player
            if isNull(player.vehicleObjectId) then
                if (core.objectIsNearTo(player, ai, constants.syncDistance) and
                    core.objectIsLookingAt(get_dynamic_player(playerIndex) --[[@as number]] ,
                                           serverObjectId, constants.syncBoundingRadius, 0,
                                           constants.syncDistance)) then
                    local updatePacket = core.updatePacket(syncedIndex, ai)
                    if updatePacket and syncedIndex then
                        Send(playerIndex, updatePacket)
                    end
                end
            else
                local vehicle = blam.object(get_object(player.vehicleObjectId))
                if vehicle and core.objectIsNearTo(vehicle, ai, constants.syncDistance) then
                    local updatePacket = core.updatePacket(syncedIndex, ai)
                    if updatePacket and syncedIndex then
                        Send(playerIndex, updatePacket)
                    end
                end
            end
        end
    end
end

function SyncUpdate()
    local playersCount = tonumber(get_var(0, "$pn"))
    if playersCount > 0 then
        for _, serverObjectId in pairs(core.getSyncedBipedIds()) do
            local ai = blam.biped(get_object(serverObjectId))
            if ai then
                local syncedIndex = core.getSyncedIndexByObjectId(serverObjectId)
                if core.isBipedSynceable(ai) and syncedIndex then
                    updateAI(ai, serverObjectId, syncedIndex)
                end
            end
        end
    end
    if CurrentScenario then
        -- Check for device machine changes
        for objectId, group in pairs(DeviceMachinesList) do
            local device = blam.deviceMachine(get_object(objectId))
            if device then
                -- Only sync device machines that are name based due to mimic client limitations
                if not isNull(device.nameIndex) then
                    local name = CurrentScenario.objectNames[device.nameIndex + 1]
                    if name then
                        local currentPower = blam.getDeviceGroup(device.powerGroupIndex)
                        local currentPosition = blam.getDeviceGroup(device.positonGroupIndex)
                        if currentPower ~= group.power then
                            DeviceMachinesList[objectId].power = currentPower
                            Broadcast("sync_device_set_power " .. name .. " " .. currentPower)
                        end
                        if currentPosition ~= group.position then
                            DeviceMachinesList[objectId].position = currentPosition
                            Broadcast("sync_device_set_position " .. name .. " " .. currentPosition)
                        end
                    end
                end
            end
        end
    end
    return true
end

---Syncs game data required just when the game starts
---@param playerIndex number
---@return boolean repeat
function SyncGameStart(playerIndex)
    -- Sync current bsp
    if currentBspIndex then
        Send(playerIndex, "sync_switch_bsp " .. currentBspIndex)
    end
    local currentMapName = get_var(0, "$map")
    -- Force client to allow going trough bipeds
    Send(playerIndex, "disable_biped_collision")
    if currentMapName:find("coop_evolved") then
        Broadcast("@i," .. coop.getRequiredVotes() .. ",4")
        if not CoopStarted then
            Send(playerIndex, "sync_camera_control 1")
            -- a50
            Send(playerIndex, "sync_camera_set insertion_3 0")
            -- b30
            Send(playerIndex, "sync_camera_set insertion_1a 0")
            -- c10
            Send(playerIndex, "sync_camera_set index_drop_1a 0")
            -- c20
            Send(playerIndex, "sync_camera_set insertion_1 0")
            -- d40
            Send(playerIndex, "sync_camera_set chief_climb_2c 0")
            Send(playerIndex, "open_coop_menu")
        end
    else
        set_timer(3000, "StartCoop")
        -- Prevent going trough bipeds
        -- Send(playerIndex, "enable_biped_collision")
    end
    return false
end

function OnPlayerJoin(playerIndex)
    -- Set players on the same team for coop purposes
    execute_script("st " .. playerIndex .. " red")

    -- Sync game data just required when the game starts
    set_timer(80, "SyncGameStart", playerIndex)

    -- Sync game state
    set_timer(300, "SyncGameState", playerIndex)
end

function OnPlayerLeave(playerIndex)
    -- Remove custom biped when player leaves
    if allowCustomBipeds then
        customPlayerBipeds[playerIndex] = nil
    end
    -- Remove player from votes list
    if not CoopStarted then
        VotesList[playerIndex] = nil
    end

    coop.findNewSpawn(playerIndex)
end

function OnPlayerDead(deadPlayerIndex)
    coop.findNewSpawn(deadPlayerIndex)
end

function ResetState()
    CoopStarted = false
    VehiclesList = {}
    mapBipedTags = {}
    customPlayerBipeds = {}
    VotesList = {}
end

function OnGameEnd()
    ResetState()
end

function ShowCurrentSyncedObjects(printTable)
    console_out("---------------------- SYNCED OBJECTS ----------------------")
    local count = 0
    for i = 0, 509 do
        local objectId = blam.getObjectIdBySincedIndex(i)
        if objectId then
            count = count + 1
            if printTable then
                local objectAddress = get_object(objectId)
                local object = blam.object(objectAddress)
                if object then
                    local format = "[%s] - %s - Object ID: %s"
                    console_out(format:format(i, blam.getTag(object.tagId).path, objectId))
                else
                    local format = "[%s] - %s - Object ID: %s"
                    console_out(format:format(i, "NULL", objectId))
                end
            end
        end
    end
    console_out("Total synced objects: " .. count)
    console_out("Total synced bipeds: " .. #core.getSyncedBipedIds())
    return true
end

function OnGameStart()
    set_timer(5000, "ShowCurrentSyncedObjects")
    console_out("-> Mimic version: " .. version)
    CurrentScenario = blam.scenario(0)
    -- Register available bipeds on the map
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tag = blam.getTag(tagIndex)
        if tag and tag.class == blam.tagClasses.biped then
            local pathSplit = tag.path:split("\\")
            local tagFileName = pathSplit[#pathSplit]
            mapBipedTags[tagFileName] = tag
        end
    end
end

function OnCommand(playerIndex, command, environment, rconPassword)
    local playerAdminLevel = tonumber(get_var(playerIndex, "$lvl"))
    if environment == 1 then
        if rconPassword == "coup" then
            if command:find "@" then
                local data = split(command, ",")
                local packetType = data[1]
                if packetType == "@r" then
                    if not CoopStarted then
                        Broadcast(core.infoPacket(coop.registerVote(playerIndex), 4))
                    end
                    return false
                elseif packetType == "@b" then
                    if allowCustomBipeds then
                        local desiredBipedTagId = tonumber(data[2])
                        for bipedName, bipedTag in pairs(mapBipedTags) do
                            if (bipedTag.id == desiredBipedTagId) then
                                Send(playerIndex, "New biped selected!")
                                customPlayerBipeds[playerIndex] = bipedTag
                                local player = blam.player(get_player(playerIndex))
                                if player then
                                    local biped = blam.biped(get_object(player.objectId))
                                    if biped then
                                        -- Force player respawn to update biped
                                        delete_object(player.objectId)
                                    end
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
        if playerAdminLevel == 4 then
            if startswith(command, "mdis") then
                local data = split(command:gsub("\"", ""), " ")
                local newRadius = tonumber(data[2])
                if newRadius then
                    constants.syncDistance = newRadius
                end
                say_all("Mimic synchronization radius: " .. constants.syncDistance)
                return false
            elseif startswith(command, "mrate") then
                local data = split(command:gsub("\"", ""), " ")
                local newRate = tonumber(data[2])
                if newRate then
                    constants.syncEveryMillisecs = newRate
                end
                say_all("Mimic synchronization rate: " .. constants.syncEveryMillisecs)
                return false
            elseif startswith(command, "mspawn") then
                coop.enableSpawn(true)
                say_all("Enabling all spawns by force!")
                return false
            elseif command:startswith "network_objects" then
                ShowCurrentSyncedObjects(true)
                return false
            elseif startswith(command, "mbullshit") then
                local data = split(command:gsub("\"", ""), " ")
                local serverId = tonumber(data[2]) --[[@as number]]
                local biped = blam.getObject(serverId)
                if biped then
                    local tag = blam.getTag(biped.tagId)
                    assert(tag, "Biped tag not found")
                    Send(playerIndex, tag.path .. " - HP: " .. biped.health)
                else
                    Send(playerIndex, "Warning, biped does not exist on the server.")
                end
                return false
            elseif startswith(command, "spawn") then
                local args = split(command:gsub("\"", ""), " ")
                local tagClass = blam.tagClasses[args[2]] or args[2]
                local tagName = args[3]
                if tagClass and tagName then
                    console_out(
                        "Spawning object with tag class: " .. tagClass .. " and tag name: " ..
                            tagName)
                    local tag = blam.findTag(tagName, tagClass)
                    if tag then
                        local playerBiped = blam.biped(get_dynamic_player(playerIndex))
                        if playerBiped then
                            local objectX = playerBiped.x + playerBiped.cameraX * 3
                            local objectY = playerBiped.y + playerBiped.cameraY * 3
                            local objectZ = playerBiped.z + playerBiped.cameraZ * 3
                            local objectId = spawn_object(tagClass, tag.path, objectX, objectY,
                                                          objectZ)
                            if objectId then
                                local object = blam.object(get_object(objectId))
                                if object and not object.isOutSideMap then
                                    console_out("Object successfully spawned!", 0, 1, 0)
                                    return false
                                else
                                    delete_object(objectId)
                                    console_out(
                                        "Error, specified object can not be spawned inside the map.",
                                        1, 0, 0)
                                    return false
                                end
                            end
                        end
                    end
                end
                return false
            end
        end
    end
end

local bipedsState = {}
function OnTick()
    -- Check for BSP Changes
    local bspIndex = read_byte(bspIndexAddress)
    if bspIndex ~= currentBspIndex then
        currentBspIndex = bspIndex
        console_out("New bsp index detected: " .. currentBspIndex)
        coop.findNewSpawn()
        Broadcast("sync_switch_bsp " .. currentBspIndex)
    end

    for playerIndex = 1, 16 do
        local playerBiped = blam.biped(get_dynamic_player(playerIndex))
        if playerBiped then
            local player = blam.player(get_player(playerIndex))
            if not isNull(playerBiped.mostRecentDamagerPlayer) then
                local player = blam.player(get_player(playerIndex))
                -- Just force AI damager if the player did not damaged himself
                if player then
                    if playerBiped.mostRecentDamagerPlayer ~= player.objectId then
                        -- Force server to tell this player was damaged by AI
                        playerBiped.mostRecentDamagerPlayer = blam.null
                    end
                end
            end
            -- TODO We might need to optimize this
            blam.bipedTag(playerBiped.tagId).disableCollision = true

            if playerBiped.isOutSideMap then
                if not IsGameOnCinematic and player then
                    -- Respawn players stuck outside current game bsp/map
                    -- TODO Add a way to respawn player inside a vehicle by force
                    -- Deleting vehicle object does not work, you can not delete it for some reason
                    if isNull(playerBiped.vehicleObjectId) then
                        delete_object(player.objectId)
                    end
                end
            end
        end
    end

    for syncedIndex = 0, 509 do
        local objectId = blam.getObjectIdBySincedIndex(syncedIndex)
        if objectId then
            local object = blam.object(get_object(objectId))
            if object and object.class == objectClasses.biped and isNull(object.playerId) then
                local biped = blam.biped(get_object(objectId))
                assert(biped, "Biped not found")
                local lastBipedState = bipedsState[syncedIndex] or {}
                if core.isBipedPropertiesSyncable(biped, lastBipedState) then
                    bipedsState[syncedIndex] = blam.dumpObject(biped)
                    Broadcast(core.bipedPropertiesPacket(syncedIndex, biped))
                end
                if biped.colorALowerBlue ~= lastBipedState.colorALowerBlue then
                    Broadcast(core.objectColorPacket(syncedIndex, biped))
                end
            end
        end
    end    
end

function OnScriptLoad()
    passwordAddress = read_dword(sig_scan("7740BA??????008D9B000000008A01") + 0x3)
    failMessageAddress = read_dword(sig_scan("B8????????E8??000000A1????????55") + 0x1)
    if passwordAddress and failMessageAddress then
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
    set_timer(constants.syncEveryMillisecs, "SyncUpdate")
    set_timer(20000, "FindNewSpawn")
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

--- Event called before an object spawns
---@param playerIndex number
---@param tagId number
---@param parentId number
---@param objectId number
---@return boolean
---@return number? newObjectTagId
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    local tag = blam.getTag(tagId)
    if tag then
        if tag.class == blam.tagClasses.biped then
            -- Object is not player biped
            if playerIndex == 0 then
            else
                local customBipedTag = customPlayerBipeds[playerIndex]
                if customBipedTag then
                    return true, customBipedTag.id
                end
            end
        elseif tag.class == blam.tagClasses.vehicle then
            VehiclesList[objectId] = tagId
        elseif tag.class == blam.tagClasses.deviceMachine then
            DeviceMachinesList[objectId] = {power = -1, position = -1}
        end
    end
    return true
end

-- Cleanup
function OnScriptUnload()
    if failMessageAddress then
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
