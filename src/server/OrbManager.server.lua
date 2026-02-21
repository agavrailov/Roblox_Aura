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
local function spawnOrb(position: Vector3, orbName: string, luminAmount: number, respawnTime: number, orbColor: Color3)
	local orbObject, orbPart = Orb.new(position, luminAmount, respawnTime)
	
	-- Set orb color
	if orbPart then
		orbPart.Color = orbColor
	end
	
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
		local collectedLumin = orbModule:collect()
		if collectedLumin then
			-- If collection was successful, add lumin to the player's data
			PlayerData.addLumin(player, collectedLumin)
			local newLumin = PlayerData.get(player, "Lumin")
			print(player.Name .. " collected " .. collectedLumin .. " Lumin. Total: " .. newLumin)
			UpdateLuminEvent:FireClient(player, newLumin) -- Update client UI
		end
	end)
end

-- Get zones from Server (shared via _G for simplicity)
_G.OrbManagerSpawnOrbs = function(zones)
	local orbsSpawned = 0
	
	for _, zone in ipairs(zones) do
		local zoneTypeData = ZoneConfig.ZoneTypes[zone.Type]
		
		if zoneTypeData and zoneTypeData.OrbConfig then
			local orbConfig = zoneTypeData.OrbConfig
			local zoneCenter = zone.Position
			
			-- Spawn multiple orbs per zone
			for i = 1, orbConfig.OrbsPerZone do
				-- Random position within zone (square area)
				local randomX = (math.random() - 0.5) * 80 -- Within 80% of zone size
				local randomZ = (math.random() - 0.5) * 80
				local orbPos = zoneCenter + Vector3.new(
					randomX,
					5, -- Height above ground
					randomZ
				)
				
				spawnOrb(
					orbPos,
					zone.Type .. "Orb_" .. zone.GridX .. "_" .. zone.GridZ .. "_" .. i,
					orbConfig.LuminValue,
					orbConfig.RespawnTime,
					orbConfig.Color
				)
				orbsSpawned += 1
			end
		end
	end
	
	print("OrbManager: Spawned " .. orbsSpawned .. " orbs across " .. #zones .. " zones")
end


