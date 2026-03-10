-- ZoneTypes.lua
-- Zone type definitions and color configurations

local ZoneTypes = {}

-- Zone Type Enum
ZoneTypes.Type = {
	SAFE = "Safe",
	BLUE = "Blue",
	GREEN = "Green",
	RED = "Red",
}

-- Zone Colors (for floor/walls)
ZoneTypes.Colors = {
	[ZoneTypes.Type.SAFE] = Color3.fromRGB(200, 200, 200), -- Light gray (neutral safe zone)
	[ZoneTypes.Type.BLUE] = Color3.fromRGB(100, 150, 255),
	[ZoneTypes.Type.GREEN] = Color3.fromRGB(100, 255, 150),
	[ZoneTypes.Type.RED] = Color3.fromRGB(255, 100, 100),
}

-- Required Aura for access (nil = no requirement)
-- SAFE zones have no entry in this table → no aura needed
ZoneTypes.RequiredAura = {
	[ZoneTypes.Type.BLUE] = "BlueAura", -- Requires Blue Aura
	[ZoneTypes.Type.GREEN] = "GreenAura", -- Requires Green Aura
	[ZoneTypes.Type.RED] = "RedAura", -- Requires Red Aura
}

-- Tier levels (for distance-based generation)
ZoneTypes.Tier = {
	[ZoneTypes.Type.SAFE] = 0,
	[ZoneTypes.Type.BLUE] = 1,
	[ZoneTypes.Type.GREEN] = 2,
	[ZoneTypes.Type.RED] = 3,
}

-- Door Types
ZoneTypes.DoorType = {
	NORMAL = "Normal", -- Requires aura to pass
	ESCAPE = "Escape", -- Always open, one-way back to lower tier
	ALTERNATE = "Alternate", -- Always open, two-way alternative path
}

-- Door Colors
ZoneTypes.DoorColors = {
	[ZoneTypes.DoorType.NORMAL] = nil, -- Use zone color
	[ZoneTypes.DoorType.ESCAPE] = Color3.fromRGB(100, 255, 100), -- Bright green
	[ZoneTypes.DoorType.ALTERNATE] = Color3.fromRGB(255, 255, 100), -- Yellow
}

return ZoneTypes
