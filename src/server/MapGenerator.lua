--!strict
-- MapGenerator.server.lua
-- Dynamically generates the game map (zones, fences, barriers) based on ZoneConfig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConfig = require(ReplicatedStorage.ZoneConfig)
local ZoneBarrier = require(game.ServerScriptService.ZoneBarrier)

local MapGenerator = {}

-- Function to create a single fence segment
local function createFenceSegment(parent: Instance, position: Vector3, size: Vector3, color: Color3, transparency: number, material: Enum.Material)
	local fencePart = Instance.new("Part")
	fencePart.Name = "FenceSegment"
	fencePart.Size = size
	fencePart.Position = position
	fencePart.Anchored = true
	fencePart.CanCollide = true
	fencePart.Color = color
	fencePart.Transparency = transparency
	fencePart.Material = material
	fencePart.Parent = parent
	return fencePart
end

-- Function to generate a zone's ground, fence, and barrier
function MapGenerator.generateMap()
	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "Zones"
	zonesFolder.Parent = workspace

	for zoneName, zoneData in pairs(ZoneConfig.Zones) do
		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = zoneName
		zoneFolder.Parent = zonesFolder

		-- Create Ground Part
		local ground = Instance.new("Part")
		ground.Name = "Ground"
		ground.Size = zoneData.Size
		ground.Position = zoneData.Position
		ground.Anchored = true
		ground.CanCollide = true
		ground.Color = Color3.fromRGB(50, 100, 50) -- Greenish ground
		ground.Material = Enum.Material.Grass
		ground.Parent = zoneFolder

		-- Create Fence
		local fenceColor = Color3.fromRGB(100, 100, 100)
		local fenceTransparency = 0.7
		local fenceMaterial = Enum.Material.ForceField

		local halfSizeX = zoneData.Size.X / 2
		local halfSizeZ = zoneData.Size.Z / 2
		local fenceHeight = zoneData.FenceHeight
		local fenceThickness = zoneData.FenceThickness
		local groundY = zoneData.Position.Y

		-- North Wall
		createFenceSegment(zoneFolder,
			zoneData.Position + Vector3.new(0, fenceHeight / 2 + groundY, -halfSizeZ - fenceThickness / 2),
			Vector3.new(zoneData.Size.X + fenceThickness * 2, fenceHeight, fenceThickness),
			fenceColor, fenceTransparency, fenceMaterial)
		-- South Wall
		createFenceSegment(zoneFolder,
			zoneData.Position + Vector3.new(0, fenceHeight / 2 + groundY, halfSizeZ + fenceThickness / 2),
			Vector3.new(zoneData.Size.X + fenceThickness * 2, fenceHeight, fenceThickness),
			fenceColor, fenceTransparency, fenceMaterial)
		-- East Wall
		createFenceSegment(zoneFolder,
			zoneData.Position + Vector3.new(halfSizeX + fenceThickness / 2, fenceHeight / 2 + groundY, 0),
			Vector3.new(fenceThickness, fenceHeight, zoneData.Size.Z),
			fenceColor, fenceTransparency, fenceMaterial)
		-- West Wall
		createFenceSegment(zoneFolder,
			zoneData.Position + Vector3.new(-halfSizeX - fenceThickness / 2, fenceHeight / 2 + groundY, 0),
			Vector3.new(fenceThickness, fenceHeight, zoneData.Size.Z),
			fenceColor, fenceTransparency, fenceMaterial)

		-- Create Barrier (if RequiredAura is defined)
		if zoneData.RequiredAura then
			local barrierPart = Instance.new("Part")
			barrierPart.Name = zoneName .. "Barrier"
			barrierPart.Size = zoneData.BarrierSize
			barrierPart.Position = zoneData.BarrierPosition
			barrierPart.Anchored = true
			barrierPart.Parent = zoneFolder

			ZoneBarrier.new(barrierPart, zoneName) -- Initialize ZoneBarrier logic
			print("Initialized barrier for " .. zoneName)
		end
	end
end

return MapGenerator
