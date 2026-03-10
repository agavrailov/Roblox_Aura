-- HUDManager.lua
-- Main HUD displaying Lumens, equipped aura, and craft button

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDManager = {}

local screenGui
local lumenLabel
local auraLabel
local craftButton

-- Create main HUD
function HUDManager.CreateHUD()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Lumen Counter (top left)
	local lumenFrame = Instance.new("Frame")
	lumenFrame.Name = "LumenFrame"
	lumenFrame.Size = UDim2.new(0, 200, 0, 60)
	lumenFrame.Position = UDim2.new(0, 10, 0, 10)
	lumenFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	lumenFrame.BackgroundTransparency = 0.3
	lumenFrame.BorderSizePixel = 0
	lumenFrame.Parent = screenGui
	
	local lumenIcon = Instance.new("TextLabel")
	lumenIcon.Name = "Icon"
	lumenIcon.Size = UDim2.new(0, 40, 1, 0)
	lumenIcon.Position = UDim2.new(0, 5, 0, 0)
	lumenIcon.BackgroundTransparency = 1
	lumenIcon.Text = "⚡"
	lumenIcon.TextSize = 30
	lumenIcon.TextColor3 = Color3.fromRGB(255, 255, 100)
	lumenIcon.Font = Enum.Font.GothamBold
	lumenIcon.Parent = lumenFrame
	
	lumenLabel = Instance.new("TextLabel")
	lumenLabel.Name = "Amount"
	lumenLabel.Size = UDim2.new(1, -50, 1, 0)
	lumenLabel.Position = UDim2.new(0, 50, 0, 0)
	lumenLabel.BackgroundTransparency = 1
	lumenLabel.Text = "0"
	lumenLabel.TextSize = 24
	lumenLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	lumenLabel.Font = Enum.Font.GothamBold
	lumenLabel.TextXAlignment = Enum.TextXAlignment.Left
	lumenLabel.Parent = lumenFrame
	
	-- Current Aura Display (top left, below lumens)
	local auraFrame = Instance.new("Frame")
	auraFrame.Name = "AuraFrame"
	auraFrame.Size = UDim2.new(0, 200, 0, 50)
	auraFrame.Position = UDim2.new(0, 10, 0, 80)
	auraFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	auraFrame.BackgroundTransparency = 0.3
	auraFrame.BorderSizePixel = 0
	auraFrame.Parent = screenGui
	
	auraLabel = Instance.new("TextLabel")
	auraLabel.Name = "AuraName"
	auraLabel.Size = UDim2.new(1, -10, 1, 0)
	auraLabel.Position = UDim2.new(0, 5, 0, 0)
	auraLabel.BackgroundTransparency = 1
	auraLabel.Text = "No Aura"
	auraLabel.TextSize = 18
	auraLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	auraLabel.Font = Enum.Font.Gotham
	auraLabel.TextXAlignment = Enum.TextXAlignment.Left
	auraLabel.Parent = auraFrame
	
	-- Craft Button (top right)
	craftButton = Instance.new("TextButton")
	craftButton.Name = "CraftButton"
	craftButton.Size = UDim2.new(0, 150, 0, 50)
	craftButton.Position = UDim2.new(1, -160, 0, 10)
	craftButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	craftButton.Text = "CRAFT AURAS"
	craftButton.TextSize = 18
	craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	craftButton.Font = Enum.Font.GothamBold
	craftButton.Parent = screenGui
	
	print("[HUDManager] HUD created")
end

-- Update lumen display
function HUDManager.UpdateLumens(amount)
	if lumenLabel then
		lumenLabel.Text = tostring(amount)
	end
end

-- Update equipped aura display
function HUDManager.UpdateEquippedAura(auraName)
	if auraLabel then
		if auraName then
			local AuraData = require(game.ReplicatedStorage.AuraData)
			local aura = AuraData.GetAura(auraName)
			if aura then
				auraLabel.Text = aura.Name
				auraLabel.TextColor3 = aura.Color
			end
		else
			auraLabel.Text = "No Aura"
			auraLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end
end

-- Get craft button for event binding
function HUDManager.GetCraftButton()
	return craftButton
end

return HUDManager
