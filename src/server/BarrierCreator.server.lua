--!strict
-- BarrierCreator.server.lua
-- Creates the ForestBarrier part in workspace if it doesn't exist.

local BARRIER_NAME = "ForestBarrier"
local TARGET_ZONE_NAME = "Forest Zone" -- The zone this barrier leads to

local function createForestBarrier()
	local existingBarrier = workspace:FindFirstChild(BARRIER_NAME)
	if existingBarrier then
		print(BARRIER_NAME .. " already exists in workspace.")
		return
	end

	local barrier = Instance.new("Part")
	barrier.Name = BARRIER_NAME
	barrier.Size = Vector3.new(5, 10, 1) -- Example size
	barrier.Position = Vector3.new(25, 5, 0) -- Example position (midway between starting and forest zone)
	barrier.Anchored = true
	barrier.CanCollide = true -- Will be managed by ZoneBarrier module
	barrier.Transparency = 0.5
	barrier.Color = Color3.fromRGB(255, 0, 0) -- Initial color (red for impassable)
	barrier.Material = Enum.Material.ForceField
	barrier.Parent = workspace

	print("Created " .. BARRIER_NAME .. " in workspace.")
end

createForestBarrier()
