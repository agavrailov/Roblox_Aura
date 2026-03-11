-- CraftingMenu.lua
-- Aura crafting and equipping menu UI

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AuraData = require(game.ReplicatedStorage.AuraData)
local CraftAuraEvent = game.ReplicatedStorage.CraftAura
local EquipAuraEvent = game.ReplicatedStorage.EquipAura

local CraftingMenu = {}

local menuGui
local menuFrame
local isVisible = false
local auraConnections = {} -- Track click connections per aura to avoid accumulation

-- Create crafting menu
function CraftingMenu.CreateMenu()
	menuGui = Instance.new("ScreenGui")
	menuGui.Name = "CraftingMenu"
	menuGui.ResetOnSpawn = false
	menuGui.Parent = playerGui
	
	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Parent = menuGui
	
	-- Main menu frame
	menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(0, 500, 0, 400)
	menuFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	menuFrame.BorderSizePixel = 0
	menuFrame.Visible = false
	menuFrame.Parent = menuGui
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	title.BorderSizePixel = 0
	title.Text = "CRAFT AURAS"
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.Parent = menuFrame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeButton.Text = "X"
	closeButton.TextSize = 20
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = menuFrame
	
	closeButton.MouseButton1Click:Connect(function()
		CraftingMenu.Hide()
	end)
	
	-- Aura list container
	local auraList = Instance.new("ScrollingFrame")
	auraList.Name = "AuraList"
	auraList.Size = UDim2.new(1, -20, 1, -70)
	auraList.Position = UDim2.new(0, 10, 0, 60)
	auraList.BackgroundTransparency = 1
	auraList.BorderSizePixel = 0
	auraList.ScrollBarThickness = 8
	auraList.Parent = menuFrame
	
	-- Populate aura list (sorted by cost, most expensive first)
	local sortedAuras = {}
	for auraName, aura in pairs(AuraData.Auras) do
		table.insert(sortedAuras, { key = auraName, data = aura })
	end
	table.sort(sortedAuras, function(a, b) return a.data.Cost > b.data.Cost end)
	
	local yOffset = 0
	for _, entry in ipairs(sortedAuras) do
		local auraName = entry.key
		local aura = entry.data
		local auraFrame = Instance.new("Frame")
		auraFrame.Name = auraName
		auraFrame.Size = UDim2.new(1, -10, 0, 100)
		auraFrame.Position = UDim2.new(0, 0, 0, yOffset)
		auraFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		auraFrame.BorderSizePixel = 0
		auraFrame.Parent = auraList
		
		-- Aura name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0.6, 0, 0, 30)
		nameLabel.Position = UDim2.new(0, 10, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = aura.Name
		nameLabel.TextSize = 20
		nameLabel.TextColor3 = aura.Color
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = auraFrame
		
		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.Size = UDim2.new(0.6, 0, 0, 40)
		descLabel.Position = UDim2.new(0, 10, 0, 40)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = aura.Description
		descLabel.TextSize = 14
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.Parent = auraFrame
		
		-- Cost
		local costLabel = Instance.new("TextLabel")
		costLabel.Name = "Cost"
		costLabel.Size = UDim2.new(0.3, 0, 0, 30)
		costLabel.Position = UDim2.new(0.65, 0, 0, 10)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = "⚡ " .. tostring(aura.Cost)
		costLabel.TextSize = 18
		costLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		costLabel.Font = Enum.Font.GothamBold
		costLabel.Parent = auraFrame
		
		-- Craft button
		local craftBtn = Instance.new("TextButton")
		craftBtn.Name = "CraftButton"
		craftBtn.Size = UDim2.new(0.3, -10, 0, 30)
		craftBtn.Position = UDim2.new(0.65, 0, 0, 50)
		craftBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		craftBtn.Text = "CRAFT"
		craftBtn.TextSize = 16
		craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		craftBtn.Font = Enum.Font.GothamBold
		craftBtn.Parent = auraFrame
		
		auraConnections[auraName] = craftBtn.MouseButton1Click:Connect(function()
			CraftAuraEvent:FireServer(auraName)
		end)
		
		yOffset = yOffset + 110
	end
	
	auraList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	
	print("[CraftingMenu] Menu created")
end

-- Show menu
function CraftingMenu.Show()
	if menuFrame then
		menuFrame.Visible = true
		menuFrame.Parent.Overlay.Visible = true
		isVisible = true
	end
end

-- Hide menu
function CraftingMenu.Hide()
	if menuFrame then
		menuFrame.Visible = false
		menuFrame.Parent.Overlay.Visible = false
		isVisible = false
	end
end

-- Toggle menu
function CraftingMenu.Toggle()
	if isVisible then
		CraftingMenu.Hide()
	else
		CraftingMenu.Show()
	end
end

-- Update aura buttons based on player data
function CraftingMenu.UpdateAuraButtons(playerData)
	if not menuFrame then return end
	
	local auraList = menuFrame:FindFirstChild("AuraList")
	if not auraList then return end
	
	for auraName, aura in pairs(AuraData.Auras) do
		local auraFrame = auraList:FindFirstChild(auraName)
		if auraFrame then
			local craftBtn = auraFrame:FindFirstChild("CraftButton")
			if craftBtn then
				-- Disconnect old handler before reconnecting
				if auraConnections[auraName] then
					auraConnections[auraName]:Disconnect()
				end
				
				if playerData.Auras[auraName] then
					-- Already owned - change to equip button
					craftBtn.Text = "EQUIP"
					craftBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
					
					auraConnections[auraName] = craftBtn.MouseButton1Click:Connect(function()
						EquipAuraEvent:FireServer(auraName)
					end)
					
					-- Show if equipped
					if playerData.EquippedAura == auraName then
						craftBtn.Text = "EQUIPPED"
						craftBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					end
				else
					-- Not owned - restore craft handler
					craftBtn.Text = "CRAFT"
					craftBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
					auraConnections[auraName] = craftBtn.MouseButton1Click:Connect(function()
						CraftAuraEvent:FireServer(auraName)
					end)
				end
			end
		end
	end
end

return CraftingMenu
