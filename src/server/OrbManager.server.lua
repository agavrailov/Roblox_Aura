--!strict
-- OrbManager.server.lua
-- Manages the spawning and collection of all orbs in the game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Orb = require(ReplicatedStorage.Orb)
local PlayerData = require(ReplicatedStorage.PlayerData)
local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")

print("OrbManager Server Script Loaded")

-- Table to map Part instances to their Orb objects
local activeOrbs = {}

-- Function to spawn an orb and add it to our map
local function spawnOrb(position: Vector3, luminAmount: number)
	local orbObject, orbPart = Orb.new(position, luminAmount)
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

-- Spawn some initial orbs
spawnOrb(Vector3.new(0, 3, -10), 10)
spawnOrb(Vector3.new(10, 3, -10), 10)
spawnOrb(Vector3.new(-10, 3, -10), 10)

