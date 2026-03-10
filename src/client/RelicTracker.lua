-- RelicTracker.lua
-- UI displaying the 3 Prismatic Keys collection status

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RelicTracker = {}

local trackerGui
local relicSlots = {} -- {Blue = frame, Green = frame, Red = frame}

-- Relic colors
local RelicColors = {
	Blue = Color3.fromRGB(100, 150, 255),
	Green = Color3.fromRGB(100, 255, 150),
	Red = Color3.fromRGB(255, 100, 100),
}

-- Create a single relic slot
local function createRelicSlot(relicName, position)
	local frame = Instance.new("Frame")
	frame.Name = relicName .. "Slot"
	frame.Size = UDim2.new(0, 80, 0, 80)
	frame.Position = position
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
	
	-- Relic icon (silhouette when not collected)
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.Position = UDim2.new(0.1, 0, 0.1, 0)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Placeholder, can be custom icon
	icon.ImageColor3 = Color3.fromRGB(80, 80, 80) -- Gray silhouette
	icon.ImageTransparency = 0.7
	icon.Parent = frame
	
	-- Glow effect (hidden initially)
	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.Size = UDim2.new(1.2, 0, 1.2, 0)
	glow.Position = UDim2.new(-0.1, 0, -0.1, 0)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	glow.ImageColor3 = RelicColors[relicName]
	glow.ImageTransparency = 1
	glow.ZIndex = 0
	glow.Parent = frame
	
	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Position = UDim2.new(0, 0, 1, 5)
	label.BackgroundTransparency = 1
	label.Text = relicName
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
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
	
	-- Container frame
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 280, 0, 130)
	container.Position = UDim2.new(0.5, -140, 0, 10)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	container.BackgroundTransparency = 0.5
	container.BorderSizePixel = 0
	container.Parent = trackerGui
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 25)
	title.BackgroundTransparency = 1
	title.Text = "PRISMATIC KEYS"
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.Parent = container
	
	-- Create 3 relic slots
	relicSlots.Blue = createRelicSlot("Blue", UDim2.new(0.05, 0, 0, 30))
	relicSlots.Blue.Parent = container
	
	relicSlots.Green = createRelicSlot("Green", UDim2.new(0.37, 0, 0, 30))
	relicSlots.Green.Parent = container
	
	relicSlots.Red = createRelicSlot("Red", UDim2.new(0.69, 0, 0, 30))
	relicSlots.Red.Parent = container
	
	print("[RelicTracker] Tracker UI created")
end

-- Update a relic slot to show collected state
function RelicTracker.UpdateRelic(relicName, collected)
	local slot = relicSlots[relicName]
	if not slot then return end
	
	local icon = slot:FindFirstChild("Icon")
	local glow = slot:FindFirstChild("Glow")
	local label = slot:FindFirstChild("Label")
	
	if collected then
		-- Light up the slot
		slot.BorderColor3 = RelicColors[relicName]
		slot.BackgroundTransparency = 0.1
		
		-- Color the icon
		if icon then
			icon.ImageColor3 = RelicColors[relicName]
			icon.ImageTransparency = 0
		end
		
		-- Enable glow effect
		if glow then
			glow.ImageTransparency = 0.5
			
			-- Pulsing animation
			local tween = game:GetService("TweenService"):Create(
				glow,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ImageTransparency = 0.8}
			)
			tween:Play()
		end
		
		-- Update label
		if label then
			label.TextColor3 = RelicColors[relicName]
			label.Text = relicName .. " ✓"
		end
		
		print("[RelicTracker] Updated", relicName, "relic to collected")
	else
		-- Reset to silhouette
		slot.BorderColor3 = Color3.fromRGB(60, 60, 60)
		slot.BackgroundTransparency = 0.3
		
		if icon then
			icon.ImageColor3 = Color3.fromRGB(80, 80, 80)
			icon.ImageTransparency = 0.7
		end
		
		if glow then
			glow.ImageTransparency = 1
		end
		
		if label then
			label.TextColor3 = Color3.fromRGB(200, 200, 200)
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
