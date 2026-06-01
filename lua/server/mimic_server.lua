------------------------------------------------------------------------------
-- Mimic Server
-- Sledmine (https://github.com/Sledmine)
-- Server side synchronization feature for AI
------------------------------------------------------------------------------
-- Declare api version before importing lua-blam
api_version = "1.12.0.0"

-- Lua modules
require "luna"
local split = string.split
local startswith = string.startswith

-- Bring compatibility modules (Lua 5.3 and Balltze API)
require "compat53"
require "balltzeCompat"

-- Pre require structures for blam2
require "structures.tag.biped"
require "structures.tag.scenario"

local blam = require "blam"
console_out = cprint

-- Halo Custom Edition modules
local isNull = blam.isNull
local objectClasses = blam.objectClasses
local tagClasses = blam.tagClasses
local core = require "mimic.core"
local toSentenceCase = core.toSentenceCase
local constants = require "mimic.constants"
local version = require "mimic.version"
local script = require "script"
local sleep = script.sleep

-- Settings
DebugMode = false
local bspIndexAddress = 0x40002CD8
local itemCollectionThresholdAddress = 0x0045adb1
local rconPasswordAddress
local failMessageAddress
local allowClientSideWeaponProjectilesAddress
local serverRconPassword
local enableSyncUpdate = true
local isItemsSystemOverridden = false

-- State
local deviceMachinesList = {}
LastSyncCommand = ""
local currentBspIndex
local currentScenario = nil
DisablePlayerCollision = true

logger = Balltze.logger.createLogger("Mimic Server")

---Enable or disable server side projectiles synchronization
---@param enable boolean
local function setServerSideProjectiles(enable)
    -- TODO Move this function to core module
    if not allowClientSideWeaponProjectilesAddress then
        logger:error("Error no address found for client side weapon projectiles")
    end
    write_byte(allowClientSideWeaponProjectilesAddress, enable and 0x0 or 0x1)
end

local function setItemCollectionThreshold(ticks)
    safe_write(true)
    -- Change engine item collection threshold
    write_dword(itemCollectionThresholdAddress + 0x2, ticks)
    safe_write(false)
    logger:info("Item collection threshold set to {} ticks ({} seconds)", ticks,
                blam.ticksToSeconds(ticks))
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
---@param considerLookingAt boolean
local function updateNetworkObject(playerIndex,
                                   unit,
                                   serverObjectId,
                                   syncedIndex,
                                   considerLookingAt)
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
        local isObjectSynchronizable = false
        -- Only sync if player is near to the object
        local isPlayerNear = core.isObjectNearToObject(player, unit, constants.syncDistance)
        if isPlayerNear then
            isObjectSynchronizable = true
            if considerLookingAt then
                isObjectSynchronizable =
                    core.objectIsLookingAt(get_dynamic_player(playerIndex) --[[@as number]] ,
                                           serverObjectId, constants.syncBoundingRadius, 0,
                                           constants.syncDistance)
            end
        end
        -- Always sync if cinematic is in progress
        -- Needed to sync certain objects during cinematics that are far from the player but close to the camera
        -- TODO Change this to use the camera position instead (cameras in the server side work differently)
        if cinematicGlobals.isInProgress then
            isObjectSynchronizable = true
        end
        if isObjectSynchronizable then
            local updatePacket = core.updateObjectPacket(syncedIndex, unit)
            if updatePacket and syncedIndex then
                monocastMessage(playerIndex, updatePacket)
            end
        end
    else
        local vehicle = blam.object(get_object(player.vehicleObjectId))
        if vehicle and core.isObjectNearToObject(vehicle, unit, constants.syncDistance) then
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

---Syncs game data required constantly during the game like object properties and state
---@param playerIndex number
---@return boolean repeat
function SyncUpdate(playerIndex)
    for syncedIndex = 0, blam.getMaximumNetworkObjects() do
        local objectHandle = blam.getObjectIdBySyncedIndex(syncedIndex)
        if objectHandle then
            local object = blam.getObject(objectHandle)
            if object then
                local isUnit = object.class == objectClasses.biped or object.class ==
                                   objectClasses.vehicle
                local isItem = object.class == objectClasses.equipment or object.class ==
                                   objectClasses.weapon
                local isSynchronizable = isUnit or isItem
                if isSynchronizable then
                    local lastObjectState = lastObjectStatePerPlayer[playerIndex][syncedIndex] or {}
                    if isUnit then
                        local unit = blam.unit(object.address)
                        assert(unit, "Unit cast failed")

                        if object.shaderPermutationIndex ~= lastObjectState.shaderPermutationIndex then
                            monocastMessage(playerIndex, core.objectColorPacket(syncedIndex, object))
                        end

                        if core.unitPropertiesShouldBeSynced(unit, lastObjectState) then
                            -- TODO Check on a better implementation for this, it is overkill
                            lastObjectState = blam.dumpObject(unit)
                            lastObjectStatePerPlayer[playerIndex][syncedIndex] = lastObjectState
                            monocastMessage(playerIndex,
                                            core.unitPropertiesPacket(syncedIndex, unit))

                            if object.class == objectClasses.biped then
                                local biped = blam.biped(object.address)
                                assert(biped, "Biped cast failed")
                                monocastMessage(playerIndex,
                                                core.bipedPropertiesPacket(syncedIndex, biped))
                            end
                        end
                    end
                    if isItem then
                        local item = blam.item(object.address)
                        assert(item, "Item cast failed")

                        if not isNull(item.nameIndex) and item.nameIndex ~=
                            lastObjectState.nameIndex then
                            lastObjectState.nameIndex = item.nameIndex
                            lastObjectStatePerPlayer[playerIndex][syncedIndex] = lastObjectState
                            monocastMessage(playerIndex, core.updateItemPacket(syncedIndex, item))
                            logger:debug(
                                "Item with handle {} has name index {}, syncing to player {}",
                                objectHandle, item.nameIndex, playerIndex)
                        end
                    end
                end
            end
        end
    end

    if player_present(playerIndex) then
        for syncedIndex = 0, blam.getMaximumNetworkObjects() do
            local objectHandle = blam.getObjectIdBySyncedIndex(syncedIndex)
            if objectHandle then
                local object = blam.object(get_object(objectHandle))
                if object then
                    local isUnit = object.class == objectClasses.biped or object.class ==
                                       objectClasses.vehicle
                    local isVehicle = object.class == objectClasses.vehicle
                    local unit = blam.unit(object.address)
                    assert(unit, "Unit cast failed")
                    local syncedIndex = core.getSyncedIndexByObjectId(objectHandle)
                    if isUnit and syncedIndex and core.isObjectSynceable(object, objectHandle) then
                        updateNetworkObject(playerIndex, unit, objectHandle, syncedIndex, not isVehicle)
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
    local syncUpdateFuncName = "SyncUpdate" .. playerIndex
    _G[syncUpdateFuncName] = function()
        -- logger:debug("Executing SyncUpdate for player {}", playerIndex)
        if not enableSyncUpdate then
            return true
        end
        return SyncUpdate(playerIndex)
    end
    local player = blam.player(get_player(playerIndex))
    if player then
        -- Add 33ms interval (like a tick ahead of server) to avoid sync problems
        local interval = player.ping + 16
        if player.ping < constants.syncEveryMillisecs then
            interval = constants.syncEveryMillisecs + 16
        end
        if player.ping > constants.maximumSyncInterval then
            say(playerIndex, "Your ping is too high, you may experience sync problems")
            interval = constants.maximumSyncInterval
        end
        -- logger:debug("Player table address is {}", string.tohex(get_player(playerIndex)))
        -- logger:debug("Player biped id is {}", string.tohex(player.objectId))
        -- logger:debug("Player sync index is {}", string.tohex(player.index))
        logger:debug("Player {} ping is {}ms", player.name, player.ping)
        logger:debug("SyncUpdate timer for player {} set to {}ms", playerIndex, interval)
        lastObjectStatePerPlayer[playerIndex] = {}
        set_timer(interval, syncUpdateFuncName)
    end
    return false
end

-- This causes crashes because coroutines can not yield inside a timer function nor an event (?)
-- script.continuous(function()
--    -- sleep(blam.secondsToTicks(constants.startSyncingAfterMillisecs / 1000))
--    sleep(blam.secondsToTicks(1))
--    for playerIndex = 1, 16 do
--        script.continuous(function()
--            sleep(function()
--                return player_present(playerIndex)
--            end)
--            if _G["SyncUpdate" .. playerIndex] then
--                return
--            end
--            logger:warning("Registering SyncUpdate timer for player {}", playerIndex)
--            -- Setup player sync update
--            set_timer(constants.startSyncingAfterMillisecs, "RegisterPlayerSync", playerIndex)
--        end)
--    end
-- end)

function OnPlayerJoin(playerIndex)
    -- Sync game data just required when the game starts
    set_timer(constants.startSyncingAfterMillisecs, "SyncGameCoreState", playerIndex)

    -- Sync game state
    set_timer(constants.startSyncingAfterMillisecs, "SyncGameState", playerIndex)

    set_timer(constants.startSyncingAfterMillisecs, "RegisterPlayerSync", playerIndex)
end

function OnPlayerLeave(playerIndex)
    -- Remove player from sync update
    local syncUpdateFuncName = "SyncUpdate" .. playerIndex
    _G[syncUpdateFuncName] = function()
        logger:debug("Removing SyncUpdate timer for player {}", playerIndex)
        -- _G[syncUpdateFuncName] = nil
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

local function printNetworkObjects(printTable)
    console_out("---------------------- NETWORK OBJECTS ----------------------")
    local networkObjectsCount = 0
    for i = 0, blam.getMaximumNetworkObjects() do
        local objectId = blam.getObjectIdBySyncedIndex(i)
        if objectId then
            networkObjectsCount = networkObjectsCount + 1
            if printTable then
                local objectAddress = get_object(objectId)
                local object = blam.object(objectAddress)
                if object then
                    local format = "[%s] - %s - Handle: %s"
                    console_out(format:format(i, blam.getTag(object.tagId).path, objectId))
                else
                    local format = "[%s] - %s - Handle: %s"
                    console_out(format:format(i, "NULL", objectId))
                end
            end
        end
    end
    if networkObjectsCount > 500 then
        logger:warning("There are more than 500 networked objects, this will cause stability issues")
        say_all("There are more than 500 networked objects, this will cause stability issues")
    end
    logger:info("Total network objects: {}", networkObjectsCount)
    logger:info("Total network bipeds: {}", #core.getNetworkBipeds())
    return true
end

function OnMapLoad()
    logger:info("Mimic version: {}", version)
    currentScenario = blam.scenario(0)
    assert(currentScenario, "No current scenario tag found")
    if currentScenario.encounterPaletteCount > 0 then
        logger:warning("Scenario has AI encounters, assuming AI synchronization is required")
        setServerSideProjectiles(true)
        isItemsSystemOverridden = true
    else
        isItemsSystemOverridden = false
        setServerSideProjectiles(false)
    end
    -- Disable feign death chance to prevent buggy behavior with AI synchronization
    core.disableBipedsFeignDeathChance()
    -- Reset created tracked items
    core.dynamicallySpawnScenarioItems(true)

    -- Debug loop to print network objects, useful to detect maps with too many network objects
    if DebugMode then
        script.continuous(function()
            local memoryUsage = collectgarbage("count") / 1024
            local memoryText = string.format("Mimic script memory usage: %.2f MB", memoryUsage)
            logger:debug(memoryText)
            printNetworkObjects()
            script.sleep(blam.secondsToTicks(4))
        end)
    end

    -- Continuously control network items to prevent them from despawning
    script.continuous(function()
        if isItemsSystemOverridden then
            -- logger:debug("Dynamically controlling network items...")
            core.dynamicallyControlNetworkItems()
            script.sleep(10)
        end
    end)

    -- Continuously respawn scenario items to ensure players will have ammo and weapons
    script.continuous(function()
        if isItemsSystemOverridden then
            --logger:debug("Respawning scenario items...")
            core.dynamicallySpawnScenarioItems()
            script.sleep(blam.secondsToTicks(10))
        end
    end)

    -- Continuously disable player collision to improve sync experience
    script.continuous(function()
        core.disablePlayerCollision(DisablePlayerCollision)
        script.sleep(blam.secondsToTicks(1))
    end)
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
        script.poll()
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

                            local message = "sync_device_set_power \"{name}\" {power}"
                            broadcastMessage(message:template(t))
                        end
                        if position and position ~= group.position then
                            -- Update last position state
                            deviceMachinesList[objectId].position = position

                            local message = "sync_device_set_position \"{name}\" {position}"
                            broadcastMessage(message:template(t))
                        end
                    end
                end
            end
        end
    end
end

local RCON_ENVIRONMENT = 1
local ADMIN_LEVEL = 4

function OnCommand(playerIndex, command, environment, rconPassword)
    local playerAdminLevel = tonumber(get_var(playerIndex, "$lvl"))
    if environment == RCON_ENVIRONMENT then
        if playerAdminLevel == ADMIN_LEVEL or rconPassword == serverRconPassword then
            if startswith(command, "mimic_distance") then
                local data = split(command:replace("\"", ""), " ")
                local newRadius = tonumber(data[2])
                if newRadius then
                    constants.syncDistance = newRadius
                end
                say_all("Mimic synchronization radius: " .. constants.syncDistance)
                return false
            elseif startswith(command, "mimic_toggle") then
                enableSyncUpdate = not enableSyncUpdate
                local status = toSentenceCase(tostring(enableSyncUpdate))
                say_all("Mimic synchronization update is now: " .. status)
                return false
            elseif startswith(command, "mimic_sync_rate") then
                local data = split(command:gsub("\"", ""), " ")
                local newRate = tonumber(data[2])
                if newRate then
                    constants.syncEveryMillisecs = newRate
                end
                say_all("Mimic synchronization rate: " .. constants.syncEveryMillisecs)
                return false
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

function PluginLoad()
    logger:muteDebug(not DebugMode)

    setItemCollectionThreshold(blam.secondsToTicks(15))

    if Engine.netgame.getServerType() == "local" or Engine.netgame.getServerType() == "sapp" then
        core.patchPlayerConnectionTimeout()
    end
    
    rconPasswordAddress = read_dword(sig_scan("7740BA??????008D9B000000008A01") + 0x3)
    failMessageAddress = read_dword(sig_scan("B8????????E8??000000A1????????55") + 0x1)
    allowClientSideWeaponProjectilesAddress = read_dword(sig_scan("803D????????01741533C0EB") + 0x2)
    if rconPasswordAddress and failMessageAddress then
        -- Remove "rcon command failure" message
        safe_write(true)
        write_byte(failMessageAddress, 0x0)
        safe_write(false)
        -- Read current rcon in the server
        serverRconPassword = read_string(rconPasswordAddress)
        if serverRconPassword then
            -- logger:debug("Server rcon password is: \"" .. serverRconPassword .. "\"")
        else
            logger:error("Error, at getting server rcon, please set and enable rcon on the server.")
        end
    else
        logger:error("Error, at obtaining rcon patches, please check SAPP version.")
    end

    -- Set server callback
    -- TODO Balltze Migrate
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
function PluginUnload()
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
