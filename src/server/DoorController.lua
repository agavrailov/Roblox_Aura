-- DoorController.lua
-- Manages doors between zones and access control based on equipped auras
-- Updated for hex grid with axial coordinates

local GameConfig = require(game.ReplicatedStorage.GameConfig)
local ZoneTypes = require(game.ReplicatedStorage.ZoneTypes)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local DoorController = {}

local activeDoors = {}

local sqrt3 = math.sqrt(3)

-- 6 hex directions matching MazeGenerator order
local DIRECTIONS = {
	{q = 1, r = 0},   -- E
	{q = 1, r = -1},  -- NE
	{q = 0, r = -1},  -- NW
	{q = -1, r = 0},  -- W
	{q = -1, r = 1},  -- SW
	{q = 0, r = 1},   -- SE
}

local function key(q, r)
	return q .. "," .. r
end

local function getCell(grid, q, r)
	return grid[key(q, r)]
end

-- Convert axial (q, r) to world (x, z) for flat-top hexagons
local function hexToWorld(q, r)
	local size = GameConfig.ZONE_SIZE / 2
	local x = size * (3 / 2 * q)
	local z = size * (sqrt3 / 2 * q + sqrt3 * r)
	return x, z
end

-- Create a door between two cells
local function createDoorPart(fromCell, toCell, doorType, requiredAura)
	local fx, fz = hexToWorld(fromCell.q, fromCell.r)
	local tx, tz = hexToWorld(toCell.q, toCell.r)

	local doorX = (fx + tx) / 2
	local doorZ = (fz + tz) / 2
	local doorPos = Vector3.new(doorX, 5, doorZ)

	-- Door oriented perpendicular to the line between cells
	local angle = math.atan2(tz - fz, tx - fx)
	local perpAngle = angle + math.pi / 2
	local doorWidth = GameConfig.ZONE_SIZE * 0.6 -- narrower than the full edge
	local doorSize = Vector3.new(doorWidth, 10, 2)

	local door = Instance.new("Part")
	door.Name = doorType or "Door"
	door.Size = doorSize
	door.CFrame = CFrame.new(doorPos) * CFrame.Angles(0, -perpAngle, 0)
	door.Anchored = true
	door.Material = Enum.Material.Neon

	if doorType == ZoneTypes.DoorType.ESCAPE then
		door.CanCollide = false
		door.Transparency = 0.7
		door.Color = ZoneTypes.DoorColors[ZoneTypes.DoorType.ESCAPE]
	elseif doorType == ZoneTypes.DoorType.ALTERNATE then
		door.CanCollide = false
		door.Transparency = 0.6
		door.Color = ZoneTypes.DoorColors[ZoneTypes.DoorType.ALTERNATE]
	else
		door.CanCollide = true
		door.Transparency = 0.3
		if requiredAura == "BlueAura" then
			door.Color = ZoneTypes.Colors[ZoneTypes.Type.BLUE]
		elseif requiredAura == "GreenAura" then
			door.Color = ZoneTypes.Colors[ZoneTypes.Type.GREEN]
		elseif requiredAura == "RedAura" then
			door.Color = ZoneTypes.Colors[ZoneTypes.Type.RED]
		else
			door.Color = Color3.fromRGB(200, 200, 200)
		end
	end

	return door
end

-- Map aura names to tier levels
local AURA_TIERS = {
	BlueAura = 1,
	GreenAura = 2,
	RedAura = 3,
}

-- Check if player can pass through door
local function canPassThrough(player, doorType, requiredAura)
	if doorType == ZoneTypes.DoorType.ESCAPE or doorType == ZoneTypes.DoorType.ALTERNATE then
		return true
	end
	if not requiredAura then return true end

	local equippedAura = PlayerDataManager.GetEquippedAura(player)
	local playerTier = AURA_TIERS[equippedAura] or 0
	local requiredTier = AURA_TIERS[requiredAura] or 1
	local canPass = playerTier >= requiredTier

	print("[DoorController] Access check for", player.Name)
	print("  - Required aura:", requiredAura, "(tier", requiredTier, ")")
	print("  - Equipped aura:", equippedAura, "(tier", playerTier, ")")
	print("  - Can pass:", canPass)

	return canPass
end

-- Setup door access control
local function setupDoorAccess(doorPart, doorType, requiredAura, fromCell, toCell)
	local touchingPlayers = {}

	doorPart.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = game.Players:GetPlayerFromCharacter(character)

		if player and not touchingPlayers[player] then
			touchingPlayers[player] = true

			if canPassThrough(player, doorType, requiredAura) then
				if doorPart.CanCollide then
					for _, part in ipairs(character:GetDescendants()) do
						if part:IsA("BasePart") then
							local noCollision = Instance.new("NoCollisionConstraint")
							noCollision.Part0 = doorPart
							noCollision.Part1 = part
							noCollision.Parent = doorPart
						end
					end
				end
			else
				doorPart.Transparency = 0.3
				task.delay(0.5, function()
					doorPart.Transparency = 0.5
				end)
			end
		end
	end)

	doorPart.TouchEnded:Connect(function(hit)
		local character = hit.Parent
		local player = game.Players:GetPlayerFromCharacter(character)
		if player then
			touchingPlayers[player] = nil
		end
	end)
end

-- Generate doors for entire hex maze
function DoorController.GenerateDoors(mazeGrid)
	local doorsFolder = Instance.new("Folder")
	doorsFolder.Name = "Doors"
	doorsFolder.Parent = workspace

	print("[DoorController] Generating doors...")

	local doorCount = 0
	local createdEdges = {} -- track which edges already have doors to avoid duplicates

	for _, k in ipairs(mazeGrid._cells) do
		local cell = mazeGrid[k]

		-- Check first 3 directions only (E, NE, NW) to avoid creating duplicate doors
		-- Each edge is shared by two cells; checking only 3 of 6 directions covers all edges
		for i = 1, 3 do
			if not cell.walls[i] then
				local dir = DIRECTIONS[i]
				local nq, nr = cell.q + dir.q, cell.r + dir.r
				local neighborCell = getCell(mazeGrid, nq, nr)

				if neighborCell and cell.zoneType ~= neighborCell.zoneType then
					-- Determine higher tier and required aura
					local fromTier = ZoneTypes.Tier[cell.zoneType] or 1
					local toTier = ZoneTypes.Tier[neighborCell.zoneType] or 1
					local higherTierCell = toTier > fromTier and neighborCell or cell
					local requiredAura = ZoneTypes.RequiredAura[higherTierCell.zoneType]

					local doorType = cell.doorTypes and cell.doorTypes[i] or ZoneTypes.DoorType.NORMAL

					local doorPart = createDoorPart(cell, neighborCell, doorType, requiredAura)
					doorPart.Parent = doorsFolder

					setupDoorAccess(doorPart, doorType, requiredAura, cell, neighborCell)

					table.insert(activeDoors, {
						Part = doorPart,
						DoorType = doorType,
						RequiredAura = requiredAura,
					})

					doorCount = doorCount + 1
				end
			end
		end
	end

	print("[DoorController] Generated", doorCount, "doors")
end

return DoorController
