local glue = require "glue"
local luna = require "luna"
local hscDoc = require "hscDoc"
local inspect = require "inspect"
local split = luna.string.split
local tohex = glue.string.tohex
local fromhex = glue.string.fromhex
local append = glue.append
local shift = glue.shift
local trim = glue.string.trim
local escape = glue.string.esc
local starts = luna.string.startswith
local sqrt = math.sqrt
local abs = math.abs
local floor = math.floor
local strpack = string.pack
local strunpack = string.unpack
local concat = table.concat
local blam = require "blam"
local isNull = blam.isNull
local color = require "ncolor"
local getIndexById = blam.getIndexById
local engine = Engine

local core = {}
local packetPrefix = "@"
local packetSeparator = ","

function core.encode(format, value)
    return tohex(strpack(format, value))
end
local encode = core.encode

function core.decode(format, value)
    return strunpack(format, fromhex(value))
end
local decode = core.decode

--- Create an object color packet string
---@param syncedIndex number
---@param object blamObject
---@return string
function core.objectColorPacket(syncedIndex, object)
    local packet = concat({
        packetPrefix .. "c",
        syncedIndex,
        color.decToHex(object.colorAUpperRed, object.colorAUpperGreen, object.colorAUpperBlue),
        color.decToHex(object.colorBUpperRed, object.colorBUpperGreen, object.colorBUpperBlue),
        color.decToHex(object.colorCUpperRed, object.colorCUpperGreen, object.colorCUpperBlue),
        color.decToHex(object.colorDUpperRed, object.colorDUpperGreen, object.colorDUpperBlue),
        object.shaderPermutationIndex

    }, packetSeparator)
    assert(#packet <= 64, "Packet size is too big")
    return packet
end

---Create an object update packet string
---@param syncedIndex number
---@param object blamObject
---@return string? updatePacket
function core.updateObjectPacketNoParent(syncedIndex, object)
    local yaw, pitch, roll = blam.getObjectRotation(object)
    return concat({
        packetPrefix .. "u",
        syncedIndex,
        encode("f", object.x),
        encode("f", object.y),
        encode("f", object.z),
        object.animation,
        object.animationFrame,
        encode("f", yaw),
        encode("f", pitch),
        encode("f", roll)
    }, packetSeparator)
end

---Create an object update packet string
---@param syncedIndex number
---@param object blamObject
---@return string? updatePacket
function core.updateObjectPacket(syncedIndex, object)
    local yaw, pitch, roll = blam.getObjectRotation(object)
    local packet = {
        packetPrefix .. "u",
        syncedIndex,
        encode("f", object.x),
        encode("f", object.y),
        encode("f", object.z),
        getIndexById(object.animationTagId),
        object.animation,
        object.animationFrame,
        encode("f", yaw),
        encode("f", pitch),
        encode("f", roll)
    }
    -- Send absolute object coordinates for vehicles until we can sync parented objects
    local isVehicle = object.class == blam.objectClasses.vehicle
    if isVehicle then
        local absolute = blam.getAbsoluteObjectCoordinates(object)
        packet[3] = encode("f", absolute.x)
        packet[4] = encode("f", absolute.y)
        packet[5] = encode("f", absolute.z)
    end
    return concat(packet, packetSeparator)
end

local snakeCaseTagClasses = {
    actor_variant = "actv",
    actor = "actr",
    antenna = "ant!",
    biped = "bipd",
    bitmap = "bitm",
    camera_track = "trak",
    color_table = "colo",
    continuous_damage_effect = "cdmg",
    contrail = "cont",
    damage_effect = "jpt!",
    decal = "deca",
    detail_object_collection = "dobc",
    device_control = "ctrl",
    device_light_fixture = "lifi",
    device_machine = "mach",
    device = "devi",
    dialogue = "udlg",
    effect = "effe",
    equipment = "eqip",
    flag = "flag",
    fog = "fog ",
    font = "font",
    garbage = "garb",
    gbxmodel = "mod2",
    globals = "matg",
    glow = "glw!",
    grenade_hud_interface = "grhi",
    hud_globals = "hudg",
    hud_message_text = "hmt ",
    hud_number = "hud#",
    item_collection = "itmc",
    item = "item",
    lens_flare = "lens",
    light_volume = "mgs2",
    light = "ligh",
    lightning = "elec",
    material_effects = "foot",
    meter = "metr",
    model_animations = "antr",
    model_collision_geometry = "coll",
    model = "mode",
    multiplayer_scenario_description = "mply",
    object = "obje",
    particle_system = "pctl",
    particle = "part",
    physics = "phys",
    placeholder = "plac",
    point_physics = "pphy",
    preferences_network_game = "ngpr",
    projectile = "proj",
    scenario_structure_bsp = "sbsp",
    scenario = "scnr",
    scenery = "scen",
    shader_environment = "senv",
    shader_model = "soso",
    shader_transparent_chicago_extended = "scex",
    shader_transparent_chicago = "schi",
    shader_transparent_generic = "sotr",
    shader_transparent_glass = "sgla",
    shader_transparent_meter = "smet",
    shader_transparent_plasma = "spla",
    shader_transparent_water = "swat",
    shader = "shdr",
    sky = "sky ",
    sound_environment = "snde",
    looping_sound = "lsnd",
    sound_scenery = "ssce",
    sound = "snd!",
    spheroid = "boom",
    string_list = "str#",
    tag_collection = "tagc",
    ui_widget_collection = "Soul",
    ui_widget_definition = "DeLa",
    unicode_string_list = "ustr",
    unit_hud_interface = "unhi",
    unit = "unit",
    vehicle = "vehi",
    virtual_keyboard = "vcky",
    weapon_hud_interface = "wphi",
    weapon = "weap",
    weather_particle_system = "rain",
    wind = "wind"
}

local function getObjectIndexByName(objectName)
    local scenario = blam.scenario(0)
    assert(scenario, "Failed to load scenario tag")
    local objectIndex = table.indexof(scenario.objectNames, objectName)
    if objectIndex then
        logger:warning("Value: {} is an object, converting to object index!", objectName)
        return objectIndex
    end
end

local function getArgType(funcMeta, argIndex)
    local argType = funcMeta.args[argIndex]
    if table.indexof(hscDoc.nativeTypes, argType) then
        return argType
    end
    if argType == "object" or argType == "vehicle" or argType == "biped" or argType == "weapon" or
        argType == "unit" or argType == "scenery" or argType == "device" or argType == "object_name" then
        return "object"
    end
    local tagType = snakeCaseTagClasses[argType]
    if tagType then
        return "tag", tagType
    end
    return argType
end

--- Create a packet string for an hsc function invocation
---@param functionName string
---@param args string[]
---@return string
function core.hscPacket(functionName, args)
    local funcMeta = table.find(hscDoc.functions, function(v, k)
        return v.funcName == functionName
    end)
    if not funcMeta then
        error("Function " .. functionName .. " not found in hscDoc")
    end
    local args = table.map(args, function(argValue, argIndex)
        local argType, tagType = getArgType(funcMeta, argIndex)
        if argType == "object" then
            local objectIndex = getObjectIndexByName(argValue)
            if objectIndex then
                logger:debug("Value {} is an object, converting to object index!", argValue)
                return objectIndex
            end
        elseif argType == "tag" then
            local argIsSubExpression = argValue:startswith "(" and argValue:endswith ")"
            if not argIsSubExpression then
                local tagEntry = blam.getTag(argValue, tagType)
                if tagEntry then
                    logger:debug("Value {} is a tag, converting to tag handle!", argValue)
                    return tagEntry.id
                end
            end
        end
        return argValue
    end)

    local packet = {packetPrefix .. funcMeta.hash, table.unpack(args)}

    return concat(packet, packetSeparator)
end

local function getObjectNameByIndex(objectIndex)
    local scenario = blam.scenario(0)
    assert(scenario, "Failed to load scenario tag")
    return scenario.objectNames[objectIndex]
end

function core.parseHscPacket(packet)
    assert(packet and packet:startswith(packetPrefix), "Invalid HSC packet")
    -- logger:debug("Parsing HSC packet: {}", packet)
    local packetParts = split(packet:replace(packetPrefix, ""), packetSeparator)
    local funcHash = packetParts[1]
    local funcMeta = table.find(hscDoc.functions, function(v, k)
        return v.hash == funcHash
    end)
    assert(funcMeta, "Function not found in hscDoc")
    local packetData = table.slice(packetParts, 2)
    packetData = table.map(packetData, function(argValue, argIndex)
        local argIsSubExpression = argValue:startswith "(" and argValue:endswith ")"
        if argIsSubExpression then
            return argValue
        end
        local argType = getArgType(funcMeta, argIndex)
        -- logger:debug("Arg type: \"{}\" for value: \"{}\"", argType, argValue)
        if argType == "object" then
            if argValue == "none" or argValue == "" then
                return argValue
            end
            local objectIndex = tointeger(argValue)
            assert(objectIndex, "Failed to convert object index to number")
            local objectName = getObjectNameByIndex(objectIndex)
            if objectName then
                -- logger:debug("Value {} is an object index, converting to object name!", argValue)
                return objectName
            end
        elseif argType == "tag" then
            local tagEntry = blam.getTag(tointeger(argValue))
            if tagEntry then
                -- logger:debug("Value {} is a tag handle, converting to tag path!", argValue)
                return tagEntry.path
            end
        end
        return argValue
    end)
    return funcMeta.funcName .. " " .. concat(packetData, " ")
end

--- Create a packet string to define object properties
---@param syncedIndex number
---@param unit unit
function core.unitPropertiesPacket(syncedIndex, unit)
    local parentSeatIndex
    local parentObjectSyncedIndex = core.getSyncedIndexByObjectId(unit.parentObjectId)
    if not isNull(unit.parentSeatIndex) then
        parentSeatIndex = unit.parentSeatIndex
    end
    local isVehicle = unit.class == blam.objectClasses.vehicle
    if isVehicle then
        parentSeatIndex = nil
        parentObjectSyncedIndex = nil
    end
    local packet = concat({
        "@o",
        syncedIndex,
        -- concat({
        unit.regionPermutation1,
        unit.regionPermutation2,
        unit.regionPermutation3,
        unit.regionPermutation4,
        unit.regionPermutation5,
        unit.regionPermutation6,
        unit.regionPermutation7,
        unit.regionPermutation8,
        -- }),
        unit.isCamoActive and 1 or 0,
        parentObjectSyncedIndex or "",
        parentSeatIndex or "",
        unit.team
    }, packetSeparator)
    assert(#packet <= 64, "Packet size is too big")
    return packet
end

--- Create a packet string to define biped properties
---@param syncedIndex number
---@param biped biped
function core.bipedPropertiesPacket(syncedIndex, biped)
    local packet = concat({
        "@b",
        syncedIndex,
        core.getSyncedIndexByObjectId(biped.firstWeaponObjectId) or "",
        core.getSyncedIndexByObjectId(biped.secondWeaponObjectId) or "",
        biped.flashlight and 1 or 0,
        biped.isApparentlyDead and 1 or 0,
    }, packetSeparator)
    assert(#packet <= 64, "Packet size is too big")
    return packet
end

--- Check if biped is near by to an object
---@param biped blamObject
---@param target blamObject
---@param sensitivity number
function core.objectIsNearTo(biped, target, sensitivity)
    if target and biped then
        local distance = sqrt((target.x - biped.x) ^ 2 + (target.y - biped.y) ^ 2 +
                                  (target.z - biped.z) ^ 2)
        if abs(distance) < sensitivity then
            return true
        end
    end
    return false
end

function core.updateObject(objectId,
                           x,
                           y,
                           z,
                           yaw,
                           pitch,
                           roll,
                           animation,
                           animationFrame,
                           animationTagIndex)
    if objectId then
        local object = blam.object(get_object(objectId))
        -- NOTES:
        -- 1. Apparently dead bipeds might not have to be updated
        -- 2. Objects outside the map lag the game when updated for some reason
        if not object then
            return false
        end
        if object.isOutSideMap then
            return false
        end
        if object.isApparentlyDead then
            return false
        end
        local isBiped = object.class == blam.objectClasses.biped
        local isVehicle = object.class == blam.objectClasses.vehicle

        object.x = x
        object.y = y
        object.z = z
        object.zVel = 0
        blam.rotateObject(object, yaw, pitch, roll)

        if isBiped then
            local animationTagHandle = blam.getTag(animationTagIndex, tagClasses.modelAnimations).id
            assert(animationTagHandle, "Failed to get synced animation tag id")
            object.animationTagId = animationTagHandle
            object.animation = animation
            object.animationFrame = animationFrame
        end
        -- if isShooting and not isNull(unit.firstWeaponObjectId) then
        --    local weapon = blam.weapon(get_object(unit.firstWeaponObjectId))
        --    if weapon then
        --        weapon.primaryTriggerState = isShooting
        --    end
        -- end
        return true
    end
    return false
end

--- "Virtualize" biped object, applies required transformations for easier network sync
---@param biped blamObject
function core.virtualizeObject(biped)
    -- Do not make biped ghost if it has a parent object
    if isNull(biped.parentObjectId) then
        biped.isGhost = false
    end
    -- biped.isOutSideMap = false
    biped.isNotDamageable = true
    -- biped.isNotAffectedByGravity = true
    -- biped.isCollideable = true
    -- biped.hasNoCollision = false
end

--- Revert virtualization transformations
---@param biped blamObject
function core.revertBipedVirtualization(biped)
    biped.isGhost = false
    biped.isNotDamageable = false
    biped.isNotAffectedByGravity = false
    biped.isCollideable = true
    biped.hasNoCollision = false
end

--- Normalize any map name or snake case name to a name with sentence case
---@param name string
function core.toSentenceCase(name)
    return string.gsub(" " .. name:gsub("_", " "), "%W%l", string.upper):sub(2)
end

--- Process HSC code from the Harmony hook
---@param hscCommand string
---@return string?
function core.adaptHSC(hscCommand)
    -- Check if the map is trying to get a player on a vehicle
    if starts(hscCommand, "sync_unit_enter_vehicle") and hscCommand:find("player") then
        local params = core.parseHSC(hscCommand)
        local unitName = params[2]
        local begin, last = unitName:find("player")
        local playerIndex = to_player_index(tonumber(unitName:sub(last + 1, last + 2), 10))
        local objectName = params[3]
        local seatIndex = tonumber(params[4], 10)
        for vehicleObjectId, vehicleTagId in pairs(VehiclesList) do
            local vehicle = blam.object(get_object(vehicleObjectId))
            if vehicle and not isNull(vehicle.nameIndex) then
                local scenario = blam.scenario(0)
                local objectScenarioName = scenario.objectNames[vehicle.nameIndex + 1]
                if objectName == objectScenarioName then
                    if player_present(playerIndex) then
                        console_debug("Player " .. playerIndex .. " will enter vehicle " ..
                                          vehicleObjectId .. " on seat " .. seatIndex)
                        enter_vehicle(vehicleObjectId, playerIndex, seatIndex)
                    end
                end
            end
        end
        return
    elseif starts(hscCommand, "sync_object_create ") or
        starts(hscCommand, "sync_object_create_anew ") then
        -- Only sync object creation if object is not a vehicle
        local params = core.parseHSC(hscCommand)
        local objectName = params[2]
        for vehicleObjectId, vehicleTagId in pairs(VehiclesList) do
            local vehicle = blam.object(get_object(vehicleObjectId))
            if vehicle and not isNull(vehicle.nameIndex) then
                local scenario = blam.scenario(0)
                assert(scenario, "Failed to load scenario tag")
                local objectScenarioName = scenario.objectNames[vehicle.nameIndex + 1]
                if (objectName == objectScenarioName) then
                    return
                end
            end
        end
    elseif (starts(hscCommand, "sync_object_teleport") and hscCommand:find("player")) then
        -- Cancel player teleport on client to prevent desync
        -- TODO Remove sync for this from the Mimic adapter, it will prevent crashes on client
        return
    elseif (starts(hscCommand, "sync_unit_suspended") and hscCommand:find("player")) then
        local params = core.parseHSC(hscCommand)
        local unitName = params[2]
        local begin, last = unitName:find("player")
        local playerIndex = to_player_index(tonumber(unitName:sub(last + 1, last + 2), 10))
        local playerBiped = blam.biped(get_dynamic_player(playerIndex))
        if (playerBiped and not isNull(playerBiped.vehicleObjectId)) then
            say_all("Erasing player vehicle...")
            delete_object(playerBiped.vehicleObjectId)
        end
        return
    elseif (hscCommand:find("nav_point")) then
        -- FIXME This is not working for some reason
        for playerIndex = 0, 15 do
            Broadcast(hscCommand:gsub("player0", "player" .. playerIndex))
        end
        return
    else
        for actionName, action in pairs(hsc) do
            -- Check if command has parameters
            if starts(hscCommand, "sync_" .. actionName .. " ") then
                -- Escape spaces and quotes
                console_debug("Raw command: " .. hscCommand)

                local params = core.parseHSC(hscCommand)
                params = shift(params, 1, -1)

                -- Structure that holds command data
                local syncPacketData = {action.packetType}

                -- Transform parameters into blam terms, IDs, indexes, etc
                for parameterIndex, parameter in pairs(action.parameters) do
                    local argumentValue = params[parameterIndex]
                    if argumentValue then
                        if parameter.value and parameter.class then
                            argumentValue = tostring(blam.getTag(argumentValue, parameter.class).id)
                        end
                        append(syncPacketData, argumentValue)
                    end
                end

                local syncPacket = concat(syncPacketData, ",")
                return syncPacket
            end
        end
    end
    return hscCommand
end

--- Get the synced network index of an object by object id
---@param localObjectId number
---@return number?
function core.getSyncedIndexByObjectId(localObjectId)
    for index = 0, 509 do
        local objectId = blam.getObjectIdBySyncedIndex(index)
        if objectId and objectId == localObjectId then
            return index
        end
    end
    return nil
end

--- Check if player is looking at object main frame
---@param mainObject? number
---@param target number
---@param sensitivity number
---@param zOffset number
---@param maximumDistance number
function core.objectIsLookingAt(mainObject, target, sensitivity, zOffset, maximumDistance)
    -- Minimum amount for distance scaling
    local baselineSensitivity = 0.012
    local function read_vector3d(Address)
        return read_float(Address), read_float(Address + 0x4), read_float(Address + 0x8)
    end
    local targetObject = get_object(target)
    -- Both objects must exist
    if (targetObject and mainObject) then
        local playerX, playerY, playerZ = read_vector3d(mainObject + 0xA0)
        local cameraX, cameraY, cameraZ = read_vector3d(mainObject + 0x230)
        -- Target location 2
        local targetX, targetY, targetZ = read_vector3d(targetObject + 0x5C)
        -- 3D distance
        local distance = sqrt((targetX - playerX) ^ 2 + (targetY - playerY) ^ 2 +
                                  (targetZ - playerZ) ^ 2)
        local localX = targetX - playerX
        local localY = targetY - playerY
        local localZ = (targetZ + (zOffset or 0)) - playerZ
        local pointX = 1 / distance * localX
        local pointY = 1 / distance * localY
        local pointZ = 1 / distance * localZ
        local xDiff = abs(cameraX - pointX)
        local yDiff = abs(cameraY - pointY)
        local zDiff = abs(cameraZ - pointZ)
        local average = (xDiff + yDiff + zDiff) / 3
        local scaler = 0
        if distance > 10 then
            scaler = floor(distance) / 1000
        end
        local aimMagnetisim = sensitivity - scaler
        if aimMagnetisim < baselineSensitivity then
            aimMagnetisim = baselineSensitivity
        end
        if average < aimMagnetisim and distance < (maximumDistance or 15) then
            return true
        end
    end
    return false
end

--- Get the synced biped ids
---@return number[]
function core.getSyncedBipedIds()
    local syncedBipedIds = {}
    for index = 0, 509 do
        local objectId = blam.getObjectIdBySyncedIndex(index)
        if objectId then
            local object = blam.object(get_object(objectId))
            if object and object.class == blam.objectClasses.biped then
                -- table.insert(syncedBipedIds, objectId)
                syncedBipedIds[index] = objectId
            end
        end
    end
    return syncedBipedIds
end

--- Get the synced biped ids
---@return number[]
function core.getSyncedObjectsIds()
    local syncedObjectsIds = {}
    for index = 0, 509 do
        local objectId = blam.getObjectIdBySyncedIndex(index)
        if objectId then
            local object = blam.object(get_object(objectId))
            if object then
                table.insert(syncedObjectsIds, objectId)
            end
        end
    end
    return syncedObjectsIds
end

---Validate if a biped is syncable
---@param object blamObject
---@param objectId number
function core.isObjectSynceable(object, objectId)
    -- Filter server bipeds that are already synced
    for playerIndex = 1, 16 do
        local playerObjectAdress = get_dynamic_player(playerIndex)
        local unit = blam.unit(playerObjectAdress)
        if unit and unit.parentObjectId == objectId then
            return false
        end
        local aiObjectAddress = get_object(objectId)
        -- AI is the same as the player, do not sync
        if playerObjectAdress == aiObjectAddress then
            return false
        end
    end
    -- Only sync ai inside the same bsp as the players
    if object.isOutSideMap then
        return false
    end
    if isNull(object.nameIndex) then
        -- return false
    end
    return true
end

local synceableObjectProperties = {
    "regionPermutation1",
    "regionPermutation2",
    "regionPermutation3",
    "regionPermutation4",
    "regionPermutation5",
    "regionPermutation6",
    "regionPermutation7",
    "regionPermutation8",
    "parentObjectId",
    "parentSeatIndex"
}

--- Check if unit should be synced
---@param unit unit
---@param lastObjectProperties table
---@return boolean
function core.unitPropertiesShouldBeSynced(unit, lastObjectProperties)
    for _, property in pairs(synceableObjectProperties) do
        if unit[property] ~= lastObjectProperties[property] then
            return true
        end
    end
    return false
end

local synceableBipedProperties = {
    "isCamoActive",
    "firstWeaponObjectId",
    "secondWeaponObjectId",
    "flashlight"
}

--- Check if biped should be synced
---@param biped biped
---@param lastBipedProperties table
---@return boolean
function core.bipedShouldBeSynced(biped, lastBipedProperties)
    for _, property in pairs(synceableBipedProperties) do
        if biped[property] ~= lastBipedProperties[property] then
            return true
        end
    end
    return false
end

local setDisconnectedFlagAddress = 0x004cbbb0 + 0x1
local stockTimeout = 15000
local expandedTimeout = 45000
function core.patchPlayerConnectionTimeout(revert)
    safe_write(true)
    -- Increase player connection timeout
    if revert then
        write_word(setDisconnectedFlagAddress, stockTimeout)
        safe_write(false)
        return
    end
    write_word(setDisconnectedFlagAddress, expandedTimeout)
    safe_write(false)
end

--- Disable player collision
---@param enable boolean
function core.disablePlayerCollision(enable)
    if engine.netgame.getServerType() == "dedicated" then
        for playerIndex = 1, 16 do
            local playerObject = get_dynamic_player(playerIndex)
            if playerObject then
                local biped = blam.biped(playerObject)
                if biped then
                    blam.bipedTag(biped.tagId).disableCollision = enable
                end
            end
        end
    else
        for playerIndex = 0, 15 do
            local playerObject = get_dynamic_player(playerIndex)
            if playerObject then
                local biped = blam.biped(playerObject)
                if biped then
                    blam.bipedTag(biped.tagId).disableCollision = enable
                end
            end
        end
    end
end

return core
