--!strict
-- ZoneBarrier.server.lua
-- Module to manage a single zone barrier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ZoneManager = require(game.ServerScriptService.ZoneManager)

local ZoneBarrier = {}
ZoneBarrier.__index = ZoneBarrier

function ZoneBarrier.new(barrierPart: BasePart, targetZoneName: string)
	local self = setmetatable({}, ZoneBarrier)

	self.barrierPart = barrierPart
	self.targetZoneName = targetZoneName
	self.playersInside = {} -- Keep track of players currently touching the barrier

	-- Initial setup of the barrier part
	self.barrierPart.CanCollide = true
	self.barrierPart.Transparency = 0.5
	self.barrierPart.Color = Color3.fromRGB(255, 0, 0) -- Red for impassable

	-- Connect touch events
	self.barrierPart.Touched:Connect(function(otherPart)
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if player and not self.playersInside[player] then
			self.playersInside[player] = true
			self:onPlayerTouched(player)
		end
	end)

	self.barrierPart.TouchEnded:Connect(function(otherPart)
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if player and self.playersInside[player] then
			self.playersInside[player] = nil
		end
	end)

	return self
end

function ZoneBarrier:onPlayerTouched(player: Player)
	local canEnter, reason = ZoneManager.canEnterZone(player, self.targetZoneName)

	if canEnter then
		print(player.Name .. " can enter " .. self.targetZoneName)
		-- Make barrier temporarily passable for this player
		self:setPassableForPlayer(player, true)
	else
		print(player.Name .. " cannot enter " .. self.targetZoneName .. ". Reason: " .. reason)
		-- Keep barrier impassable, maybe show a UI message
		self:setPassableForPlayer(player, false)
	end
end

function ZoneBarrier:setPassableForPlayer(player: Player, passable: boolean)
	-- This is a simplified approach. In a real game, you might use
	-- CollisionGroups or a more complex client-side solution.
	if passable then
		self.barrierPart.CanCollide = false
		self.barrierPart.Transparency = 0.8
		self.barrierPart.Color = Color3.fromRGB(0, 255, 0) -- Green for passable
	else
		self.barrierPart.CanCollide = true
		self.barrierPart.Transparency = 0.5
		self.barrierPart.Color = Color3.fromRGB(255, 0, 0) -- Red for impassable
	end
end

return ZoneBarrier
