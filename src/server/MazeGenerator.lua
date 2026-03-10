-- MazeGenerator.lua
-- Generates a hexagonal maze using Recursive Backtracker algorithm + loops
-- Uses axial coordinates (q, r) with center at (0, 0)

local GameConfig = require(game.ReplicatedStorage.GameConfig)
local ZoneTypes = require(game.ReplicatedStorage.ZoneTypes)
local MazePlayabilityValidator = require(script.Parent.MazePlayabilityValidator)

print("[MazeGenerator] Module loaded with MazePlayabilityValidator integration")

local MazeGenerator = {}

-- 6 hex directions in axial coordinates (q, r)
-- Order: E, NE, NW, W, SW, SE
local DIRECTIONS = {
	{q = 1, r = 0},   -- E
	{q = 1, r = -1},  -- NE
	{q = 0, r = -1},  -- NW
	{q = -1, r = 0},  -- W
	{q = -1, r = 1},  -- SW
	{q = 0, r = 1},   -- SE
}

-- Opposite direction: index i -> i+3 (wrapped in 1-6 range)
local function oppositeDir(i)
	return ((i - 1 + 3) % 6) + 1
end

-- Grid key from axial coordinates
local function key(q, r)
	return q .. "," .. r
end

-- Check if (q, r) is inside the hex board of given radius
local function isValidHex(q, r, radius)
	return math.abs(q) <= radius and math.abs(r) <= radius and math.abs(q + r) <= radius
end

-- Create empty hex grid
local function createGrid(radius)
	local grid = {}
	local cells = {} -- ordered list of all cell keys for iteration
	for q = -radius, radius do
		for r = -radius, radius do
			if isValidHex(q, r, radius) then
				local k = key(q, r)
				grid[k] = {
					q = q,
					r = r,
					visited = false,
					walls = {true, true, true, true, true, true}, -- 6 walls
					zoneType = nil,
					doorTypes = {nil, nil, nil, nil, nil, nil},
				}
				table.insert(cells, k)
			end
		end
	end
	grid._cells = cells -- store ordered list for iteration
	return grid
end

-- Get cell at position
local function getCell(grid, q, r)
	return grid[key(q, r)]
end

-- Get unvisited neighbors
local function getUnvisitedNeighbors(grid, cell)
	local neighbors = {}
	for i, dir in ipairs(DIRECTIONS) do
		local nq, nr = cell.q + dir.q, cell.r + dir.r
		local neighbor = getCell(grid, nq, nr)
		if neighbor and not neighbor.visited then
			table.insert(neighbors, {cell = neighbor, direction = i})
		end
	end
	return neighbors
end

-- Remove wall between two cells
local function removeWall(grid, cell, direction)
	cell.walls[direction] = false
	local dir = DIRECTIONS[direction]
	local neighbor = getCell(grid, cell.q + dir.q, cell.r + dir.r)
	if neighbor then
		neighbor.walls[oppositeDir(direction)] = false
	end
end

-- Recursive Backtracker algorithm
local function carveMaze(grid)
	local stack = {}
	local current = getCell(grid, 0, 0)
	current.visited = true

	while true do
		local neighbors = getUnvisitedNeighbors(grid, current)

		if #neighbors > 0 then
			local chosen = neighbors[math.random(1, #neighbors)]
			table.insert(stack, current)
			removeWall(grid, current, chosen.direction)
			current = chosen.cell
			current.visited = true
		elseif #stack > 0 then
			current = table.remove(stack)
		else
			break
		end
	end
end

-- Add extra connections to create loops
local function addLoops(grid)
	local cells = grid._cells
	local totalWalls = #cells * 3 -- approximate internal walls (each wall shared by 2 cells)
	local loopsToAdd = math.floor(totalWalls * GameConfig.LOOP_PERCENTAGE / 100)

	local added = 0
	local attempts = 0
	local maxAttempts = loopsToAdd * 10

	while added < loopsToAdd and attempts < maxAttempts do
		attempts = attempts + 1
		local k = cells[math.random(1, #cells)]
		local cell = grid[k]
		local dir = math.random(1, 6)

		if cell.walls[dir] then
			local d = DIRECTIONS[dir]
			local neighbor = getCell(grid, cell.q + d.q, cell.r + d.r)
			if neighbor then
				removeWall(grid, cell, dir)
				added = added + 1
			end
		end
	end

	print("[MazeGenerator] Added", added, "loops to maze")
end

-- Ensure connectivity between different zone types
local function ensureZoneConnectivity(grid)
	local connectionsAdded = 0

	for _, k in ipairs(grid._cells) do
		local cell = grid[k]
		local hasConnectionToOtherZone = false

		for i, dir in ipairs(DIRECTIONS) do
			if not cell.walls[i] then
				local neighbor = getCell(grid, cell.q + dir.q, cell.r + dir.r)
				if neighbor and neighbor.zoneType ~= cell.zoneType then
					hasConnectionToOtherZone = true
					break
				end
			end
		end

		if not hasConnectionToOtherZone then
			for i, dir in ipairs(DIRECTIONS) do
				local neighbor = getCell(grid, cell.q + dir.q, cell.r + dir.r)
				if neighbor and neighbor.zoneType ~= cell.zoneType then
					removeWall(grid, cell, i)
					connectionsAdded = connectionsAdded + 1
					break
				end
			end
		end
	end

	print("[MazeGenerator] Added", connectionsAdded, "connections between different zones")
end

-- Assign zone colors based on distance from center
local function assignZoneColors(grid)
	local startCell = getCell(grid, 0, 0)

	-- BFS to calculate distances
	local distances = {}
	for _, k in ipairs(grid._cells) do
		distances[k] = math.huge
	end

	local startKey = key(0, 0)
	distances[startKey] = 0
	local queue = {{cell = startCell, dist = 0}}

	while #queue > 0 do
		local current = table.remove(queue, 1)
		local cell = current.cell
		local dist = current.dist

		for i, dir in ipairs(DIRECTIONS) do
			if not cell.walls[i] then
				local nq, nr = cell.q + dir.q, cell.r + dir.r
				local neighbor = getCell(grid, nq, nr)
				local nk = key(nq, nr)
				if neighbor and distances[nk] > dist + 1 then
					distances[nk] = dist + 1
					table.insert(queue, {cell = neighbor, dist = dist + 1})
				end
			end
		end
	end

	-- Find max distance
	local maxDist = 0
	for _, k in ipairs(grid._cells) do
		if distances[k] < math.huge and distances[k] > maxDist then
			maxDist = distances[k]
		end
	end
	if maxDist == 0 then maxDist = 1 end

	-- Starting cell is Safe zone
	startCell.zoneType = ZoneTypes.Type.SAFE

	local blueCount, greenCount, redCount = 0, 0, 0

	for _, k in ipairs(grid._cells) do
		local cell = grid[k]
		if cell.q == 0 and cell.r == 0 then
			-- Skip start cell (already assigned)
		elseif distances[k] < math.huge then
			local dist = distances[k]
			local normalizedDist = dist / maxDist
			local randomOffset = (math.random() - 0.5) * 0.2
			local adjustedDist = math.max(0, math.min(1, normalizedDist + randomOffset))

			if adjustedDist < 0.5 then
				cell.zoneType = ZoneTypes.Type.BLUE
				blueCount = blueCount + 1
			elseif adjustedDist < 0.75 then
				cell.zoneType = ZoneTypes.Type.GREEN
				greenCount = greenCount + 1
			else
				cell.zoneType = ZoneTypes.Type.RED
				redCount = redCount + 1
			end
		else
			cell.zoneType = ZoneTypes.Type.BLUE
			blueCount = blueCount + 1
		end
	end

	print("[MazeGenerator] Zone distribution - Safe: 1, Blue:", blueCount, "Green:", greenCount, "Red:", redCount)
end

-- Add escape routes from higher tier zones back to lower tier zones
local function addEscapeRoutes(grid)
	local escapeRoutesAdded = 0

	for _, k in ipairs(grid._cells) do
		local cell = grid[k]
		local cellTier = ZoneTypes.Tier[cell.zoneType] or 1

		if cellTier > 1 then
			local hasEscapeRoute = false

			for i, dir in ipairs(DIRECTIONS) do
				if not cell.walls[i] then
					local neighbor = getCell(grid, cell.q + dir.q, cell.r + dir.r)
					if neighbor then
						local neighborTier = ZoneTypes.Tier[neighbor.zoneType] or 1
						if neighborTier < cellTier then
							hasEscapeRoute = true
							break
						end
					end
				end
			end

			if not hasEscapeRoute then
				for i, dir in ipairs(DIRECTIONS) do
					local neighbor = getCell(grid, cell.q + dir.q, cell.r + dir.r)
					if neighbor then
						local neighborTier = ZoneTypes.Tier[neighbor.zoneType] or 1
						if neighborTier < cellTier then
							removeWall(grid, cell, i)
							cell.doorTypes[i] = ZoneTypes.DoorType.ESCAPE
							escapeRoutesAdded = escapeRoutesAdded + 1
							break
						end
					end
				end
			end
		end
	end

	print("[MazeGenerator] Added", escapeRoutesAdded, "escape routes")
end

-- Add alternate paths (free routes) to create more options
local function addAlternatePaths(grid)
	local cells = grid._cells
	local alternatePathsToAdd = math.max(1, math.floor(#cells * 0.05))
	local added = 0
	local attempts = 0
	local maxAttempts = alternatePathsToAdd * 10

	while added < alternatePathsToAdd and attempts < maxAttempts do
		attempts = attempts + 1
		local k = cells[math.random(1, #cells)]
		local cell = grid[k]
		local dir = math.random(1, 6)
		local d = DIRECTIONS[dir]
		local neighbor = getCell(grid, cell.q + d.q, cell.r + d.r)

		if neighbor and cell.zoneType ~= neighbor.zoneType then
			if cell.walls[dir] then
				removeWall(grid, cell, dir)
				cell.doorTypes[dir] = ZoneTypes.DoorType.ALTERNATE
				added = added + 1
			elseif not cell.doorTypes[dir] then
				cell.doorTypes[dir] = ZoneTypes.DoorType.ALTERNATE
				added = added + 1
			end
		end
	end

	print("[MazeGenerator] Added", added, "alternate paths")
end

local MAX_GENERATION_RETRIES = 10

-- Generate complete maze
function MazeGenerator.Generate(attempt)
	attempt = attempt or 1
	print("[MazeGenerator] Generating hex maze (attempt " .. attempt .. "/" .. MAX_GENERATION_RETRIES .. ")...")

	local radius = GameConfig.HEX_RADIUS
	local grid = createGrid(radius)

	-- Step 1: Carve maze using Recursive Backtracker
	carveMaze(grid)

	-- Step 2: Add loops for multiple paths
	addLoops(grid)

	-- Step 3: Assign zone colors based on distance
	assignZoneColors(grid)

	-- Step 4: Ensure every cell has connection to different zone
	ensureZoneConnectivity(grid)

	-- Step 5: Add escape routes for higher tier zones
	addEscapeRoutes(grid)

	-- Step 6: Add alternate paths (free routes)
	addAlternatePaths(grid)

	-- Step 7: Validate maze playability
	local isPlayable = MazePlayabilityValidator.Validate(grid)
	if not isPlayable then
		if attempt >= MAX_GENERATION_RETRIES then
			warn("[MazeGenerator] Failed after " .. MAX_GENERATION_RETRIES .. " attempts, using last generated maze")
		else
			warn("[MazeGenerator] Maze failed playability validation, regenerating...")
			return MazeGenerator.Generate(attempt + 1)
		end
	end

	-- Get and display stats
	local stats = MazePlayabilityValidator.GetStats(grid)
	print("[MazeGenerator] ========================================")
	print("[MazeGenerator] Maze generation complete!")
	print("[MazeGenerator] Reachable zones by tier:")
	print("[MazeGenerator]   No aura:", stats.noAura, "zones")
	print("[MazeGenerator]   Blue aura:", stats.blueAura, "zones")
	print("[MazeGenerator]   Green aura:", stats.greenAura, "zones")
	print("[MazeGenerator]   Red aura:", stats.redAura, "/", stats.totalCells, "zones")
	print("[MazeGenerator] ========================================")
	return grid
end

return MazeGenerator
