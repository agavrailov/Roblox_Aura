-- GameConfig.lua
-- Centralized game configuration constants

local GameConfig = {}

-- Map Settings
GameConfig.HEX_RADIUS = 7 -- Hex board radius (3*R^2 + 3*R + 1)
GameConfig.ZONE_SIZE = 30 -- Size of each zone in studs

-- Zone Distribution (must sum to 100)
GameConfig.BLUE_ZONE_PERCENT = 1 
GameConfig.GREEN_ZONE_PERCENT = 40
GameConfig.RED_ZONE_PERCENT = 30

-- Orb Respawn Times (in seconds)
GameConfig.BLUE_ORB_RESPAWN_MIN = 15
GameConfig.BLUE_ORB_RESPAWN_MAX = 30
GameConfig.GREEN_ORB_RESPAWN = 60
GameConfig.RED_ORB_RESPAWN = 120

-- Orb Values (in Lumens)
GameConfig.BLUE_ORB_VALUE = 2
GameConfig.GREEN_ORB_VALUE = 7
GameConfig.RED_ORB_VALUE = 12

-- Orb Spawn Frequency (percentage)
GameConfig.BLUE_ORB_FREQUENCY = 50
GameConfig.GREEN_ORB_FREQUENCY = 35
GameConfig.RED_ORB_FREQUENCY = 15

-- Aura Costs (in Lumens)
GameConfig.BLUE_AURA_COST = 10
GameConfig.GREEN_AURA_COST = 50
GameConfig.RED_AURA_COST = 100

-- Starting Zone
GameConfig.STARTING_LUMENS = 100 -- Players start with 100 lumens (TESTING - REMOVE LATER)

-- DataStore Settings
GameConfig.DATASTORE_NAME = "AuraMazePlayerData"
GameConfig.AUTO_SAVE_INTERVAL = 180 -- Auto-save every 3 minutes

-- Camera Settings
GameConfig.MAX_ZOOM = 30-- Max camera zoom distance in studs (limits how far out player can zoom)

-- Maze Generation
GameConfig.LOOP_PERCENTAGE = 15 -- Add 15% extra connections to create loops

return GameConfig
