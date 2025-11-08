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

