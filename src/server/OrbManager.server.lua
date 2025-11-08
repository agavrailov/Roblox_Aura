--!strict
-- OrbManager.server.lua
-- Manages the spawning and collection of all orbs in the game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Orb = require(ReplicatedStorage.Orb)
local PlayerData = require(ReplicatedStorage.PlayerData)
local ZoneConfig = require(ReplicatedStorage.ZoneConfig) -- New: Require ZoneConfig
local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")

print("OrbManager Server Script Loaded")

-- Table to map Part instances to their Orb objects
local activeOrbs = {}

-- Function to spawn an orb and add it to our map
local function spawnOrb(position: Vector3, orbName: string, luminAmount: number, respawnTime: number)
	local orbObject, orbPart = Orb.new(position, luminAmount, respawnTime) -- Orb module needs to be updated to accept respawnTime
	activeOrbs[orbPart] = orbObject

	orbPart.Touched:Connect(function(otherPart)
		-- Check if it was a player who touched it
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if not player then
			return
		end

		-- Check if the touched part is a registered orb
		local orbModule = activeOrbs[orbPart]
		if not orbModule then
			return
		end

		-- Try to collect the orb
		local luminAmount = orbModule:collect()
		if luminAmount then
			-- If collection was successful, add lumin to the player's data
			PlayerData.addLumin(player, luminAmount)
			local newLumin = PlayerData.get(player, "Lumin")
			print(player.Name .. " now has " .. newLumin .. " Lumin.")
			UpdateLuminEvent:FireClient(player, newLumin) -- Update client UI
		end
	end)
end

-- Spawn orbs based on ZoneConfig
for zoneName, zoneData in pairs(ZoneConfig.Zones) do
	-- For now, use a single placeholder spawn point for each zone
	-- In a real game, these would be defined in ZoneConfig or dynamically generated
	local placeholderSpawnPoint = Vector3.new(0, 3, 0) -- Default for starting zone
	if zoneName == "Forest Zone" then
		placeholderSpawnPoint = Vector3.new(50, 3, 0) -- Placeholder for Forest Zone
	end
	-- Add more placeholder spawn points for other zones as needed

	for _, orbType in pairs(zoneData.OrbTypes) do
		-- Spawn multiple orbs of each type for demonstration
		for i = 1, 3 do -- Spawn 3 orbs of each type
			spawnOrb(placeholderSpawnPoint + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)), orbType.Name, orbType.LuminValue, orbType.RespawnTime)
		end
	end
end

