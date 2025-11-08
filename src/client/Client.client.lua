-- Client.client.lua
-- Main client script for Aura Collector Simulator

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LuminDisplay = require(script.Parent.UI.LuminDisplay)
local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")

print("Aura Collector Simulator Client Script Loaded")

local player = Players.LocalPlayer

print("Client script running for " .. player.Name)

-- Create and set up the Lumin display UI
local luminGui, luminTextLabel = LuminDisplay.new()
luminGui.Parent = player.PlayerGui

-- Function to update the Lumin display
local function updateLuminDisplay(newAmount: number)
	luminTextLabel.Text = "Lumin: " .. newAmount
end

-- Listen for Lumin updates from the server
UpdateLuminEvent.OnClientEvent:Connect(updateLuminDisplay)

-- ############ TEMPORARY TEST FOR AURA VISUALS ############
local AuraVisuals = require(script.Parent.AuraVisuals)

local function onCharacterAdded(character)
	-- Wait a moment for the character to be fully set up
	task.wait(1)
	print("Character added, attaching test aura...")
	AuraVisuals.create("Basic Aura", character)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
-- #########################################################

