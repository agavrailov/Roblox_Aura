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
	luminTextLabel.Size = UDim2.new(0.25, 0, 0.08, 0) -- Larger size
	luminTextLabel.Position = UDim2.new(0.74, 0, 0.91, 0) -- Bottom-right corner (with some padding)
	luminTextLabel.AnchorPoint = Vector2.new(1, 1) -- Anchor to bottom-right for easier positioning
	luminTextLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Darker background
	luminTextLabel.BackgroundTransparency = 0.6
	luminTextLabel.TextColor3 = Color3.fromRGB(255, 140, 0) -- Orange text
	luminTextLabel.TextScaled = true
	luminTextLabel.Font = Enum.Font.SourceSansBold
	luminTextLabel.Text = "Lumin: 0"
	luminTextLabel.TextXAlignment = Enum.TextXAlignment.Right -- Right-aligned text
	luminTextLabel.TextYAlignment = Enum.TextYAlignment.Center
	luminTextLabel.BorderSizePixel = 0
	luminTextLabel.Parent = screenGui

	return screenGui, luminTextLabel
end

return LuminDisplay
