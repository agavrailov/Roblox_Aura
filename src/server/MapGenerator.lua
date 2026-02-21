-- Generates rectangular grid map with zones
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RectGrid = require(ReplicatedStorage.RectGrid)
local ZoneConfig = require(ReplicatedStorage.ZoneConfig)

local MapGenerator = {}

-- Assign zone type randomly
local function AssignZoneType(x, z)
	local rand = math.random(1, 100)
	
	if rand <= 20 then
		return "Green"
	elseif rand <= 50 then
		return "Blue"
	else
		return "Red"
	end
end

-- Create barrier walls around zone with 1-2 openings
local function CreateZoneBarriers(x, z, zoneType, parent)
	local position = RectGrid.GridToWorld(x, z)
	local size = RectGrid.ZONE_SIZE
	local wallHeight = 8
	local wallThickness = 1
	
	-- Determine which sides have openings (1 or 2 random sides)
	local numOpenings = math.random(1, 2)
	local sides = {"North", "South", "East", "West"}
	local openings = {}
	
	for i = 1, numOpenings do
		local idx = math.random(1, #sides)
		openings[sides[idx]] = true
		table.remove(sides, idx)
	end
	
	local barriers = {}
	
	-- North wall
	if not openings.North then
		local wall = Instance.new("Part")
		wall.Size = Vector3.new(size, wallHeight, wallThickness)
		wall.Position = position + Vector3.new(0, wallHeight/2, -size/2)
		wall.Anchored = true
		wall.Color = Color3.fromRGB(100, 100, 100)
		wall.Transparency = 0.3
		wall.Name = "Barrier_North"
		wall.Parent = parent
		table.insert(barriers, wall)
	end
	
	-- South wall
	if not openings.South then
		local wall = Instance.new("Part")
		wall.Size = Vector3.new(size, wallHeight, wallThickness)
		wall.Position = position + Vector3.new(0, wallHeight/2, size/2)
		wall.Anchored = true
		wall.Color = Color3.fromRGB(100, 100, 100)
		wall.Transparency = 0.3
		wall.Name = "Barrier_South"
		wall.Parent = parent
		table.insert(barriers, wall)
	end
	
	-- East wall
	if not openings.East then
		local wall = Instance.new("Part")
		wall.Size = Vector3.new(wallThickness, wallHeight, size)
		wall.Position = position + Vector3.new(size/2, wallHeight/2, 0)
		wall.Anchored = true
		wall.Color = Color3.fromRGB(100, 100, 100)
		wall.Transparency = 0.3
		wall.Name = "Barrier_East"
		wall.Parent = parent
		table.insert(barriers, wall)
	end
	
	-- West wall
	if not openings.West then
		local wall = Instance.new("Part")
		wall.Size = Vector3.new(wallThickness, wallHeight, size)
		wall.Position = position + Vector3.new(-size/2, wallHeight/2, 0)
		wall.Anchored = true
		wall.Color = Color3.fromRGB(100, 100, 100)
		wall.Transparency = 0.3
		wall.Name = "Barrier_West"
		wall.Parent = parent
		table.insert(barriers, wall)
	end
	
	return barriers
end

-- Create visual zone part
local function CreateZonePart(x, z, zoneType, parent)
	local position = RectGrid.GridToWorld(x, z)
	local zoneInfo = ZoneConfig.ZoneTypes[zoneType]
	
	local part = Instance.new("Part")
	part.Size = Vector3.new(RectGrid.ZONE_SIZE, 1, RectGrid.ZONE_SIZE)
	part.Position = position
	part.Anchored = true
	part.Color = zoneInfo.Color
	part.Material = Enum.Material.SmoothPlastic
	part.Name = string.format("Zone_%d_%d", x, z)
	part.Transparency = 0.3
	part.CanCollide = false
	part.Parent = parent
	
	return part
end

-- Generate entire map
function MapGenerator.Generate(parent)
	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "ZoneMap"
	mapFolder.Parent = parent
	
	local zones = {}
	
	for x = 0, RectGrid.GRID_WIDTH - 1 do
		for z = 0, RectGrid.GRID_HEIGHT - 1 do
			local zoneType = AssignZoneType(x, z)
			local part = CreateZonePart(x, z, zoneType, mapFolder)
			local barriers = CreateZoneBarriers(x, z, zoneType, mapFolder)
			
			table.insert(zones, {
				GridX = x,
				GridZ = z,
				Type = zoneType,
				Part = part,
				Barriers = barriers,
				Position = RectGrid.GridToWorld(x, z)
			})
		end
	end
	
	print(string.format("Generated %d zones (%dx%d grid)", 
		#zones, RectGrid.GRID_WIDTH, RectGrid.GRID_HEIGHT))
	
	return zones, mapFolder
end

return MapGenerator
