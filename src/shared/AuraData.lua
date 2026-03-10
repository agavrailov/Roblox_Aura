-- AuraData.lua
-- Aura definitions and properties

local GameConfig = require(script.Parent.GameConfig)

local AuraData = {}

-- Aura definitions
AuraData.Auras = {
	BlueAura = {
		Name = "Blue Aura",
		Cost = GameConfig.BLUE_AURA_COST,
		Color = Color3.fromRGB(100, 150, 255),
		Description = "Allows passage through Blue doors",
		Tier = 1,
	},
	GreenAura = {
		Name = "Green Aura",
		Cost = GameConfig.GREEN_AURA_COST,
		Color = Color3.fromRGB(100, 255, 150),
		Description = "Allows passage through Green doors",
		Tier = 2,
	},
	RedAura = {
		Name = "Red Aura",
		Cost = GameConfig.RED_AURA_COST,
		Color = Color3.fromRGB(255, 100, 100),
		Description = "Allows passage through Red doors",
		Tier = 3,
	},
}

-- Helper function to get aura by name
function AuraData.GetAura(auraName)
	return AuraData.Auras[auraName]
end

-- Get all aura names
function AuraData.GetAllAuraNames()
	local names = {}
	for name, _ in pairs(AuraData.Auras) do
		table.insert(names, name)
	end
	return names
end

return AuraData
