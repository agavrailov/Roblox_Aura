-- Server.server.lua
-- Main server script for Aura Collector Simulator

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerData = require(ReplicatedStorage.PlayerData)
local AuraManager = require(game.ServerScriptService.AuraManager)
local MapGenerator = require(game.ServerScriptService.MapGenerator)
local ZoneAccess = require(game.ServerScriptService.ZoneAccess)
local ZoneBarrier = require(game.ServerScriptService.ZoneBarrier)
local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")
local EquipAuraEvent = ReplicatedStorage:WaitForChild("EquipAura")
local GetEquippedAuraFunction = ReplicatedStorage:WaitForChild("GetEquippedAura") -- New RemoteFunction
local CraftAuraEvent = ReplicatedStorage:WaitForChild("CraftAura") -- New RemoteEvent for crafting

print("Aura Collector Simulator Server Script Loaded")

-- Generate rectangular map
local zones, mapFolder = MapGenerator.Generate(workspace)
print("Server: Generated " .. #zones .. " zones")

-- Spawn orbs in zones
task.wait(0.5) -- Give OrbManager time to load
if _G.OrbManagerSpawnOrbs then
	_G.OrbManagerSpawnOrbs(zones)
else
	warn("OrbManager not loaded yet")
end

-- Setup zone access barriers
ZoneBarrier.Setup(zones)

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
	
	-- Spawn player at accessible perimeter zone
	local accessibleZones = ZoneAccess.GetAccessiblePerimeterZones(player, zones)
	if #accessibleZones > 0 then
		local spawnZone = accessibleZones[math.random(1, #accessibleZones)]
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		humanoidRootPart.CFrame = CFrame.new(spawnZone.Position + Vector3.new(0, 10, 0))
		print("Spawned " .. player.Name .. " at " .. spawnZone.Type .. " zone")
	else
		warn("No accessible zones for " .. player.Name)
	end
end)

-- Handle client requests to craft an aura
CraftAuraEvent.OnServerEvent:Connect(function(player: Player, auraName: string)
	local success, newLumin = AuraManager.craftAura(player, auraName)
	if success then
		UpdateLuminEvent:FireClient(player, newLumin)
		AuraManager.sendAuraDataToClient(player) -- Send updated owned auras
	else
		-- Optionally, send a message to the client that crafting failed (e.g., not enough lumin)
		warn(player.Name .. " failed to craft " .. auraName)
	end
end)

EquipAuraEvent.OnServerEvent:Connect(function(player: Player, auraName: string)
	-- The actual equipping logic is in AuraManager, but we need to update the collision group here
	local equippedAura = PlayerData.getEquippedAura(player)
	if equippedAura ~= auraName then
		-- This is a request to change aura
		PlayerData.setEquippedAura(player, auraName)
		AuraManager.sendAuraDataToClient(player) -- Update client UI
	end
end)

