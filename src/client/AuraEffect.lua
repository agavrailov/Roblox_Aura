-- AuraEffect.lua
-- Applies / removes visual aura effect on the local character

local Players = game:GetService("Players")
local AuraData = require(game.ReplicatedStorage.AuraData)

local AuraEffect = {}

local ATTACHMENT_NAME = "AuraEffectAttachment"

-- Remove any existing aura effect from the character
function AuraEffect.Remove(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local existing = hrp:FindFirstChild(ATTACHMENT_NAME)
	if existing then
		existing:Destroy()
	end
end

-- Apply aura effect for the given aura key (e.g. "BlueAura")
-- Pass nil to just remove the current effect
function AuraEffect.Apply(auraName)
	local character = Players.LocalPlayer.Character
	if not character then return end

	AuraEffect.Remove(character)

	if not auraName then return end

	local aura = AuraData.GetAura(auraName)
	if not aura then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = ATTACHMENT_NAME
	attachment.Parent = hrp

	-- Particles rising off the body
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(aura.Color)
	particles.LightEmission = 0.8
	particles.LightInfluence = 0.2
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Lifetime = NumberRange.new(0.6, 1.2)
	particles.Rate = 25
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = attachment

	-- Colored point light glow
	local light = Instance.new("PointLight")
	light.Color = aura.Color
	light.Brightness = 2
	light.Range = 10
	light.Parent = attachment

	print("[AuraEffect] Applied", auraName, "effect on character")
end

return AuraEffect
