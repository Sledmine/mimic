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
local blam = require "blam"
console_out = cprint

-- Bring compatibility with Balltze
require "balltzeCompat"

-- Lua modules
local luna = require "luna"
local split = string.split
local startswith = string.startswith

-- Halo Custom Edition modules
local isNull = blam.isNull
local objectClasses = blam.objectClasses
local tagClasses = blam.tagClasses
local core = require "mimic.core"
local toSentenceCase = core.toSentenceCase
local constants = require "mimic.constants"
local version = require "mimic.version"

-- Settings
DebugMode = false
local bspIndexAddress = 0x40002CD8
local rconPasswordAddress
local failMessageAddress
local allowClientSideWeaponProjectilesAddress
local rconPassword

-- State
local deviceMachinesList = {}
LastSyncCommand = ""
local currentBspIndex
local currentScenario = nil

logger = Balltze.logger.createLogger("Mimic Server")

---Enable or disable server side projectiles synchronization
---@param enable boolean
local function serverSideProjectiles(enable)
    -- TODO Move this function to core module
    if not allowClientSideWeaponProjectilesAddress then
        logger:error("Error no address found for client side weapon projectiles")
    end
    write_byte(allowClientSideWeaponProjectilesAddress, enable and 0x0 or 0x1)
end

local function broadcastMessage(message)
    for playerIndex = 1, 16 do
        if player_present(playerIndex) then
            rprint(playerIndex, message)
        end
    end
    return false
end

function monocastMessage(playerIndex, message)
    rprint(playerIndex, message)
    return false
end

local function getBspIndex()
    return read_byte(bspIndexAddress)
end

local function syncBspIndex(playerIndex)
    local bspIndex = getBspIndex() or 0
    if not playerIndex then
        broadcastMessage("sync_switch_bsp " .. bspIndex)
        return
    end
    monocastMessage(playerIndex, "sync_switch_bsp " .. bspIndex)
end

function SyncGameState(playerIndex)
    for objectId, group in pairs(deviceMachinesList) do
        local device = blam.deviceMachine(get_object(objectId))
        if device then
            -- Only sync device machines that are name based due to mimic client limitations
            if not isNull(device.nameIndex) then
                assert(currentScenario, "No current scenario tag found")
                local name = currentScenario.objectNames[device.nameIndex + 1]
                if name then
                    local power = deviceMachinesList[objectId].power
                    local position = deviceMachinesList[objectId].position

                    local powerMessage = "device_set_power \"{name}\" {power}"
                    powerMessage = powerMessage:template{name = name, power = power}
                    monocastMessage(playerIndex, "sync_" .. powerMessage)

                    local positionMessage = "device_set_position_immediate \"{name}\" {position}"
                    positionMessage = positionMessage:template{name = name, position = position}
                    monocastMessage(playerIndex, "sync_" .. positionMessage)
                end
            end
        end
    end
end

--- Sync network object to player
---@param playerIndex number
---@param unit unit
---@param serverObjectId number
---@param syncedIndex number
local function updateNetworkObject(playerIndex, unit, serverObjectId, syncedIndex)
    local player = blam.biped(get_dynamic_player(playerIndex))
    if not player then
        return
    end
    -- Prevents AI from running out of ammo
    -- local aiWeapon = blam.weapon(get_object(ai.firstWeaponObjectId))
    -- if aiWeapon then
    --    -- TODO We should not use this
    --    aiWeapon.totalAmmo = 999
    -- end
    -- Sync AI biped if it is near to the player
    local cinematicGlobals = blam.cinematicGlobals()
    if isNull(player.vehicleObjectId) then
        if cinematicGlobals.isInProgress or
            (core.objectIsNearTo(player, unit, constants.syncDistance) and
                core.objectIsLookingAt(get_dynamic_player(playerIndex) --[[@as number]] ,
                                       serverObjectId, constants.syncBoundingRadius, 0,
                                       constants.syncDistance)) then
            local updatePacket = core.updateObjectPacket(syncedIndex, unit)
            if updatePacket and syncedIndex then
                monocastMessage(playerIndex, updatePacket)
            end
        end
    else
        local vehicle = blam.object(get_object(player.vehicleObjectId))
        if vehicle and core.objectIsNearTo(vehicle, unit, constants.syncDistance) then
            local updatePacket = core.updateObjectPacket(syncedIndex, unit)
            if updatePacket and syncedIndex then
                monocastMessage(playerIndex, updatePacket)
            end
        end
    end

end

---Syncs game data required just when the game starts
---@param playerIndex number
---@return boolean repeat
function SyncGameCoreState(playerIndex)
    -- Sync current bsp
    syncBspIndex(playerIndex)
    -- Force client to allow going trough bipeds
    monocastMessage(playerIndex, "disable_biped_collision")
    return false
end

local lastObjectStatePerPlayer = {}

---Syncs game data required constantly during the game
function SyncUpdate(playerIndex)
    for syncedIndex = 0, blam.getMaximumNetworkObjects() do
        local objectId = blam.getObjectIdBySyncedIndex(syncedIndex)
        if objectId then
            local object = blam.getObject(objectId)
            if object and
                (object.class == objectClasses.biped or object.class == objectClasses.vehicle) then
                local unit = blam.unit(object.address)
                assert(unit, "Unit cast failed")

                local lastObjectState = lastObjectStatePerPlayer[playerIndex][syncedIndex] or {}
                if object.shaderPermutationIndex ~= lastObjectState.shaderPermutationIndex then
                    monocastMessage(playerIndex, core.objectColorPacket(syncedIndex, object))
                end

                if core.unitPropertiesShouldBeSynced(unit, lastObjectState) then
                    lastObjectState = blam.dumpObject(unit)
                    lastObjectStatePerPlayer[playerIndex][syncedIndex] = lastObjectState
                    monocastMessage(playerIndex, core.unitPropertiesPacket(syncedIndex, unit))

                    if object.class == objectClasses.biped then
                        local biped = blam.biped(object.address)
                        assert(biped, "Biped cast failed")
                        monocastMessage(playerIndex, core.bipedPropertiesPacket(syncedIndex, biped))
                    end
                end
            end
        end
    end

    if player_present(playerIndex) then
        -- for _, objectId in pairs(core.getSyncedBipedIds()) do
        for syncedIndex = 0, blam.getMaximumNetworkObjects() do
            local objectId = blam.getObjectIdBySyncedIndex(syncedIndex)
            if objectId then
                local object = blam.object(get_object(objectId))
                if object then
                    local isUnit = object.class == objectClasses.biped or object.class ==
                                       objectClasses.vehicle
                    local unit = blam.unit(object.address)
                    assert(unit, "Unit cast failed")
                    local syncedIndex = core.getSyncedIndexByObjectId(objectId)
                    if isUnit and syncedIndex and core.isObjectSynceable(object, objectId) then
                        updateNetworkObject(playerIndex, unit, objectId, syncedIndex)
                    end
                end
            end
        end
        return true
    end
    return false
end

function RegisterPlayerSync(playerIndex)
    -- Register global function to sync data to new player
    _G["SyncUpdate" .. playerIndex] = function()
        return SyncUpdate(playerIndex)
    end
    local player = blam.player(get_player(playerIndex))
    if player then
        -- Add 33ms interval (like a tick ahead of server) to avoid sync problems
        local interval = player.ping + 15
        if player.ping < constants.syncEveryMillisecs then
            interval = constants.syncEveryMillisecs + 15
        end
        if player.ping > constants.maximumSyncInterval then
            say(playerIndex, "Your ping is too high, you may experience sync problems")
            interval = constants.maximumSyncInterval
        end
        logger:debug("Player table address is {}", string.tohex(get_player(playerIndex)))
        logger:debug("Player biped id is {}", string.tohex(player.objectId))
        logger:debug("Player sync index is {}", string.tohex(player.index))
        logger:debug("Player {} ping is {}ms", player.name, player.ping)
        logger:debug("SyncUpdate timer for player {} set to {}ms", playerIndex, interval)
        lastObjectStatePerPlayer[playerIndex] = {}
        set_timer(interval, "SyncUpdate" .. playerIndex)
    end
    return false
end

function OnPlayerJoin(playerIndex)
    -- Sync game data just required when the game starts
    set_timer(constants.startSyncingAfterMillisecs, "SyncGameCoreState", playerIndex)

    -- Sync game state
    set_timer(constants.startSyncingAfterMillisecs, "SyncGameState", playerIndex)

    -- Setup player sync update
    set_timer(constants.startSyncingAfterMillisecs, "RegisterPlayerSync", playerIndex)
end

function OnPlayerLeave(playerIndex)
    -- Remove player from sync update
    _G["SyncUpdate" .. playerIndex] = function()
        logger:debug("Removing SyncUpdate timer for player {}", playerIndex)
        return false
    end
end

function OnPlayerDead(deadPlayerIndex)
end

function resetState()
    deviceMachinesList = {}
    LastSyncCommand = ""
    currentBspIndex = nil
    currentScenario = nil
end

function OnGameEnd()
    resetState()
end

function ShowCurrentSyncedObjects(printTable)
    console_out("---------------------- SYNCED OBJECTS ----------------------")
    local syncedObjectsCount = 0
    for i = 0, 509 do
        local objectId = blam.getObjectIdBySyncedIndex(i)
        if objectId then
            syncedObjectsCount = syncedObjectsCount + 1
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
    if syncedObjectsCount > 500 then
        logger:warning("There are more than 500 synced objects, this will cause sync issues")
        say_all("There are more than 500 synced objects, this will cause sync issues")
    end
    logger:info("Total synced objects: {}", syncedObjectsCount)
    logger:info("Total synced bipeds: {}", #core.getSyncedBipedIds())
    return true
end

function OnMapLoad()
    if DebugMode then
        set_timer(5000, "ShowCurrentSyncedObjects")
    end
    resetState()
    logger:info("Mimic version: {}", version)
    currentScenario = blam.scenario(0)
    assert(currentScenario, "No current scenario tag found")
    if currentScenario.encounterPaletteCount > 0 then
        logger:warning("Scenario has AI encounters, enabling projectiles sync")
        serverSideProjectiles(true)
    else
        serverSideProjectiles(false)
    end
end

function OnTick()
    -- Check for BSP Changes
    local bspIndex = getBspIndex()
    if bspIndex ~= currentBspIndex then
        currentBspIndex = bspIndex
        logger:debug("New bsp index detected: {}", currentBspIndex)
        syncBspIndex()
    end

    for playerIndex = 1, 16 do
        local playerBiped = blam.biped(get_dynamic_player(playerIndex))
        if playerBiped then
            local player = blam.player(get_player(playerIndex))

            -- TODO We might need to optimize this
            blam.bipedTag(playerBiped.tagId).disableCollision = true

            -- We might need to turn this into a feature or something cause it affects maps
            -- that have phantom BSPs causing the player to be out side of the map for a fraction
            -- of time
            -- TODO Add a way to load these features from a file or something
            if playerBiped.isOutSideMap then
                local cinematic = blam.cinematicGlobals()
                if not cinematic.isInProgress and player then
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

    if currentScenario then
        -- Check for device machine changes
        for objectId, group in pairs(deviceMachinesList) do
            local device = blam.deviceMachine(get_object(objectId))
            if device then
                -- Only sync device machines that are name based due to mimic client limitations
                if not isNull(device.nameIndex) then
                    local name = currentScenario.objectNames[device.nameIndex + 1]
                    if name then
                        local power = blam.getDeviceGroup(device.powerGroupIndex)
                        local position = blam.getDeviceGroup(device.positionGroupIndex)

                        local t = {name = name, power = power, position = position}
                        if power and power ~= group.power then
                            -- Update last power state
                            deviceMachinesList[objectId].power = power

                            local command = "sync_device_set_power \"{name}\" {power}"
                            broadcastMessage(command:template(t))
                        end
                        if position and position ~= group.position then
                            -- Update last position state
                            deviceMachinesList[objectId].position = position

                            local command = "sync_device_set_position \"{name}\" {position}"
                            broadcastMessage(command:template(t))
                        end
                    end
                end
            end
        end
    end
end

function OnCommand(playerIndex, command, environment, rconPassword)
    local playerAdminLevel = tonumber(get_var(playerIndex, "$lvl"))
    if environment == 1 then
        if playerAdminLevel == 4 then
            if startswith(command, "mdis") then
                local data = split(command:replace("\"", ""), " ")
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
                -- elseif command:startswith "network_objects" then
                --    ShowCurrentSyncedObjects(true)
                --    return false
            elseif startswith(command, "mbullshit") then
                local data = split(command:gsub("\"", ""), " ")
                local serverId = tonumber(data[2]) --[[@as number]]
                local biped = blam.getObject(serverId)
                if biped then
                    local tag = blam.getTag(biped.tagId)
                    assert(tag, "Biped tag not found")
                    monocastMessage(playerIndex, tag.path .. " - HP: " .. biped.health)
                else
                    monocastMessage(playerIndex, "Warning, biped does not exist on the server.")
                end
                return false
            end
        end
    end
end

function OnScriptLoad()
    core.patchPlayerConnectionTimeout()
    rconPasswordAddress = read_dword(sig_scan("7740BA??????008D9B000000008A01") + 0x3)
    failMessageAddress = read_dword(sig_scan("B8????????E8??000000A1????????55") + 0x1)
    allowClientSideWeaponProjectilesAddress = read_dword(sig_scan("803D????????01741533C0EB") + 0x2)
    if rconPasswordAddress and failMessageAddress then
        -- Remove "rcon command failure" message
        safe_write(true)
        write_byte(failMessageAddress, 0x0)
        safe_write(false)
        -- Read current rcon in the server
        rconPassword = read_string(rconPasswordAddress)
        if rconPassword then
            cprint("Server rcon password is: \"" .. rconPassword .. "\"")
        else
            cprint("Error, at getting server rcon, please set and enable rcon on the server.")
        end
    else
        cprint("Error, at obtaining rcon patches, please check SAPP version.")
    end

    -- Set server callback
    register_callback(cb["EVENT_GAME_START"], "OnMapLoad")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
    register_callback(cb["EVENT_LEAVE"], "OnPlayerLeave")
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb["EVENT_DIE"], "OnPlayerDead")
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
        if tag.class == tagClasses.deviceMachine then
            deviceMachinesList[objectId] = {power = -1, position = -1}
        end
    end
    return true
end

-- Cleanup
function OnScriptUnload()
    if failMessageAddress then
        -- Restore "rcon command failure" message
        safe_write(true)
        write_byte(failMessageAddress, 0x72)
        safe_write(false)
    end
end

-- Log traceback for debug purposes
function OnError(message)
    logger:error("An error occurred: {}", message)
    local tb = debug.traceback()
    print(tb)
    say_all("An error is ocurring on the server side, tell a developer to check the logs.")
end
