--!strict
-- ZoneMessageGui.lua
-- Minimal UI module to show short zone-related messages to the player.

local Players = game:GetService("Players")

local ZoneMessageGui = {}

local FADE_TIME = 0.3
local DISPLAY_TIME = 2

local function createGui(): (ScreenGui, TextLabel)
	local player = Players.LocalPlayer
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ZoneMessageGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true

	local label = Instance.new("TextLabel")
	label.Name = "MessageLabel"
	label.Size = UDim2.new(0.4, 0, 0.06, 0)
	label.Position = UDim2.new(0.3, 0, 0.15, 0)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.Visible = false
	label.Parent = screenGui

	screenGui.Parent = player:WaitForChild("PlayerGui")

	return screenGui, label
end

local gui: ScreenGui? = nil
local label: TextLabel? = nil
local currentTween: Tween? = nil

function ZoneMessageGui.init()
	if gui and label then
		return gui, label
	end
	gui, label = createGui()
	return gui, label
end

function ZoneMessageGui.show(message: string)
	local TweenService = game:GetService("TweenService")
	if not gui or not label then
		ZoneMessageGui.init()
	end
	assert(label, "ZoneMessageGui label should be initialized")

	if currentTween then
		currentTween:Cancel()
	end

	label.Text = message
	label.Visible = true
	label.TextTransparency = 0
	label.BackgroundTransparency = 0.3

	-- Fade out after DISPLAY_TIME
	task.delay(DISPLAY_TIME, function()
		if not label then return end
		local info = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(label, info, {TextTransparency = 1, BackgroundTransparency = 1})
		currentTween = tween
		tween:Play()
		tween.Completed:Wait()
		if label then
			label.Visible = false
		end
	end)
end

return ZoneMessageGui
