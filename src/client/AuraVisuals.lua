--!strict
-- AuraVisuals.lua
-- Client-side module to create and manage the visual effects for auras.

local AuraVisuals = {}

-- This table will hold functions that create the particle effect for each aura.
local AuraEffectCreators = {}

AuraEffectCreators["Basic Aura"] = function(parentPart: BasePart)
	local auraPart = Instance.new("Part")
	auraPart.Name = "AuraEffectPart"
	auraPart.Shape = Enum.PartType.Ball
	auraPart.Size = Vector3.new(8, 2, 8) -- Wider, flatter shape around the torso
	auraPart.Anchored = false
	auraPart.CanCollide = false
	auraPart.Transparency = 1
	auraPart.Parent = parentPart

	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Rate = 150 -- Increased rate
	particleEmitter.Lifetime = NumberRange.new(0.8, 1.2)
	particleEmitter.Speed = NumberRange.new(0)
	particleEmitter.SpreadAngle = Vector2.new(360, 360)
	particleEmitter.Shape = Enum.ParticleEmitterShape.Sphere
	particleEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 150))
	particleEmitter.Size = NumberSequence.new(0.2, 0) -- Start larger and shrink
	particleEmitter.LightEmission = 0.5 -- Make particles glow
	particleEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2), -- Start more opaque
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	particleEmitter.Parent = auraPart

	-- Weld the effect part to the parent part (e.g., UpperTorso)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = auraPart
	weld.Part1 = parentPart
	weld.Parent = auraPart

	return auraPart
end

-- Creates and attaches an aura effect to a character model.
function AuraVisuals.create(auraName: string, character: Model)
	local upperTorso = character:FindFirstChild("UpperTorso")
	if not upperTorso then
		warn("Could not find UpperTorso to attach aura to.")
		return
	end

	-- Find the creator function for the requested aura
	local creator = AuraEffectCreators[auraName]
	if not creator then
		warn("No visual effect defined for aura: " .. auraName)
		return
	end

	-- Create the effect and parent it to the character
	local effect = creator(upperTorso)

	print("Attached visual effect for '" .. auraName .. "'")
	return effect
end

-- Removes an aura effect from a character.
function AuraVisuals.remove(character: Model)
	local upperTorso = character:FindFirstChild("UpperTorso")
	if upperTorso then
		local existingAura = upperTorso:FindFirstChild("AuraEffectPart")
		if existingAura then
			existingAura:Destroy()
		end
	end
end

return AuraVisuals
