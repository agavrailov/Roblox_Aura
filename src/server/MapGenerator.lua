--!strict
-- MapGenerator.lua
-- Generates a hexagonal maze map.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConfig = require(ReplicatedStorage.ZoneConfig)
local PhysicsService = game:GetService("PhysicsService")

local MapGenerator = {}

local HEX_SIZE = ZoneConfig.Map.HexagonSize
local WALL_THICKNESS = ZoneConfig.Map.WallThickness
local WALL_HEIGHT = ZoneConfig.Map.WallHeight
local TOTAL_ZONES = ZoneConfig.Map.TotalZones

local HEX_WIDTH = math.sqrt(3) * HEX_SIZE
local HEX_HEIGHT = 2 * HEX_SIZE

local zones = {}
local walls = {}

-- Collision Groups
local WALL_GROUP = "ZoneWalls"
local PLAYER_GROUP = "Players"

local function setupCollisionGroups()
	-- Register groups if they don't exist
	local existingGroups = {}
	for _, group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
		existingGroups[group.name] = true
	end

	if not existingGroups[WALL_GROUP] then
		pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, WALL_GROUP)
	end
	if not existingGroups[PLAYER_GROUP] then
		pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, PLAYER_GROUP)
	end

	-- Set all aura-based collision groups
	for i = 1, 10 do -- Assuming 10 tiers of auras
		local groupName = "PlayerAura" .. i
		if not existingGroups[groupName] then
			pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, groupName)
		end
		-- Players with a certain aura should not collide with walls of the same or lower tier
		for j = 1, i do
			local wallGroupName = "WallAura" .. j
			if not existingGroups[wallGroupName] then
				pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, wallGroupName)
			end
			PhysicsService:CollisionGroupSetCollidable(groupName, wallGroupName, false)
		end
	end
end

local function getHexCenter(q, r)
	local x = HEX_SIZE * (math.sqrt(3) * q + math.sqrt(3) / 2 * r)
	local z = HEX_SIZE * (3 / 2 * r)
	return Vector3.new(x, 0, z)
end

local function createHexPlatform(position, zoneId)
	local hexFolder = Instance.new("Folder")
	hexFolder.Name = "Zone_" .. zoneId
	hexFolder.Parent = workspace.GeneratedMap

	for i = 1, 6 do
		local wedge = Instance.new("WedgePart")
		wedge.Name = "HexWedge" .. i
		wedge.Size = Vector3.new(1, HEX_SIZE, HEX_WIDTH / 2)
		wedge.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(60 * i), 0) * CFrame.new(0, 0, HEX_WIDTH / 4)
		wedge.Anchored = true
		wedge.Color = Color3.fromHSV(zoneId / TOTAL_ZONES, 0.8, 0.9)
		wedge.Material = Enum.Material.Grass
		wedge.TopSurface = Enum.SurfaceType.Smooth
		wedge.BottomSurface = Enum.SurfaceType.Smooth
		wedge.Parent = hexFolder
	end
	
	return hexFolder
end

local function createWall(position, angle, zoneId, requiredAuraTier)
	local wall = Instance.new("Part")
	wall.Name = "Wall"
	wall.Size = Vector3.new(HEX_SIZE, WALL_HEIGHT, WALL_THICKNESS)
	wall.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(angle), 0)
	wall.Anchored = true
	wall.Color = Color3.fromRGB(100, 100, 100)
	wall.Material = Enum.Material.Metal
	
	local wallGroupName = "WallAura" .. requiredAuraTier
	wall.CollisionGroup = wallGroupName
	
	return wall
end

local function getNeighbors(q, r)
	local neighbors = {}
	local directions = {
		{1, 0}, {0, 1}, {-1, 1},
		{-1, 0}, {0, -1}, {1, -1}
	}
	for _, dir in ipairs(directions) do
		table.insert(neighbors, {q + dir[1], r + dir[2]})
	end
	return neighbors
end

function MapGenerator.generateMap()
	print("Starting map generation...")
	setupCollisionGroups()

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "GeneratedMap"
	mapFolder.Parent = workspace

	local grid = {}
	local visited = {}
	local stack = {}

	-- 1. Create the grid of zones
	local zoneId = 1
	for q = -5, 5 do
		for r = -5, 5 do
			if zoneId <= TOTAL_ZONES then
				grid[q .. "," .. r] = {q = q, r = r, id = zoneId, neighbors = {}}
				zoneId += 1
			end
		end
	end
	print("Total zones in grid: " .. zoneId - 1)

	-- 2. Maze generation using Randomized DFS
	local startNode = grid["0,0"]
	table.insert(stack, startNode)
	visited[startNode.id] = true

	while #stack > 0 do
		local current = stack[#stack]
		local unvisitedNeighbors = {}
		
		for _, neighborCoords in ipairs(getNeighbors(current.q, current.r)) do
			local key = neighborCoords[1] .. "," .. neighborCoords[2]
			if grid[key] and not visited[grid[key].id] then
				table.insert(unvisitedNeighbors, grid[key])
			end
		end

		if #unvisitedNeighbors > 0 then
			local nextNode = unvisitedNeighbors[math.random(1, #unvisitedNeighbors)]
			
			-- Remove wall between current and next
			print("Connecting zone " .. current.id .. " and zone " .. nextNode.id)
			table.insert(current.neighbors, nextNode)
			table.insert(nextNode.neighbors, current)
			
			visited[nextNode.id] = true
			table.insert(stack, nextNode)
		else
			table.remove(stack)
		end
	end

	-- 3. Create the visual representation
	print("Creating visual representation of the map...")
	local firstZonePos = nil
	for key, node in pairs(grid) do
		local pos = getHexCenter(node.q, node.r)
		if not firstZonePos then
			firstZonePos = pos
		end
		local hexPlatform = createHexPlatform(pos, node.id)
		hexPlatform.Parent = mapFolder
		zones[node.id] = hexPlatform

		local allNeighbors = getNeighbors(node.q, node.r)
		for i, neighborCoords in ipairs(allNeighbors) do
			local neighborKey = neighborCoords[1] .. "," .. neighborCoords[2]
			local isConnected = false
			for _, connectedNeighbor in ipairs(node.neighbors) do
				if connectedNeighbor.q == neighborCoords[1] and connectedNeighbor.r == neighborCoords[2] then
					isConnected = true
					break
				end
			end

			if not isConnected then
				local angle = 60 * (i - 1) + 30
				local wallPos = pos + Vector3.new(
					HEX_WIDTH / 2 * math.cos(math.rad(angle)),
					WALL_HEIGHT / 2,
					HEX_WIDTH / 2 * math.sin(math.rad(angle))
				)
				
				-- Assign a required aura tier to the wall (e.g., based on zoneId)
				local requiredAuraTier = math.ceil(node.id / 10) -- Example: 10 zones per tier
				local wall = createWall(wallPos, angle, node.id, requiredAuraTier)
				wall.Parent = mapFolder
				table.insert(walls, wall)
			end
		end
	end
	print("Map generation complete. First zone position: " .. tostring(firstZonePos))
end

return MapGenerator
