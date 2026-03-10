-- GameConfig.lua
-- Centralized game configuration constants

local GameConfig = {}

-- Map Settings
GameConfig.HEX_RADIUS = 6 -- Hex board radius (3*R^2 + 3*R + 1)
GameConfig.ZONE_SIZE = 40 -- Size of each zone in studs

-- Zone Distribution (must sum to 100)
GameConfig.BLUE_ZONE_PERCENT = 45 -- 45 zones
GameConfig.GREEN_ZONE_PERCENT = 30 -- 30 zones
GameConfig.RED_ZONE_PERCENT = 25 -- 25 zones

-- Orb Respawn Times (in seconds)
GameConfig.BLUE_ORB_RESPAWN_MIN = 15
GameConfig.BLUE_ORB_RESPAWN_MAX = 30
GameConfig.GREEN_ORB_RESPAWN = 60
GameConfig.RED_ORB_RESPAWN = 120

-- Orb Values (in Lumens)
GameConfig.BLUE_ORB_VALUE = 1
GameConfig.GREEN_ORB_VALUE = 5
GameConfig.RED_ORB_VALUE = 10

-- Orb Spawn Frequency (percentage)
GameConfig.BLUE_ORB_FREQUENCY = 60
GameConfig.GREEN_ORB_FREQUENCY = 30
GameConfig.RED_ORB_FREQUENCY = 10

-- Aura Costs (in Lumens)
GameConfig.BLUE_AURA_COST = 10
GameConfig.GREEN_AURA_COST = 50
GameConfig.RED_AURA_COST = 100

-- Starting Zone
GameConfig.STARTING_LUMENS = 100 -- Players start with 100 lumens (TESTING - REMOVE LATER)

-- DataStore Settings
GameConfig.DATASTORE_NAME = "AuraMazePlayerData"
GameConfig.AUTO_SAVE_INTERVAL = 180 -- Auto-save every 3 minutes

-- Maze Generation
GameConfig.LOOP_PERCENTAGE = 15 -- Add 15% extra connections to create loops

return GameConfig
