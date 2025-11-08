--!strict
-- AuraManager.server.lua
-- Manages the crafting and equipping of auras.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players") -- Need Players service here

local PlayerData = require(ReplicatedStorage.PlayerData)
local AuraConfig = require(ReplicatedStorage.AuraConfig)
local CraftAuraEvent = ReplicatedStorage:WaitForChild("CraftAura")
local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")
local EquipAuraEvent = ReplicatedStorage:WaitForChild("EquipAura")
local UpdateAurasEvent = ReplicatedStorage:WaitForChild("UpdateAuras") -- New RemoteEvent

print("AuraManager Server Script Loaded")

-- Helper function to send all relevant aura data to a client
local function sendAuraDataToClient(player: Player)
	local ownedAuras = PlayerData.get(player, "Auras")
	local equippedAura = PlayerData.getEquippedAura(player)
	UpdateAurasEvent:FireClient(player, ownedAuras, equippedAura)
end

local function onEquipAura(player: Player, auraName: string?)
	if auraName and not PlayerData.hasAura(player, auraName) then
		warn("Player " .. player.Name .. " tried to equip an aura they don't own: " .. tostring(auraName))
		return
	end
	PlayerData.setEquippedAura(player, auraName)
	EquipAuraEvent:FireClient(player, auraName) -- Notify client to update visual
	sendAuraDataToClient(player) -- Update inventory UI
	print("Player " .. player.Name .. " equipped: " .. tostring(auraName))
end

local function onCraftAura(player: Player, auraName: string)
	print("Player " .. player.Name .. " is attempting to craft '" .. auraName .. "'")

	-- 1. Validate the request
	local auraData = AuraConfig.Auras[auraName]
	if not auraData then
		warn("Player " .. player.Name .. " tried to craft a non-existent aura: " .. auraName)
		return
	end

	if PlayerData.hasAura(player, auraName) then
		warn("Player " .. player.Name .. " tried to craft an aura they already own: " .. auraName)
		return
	end

	local currentLumin = PlayerData.get(player, "Lumin")
	if currentLumin < auraData.Cost then
		warn("Player " .. player.Name .. " does not have enough Lumin to craft " .. auraName)
		return
	end

	-- 2. Process the request
	PlayerData.subtractLumin(player, auraData.Cost)
	PlayerData.addAura(player, auraName)
	PlayerData.setEquippedAura(player, auraName) -- Automatically equip newly crafted aura

	-- 3. Notify the client and log the success
	local newLumin = PlayerData.get(player, "Lumin")
	UpdateLuminEvent:FireClient(player, newLumin)
	EquipAuraEvent:FireClient(player, auraName) -- Notify client to update visual
	sendAuraDataToClient(player) -- Update inventory UI

	print("Successfully crafted '" .. auraName .. "' for " .. player.Name .. ". New Lumin: " .. tostring(newLumin))
end

CraftAuraEvent.OnServerEvent:Connect(onCraftAura)
EquipAuraEvent.OnServerEvent:Connect(onEquipAura)

-- When a player joins, send them their initial aura data
Players.PlayerAdded:Connect(function(player)
	sendAuraDataToClient(player)
end)
