-- Simple rectangular grid for zone layout
local RectGrid = {}

-- Grid configuration
RectGrid.ZONE_SIZE = 30 -- studs per zone (square)
RectGrid.GRID_WIDTH = 10 -- zones
RectGrid.GRID_HEIGHT = 10 -- zones

-- Convert world position to grid coordinates
function RectGrid.WorldToGrid(position)
	local x = math.floor(position.X / RectGrid.ZONE_SIZE)
	local z = math.floor(position.Z / RectGrid.ZONE_SIZE)
	return x, z
end

-- Convert grid coordinates to world position (center of zone)
function RectGrid.GridToWorld(x, z)
	local worldX = x * RectGrid.ZONE_SIZE + RectGrid.ZONE_SIZE / 2
	local worldZ = z * RectGrid.ZONE_SIZE + RectGrid.ZONE_SIZE / 2
	return Vector3.new(worldX, 0, worldZ)
end

-- Check if grid coordinates are valid
function RectGrid.IsValidCoord(x, z)
	return x >= 0 and x < RectGrid.GRID_WIDTH and
	       z >= 0 and z < RectGrid.GRID_HEIGHT
end

-- Get all neighbors of a zone (4-directional)
function RectGrid.GetNeighbors(x, z)
	local neighbors = {}
	local directions = {
		{1, 0}, {-1, 0}, {0, 1}, {0, -1}
	}
	
	for _, dir in ipairs(directions) do
		local nx = x + dir[1]
		local nz = z + dir[2]
		if RectGrid.IsValidCoord(nx, nz) then
			table.insert(neighbors, {x = nx, z = nz})
		end
	end
	
	return neighbors
end

-- Get perimeter zones (edge of grid)
function RectGrid.GetPerimeterZones()
	local perimeter = {}
	
	for x = 0, RectGrid.GRID_WIDTH - 1 do
		for z = 0, RectGrid.GRID_HEIGHT - 1 do
			if x == 0 or x == RectGrid.GRID_WIDTH - 1 or
			   z == 0 or z == RectGrid.GRID_HEIGHT - 1 then
				table.insert(perimeter, {x = x, z = z})
			end
		end
	end
	
	return perimeter
end

return RectGrid
