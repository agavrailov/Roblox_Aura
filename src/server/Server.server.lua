-- Server.server.lua
-- Main server script for Aura Collector Simulator

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerData = require(ReplicatedStorage.PlayerData)
-- local AuraManager = require(game.ServerScriptService.AuraManager) -- Require AuraManager explicitly
local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")
local EquipAuraEvent = ReplicatedStorage:WaitForChild("EquipAura")

print("Aura Collector Simulator Server Script Loaded")

-- Send initial Lumin and Equipped Aura to player when they join
Players.PlayerAdded:Connect(function(player)
	PlayerData.load(player) -- Ensure data is loaded before sending
	local initialLumin = PlayerData.get(player, "Lumin")
	UpdateLuminEvent:FireClient(player, initialLumin)

	-- Now send the full aura data to the client
	-- AuraManager.sendAuraDataToClient(player)
end)

