--!strict
-- ZoneConfig.lua
-- Defines the configuration for the hexagonal zone map generation.

local ZoneConfig = {}

ZoneConfig.Map = {
	TotalZones = 100,
	HexagonSize = 50, -- The distance from the center to a vertex
	WallThickness = 2,
	WallHeight = 10,
}

return ZoneConfig
