--!strict
-- ZoneConfig.lua
-- Defines all zones in the game and their properties.

local ZoneConfig = {}

ZoneConfig.Zones = {
	["Starting Zone"] = {
		Name = "Starting Zone",
		RequiredAura = nil, -- No aura required for the starting zone
		OrbTypes = {
			{Name = "Basic Orb", LuminValue = 1, RespawnTime = 5},
		},
		SpawnPoints = {
			Vector3.new(0, 3, -10),
			Vector3.new(10, 3, -10),
			Vector3.new(-10, 3, -10),
		},
	},

	["Forest Zone"] = {
		Name = "Forest Zone",
		RequiredAura = "Green Aura", -- Requires Green Aura to enter
		OrbTypes = {
			{Name = "Forest Orb", LuminValue = 5, RespawnTime = 7},
		},
		SpawnPoints = {
			Vector3.new(40, 3, -10),
			Vector3.new(50, 3, -10),
			Vector3.new(60, 3, -10),
		},
	},

	-- Add more zones as needed
}

return ZoneConfig
