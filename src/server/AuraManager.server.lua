--!strict
-- AuraManager.server.lua
-- Manages the crafting and equipping of auras.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.PlayerData)
local AuraConfig = require(ReplicatedStorage.AuraConfig)
local CraftAuraEvent = ReplicatedStorage:WaitForChild("CraftAura")
local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")

print("AuraManager Server Script Loaded")

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

	-- 3. Notify the client and log the success
	local newLumin = PlayerData.get(player, "Lumin")
	UpdateLuminEvent:FireClient(player, newLumin)

	print("Successfully crafted '" .. auraName .. "' for " .. player.Name .. ". New Lumin: " .. tostring(newLumin))
end

CraftAuraEvent.OnServerEvent:Connect(onCraftAura)
