--!strict
-- AuraInventoryGui.lua
-- Module to create and manage the Aura Inventory UI.

local AuraInventoryGui = {}

function AuraInventoryGui.new()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AuraInventoryGui"
	screenGui.ResetOnSpawn = false

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
	mainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Draggable = true
	mainFrame.Visible = false -- Hidden by default
	mainFrame.Parent = screenGui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 24
	titleLabel.Text = "Aura Inventory"
	titleLabel.Parent = mainFrame

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0.1, 0, 0.1, 0)
	closeButton.Position = UDim2.new(0.9, 0, 0, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.TextSize = 20
	closeButton.Text = "X"
	closeButton.Parent = mainFrame

	local auraListScrollingFrame = Instance.new("ScrollingFrame")
	auraListScrollingFrame.Name = "AuraList"
	auraListScrollingFrame.Size = UDim2.new(1, 0, 0.9, 0)
	auraListScrollingFrame.Position = UDim2.new(0, 0, 0.1, 0)
	auraListScrollingFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	auraListScrollingFrame.BorderSizePixel = 0
	auraListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
	auraListScrollingFrame.ScrollBarThickness = 8
	auraListScrollingFrame.Parent = mainFrame

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "AuraListLayout"
	uIListLayout.FillDirection = Enum.FillDirection.Vertical
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.Parent = auraListScrollingFrame

	return screenGui, mainFrame, auraListScrollingFrame, closeButton
end

-- Function to create a single aura item in the list
function AuraInventoryGui.createAuraItem(auraName: string, isEquipped: boolean, onEquipClicked: (auraName: string) -> ())
	local auraItemFrame = Instance.new("Frame")
	auraItemFrame.Name = auraName .. "Item"
	auraItemFrame.Size = UDim2.new(0.95, 0, 0, 60) -- Fixed height
	auraItemFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	auraItemFrame.BorderSizePixel = 0

	local auraNameLabel = Instance.new("TextLabel")
	auraNameLabel.Name = "AuraNameLabel"
	auraNameLabel.Size = UDim2.new(0.7, 0, 1, 0)
	auraNameLabel.Position = UDim2.new(0.02, 0, 0, 0)
	auraNameLabel.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	auraNameLabel.BackgroundTransparency = 1
	auraNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	auraNameLabel.Font = Enum.Font.SourceSansBold
	auraNameLabel.TextSize = 18
	auraNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	auraNameLabel.Text = auraName
	auraNameLabel.Parent = auraItemFrame

	local equipButton = Instance.new("TextButton")
	equipButton.Name = "EquipButton"
	equipButton.Size = UDim2.new(0.25, 0, 0.8, 0)
	equipButton.Position = UDim2.new(0.73, 0, 0.1, 0)
	equipButton.BackgroundColor3 = if isEquipped then Color3.fromRGB(50, 150, 50) else Color3.fromRGB(50, 100, 150)
	equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	equipButton.Font = Enum.Font.SourceSansBold
	equipButton.TextSize = 16
	equipButton.Text = if isEquipped then "Equipped" else "Equip"
	equipButton.Parent = auraItemFrame

	if not isEquipped then
		equipButton.MouseButton1Click:Connect(function()
			onEquipClicked(auraName)
		end)
	end

	return auraItemFrame, equipButton
end

return AuraInventoryGui
