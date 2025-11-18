-- Server.server.lua
-- Main server script for Aura Collector Simulator

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerData = require(ReplicatedStorage.PlayerData)
local AuraManager = require(game.ServerScriptService.AuraManager)
local ZoneGate = require(game.ServerScriptService.ZoneGate)
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
	local initialLumin = PlayerData.get(player, "Lumin") or 0
	UpdateLuminEvent:FireClient(player, initialLumin)

	-- Now send the full aura data to the client
	AuraManager.sendAuraDataToClient(player)

	-- Also send the initial equipped aura to the client for visual display
	local equippedAura = PlayerData.getEquippedAura(player)
	EquipAuraEvent:FireClient(player, equippedAura)
end)

35+Players.PlayerRemoving:Connect(function(player)
36+	PlayerData.save(player)
37+end)
38+
-- Initialize Zone Gates (trigger parts in front of visual walls)
local forestTrigger = workspace:FindFirstChild("ForestZoneTrigger")
if forestTrigger and forestTrigger:IsA("BasePart") then
	-- TODO: adjust target position to your actual Forest Zone spawn point
	local forestSpawn = Vector3.new(50, 3, -10)
	ZoneGate.new(forestTrigger, "Forest Zone", forestSpawn)
	print("Forest Zone gate initialized.")
else
	warn("ForestZoneTrigger part not found in Workspace. Zone access not fully functional.")
end

