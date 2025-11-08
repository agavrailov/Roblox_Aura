--!strict
-- OrbManager.server.lua
-- Manages the spawning and collection of all orbs in the game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Orb = require(ReplicatedStorage.Orb)
local PlayerData = require(ReplicatedStorage.PlayerData)

print("OrbManager Server Script Loaded")

-- Spawn some initial orbs
local orb1 = Orb.new(Vector3.new(0, 3, -10), 10)
local orb2 = Orb.new(Vector3.new(10, 3, -10), 10)
local orb3 = Orb.new(Vector3.new(-10, 3, -10), 10)

-- Handle orb collection
workspace.Touched:Connect(function(hitPart, otherPart)
	-- Check if the part that was hit has an Orb module attached
	local orbModule = hitPart:GetAttribute("OrbModule")
	if not orbModule then
		return
	end

	-- Check if it was a player who touched it
	local player = Players:GetPlayerFromCharacter(otherPart.Parent)
	if not player then
		return
	end

	-- Try to collect the orb
	local luminAmount = orbModule:collect()
	if luminAmount then
		-- If collection was successful, add lumin to the player's data
		PlayerData.addLumin(player, luminAmount)
		print(player.Name .. " now has " .. PlayerData.get(player, "Lumin") .. " Lumin.")
	end
end)
