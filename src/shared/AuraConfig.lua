--!strict
-- AuraConfig.lua
-- Defines all available auras in the game.

local AuraConfig = {}

AuraConfig.Auras = {
	-- Basic Aura
	["Basic Aura"] = {
		Name = "Basic Aura",
		Cost = 100,
		LuminMultiplier = 1.1, -- 10% more Lumin
		ParticleEffect = "rbxassetid://0", -- Placeholder for a particle effect ID
		Description = "A simple, yet elegant aura.",
		NextAura = "Green Aura", -- Unlocks Green Aura
	},

	-- Green Aura
	["Green Aura"] = {
		Name = "Green Aura",
		Cost = 500,
		LuminMultiplier = 1.25, -- 25% more Lumin
		ParticleEffect = "rbxassetid://0", -- Placeholder
		Description = "A vibrant green glow.",
		PreviousAura = "Basic Aura",
		NextAura = "Blue Aura",
	},

	-- Blue Aura
	["Blue Aura"] = {
		Name = "Blue Aura",
		Cost = 1, -- Temporarily reduced for testing
		LuminMultiplier = 1.5, -- 50% more Lumin
		ParticleEffect = "rbxassetid://0", -- Placeholder
		Description = "A calming blue radiance.",
		PreviousAura = "Green Aura",
		NextAura = "Red Aura",
	},

	-- Red Aura
	["Red Aura"] = {
		Name = "Red Aura",
		Cost = 5000,
		LuminMultiplier = 2.0, -- 100% more Lumin
		ParticleEffect = "rbxassetid://0", -- Placeholder
		Description = "An intense red energy.",
		PreviousAura = "Blue Aura",
		NextAura = nil, -- Last aura in this chain for now
	},
}

return AuraConfig
