-- RelicTracker.lua
-- Compact bottom-left UI showing 3 Prismatic Key collection status

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RelicTracker = {}

local trackerGui
local relicSlots = {} -- {Blue = frame, Green = frame, Red = frame}

local RelicColors = {
	Blue = Color3.fromRGB(100, 150, 255),
	Green = Color3.fromRGB(100, 255, 150),
	Red = Color3.fromRGB(255, 100, 100),
}

local RelicDimColors = {
	Blue = Color3.fromRGB(40, 55, 80),
	Green = Color3.fromRGB(40, 80, 55),
	Red = Color3.fromRGB(80, 40, 40),
}

-- Build a crystal-key icon from UI primitives
local function createKeyIcon(relicName, parent)
	local color = RelicDimColors[relicName]

	-- Icon container
	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, -14)
	icon.Position = UDim2.new(0, 0, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Parent = parent

	-- Diamond head (rotated square)
	local diamond = Instance.new("Frame")
	diamond.Name = "Diamond"
	diamond.Size = UDim2.new(0, 20, 0, 20)
	diamond.Position = UDim2.new(0.5, -10, 0.3, -10)
	diamond.AnchorPoint = Vector2.new(0, 0)
	diamond.Rotation = 45
	diamond.BackgroundColor3 = color
	diamond.BackgroundTransparency = 0
	diamond.BorderSizePixel = 0
	diamond.Parent = icon

	local diamondCorner = Instance.new("UICorner")
	diamondCorner.CornerRadius = UDim.new(0, 3)
	diamondCorner.Parent = diamond

	-- Inner facet highlight
	local facet = Instance.new("Frame")
	facet.Name = "Facet"
	facet.Size = UDim2.new(0, 10, 0, 10)
	facet.Position = UDim2.new(0.5, -5, 0.5, -5)
	facet.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	facet.BackgroundTransparency = 0.85
	facet.BorderSizePixel = 0
	facet.Rotation = 0
	facet.Parent = diamond

	local facetCorner = Instance.new("UICorner")
	facetCorner.CornerRadius = UDim.new(0, 2)
	facetCorner.Parent = facet

	-- Key stem
	local stem = Instance.new("Frame")
	stem.Name = "Stem"
	stem.Size = UDim2.new(0, 4, 0, 12)
	stem.Position = UDim2.new(0.5, -2, 0.3, 12)
	stem.BackgroundColor3 = color
	stem.BackgroundTransparency = 0
	stem.BorderSizePixel = 0
	stem.Parent = icon

	-- Key teeth (two small notches on the stem)
	for i = 0, 1 do
		local tooth = Instance.new("Frame")
		tooth.Name = "Tooth" .. i
		tooth.Size = UDim2.new(0, 4, 0, 2)
		tooth.Position = UDim2.new(1, 0, 0, 4 + i * 4)
		tooth.BackgroundColor3 = color
		tooth.BackgroundTransparency = 0
		tooth.BorderSizePixel = 0
		tooth.Parent = stem
	end

	-- Key ring (small circle at bottom of stem)
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.Size = UDim2.new(0, 8, 0, 8)
	ring.Position = UDim2.new(0.5, -4, 0.3, 23)
	ring.BackgroundColor3 = color
	ring.BackgroundTransparency = 0.3
	ring.BorderSizePixel = 0
	ring.Parent = icon

	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius = UDim.new(1, 0)
	ringCorner.Parent = ring

	return icon
end

local function createRelicSlot(relicName, layoutOrder)
	local frame = Instance.new("Frame")
	frame.Name = relicName .. "Slot"
	frame.Size = UDim2.new(0, 46, 0, 52)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 1
	frame.BorderColor3 = Color3.fromRGB(50, 50, 55)
	frame.LayoutOrder = layoutOrder

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 4)
	slotCorner.Parent = frame

	-- Programmatic key icon
	createKeyIcon(relicName, frame)

	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, 12)
	label.Position = UDim2.new(0, 0, 1, -13)
	label.BackgroundTransparency = 1
	label.Text = relicName
	label.TextSize = 10
	label.TextColor3 = Color3.fromRGB(140, 140, 140)
	label.Font = Enum.Font.Gotham
	label.Parent = frame

	return frame
end

-- Create tracker UI
function RelicTracker.CreateTracker()
	trackerGui = Instance.new("ScreenGui")
	trackerGui.Name = "RelicTracker"
	trackerGui.ResetOnSpawn = false
	trackerGui.Parent = playerGui

	-- Container: bottom-left, aligned with HUD (x=10)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 170, 0, 72)
	container.Position = UDim2.new(0, 10, 1, -82)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = trackerGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 6)
	containerCorner.Parent = container

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 16)
	title.Position = UDim2.new(0, 0, 0, 2)
	title.BackgroundTransparency = 1
	title.Text = "KEYS"
	title.TextSize = 10
	title.TextColor3 = Color3.fromRGB(180, 180, 180)
	title.Font = Enum.Font.GothamBold
	title.Parent = container

	-- Slot row
	local row = Instance.new("Frame")
	row.Name = "SlotRow"
	row.Size = UDim2.new(1, -12, 0, 52)
	row.Position = UDim2.new(0, 6, 0, 17)
	row.BackgroundTransparency = 1
	row.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.Parent = row

	relicSlots.Blue = createRelicSlot("Blue", 1)
	relicSlots.Blue.Parent = row

	relicSlots.Green = createRelicSlot("Green", 2)
	relicSlots.Green.Parent = row

	relicSlots.Red = createRelicSlot("Red", 3)
	relicSlots.Red.Parent = row

	print("[RelicTracker] Tracker UI created")
end

-- Color all key parts for a slot
local function setKeyColor(slot, color, transparency)
	local icon = slot:FindFirstChild("Icon")
	if not icon then return end

	for _, child in ipairs(icon:GetDescendants()) do
		if child:IsA("Frame") and child.Name ~= "Facet" then
			child.BackgroundColor3 = color
			child.BackgroundTransparency = transparency
		end
	end
end

-- Update a relic slot to show collected state
function RelicTracker.UpdateRelic(relicName, collected)
	local slot = relicSlots[relicName]
	if not slot then return end

	local label = slot:FindFirstChild("Label")

	if collected then
		local color = RelicColors[relicName]

		-- Light up slot border
		slot.BorderColor3 = color
		slot.BackgroundTransparency = 0.1

		-- Color the key icon
		setKeyColor(slot, color, 0)

		-- Pulse the diamond
		local icon = slot:FindFirstChild("Icon")
		if icon then
			local diamond = icon:FindFirstChild("Diamond")
			if diamond then
				local pulse = TweenService:Create(
					diamond,
					TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{BackgroundTransparency = 0.3}
				)
				pulse:Play()
			end
		end

		-- Update label
		if label then
			label.TextColor3 = color
			label.Text = relicName .. " ✓"
		end

		print("[RelicTracker] Updated", relicName, "relic to collected")
	else
		-- Reset to dim
		slot.BorderColor3 = Color3.fromRGB(50, 50, 55)
		slot.BackgroundTransparency = 0.2

		setKeyColor(slot, RelicDimColors[relicName], 0)

		if label then
			label.TextColor3 = Color3.fromRGB(140, 140, 140)
			label.Text = relicName
		end
	end
end

-- Update all relics based on data
function RelicTracker.UpdateAllRelics(relicsData)
	if not relicsData then return end

	RelicTracker.UpdateRelic("Blue", relicsData.Blue)
	RelicTracker.UpdateRelic("Green", relicsData.Green)
	RelicTracker.UpdateRelic("Red", relicsData.Red)
end

return RelicTracker
