-- PathValidator.lua
-- Validates that maze has minimum path length and adjusts if needed

print("[PathValidator] Module loaded")

local PathValidator = {}

local DIRECTIONS = {
	{x = 0, y = -1}, -- North
	{x = 1, y = 0},  -- East
	{x = 0, y = 1},  -- South
	{x = -1, y = 0}, -- West
}

-- Get cell at position
local function getCell(grid, x, y)
	if y >= 1 and y <= #grid and x >= 1 and x <= #grid[1] then
		return grid[y][x]
	end
	return nil
end

-- BFS to find shortest path length
local function findShortestPath(grid, startX, startY, endX, endY)
	local size = #grid
	local visited = {}
	for y = 1, size do
		visited[y] = {}
		for x = 1, size do
			visited[y][x] = false
		end
	end
	
	local queue = {{x = startX, y = startY, dist = 1}}
	visited[startY][startX] = true
	
	while #queue > 0 do
		local current = table.remove(queue, 1)
		
		-- Check if we reached the end
		if current.x == endX and current.y == endY then
			return current.dist
		end
		
		local cell = grid[current.y][current.x]
		
		-- Check all 4 directions
		for i, dir in ipairs(DIRECTIONS) do
			if not cell.walls[i] then -- If there's no wall
				local nx, ny = current.x + dir.x, current.y + dir.y
				local neighbor = getCell(grid, nx, ny)
				if neighbor and not visited[ny][nx] then
					visited[ny][nx] = true
					table.insert(queue, {x = nx, y = ny, dist = current.dist + 1})
				end
			end
		end
	end
	
	return math.huge -- No path found
end

-- Find the cell farthest from start
local function findFarthestCell(grid, startX, startY)
	local size = #grid
	local distances = {}
	for y = 1, size do
		distances[y] = {}
		for x = 1, size do
			distances[y][x] = math.huge
		end
	end
	
	local queue = {{x = startX, y = startY, dist = 1}}
	distances[startY][startX] = 1
	
	local maxDist = 1
	local farthestCell = {x = startX, y = startY}
	
	while #queue > 0 do
		local current = table.remove(queue, 1)
		local cell = grid[current.y][current.x]
		
		if current.dist > maxDist then
			maxDist = current.dist
			farthestCell = {x = current.x, y = current.y}
		end
		
		-- Check all 4 directions
		for i, dir in ipairs(DIRECTIONS) do
			if not cell.walls[i] then
				local nx, ny = current.x + dir.x, current.y + dir.y
				local neighbor = getCell(grid, nx, ny)
				if neighbor and distances[ny][nx] > current.dist + 1 then
					distances[ny][nx] = current.dist + 1
					table.insert(queue, {x = nx, y = ny, dist = current.dist + 1})
				end
			end
		end
	end
	
	return farthestCell, maxDist
end

-- Close walls to increase path length
local function closeWalls(grid, targetLength)
	local size = #grid
	local closed = 0
	local attempts = 0
	local maxAttempts = size * size * 4
	
	while attempts < maxAttempts do
		attempts = attempts + 1
		
		-- Pick random cell and direction
		local x = math.random(1, size)
		local y = math.random(1, size)
		local dir = math.random(1, 4)
		
		local cell = grid[y][x]
		
		-- Only process if wall doesn't exist and neighbor is valid
		if not cell.walls[dir] then
			local dirVec = DIRECTIONS[dir]
			local nx, ny = x + dirVec.x, y + dirVec.y
			local neighbor = getCell(grid, nx, ny)
			
			if neighbor then
				-- Temporarily close this wall
				cell.walls[dir] = true
				
				-- Get opposite direction
				local oppositeDir = ((dir + 1) % 4) + 1
				if dir == 1 then oppositeDir = 3 end -- North -> South
				if dir == 2 then oppositeDir = 4 end -- East -> West
				if dir == 3 then oppositeDir = 1 end -- South -> North
				if dir == 4 then oppositeDir = 2 end -- West -> East
				neighbor.walls[oppositeDir] = true
				
				-- Check if path still exists and if length increased
				local farthest, maxDist = findFarthestCell(grid, 1, 1)
				local pathLength = findShortestPath(grid, 1, 1, farthest.x, farthest.y)
				
				if pathLength >= targetLength and pathLength < math.huge then
					-- Good! Keep this wall closed
					closed = closed + 1
					print("[PathValidator] Closed wall at (" .. x .. "," .. y .. ") dir=" .. dir .. ", path now: " .. pathLength)
					
					if pathLength >= targetLength then
						return true, pathLength
					end
				else
					-- Revert - this breaks connectivity or doesn't help
					cell.walls[dir] = false
					neighbor.walls[oppositeDir] = false
				end
			end
		end
	end
	
	return false, 0
end

-- Validate and adjust maze to ensure minimum path length
function PathValidator.ValidateAndAdjust(grid, minPathLength)
	print("[PathValidator] ========================================")
	print("[PathValidator] Starting path validation...")
	print("[PathValidator] Required minimum: " .. minPathLength .. " zones")
	print("[PathValidator] ========================================")
	
	local size = #grid
	
	-- Step 1: Find farthest cell from start (1,1)
	local farthest, maxDist = findFarthestCell(grid, 1, 1)
	print("[PathValidator] Farthest cell: (" .. farthest.x .. "," .. farthest.y .. ")")
	
	-- Step 2: Find shortest path to farthest cell
	local shortestPath = findShortestPath(grid, 1, 1, farthest.x, farthest.y)
	print("[PathValidator] Shortest path: " .. shortestPath .. " zones")
	
	-- Step 3: Check if path meets minimum requirement
	if shortestPath >= minPathLength then
		print("[PathValidator] ========================================")
		print("[PathValidator] ✓ VALIDATION SUCCESSFUL")
		print("[PathValidator] Path length: " .. shortestPath .. " zones (>= " .. minPathLength .. ")")
		print("[PathValidator] ========================================")
		return true, shortestPath
	end
	
	print("[PathValidator] ----------------------------------------")
	print("[PathValidator] ✗ Path too short: " .. shortestPath .. " < " .. minPathLength)
	print("[PathValidator] Adjusting maze by closing walls...")
	print("[PathValidator] ----------------------------------------")
	
	-- Step 4: Try to increase path length by closing walls
	local success, newLength = closeWalls(grid, minPathLength)
	
	if success then
		print("[PathValidator] ========================================")
		print("[PathValidator] ✓ VALIDATION SUCCESSFUL (adjusted)")
		print("[PathValidator] Final path length: " .. newLength .. " zones")
		print("[PathValidator] ========================================")
		return true, newLength
	else
		print("[PathValidator] ========================================")
		warn("[PathValidator] ✗ VALIDATION FAILED")
		warn("[PathValidator] Could not reach minimum: " .. minPathLength)
		warn("[PathValidator] Current: " .. shortestPath .. " zones")
		print("[PathValidator] ========================================")
		return false, shortestPath
	end
end

-- Get path statistics
function PathValidator.GetPathStats(grid)
	local farthest, maxDist = findFarthestCell(grid, 1, 1)
	local shortestPath = findShortestPath(grid, 1, 1, farthest.x, farthest.y)
	
	return {
		farthestCell = farthest,
		maxDistance = maxDist,
		shortestPath = shortestPath
	}
end

return PathValidator
