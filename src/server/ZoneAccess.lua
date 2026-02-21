-- Zone access control based on equipped aura
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConfig = require(ReplicatedStorage.ZoneConfig)

local ZoneAccess = {}

-- Взима equipped aura на играча
function ZoneAccess.GetEquippedAura(player)
	-- TODO: Integration с aura system
	-- ТЕСТОВ РЕЖИМ: Връща Legendary за тестване
	return "Legendary"
	
	--[[ За production:
	local auraData = player:FindFirstChild("AuraData")
	if auraData then
		local equipped = auraData:FindFirstChild("Equipped")
		if equipped and equipped.Value then
			return equipped.Value
		end
	end
	return "Common" -- default
	--]]
end

-- Проверява дали играчът може да влезе в зона
function ZoneAccess.CanEnterZone(player, zoneType)
	local equippedAura = ZoneAccess.GetEquippedAura(player)
	return ZoneConfig.HasAccess(equippedAura, zoneType)
end

-- Намира достъпни perimeter zones за играч
function ZoneAccess.GetAccessiblePerimeterZones(player, allZones)
	local accessible = {}
	local equippedAura = ZoneAccess.GetEquippedAura(player)
	
	for _, zone in ipairs(allZones) do
		if zone.IsPerimeter and ZoneConfig.HasAccess(equippedAura, zone.Type) then
			table.insert(accessible, zone)
		end
	end
	
	return accessible
end

-- Блокира играч от зона (телепортира назад)
function ZoneAccess.BlockPlayer(player, reason)
	warn(player.Name .. " blocked from zone: " .. reason)
	-- TODO: Телепортира играча до последната валидна позиция
	-- TODO: Покажи UI message
end

return ZoneAccess
