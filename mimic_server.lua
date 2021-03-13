-- SAPP Lua Script Boilerplate
-- Version 1.0
-- Every function uses lower camel case, be careful about naming conventions
-- Api version must be declared at the top
-- It helps lua-blam to detect if the script is made for SAPP or Chimera
api_version = "1.12.0.0"

-- Lua libraries
local inspect = require "inspect"

-- Halo Custom Edition specific libraries
local blam = require "blam"

-- Mimic specific variables & depenencies
local listAi, clkTics = {}, 0

-- On tick function provided by default if needed
-- Be careful at handling data here, things can be messy
function OnTick(playerIndex)
    local player = blam.biped(get_dynamic_player(1))
    if (player and player.flashlightKey) then
        execute_script("ai_kill encounter")
        --execute_script("ai_place encounter")
         listAi = {}
    end


    if (clkTics == 5) then
        for index, objectId in pairs(listAi) do
            local biped = blam.biped(get_object(objectId))
            --rprint(1, biped.x .. biped.y .. biped.z .. clkTics) 
            rprint(1, clkTics)
        end
        clkTics = 0
    end
    
    clkTics = clkTics + 1
end

-- Put initialization code here
function OnScriptLoad()
    -- We can set up our event callbacks, like the onTick callback
    register_callback(cb['EVENT_TICK'], "OnTick")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
end

-- Change biped tag =id from players and store their object ids
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    local tempTag = blam.getTag(tagId)
    if (tempTag and tempTag.class == blam.tagClasses.biped and playerIndex == 0) then
        listAi[#listAi + 1] = objectId
        print("playerIndex: " .. playerIndex)
        print("tagPath: " .. tempTag.path)
        print("objectId: " .. objectId)
    end
    return true
end

-- Put cleanup code here
function OnScriptUnload()
end

-- This function is not mandatory, but if you want to log errors, use this
function OnError(Message)
    rprint("Updating changes on Dev map...")
    execute_script("reload")
end
