--!strict
-- ZoneBarrier.server.lua
-- Module to manage a single zone barrier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService") -- New: Require PhysicsService

local ZoneManager = require(game.ServerScriptService.ZoneManager)

local ZoneBarrier = {}
ZoneBarrier.__index = ZoneBarrier

-- Collision Group Names
local BARRIER_GROUP_NAME = "ZoneBarrier"
local PLAYER_PASS_GROUP_NAME = "PlayerPassBarrier"
local PLAYER_BLOCK_GROUP_NAME = "PlayerBlockBarrier"

-- Configure Collision Groups once
local function setupCollisionGroups()
	local groupsToCreate = {BARRIER_GROUP_NAME, PLAYER_PASS_GROUP_NAME, PLAYER_BLOCK_GROUP_NAME}
	-- First, ensure all groups are created
	for _, groupName in ipairs(groupsToCreate) do
		local groupExists = false
		for _, groupInfo in ipairs(PhysicsService:GetCollisionGroups()) do
			if groupInfo.name == groupName then
				groupExists = true
				break
			end
		end
		if not groupExists then
			PhysicsService:CreateCollisionGroup(groupName)
		end
	end

	-- Then, set collision rules
	PhysicsService:SetCollisionGroupCollidable(BARRIER_GROUP_NAME, PLAYER_PASS_GROUP_NAME, false)
	PhysicsService:SetCollisionGroupCollidable(BARRIER_GROUP_NAME, PLAYER_BLOCK_GROUP_NAME, true)
	PhysicsService:SetCollisionGroupCollidable(PLAYER_PASS_GROUP_NAME, PLAYER_BLOCK_GROUP_NAME, true)
	PhysicsService:SetCollisionGroupCollidable(PLAYER_PASS_GROUP_NAME, PLAYER_PASS_GROUP_NAME, true)
	PhysicsService:SetCollisionGroupCollidable(PLAYER_BLOCK_GROUP_NAME, PLAYER_BLOCK_GROUP_NAME, true)
end

setupCollisionGroups() -- Call once when the module loads

function ZoneBarrier.new(barrierPart: BasePart, targetZoneName: string)
	local self = setmetatable({}, ZoneBarrier)

	self.barrierPart = barrierPart
	self.targetZoneName = targetZoneName
	self.playersInside = {} -- Keep track of players currently touching the barrier

	-- Initial setup of the barrier part
	self.barrierPart.CollisionGroup = BARRIER_GROUP_NAME
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
	local targetGroup = passable and PLAYER_PASS_GROUP_NAME or PLAYER_BLOCK_GROUP_NAME
	local character = player.Character
	if not character then return end

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, targetGroup)
		end
	end

	-- Store the connection to disconnect later
	local characterAddedConnection
	characterAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
		-- Reapply collision group to new character parts
		for _, part in ipairs(newCharacter:GetDescendants()) do
			if part:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(part, targetGroup)
			end
		end
		characterAddedConnection:Disconnect() -- Disconnect after first use
	end)

	-- Clean up connection when player leaves
	local characterRemovingConnection
	characterRemovingConnection = player.CharacterRemoving:Connect(function(char)
		characterAddedConnection:Disconnect()
		characterRemovingConnection:Disconnect()
	end)

	if passable then
		self.barrierPart.Transparency = 0.8
		self.barrierPart.Color = Color3.fromRGB(0, 255, 0) -- Green for passable
	else
		self.barrierPart.Transparency = 0.5
		self.barrierPart.Color = Color3.fromRGB(255, 0, 0) -- Red for impassable
	end
end

return ZoneBarrier
