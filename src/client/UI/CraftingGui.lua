--!strict
-- CraftingGui.lua
-- Module to create and manage the Aura Crafting UI.

local CraftingGui = {}

function CraftingGui.new()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CraftingGui"
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
	titleLabel.Text = "Aura Crafting"
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

	-- Placeholder for crafting recipes or available auras to craft
	local craftingListScrollingFrame = Instance.new("ScrollingFrame")
	craftingListScrollingFrame.Name = "CraftingList"
	craftingListScrollingFrame.Size = UDim2.new(1, 0, 0.9, 0)
	craftingListScrollingFrame.Position = UDim2.new(0, 0, 0.1, 0)
	craftingListScrollingFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	craftingListScrollingFrame.BorderSizePixel = 0
	craftingListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated dynamically
	craftingListScrollingFrame.ScrollBarThickness = 8
	craftingListScrollingFrame.Parent = mainFrame

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "CraftingListLayout"
	uIListLayout.FillDirection = Enum.FillDirection.Vertical
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.Parent = craftingListScrollingFrame

	return screenGui, mainFrame, craftingListScrollingFrame, closeButton
end

-- Function to create a single crafting item in the list
function CraftingGui.createCraftingItem(auraName: string, cost: number, onCraftClicked: (auraName: string) -> ())
	local craftingItemFrame = Instance.new("Frame")
	craftingItemFrame.Name = auraName .. "CraftItem"
	craftingItemFrame.Size = UDim2.new(0.95, 0, 0, 60) -- Fixed height
	craftingItemFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	craftingItemFrame.BorderSizePixel = 0

	local auraNameLabel = Instance.new("TextLabel")
	auraNameLabel.Name = "AuraNameLabel"
	auraNameLabel.Size = UDim2.new(0.6, 0, 1, 0)
	auraNameLabel.Position = UDim2.new(0.02, 0, 0, 0)
	auraNameLabel.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	auraNameLabel.BackgroundTransparency = 1
	auraNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	auraNameLabel.Font = Enum.Font.SourceSansBold
	auraNameLabel.TextSize = 18
	auraNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	auraNameLabel.Text = auraName .. " (Cost: " .. cost .. " Lumin)"
	auraNameLabel.Parent = craftingItemFrame

	local craftButton = Instance.new("TextButton")
	craftButton.Name = "CraftButton"
	craftButton.Size = UDim2.new(0.3, 0, 0.8, 0)
	craftButton.Position = UDim2.new(0.68, 0, 0.1, 0)
	craftButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	craftButton.Font = Enum.Font.SourceSansBold
	craftButton.TextSize = 16
	craftButton.Text = "Craft"
	craftButton.Parent = craftingItemFrame

	craftButton.MouseButton1Click:Connect(function()
		onCraftClicked(auraName)
	end)

	return craftingItemFrame, craftButton
end

return CraftingGui
