-- RelicManager.lua
-- Manages the 3 Prismatic Keys (relics) that players need to collect for Rebirth

local RunService = game:GetService("RunService")
local GameConfig = require(game.ReplicatedStorage.GameConfig)
local ZoneTypes = require(game.ReplicatedStorage.ZoneTypes)

local CollectRelicEvent = game.ReplicatedStorage.CollectRelic

local RelicManager = {}

-- Track which players have collected which relics
local playerRelics = {} -- [UserId] = {Blue = bool, Green = bool, Red = bool}

local sqrt3 = math.sqrt(3)

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

-- Relic definitions
local RelicTypes = {
	Blue = {
		Name = "Blue Prismatic Key",
		Color = Color3.fromRGB(100, 150, 255),
		RequiredZoneType = ZoneTypes.Type.BLUE,
	},
	Green = {
		Name = "Green Prismatic Key",
		Color = Color3.fromRGB(100, 255, 150),
		RequiredZoneType = ZoneTypes.Type.GREEN,
	},
	Red = {
		Name = "Red Prismatic Key",
		Color = Color3.fromRGB(255, 100, 100),
		RequiredZoneType = ZoneTypes.Type.RED,
	},
}

-- Find dead-end cells (cells with only 1 open connection)
-- For hex grid: a dead end has 5 walls (only 1 opening out of 6)
local function findDeadEnds(mazeGrid)
	local deadEnds = {
		[ZoneTypes.Type.BLUE] = {},
		[ZoneTypes.Type.GREEN] = {},
		[ZoneTypes.Type.RED] = {},
	}
	
	for _, k in ipairs(mazeGrid._cells) do
		local cell = mazeGrid[k]
		
		-- Count walls (a dead end has 5 walls in hex grid)
		local wallCount = 0
		for _, hasWall in ipairs(cell.walls) do
			if hasWall then
				wallCount = wallCount + 1
			end
		end
		
		if wallCount == 5 then
			local zoneType = cell.zoneType
			if deadEnds[zoneType] then
				table.insert(deadEnds[zoneType], cell)
			end
		end
	end
	
	return deadEnds
end

-- Find the farthest cell from center in a zone type
-- Uses hex distance: max(|q|, |r|, |q+r|)
local function findFarthestCell(mazeGrid, zoneType)
	local farthestCell = nil
	local maxDistance = -1
	
	for _, k in ipairs(mazeGrid._cells) do
		local cell = mazeGrid[k]
		if cell.zoneType == zoneType then
			local distance = math.max(math.abs(cell.q), math.abs(cell.r), math.abs(cell.q + cell.r))
			if distance > maxDistance then
				maxDistance = distance
				farthestCell = cell
			end
		end
	end
	
	return farthestCell
end

-- Create a relic visual object
local function createRelicPart(relicType, position)
	local color = RelicTypes[relicType].Color

	local relic = Instance.new("Part")
	relic.Name = relicType .. "Relic"
	relic.Shape = Enum.PartType.Ball
	relic.Size = Vector3.new(5, 5, 5)
	relic.Position = position + Vector3.new(0, 3, 0) -- raise above ground
	relic.Anchored = true
	relic.CanCollide = false
	relic.Material = Enum.Material.Neon
	relic.Color = color
	relic.Transparency = 0.2

	-- Bobbing animation
	local TweenService = game:GetService("TweenService")
	local bobTween = TweenService:Create(
		relic,
		TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Position = relic.Position + Vector3.new(0, 2, 0)}
	)
	bobTween:Play()

	-- Add spinning animation
	local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
	bodyAngularVelocity.AngularVelocity = Vector3.new(0, 2, 0)
	bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
	bodyAngularVelocity.P = 1000
	bodyAngularVelocity.Parent = relic

	-- Add particle effect
	local particle = Instance.new("ParticleEmitter")
	particle.Color = ColorSequence.new(color)
	particle.Size = NumberSequence.new(1)
	particle.Lifetime = NumberRange.new(1, 2)
	particle.Rate = 60
	particle.Speed = NumberRange.new(5)
	particle.SpreadAngle = Vector2.new(180, 180)
	particle.Parent = relic

	-- Add light (brighter, larger range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 4
	light.Range = 40
	light.Parent = relic

	-- Vertical beam pillar (visible from across the maze)
	local beam = Instance.new("Part")
	beam.Name = relicType .. "Beam"
	beam.Size = Vector3.new(1, 80, 1)
	beam.Position = relic.Position + Vector3.new(0, 40, 0)
	beam.Anchored = true
	beam.CanCollide = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Transparency = 0.6
	beam.Parent = relic

	-- Billboard label (readable from distance)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 150
	billboard.Parent = relic

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = RelicTypes[relicType].Name
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	return relic
end

-- Spawn relics in the maze
function RelicManager.SpawnRelics(mazeGrid)
	print("[RelicManager] Spawning relics...")
	
	local relicsFolder = Instance.new("Folder")
	relicsFolder.Name = "Relics"
	relicsFolder.Parent = workspace
	
	-- Find dead ends for each zone type
	local deadEnds = findDeadEnds(mazeGrid)
	
	-- Spawn Blue Relic (in a Blue dead end)
	local blueDeadEnds = deadEnds[ZoneTypes.Type.BLUE]
	if #blueDeadEnds > 0 then
		-- Choose the farthest blue dead end from center
		local farthestBlue = blueDeadEnds[1]
		local maxDist = 0
		for _, cell in ipairs(blueDeadEnds) do
			local dist = math.max(math.abs(cell.q), math.abs(cell.r), math.abs(cell.q + cell.r))
			if dist > maxDist then
				maxDist = dist
				farthestBlue = cell
			end
		end
		
		local wx, wz = hexToWorld(farthestBlue.q, farthestBlue.r)
		local blueRelic = createRelicPart("Blue", Vector3.new(wx, 3, wz))
		blueRelic.Parent = relicsFolder
		
		print("[RelicManager] Spawned Blue Relic at zone", farthestBlue.q, farthestBlue.r)
	else
		warn("[RelicManager] No Blue dead ends found, using farthest Blue zone")
		local cell = findFarthestCell(mazeGrid, ZoneTypes.Type.BLUE)
		if cell then
			local wx, wz = hexToWorld(cell.q, cell.r)
			local blueRelic = createRelicPart("Blue", Vector3.new(wx, 3, wz))
			blueRelic.Parent = relicsFolder
		end
	end
	
	-- Spawn Green Relic
	local greenDeadEnds = deadEnds[ZoneTypes.Type.GREEN]
	if #greenDeadEnds > 0 then
		local farthestGreen = greenDeadEnds[1]
		local maxDist = 0
		for _, cell in ipairs(greenDeadEnds) do
			local dist = math.max(math.abs(cell.q), math.abs(cell.r), math.abs(cell.q + cell.r))
			if dist > maxDist then
				maxDist = dist
				farthestGreen = cell
			end
		end
		
		local wx, wz = hexToWorld(farthestGreen.q, farthestGreen.r)
		local greenRelic = createRelicPart("Green", Vector3.new(wx, 3, wz))
		greenRelic.Parent = relicsFolder
		
		print("[RelicManager] Spawned Green Relic at zone", farthestGreen.q, farthestGreen.r)
	else
		local cell = findFarthestCell(mazeGrid, ZoneTypes.Type.GREEN)
		if cell then
			local wx, wz = hexToWorld(cell.q, cell.r)
			local greenRelic = createRelicPart("Green", Vector3.new(wx, 3, wz))
			greenRelic.Parent = relicsFolder
		end
	end
	
	-- Spawn Red Relic (deepest point)
	local redDeadEnds = deadEnds[ZoneTypes.Type.RED]
	if #redDeadEnds > 0 then
		local farthestRed = redDeadEnds[1]
		local maxDist = 0
		for _, cell in ipairs(redDeadEnds) do
			local dist = math.max(math.abs(cell.q), math.abs(cell.r), math.abs(cell.q + cell.r))
			if dist > maxDist then
				maxDist = dist
				farthestRed = cell
			end
		end
		
		local wx, wz = hexToWorld(farthestRed.q, farthestRed.r)
		local redRelic = createRelicPart("Red", Vector3.new(wx, 3, wz))
		redRelic.Parent = relicsFolder
		
		print("[RelicManager] Spawned Red Relic at zone", farthestRed.q, farthestRed.r)
	else
		local cell = findFarthestCell(mazeGrid, ZoneTypes.Type.RED)
		if cell then
			local wx, wz = hexToWorld(cell.q, cell.r)
			local redRelic = createRelicPart("Red", Vector3.new(wx, 3, wz))
			redRelic.Parent = relicsFolder
		end
	end
	
	-- Proximity-based collection (more reliable than .Touched for anchored parts)
	local COLLECT_DISTANCE = 8
	local collected = {} -- [UserId..relicType] = true

	RunService.Heartbeat:Connect(function()
		for _, relic in ipairs(relicsFolder:GetChildren()) do
			local relicType = relic.Name:match("(%w+)Relic")
			if not relicType then continue end

			for _, player in ipairs(game.Players:GetPlayers()) do
				local character = player.Character
				if not character then continue end
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if not rootPart then continue end

				local dKey = player.UserId .. relicType
				if collected[dKey] then continue end

				local dist = (rootPart.Position - relic.Position).Magnitude
				if dist <= COLLECT_DISTANCE then
					collected[dKey] = true
					RelicManager.CollectRelic(player, relicType)
				end
			end
		end
	end)

	print("[RelicManager] All relics spawned with proximity detection")
end

-- Initialize player relic data
function RelicManager.InitializePlayer(player)
	playerRelics[player.UserId] = {
		Blue = false,
		Green = false,
		Red = false,
	}
end

-- Collect a relic (per-player)
function RelicManager.CollectRelic(player, relicType)
	local userId = player.UserId
	
	if not playerRelics[userId] then
		RelicManager.InitializePlayer(player)
	end
	
	-- Check if already collected
	if playerRelics[userId][relicType] then
		print("[RelicManager]", player.Name, "already has", relicType, "relic")
		return
	end
	
	-- Collect relic
	playerRelics[userId][relicType] = true
	
	print("[RelicManager]", player.Name, "collected", relicType, "relic!")
	
	-- Notify client
	CollectRelicEvent:FireClient(player, relicType)
	
	-- Check if player has all 3 relics
	if playerRelics[userId].Blue and playerRelics[userId].Green and playerRelics[userId].Red then
		print("[RelicManager]", player.Name, "has collected ALL relics!")
		-- TODO: Enable rebirth portal access
	end
end

-- Get player's collected relics
function RelicManager.GetPlayerRelics(player)
	return playerRelics[player.UserId] or {Blue = false, Green = false, Red = false}
end

-- Reset player's relics (for rebirth)
function RelicManager.ResetPlayerRelics(player)
	if playerRelics[player.UserId] then
		playerRelics[player.UserId] = {
			Blue = false,
			Green = false,
			Red = false,
		}
	end
end

-- Cleanup on player leave
game.Players.PlayerRemoving:Connect(function(player)
	playerRelics[player.UserId] = nil
end)

return RelicManager
