-- Server.server.lua
-- Main server script for Aura Collector Simulator

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerData = require(ReplicatedStorage.PlayerData)
local AuraManager = require(game.ServerScriptService.AuraManager) -- Require AuraManager explicitly
local ZoneBarrier = require(game.ServerScriptService.ZoneBarrier) -- New: Require ZoneBarrier
local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")
local EquipAuraEvent = ReplicatedStorage:WaitForChild("EquipAura")
local GetEquippedAuraFunction = ReplicatedStorage:WaitForChild("GetEquippedAura") -- New RemoteFunction

print("Aura Collector Simulator Server Script Loaded")

-- Handle client requests for equipped aura
GetEquippedAuraFunction.OnServerInvoke = function(player: Player): string?
	return PlayerData.getEquippedAura(player)
end

-- Send initial Lumin and Equipped Aura to player when they join
Players.PlayerAdded:Connect(function(player)
	PlayerData.load(player) -- Ensure data is loaded before sending
	local initialLumin = PlayerData.get(player, "Lumin")
	UpdateLuminEvent:FireClient(player, initialLumin)

	-- Now send the full aura data to the client
	AuraManager.sendAuraDataToClient(player)

	-- Also send the initial equipped aura to the client for visual display
	local equippedAura = PlayerData.getEquippedAura(player)
	EquipAuraEvent:FireClient(player, equippedAura)
end)

-- Initialize Zone Barriers
local forestBarrierPart = workspace:FindFirstChild("ForestBarrier")
if forestBarrierPart then
	ZoneBarrier.new(forestBarrierPart, "Forest Zone")
	print("Forest Zone barrier initialized.")
else
	warn("ForestBarrier part not found in Workspace. Zone access not fully functional.")
end

