local engine = Engine

local constants = {
    -- Distance at which an AI will be synced to a player
    syncDistance = 80,
    -- Sync custom messages every 33ms
    syncEveryMillisecs = 33,
    -- Bounding used to determine if a player is looking close enough to an AI to sync
    syncBoundingRadius = 0.75,
    -- Prevent player network messages from being flooded by custom messages
    startSyncingAfterMillisecs = 2500,
    maximumSyncInterval = 167, -- Maximum time between syncs (5 ticks delay at 33ms),
    firstPlayerIndex = 0,
    lastPlayerIndex = 15,
    maxItemDistanceRespawn = 10, -- Distance at which items will respawn in world units
    removeItemsTicksThreshold = 900,
    maximumNetworkItems = 180 -- Maximum number of network objects before we start preventing item respawns to avoid hitting the network object limit
}

if engine.netgame.getServerType() == "sapp" then
    constants.firstPlayerIndex = 1
    constants.lastPlayerIndex = 16
end

return constants
