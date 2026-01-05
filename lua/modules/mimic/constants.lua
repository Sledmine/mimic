return {
    -- Distance at which an AI will be synced to a player
    syncDistance = 80,
    -- Sync custom messages every 33ms
    syncEveryMillisecs = 33,
    -- Bounding used to determine if a player is looking close enough to an AI to sync
    syncBoundingRadius = 0.75,
    -- Prevent player network messages from being flooded by custom messages
    startSyncingAfterMillisecs = 2500,
    maximumSyncInterval = 165 -- Maximum time between syncs (5 ticks delay at 33ms)
}
