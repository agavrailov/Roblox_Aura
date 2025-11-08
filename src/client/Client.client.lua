-- Client.client.lua
-- Main client script for Aura Collector Simulator

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LuminDisplay = require(script.Parent.UI.LuminDisplay)
local AuraVisuals = require(script.Parent.AuraVisuals)
local AuraInventoryGui = require(script.Parent.UI.AuraInventoryGui) -- New module

local UpdateLuminEvent = ReplicatedStorage:WaitForChild("UpdateLumin")
local EquipAuraEvent = ReplicatedStorage:WaitForChild("EquipAura")
local UpdateAurasEvent = ReplicatedStorage:WaitForChild("UpdateAuras") -- Get from ReplicatedStorage
local GetEquippedAuraFunction = ReplicatedStorage:WaitForChild("GetEquippedAura") -- New RemoteFunction

print("Aura Collector Simulator Client Script Loaded")

local player = Players.LocalPlayer
local currentAuraEffect = nil -- To keep track of the currently displayed aura effect

print("Client script running for " .. player.Name)

-- Create and set up the Lumin display UI
local luminGui, luminTextLabel = LuminDisplay.new()
luminGui.Parent = player.PlayerGui

-- Create and set up the Aura Inventory UI
local auraInventoryGui, auraInventoryMainFrame, auraListScrollingFrame, auraInventoryCloseButton = AuraInventoryGui.new()
auraInventoryGui.Parent = player.PlayerGui

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

-- Function to handle equipping an aura from the UI
local function onEquipAuraClicked(auraName: string)
	EquipAuraEvent:FireServer(auraName)
	auraInventoryMainFrame.Visible = false -- Close UI after equipping
end

-- Function to update the aura inventory display
local function updateAuraInventory(ownedAuras: {string}, equippedAura: string?)
	-- Clear existing items
	for _, child in ipairs(auraListScrollingFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add new items
	for _, auraName in ipairs(ownedAuras) do
		local isEquipped = (auraName == equippedAura)
		local auraItemFrame, equipButton = AuraInventoryGui.createAuraItem(auraName, isEquipped, onEquipAuraClicked)
		auraItemFrame.Parent = auraListScrollingFrame
	end

	-- Adjust CanvasSize
	local contentHeight = #ownedAuras * (60 + 5) -- 60 is item height, 5 is padding
	auraListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end

-- Listen for Lumin updates from the server
UpdateLuminEvent.OnClientEvent:Connect(updateLuminDisplay)

-- Listen for equipped aura updates from the server
EquipAuraEvent.OnClientEvent:Connect(updateAuraVisual)

-- Listen for owned auras updates from the server
UpdateAurasEvent.OnClientEvent:Connect(updateAuraInventory)

-- Toggle button for Aura Inventory
local toggleInventoryButton = Instance.new("TextButton")
toggleInventoryButton.Name = "ToggleInventoryButton"
toggleInventoryButton.Size = UDim2.new(0.1, 0, 0.05, 0)
toggleInventoryButton.Position = UDim2.new(0.89, 0, 0.01, 0) -- Top-right corner
toggleInventoryButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleInventoryButton.BackgroundTransparency = 0.5
toggleInventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleInventoryButton.Font = Enum.Font.SourceSansBold
toggleInventoryButton.TextSize = 18
toggleInventoryButton.Text = "Auras"
toggleInventoryButton.Parent = luminGui -- Parent to luminGui for convenience

toggleInventoryButton.MouseButton1Click:Connect(function()
	auraInventoryMainFrame.Visible = not auraInventoryMainFrame.Visible
end)

auraInventoryCloseButton.MouseButton1Click:Connect(function()
	auraInventoryMainFrame.Visible = false
end)

-- Handle character changes (e.g., respawn)
local function onCharacterAdded(character)
	-- Wait a moment for the character to be fully set up
	task.wait(1)
	-- Request equipped aura from server and display it
	local equippedAura = GetEquippedAuraFunction:InvokeServer()
	updateAuraVisual(equippedAura)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

