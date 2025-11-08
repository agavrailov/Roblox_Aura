--!strict
-- Orb.lua
-- Module to control the behavior of a single collectible orb.

local Orb = {}
Orb.__index = Orb

local DEBOUNCE_SECONDS = 1 -- How long the orb is disabled after being collected
local RESPAWN_SECONDS = 5 -- How long it takes for the orb to reappear

function Orb.new(position: Vector3, luminAmount: number)
	local self = setmetatable({}, Orb)

	self.luminAmount = luminAmount
	self.enabled = true

	-- Create the visual part for the orb
	local part = Instance.new("Part")
	part.Size = Vector3.new(3, 3, 3)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Ball
	part.Color = Color3.fromRGB(255, 255, 0) -- Bright yellow
	part.Material = Enum.Material.Neon
	part.Parent = workspace

	-- Add a simple particle effect
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Rate = 5
	particleEmitter.Lifetime = NumberRange.new(1)
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 127))
	particleEmitter.Parent = part

	self.part = part
	
	-- Attach the orb object to the part so we can find it on touch
	part:SetAttribute("OrbModule", self)

	return self
end

function Orb:collect()
	if not self.enabled then
		return false
	end

	print("Orb collected for " .. self.luminAmount .. " Lumin.")
	self.enabled = false

	-- Hide the orb
	self.part.Transparency = 1
	self.part.ParticleEmitter.Enabled = false

	-- Debounce period
	task.delay(DEBOUNCE_SECONDS, function()
		self.enabled = true
	end)

	-- Respawn logic
	task.delay(RESPAWN_SECONDS, function()
		self:respawn()
	end)
	
	return self.luminAmount
end

function Orb:respawn()
	print("Orb respawned.")
	self.part.Transparency = 0
	self.part.ParticleEmitter.Enabled = true
end

return Orb
