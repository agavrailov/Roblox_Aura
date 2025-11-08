--!strict
-- ZoneManager.server.lua
-- Manages zone access logic and player interaction with zones.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ZoneConfig = require(ReplicatedStorage.ZoneConfig)
local PlayerData = require(ReplicatedStorage.PlayerData)

print("ZoneManager Server Script Loaded")

local ZoneManager = {}

-- Function to check if a player can enter a specific zone
function ZoneManager.canEnterZone(player: Player, zoneName: string): (boolean, string?)
	local zoneData = ZoneConfig.Zones[zoneName]
	if not zoneData then
		return false, "Zone does not exist."
	end

	if not zoneData.RequiredAura then
		return true, nil -- No aura required, access granted
	end

	local equippedAura = PlayerData.getEquippedAura(player)
	if equippedAura == zoneData.RequiredAura then
		return true, nil
	else
		return false, "Requires " .. zoneData.RequiredAura .. " to enter this zone."
	end
end

-- For now, a simple placeholder for zone entry detection
-- In a real game, this would involve actual zone parts and touch events
Players.PlayerAdded:Connect(function(player)
	print(player.Name .. " entered the Starting Zone.")
	-- Later: check for zone changes and apply access logic
end)

return ZoneManager
