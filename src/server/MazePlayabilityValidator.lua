-- MazePlayabilityValidator.lua
-- Ensures hex maze is fully playable without dead ends or impossible situations
-- Grid uses axial coordinates (q, r) with string keys "q,r"

print("[MazePlayabilityValidator] Module loaded")

local ZoneTypes = require(game.ReplicatedStorage.ZoneTypes)

local MazePlayabilityValidator = {}

-- 6 hex directions in axial coordinates
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

-- Check if player with given aura tier can pass through a door
local function canPassDoor(fromZone, toZone, auraTier)
	if fromZone == toZone then
		return true
	end
	local requiredTier = ZoneTypes.Tier[toZone] or 1
	return auraTier >= requiredTier
end

-- BFS to find all reachable cells with given aura tier
local function findReachableCells(grid, startQ, startR, auraTier)
	local visited = {}
	local reachable = {}
	local sk = key(startQ, startR)
	visited[sk] = true
	table.insert(reachable, {q = startQ, r = startR})
	local queue = {{q = startQ, r = startR}}

	while #queue > 0 do
		local current = table.remove(queue, 1)
		local cell = getCell(grid, current.q, current.r)

		for i, dir in ipairs(DIRECTIONS) do
			if not cell.walls[i] then
				local nq, nr = current.q + dir.q, current.r + dir.r
				local nk = key(nq, nr)
				local neighbor = getCell(grid, nq, nr)

				if neighbor and not visited[nk] then
					if canPassDoor(cell.zoneType, neighbor.zoneType, auraTier) then
						visited[nk] = true
						table.insert(queue, {q = nq, r = nr})
						table.insert(reachable, {q = nq, r = nr})
					end
				end
			end
		end
	end

	return reachable
end

-- Check if all cells are reachable from start
local function validateFullConnectivity(grid)
	print("[PlayabilityValidator] Checking full connectivity...")

	local totalCells = #grid._cells
	local reachable = findReachableCells(grid, 0, 0, 3)

	if #reachable < totalCells then
		warn("[PlayabilityValidator] Not fully connected! Reachable:", #reachable, "Total:", totalCells)
		return false
	end

	print("[PlayabilityValidator] All", totalCells, "cells are reachable")
	return true
end

-- Check if player can make progress through tiers
local function validateTierProgression(grid)
	print("[PlayabilityValidator] Checking tier progression...")

	local tier0Reachable = findReachableCells(grid, 0, 0, 0)
	if #tier0Reachable == 0 then
		warn("[PlayabilityValidator] Starting cell is not reachable!")
		return false
	end
	print("[PlayabilityValidator] Tier 0 (no aura):", #tier0Reachable, "safe cell(s)")

	local tier1Reachable = findReachableCells(grid, 0, 0, 1)
	local blueCount = 0
	for _, pos in ipairs(tier1Reachable) do
		local cell = getCell(grid, pos.q, pos.r)
		if cell.zoneType == ZoneTypes.Type.BLUE then
			blueCount = blueCount + 1
		end
	end
	if #tier1Reachable <= #tier0Reachable then
		warn("[PlayabilityValidator] Blue aura doesn't expand reachable area!")
		return false
	end
	if blueCount == 0 then
		warn("[PlayabilityValidator] No blue zones reachable with blue aura!")
		return false
	end
	print("[PlayabilityValidator] Tier 1 (blue aura):", #tier1Reachable, "cells,", blueCount, "blue zones")

	local tier2Reachable = findReachableCells(grid, 0, 0, 2)
	local greenCount = 0
	for _, pos in ipairs(tier2Reachable) do
		local cell = getCell(grid, pos.q, pos.r)
		if cell.zoneType == ZoneTypes.Type.GREEN then
			greenCount = greenCount + 1
		end
	end
	if #tier2Reachable <= #tier1Reachable then
		warn("[PlayabilityValidator] Green aura doesn't expand reachable area!")
		return false
	end
	if greenCount == 0 then
		warn("[PlayabilityValidator] No green zones reachable with green aura!")
		return false
	end
	print("[PlayabilityValidator] Tier 2 (green aura):", #tier2Reachable, "cells,", greenCount, "green zones")

	local tier3Reachable = findReachableCells(grid, 0, 0, 3)
	local redCount = 0
	for _, pos in ipairs(tier3Reachable) do
		local cell = getCell(grid, pos.q, pos.r)
		if cell.zoneType == ZoneTypes.Type.RED then
			redCount = redCount + 1
		end
	end
	if #tier3Reachable <= #tier2Reachable then
		warn("[PlayabilityValidator] Red aura doesn't expand reachable area!")
		return false
	end
	if redCount == 0 then
		warn("[PlayabilityValidator] No red zones reachable with red aura!")
		return false
	end
	print("[PlayabilityValidator] Tier 3 (red aura):", #tier3Reachable, "cells,", redCount, "red zones")

	return true
end

-- Check that no cell is completely isolated
local function validateNoIsolatedCells(grid)
	print("[PlayabilityValidator] Checking for isolated cells...")

	local isolatedCount = 0

	for _, k in ipairs(grid._cells) do
		local cell = grid[k]
		local hasConnection = false
		for i = 1, 6 do
			if not cell.walls[i] then
				hasConnection = true
				break
			end
		end
		if not hasConnection then
			isolatedCount = isolatedCount + 1
			warn("[PlayabilityValidator] Cell (" .. cell.q .. "," .. cell.r .. ") is completely isolated!")
		end
	end

	if isolatedCount > 0 then
		warn("[PlayabilityValidator] Found", isolatedCount, "isolated cells")
		return false
	end

	print("[PlayabilityValidator] No isolated cells")
	return true
end

-- Check that starting position is valid
local function validateStartingPosition(grid)
	print("[PlayabilityValidator] Checking starting position...")

	local startCell = getCell(grid, 0, 0)

	if not startCell then
		warn("[PlayabilityValidator] Starting cell (0,0) does not exist!")
		return false
	end

	if startCell.zoneType ~= ZoneTypes.Type.SAFE then
		warn("[PlayabilityValidator] Starting cell is not SAFE zone! Got:", startCell.zoneType)
		return false
	end

	local hasConnection = false
	for i = 1, 6 do
		if not startCell.walls[i] then
			hasConnection = true
			break
		end
	end

	if not hasConnection then
		warn("[PlayabilityValidator] Starting cell has no connections!")
		return false
	end

	print("[PlayabilityValidator] Starting position valid (Safe zone with connections)")
	return true
end

-- Main validation function
function MazePlayabilityValidator.Validate(grid)
	print("[PlayabilityValidator] ========================================")
	print("[PlayabilityValidator] Starting maze playability validation...")
	print("[PlayabilityValidator] ========================================")

	local checks = {
		{name = "Starting Position", fn = validateStartingPosition},
		{name = "No Isolated Cells", fn = validateNoIsolatedCells},
		{name = "Full Connectivity", fn = validateFullConnectivity},
		{name = "Tier Progression", fn = validateTierProgression},
	}

	local allPassed = true

	for _, check in ipairs(checks) do
		local success = check.fn(grid)
		if not success then
			allPassed = false
			warn("[PlayabilityValidator] Failed check:", check.name)
		end
	end

	print("[PlayabilityValidator] ========================================")
	if allPassed then
		print("[PlayabilityValidator] ALL CHECKS PASSED - MAZE IS PLAYABLE")
	else
		warn("[PlayabilityValidator] VALIDATION FAILED - MAZE IS NOT PLAYABLE")
	end
	print("[PlayabilityValidator] ========================================")

	return allPassed
end

-- Get detailed playability statistics
function MazePlayabilityValidator.GetStats(grid)
	local tier0 = findReachableCells(grid, 0, 0, 0)
	local tier1 = findReachableCells(grid, 0, 0, 1)
	local tier2 = findReachableCells(grid, 0, 0, 2)
	local tier3 = findReachableCells(grid, 0, 0, 3)

	return {
		noAura = #tier0,
		blueAura = #tier1,
		greenAura = #tier2,
		redAura = #tier3,
		totalCells = #grid._cells,
	}
end

return MazePlayabilityValidator
