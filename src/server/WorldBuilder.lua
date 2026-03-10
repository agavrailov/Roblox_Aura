-- WorldBuilder.lua
-- Generates physical 3D geometry for the hex maze (floors, walls)
-- Uses axial coordinates (q, r) → world position conversion (flat-top hexagons)

local GameConfig = require(game.ReplicatedStorage.GameConfig)
local ZoneTypes = require(game.ReplicatedStorage.ZoneTypes)

local WorldBuilder = {}

local WALL_HEIGHT = 10
local WALL_THICKNESS = 1
local WALL_BARRIER_HEIGHT = 8 -- invisible extension to prevent jumping over walls

local sqrt3 = math.sqrt(3)

-- Convert axial (q, r) to world (x, z) for flat-top hexagons
local function hexToWorld(q, r)
	local size = GameConfig.ZONE_SIZE / 2 -- half-size (center to vertex)
	local x = size * (3 / 2 * q)
	local z = size * (sqrt3 / 2 * q + sqrt3 * r)
	return x, z
end

-- Get the 6 corner positions of a flat-top hex centered at (cx, cz)
-- Corners are numbered 0-5 starting from right, going counter-clockwise
local function hexCorners(cx, cz)
	local size = GameConfig.ZONE_SIZE / 2
	local corners = {}
	for i = 0, 5 do
		local angle = math.rad(60 * i)
		corners[i + 1] = {
			x = cx + size * math.cos(angle),
			z = cz + size * math.sin(angle),
		}
	end
	return corners
end

-- Create floor for a hex cell using a cylinder (6-sided approximation)
-- Roblox cylinders align along the Y axis when rotated
local function createFloor(cell)
	local cx, cz = hexToWorld(cell.q, cell.r)
	local size = GameConfig.ZONE_SIZE / 2

	local floor = Instance.new("Part")
	floor.Name = "Floor_" .. cell.q .. "_" .. cell.r
	-- Use a cylinder part rotated to be flat; approximate hex with slightly smaller circle
	floor.Shape = Enum.PartType.Cylinder
	-- Cylinder: Size.X = height (thin), Size.Y = diameter, Size.Z = diameter
	floor.Size = Vector3.new(1, size * 2 * 0.95, size * 2 * 0.95)
	floor.CFrame = CFrame.new(cx, 2.5, cz) * CFrame.Angles(0, 0, math.rad(90))
	floor.Anchored = true
	floor.Material = Enum.Material.SmoothPlastic

	-- Color based on zone type
	floor.Color = ZoneTypes.Colors[cell.zoneType] or Color3.fromRGB(150, 150, 150)

	-- Add zone label
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Right
	surfaceGui.AlwaysOnTop = false
	surfaceGui.Parent = floor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = cell.q .. "," .. cell.r
	label.TextSize = 24
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.GothamBold
	label.Parent = surfaceGui

	return floor
end

-- Create a wall segment between two world points
local function createWall(x1, z1, x2, z2)
	local midX = (x1 + x2) / 2
	local midZ = (z1 + z2) / 2
	local length = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
	local angle = math.atan2(z2 - z1, x2 - x1)

	local wall = Instance.new("Part")
	wall.Name = "Wall"
	wall.Size = Vector3.new(length, WALL_HEIGHT, WALL_THICKNESS)
	wall.CFrame = CFrame.new(midX, WALL_HEIGHT / 2, midZ) * CFrame.Angles(0, -angle, 0)
	wall.Anchored = true
	wall.Material = Enum.Material.Concrete
	wall.Color = Color3.fromRGB(60, 60, 60)

	-- Invisible barrier on top to prevent jumping over
	local barrier = Instance.new("Part")
	barrier.Name = "WallBarrier"
	barrier.Size = Vector3.new(length, WALL_BARRIER_HEIGHT, WALL_THICKNESS)
	barrier.CFrame = CFrame.new(midX, WALL_HEIGHT + WALL_BARRIER_HEIGHT / 2, midZ) * CFrame.Angles(0, -angle, 0)
	barrier.Anchored = true
	barrier.Transparency = 1
	barrier.CanCollide = true
	barrier.CanQuery = false
	barrier.CanTouch = false
	barrier.Parent = wall

	return wall
end

-- Wall edge mapping for flat-top hex:
-- Each direction's neighbor is at a specific world angle from the cell center.
-- The separating edge is perpendicular to that angle, between two adjacent corners.
-- Corner indices: 1=right(0°), 2=upper-right(60°), 3=upper-left(120°), 4=left(180°), 5=lower-left(240°), 6=lower-right(300°)
local WALL_EDGE = {
	{1, 2}, -- E:  edge at 30°, between corners at 0° and 60°
	{1, 6}, -- NE: edge at 330°, between corners at 0° and 300°
	{5, 6}, -- NW: edge at 270°, between corners at 240° and 300°
	{4, 5}, -- W:  edge at 210°, between corners at 180° and 240°
	{3, 4}, -- SW: edge at 150°, between corners at 120° and 180°
	{2, 3}, -- SE: edge at 90°, between corners at 60° and 120°
}

-- Create walls for a cell based on its wall configuration
-- createdEdges: shared set to avoid duplicate wall parts on shared hex edges
local function createWallsForCell(cell, createdEdges)
	local walls = {}
	local cx, cz = hexToWorld(cell.q, cell.r)
	local corners = hexCorners(cx, cz)

	for i = 1, 6 do
		if cell.walls[i] then
			local edge = WALL_EDGE[i]
			local c1 = corners[edge[1]]
			local c2 = corners[edge[2]]
			-- Deduplicate shared edges using rounded midpoint as key
			local mx = math.floor((c1.x + c2.x) * 10 + 0.5)
			local mz = math.floor((c1.z + c2.z) * 10 + 0.5)
			local edgeKey = mx .. "," .. mz
			if not createdEdges[edgeKey] then
				createdEdges[edgeKey] = true
				local wall = createWall(c1.x, c1.z, c2.x, c2.z)
				table.insert(walls, wall)
			end
		end
	end

	return walls
end

-- Build entire world from hex maze grid
function WorldBuilder.BuildWorld(mazeGrid)
	print("[WorldBuilder] Building physical hex world...")

	-- Create folder structure
	local worldFolder = Instance.new("Folder")
	worldFolder.Name = "MazeWorld"
	worldFolder.Parent = workspace

	local floorsFolder = Instance.new("Folder")
	floorsFolder.Name = "Floors"
	floorsFolder.Parent = worldFolder

	local wallsFolder = Instance.new("Folder")
	wallsFolder.Name = "Walls"
	wallsFolder.Parent = worldFolder

	local floorCount = 0
	local wallCount = 0
	local createdEdges = {} -- track edges to avoid duplicate wall parts

	-- Generate floors and walls for each cell
	for _, k in ipairs(mazeGrid._cells) do
		local cell = mazeGrid[k]

		-- Create floor
		local floor = createFloor(cell)
		floor.Parent = floorsFolder
		floorCount = floorCount + 1

		-- Create walls
		local walls = createWallsForCell(cell, createdEdges)
		for _, wall in ipairs(walls) do
			wall.Parent = wallsFolder
			wallCount = wallCount + 1
		end
	end

	print("[WorldBuilder] Created", floorCount, "floors and", wallCount, "walls")

	return worldFolder
end

return WorldBuilder
