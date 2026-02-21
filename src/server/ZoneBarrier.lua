--!strict
-- ZoneBarrier.lua
-- Manages player collision groups based on their equipped aura.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraConfig = require(ReplicatedStorage.AuraConfig)

local ZoneBarrier = {}

-- Function to get the aura tier from its name
local function getAuraTier(auraName: string): number
	local i = 1
	for name, _ in pairs(AuraConfig.Auras) do
		if name == auraName then
			return math.ceil(i / 1) -- Example: 1 aura per tier
		end
		i += 1
	end
	return 0 -- Default tier if not found
end

-- Updates the collision group of a player's character based on their equipped aura
function ZoneBarrier.updatePlayerCollisionGroup(player: Player, auraName: string?)
	local character = player.Character
	if not character then return end

	local auraTier = 0
	if auraName then
		auraTier = getAuraTier(auraName)
	end

	local targetGroup = "PlayerAura" .. auraTier
	if auraTier == 0 then
		targetGroup = "Players"
	end

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = targetGroup
		end
	end
end

-- Handle new characters being added
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Set initial collision group
		ZoneBarrier.updatePlayerCollisionGroup(player, nil)
	end)
end)

return ZoneBarrier
