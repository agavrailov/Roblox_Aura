--!strict
-- Orb.lua
-- Module to control the behavior of a single collectible orb.

local Orb = {}
Orb.__index = Orb

export type OrbTypeConfig = {
	Name: string?,
	LuminValue: number,
	RespawnTime: number,
	Color: Color3?,
	Size: Vector3?,
}

function Orb.new(position: Vector3, orbType: OrbTypeConfig)
	local self = setmetatable({}, Orb)

	self.luminAmount = orbType.LuminValue
	self.respawnTime = orbType.RespawnTime
	self.enabled = true

	-- Create the visual part for the orb
	local part = Instance.new("Part")
	part.Name = orbType.Name or "Orb"
	part.Size = orbType.Size or Vector3.new(3, 3, 3)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Ball
	part.Color = orbType.Color or Color3.fromRGB(255, 255, 0) -- Bright yellow by default
	part.Material = Enum.Material.Neon
	part.Parent = workspace

	-- Add a simple particle effect
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Rate = 5
	particleEmitter.Lifetime = NumberRange.new(1)
	particleEmitter.Color = ColorSequence.new(part.Color)
	particleEmitter.Parent = part

	self.part = part
	self.particleEmitter = particleEmitter
	
	-- The OrbManager will be responsible for mapping this part to the object
	return self, part
end

function Orb:collect()
	if not self.enabled then
		return false
	end

	print("Orb collected for " .. self.luminAmount .. " Lumin.")
	self.enabled = false

	-- Hide the orb
	self.part.Transparency = 1
	if self.particleEmitter then
		self.particleEmitter.Enabled = false
	end

	-- Respawn logic
	task.delay(self.respawnTime, function()
		self:respawn()
	end)
	
	return self.luminAmount
end

function Orb:respawn()
	print("Orb respawned.")
	self.part.Transparency = 0
	if self.particleEmitter then
		self.particleEmitter.Enabled = true
	end
	self.enabled = true -- Re-enable collection only when orb is visible
end

return Orb
