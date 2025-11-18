--!strict
-- ZoneGate.server.lua
-- Simple trigger-based gate for zone access.
-- A thin, invisible trigger part in front of a visual wall decides whether
-- a player can enter a given zone based on ZoneManager.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ZoneManager = require(game.ServerScriptService.ZoneManager)

local ZoneGate = {}
ZoneGate.__index = ZoneGate

local ZoneMessageEvent: RemoteEvent = (function()
	local existing = ReplicatedStorage:FindFirstChild("ZoneMessage")
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local newEvent = Instance.new("RemoteEvent")
	newEvent.Name = "ZoneMessage"
	newEvent.Parent = ReplicatedStorage
	return newEvent
end)()

-- triggerPart: a non-colliding, CanTouch=true part in front of the visual wall
-- zoneName: name key in ZoneConfig.Zones
-- targetPosition: where to teleport allowed players (e.g. zone spawn position)
function ZoneGate.new(triggerPart: BasePart, zoneName: string, targetPosition: Vector3)
	local self = setmetatable({}, ZoneGate)

	self.triggerPart = triggerPart
	self.zoneName = zoneName
	self.targetPosition = targetPosition

	self.triggerPart.Touched:Connect(function(otherPart)
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if not player then
			return
		end
		self:onPlayerTouched(player)
	end)

	return self
end

function ZoneGate:onPlayerTouched(player: Player)
	local canEnter, reason = ZoneManager.canEnterZone(player, self.zoneName)

	if canEnter then
		print(player.Name .. " can enter " .. self.zoneName)
		self:teleportPlayerToZone(player)
	else
		print(player.Name .. " cannot enter " .. self.zoneName .. ". Reason: " .. tostring(reason))
		if reason then
			ZoneMessageEvent:FireClient(player, reason)
		end
	end
end

function ZoneGate:teleportPlayerToZone(player: Player)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	hrp.CFrame = CFrame.new(self.targetPosition)
end

return ZoneGate
