clua_version = 2.056

local blam = require "blam"
objectClasses = blam.objectClasses

function OnTick()
    local player = blam.biped(get_dynamic_player())
    if (player) then
        --console_out("P: " .. player.x .. " " .. player.y .. " " .. player.z)
    end
    -- Add filter for objects that are being synced from the server
    for _, objectIndex in pairs(blam.getObjects()) do
        local tempObject = blam.object(get_object(objectIndex))
        if (tempObject and tempObject.type == objectClasses.biped and
            blam.isNull(tempObject.playerId)) then
            tempObject.x = 0
            tempObject.y = 0
            tempObject.z = 0
            tempObject.zVel = 0
        end
    end
end

function OnRcon(message)
    console_out(message)
    return false
end

set_callback("tick", "OnTick")
set_callback("rcon message", "OnRcon")
