-- Zone configuration for rectangular grid map
local ZoneConfig = {}

-- Zone colors and access
ZoneConfig.ZoneTypes = {
	Green = {
		Color = Color3.fromRGB(34, 139, 34),
		Name = "Green Zone",
		RequiredAura = "Common",
		OrbConfig = {
			OrbsPerZone = 3,
			LuminValue = 10,
			RespawnTime = 5,
			Color = Color3.fromRGB(100, 255, 100)
		}
	},
	Blue = {
		Color = Color3.fromRGB(30, 144, 255),
		Name = "Blue Zone",
		RequiredAura = "Rare",
		OrbConfig = {
			OrbsPerZone = 2,
			LuminValue = 25,
			RespawnTime = 8,
			Color = Color3.fromRGB(100, 100, 255)
		}
	},
	Red = {
		Color = Color3.fromRGB(220, 20, 60),
		Name = "Red Zone",
		RequiredAura = "Legendary",
		OrbConfig = {
			OrbsPerZone = 1,
			LuminValue = 50,
			RespawnTime = 12,
			Color = Color3.fromRGB(255, 100, 100)
		}
	}
}

-- Aura tiers (по ред на мощност)
ZoneConfig.AuraTiers = {
	"Common",
	"Rare",
	"Legendary"
}

-- Проверка дали aura дава достъп до зона
function ZoneConfig.HasAccess(equippedAura, zoneType)
	if not equippedAura or not zoneType then
		return false
	end
	
	local requiredAura = ZoneConfig.ZoneTypes[zoneType].RequiredAura
	local equippedTier = table.find(ZoneConfig.AuraTiers, equippedAura)
	local requiredTier = table.find(ZoneConfig.AuraTiers, requiredAura)
	
	if not equippedTier or not requiredTier then
		return false
	end
	
	return equippedTier >= requiredTier
end

return ZoneConfig
