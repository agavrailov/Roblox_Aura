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
		-- Physical properties for map generation
		Size = Vector3.new(100, 1, 100),
		Position = Vector3.new(0, 0, 0),
		BarrierPosition = Vector3.new(25, 5, 0), -- Example position for barrier to Forest Zone
		BarrierSize = Vector3.new(5, 10, 1),
		FenceHeight = 15,
		FenceThickness = 1,
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
		-- Physical properties for map generation
		Size = Vector3.new(100, 1, 100),
		Position = Vector3.new(50, 0, 0),
		BarrierPosition = Vector3.new(75, 5, 0), -- Example position for barrier to next zone (if any)
		BarrierSize = Vector3.new(5, 10, 1),
		FenceHeight = 15,
		FenceThickness = 1,
	},

	-- Add more zones as needed
}

return ZoneConfig
