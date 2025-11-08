--!strict
-- LuminDisplay.lua
-- Module to create and manage the Lumin display UI.

local LuminDisplay = {}

function LuminDisplay.new()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LuminDisplayGui"
	screenGui.ResetOnSpawn = false -- Keep UI on respawn

	local luminTextLabel = Instance.new("TextLabel")
	luminTextLabel.Name = "LuminTextLabel"
	luminTextLabel.Size = UDim2.new(0.2, 0, 0.05, 0) -- 20% width, 5% height
	luminTextLabel.Position = UDim2.new(0.01, 0, 0.01, 0) -- Top-left corner
	luminTextLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	luminTextLabel.BackgroundTransparency = 0.5
	luminTextLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow text
	luminTextLabel.TextScaled = true
	luminTextLabel.Font = Enum.Font.SourceSansBold
	luminTextLabel.Text = "Lumin: 0"
	luminTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	luminTextLabel.TextYAlignment = Enum.TextYAlignment.Center
	luminTextLabel.BorderSizePixel = 0
	luminTextLabel.Parent = screenGui

	return screenGui, luminTextLabel
end

return LuminDisplay
