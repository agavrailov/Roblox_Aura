-- Client.client.lua
-- Main client script for Aura Collector Simulator

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LuminDisplay = require(script.Parent.UI.LuminDisplay)
local AuraVisuals = require(script.Parent.AuraVisuals) -- New module
local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")
local EquipAuraEvent = ReplicatedStorage:WaitForChild("EquipAura") -- New RemoteEvent

print("Aura Collector Simulator Client Script Loaded")

local player = Players.LocalPlayer
local currentAuraEffect = nil -- To keep track of the currently displayed aura effect

print("Client script running for " .. player.Name)

-- Create and set up the Lumin display UI
local luminGui, luminTextLabel = LuminDisplay.new()
luminGui.Parent = player.PlayerGui

-- Function to update the Lumin display
local function updateLuminDisplay(newAmount: number)
	luminTextLabel.Text = "Lumin: " .. newAmount
end

-- Function to update the visual aura
local function updateAuraVisual(auraName: string?)
	if currentAuraEffect then
		currentAuraEffect:Destroy()
		currentAuraEffect = nil
	end

	if auraName and player.Character then
		currentAuraEffect = AuraVisuals.create(auraName, player.Character)
	end
end

-- Listen for Lumin updates from the server
UpdateLuminEvent.OnClientEvent:Connect(updateLuminDisplay)

-- Listen for equipped aura updates from the server
EquipAuraEvent.OnClientEvent:Connect(updateAuraVisual)

-- Handle character changes (e.g., respawn)
local function onCharacterAdded(character)
	-- Wait a moment for the character to be fully set up
	task.wait(1)
	-- Re-apply the current aura visual if one is equipped
	local equippedAura = EquipAuraEvent:InvokeServer() -- This won't work, need to get from server
	-- For now, we'll rely on the server sending the equipped aura on player join/respawn
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

