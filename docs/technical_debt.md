# Technical Debt

## Project Restart - 2026-02-21
Project restarted from scratch following Game Design Document.md specification.
Old codebase removed, starting fresh implementation.

## Current Issues

### Deprecated PathValidator Module
**Status:** Can be safely deleted

**Description:** `src/server/PathValidator.lua` is no longer used. It has been replaced by `MazePlayabilityValidator.lua` which provides better validation based on actual game mechanics.

**Action Required:** Delete the file when confirmed the new system works correctly.

## Resolved Issues

### ✅ Maze Validation System Redesign - 2026-02-24
**Issue:** PathValidator tried to enforce impossible 100-zone minimum path in 10x10 grid, causing infinite regeneration loops, timeouts, and didn't validate actual playability.

**Root Cause:** 
- Structurally impossible to have 100-zone shortest path in 10x10 grid with loops
- Wall-closing algorithm was inefficient and timeout-prone
- Didn't check if players could actually progress through Blue → Green → Red tiers
- Didn't detect dead ends that could trap players

**Solution:** 
- Created new `MazePlayabilityValidator` that validates actual game mechanics
- Validates 5 critical aspects: starting position, isolated cells, connectivity, tier progression, and dead end traps
- Uses fast BFS to simulate player movement with different aura tiers
- Non-destructive validation (only reads maze, doesn't modify)
- Removed obsolete MIN_PATH_LENGTH config

**Impact:** 
- Maze generation should succeed on first or second attempt
- No more infinite regeneration loops or timeouts
- Clear validation output showing exactly what's being checked
- Guarantees playable mazes that support proper progression

**Documentation:** See `docs/maze_validation.md` and `docs/VALIDATION_SYSTEM_CHANGES.md`

### ✅ Door Collision Bug - 2026-02-21
**Issue:** Doors were being created for every passage in the maze, including passages within same-tier zones, making navigation impossible.

**Root Cause:** DoorController was creating doors wherever `not cell.walls[X]` without checking if the zones were different tiers.

**Solution:** Added tier comparison check - doors are now only created when `fromTier ~= toTier`, allowing free movement within same-colored zones.

**Impact:** Players can now move freely within Blue/Green/Red zones and only encounter doors at tier boundaries.

### ✅ removeWall One-Sided Bug - 2026-03-10
**Issue:** `removeWall(cell1, direction)` called `getCell(cell1, x, y)` where `cell1` is a cell object, not the grid. Since `#cell1` is 0 (no integer keys), `getCell` always returned nil, so the opposite wall on the neighbor was never removed. Every carved passage was only open from one side.

**Impact:** `WorldBuilder` creates wall parts per-cell. Even though cell A's east wall was removed, cell B's west wall (same physical boundary) was still present, blocking all movement. Players couldn't advance a single cell.

**Solution:** Changed `removeWall(cell1, direction)` → `removeWall(grid, cell1, direction)` and updated all 6 call sites to pass `grid`.

### ✅ DoorController Exact Match Access Bug - 2026-03-10
**Issue:** `canPassThrough` checked `equippedAura == requiredAura` (exact string match). A player with Green aura couldn't pass Blue doors, despite Green being a higher tier.

**Solution:** Changed to tier-based comparison: `playerTier >= requiredTier`. Green aura (tier 2) now passes Blue (tier 1) and Green (tier 2) doors.

### ✅ Validator Tier Progression Mismatch - 2026-03-10
**Issue:** Validator required tier 1 (Blue aura) to expand reachable area beyond tier 0 (no aura). This always failed because same-zone movement is free and all Blue zones were reachable without aura, making T0 and T1 identical. Blue aura was functionally useless.

**Solution:** Introduced SAFE zone type (tier 0) for starting cell (1,1). Now the full progression works: Safe (no aura) → Blue (Blue aura, 10L) → Green (Green aura, 50L) → Red (Red aura, 100L). Validator checks T0→T1→T2→T3 expansion. Added max retry limit (10) to prevent infinite regeneration loops. Verified with 1000/1000 Python test runs.

### ✅ Hex Grid Conversion - 2026-03-10
**Issue:** Rectangular 10x10 grid with corner start (1,1) created unnatural tier progression and symmetrical layout.

**Solution:** Converted entire board to hexagonal grid with axial coordinates (q, r):
- Board shape: regular hexagon with radius 5 (91 cells)
- Center start at (0,0) — concentric rings naturally map to tier zones
- 6 directions/walls per cell instead of 4
- Grid stored as dictionary keyed by "q,r" strings with `_cells` list for iteration
- All modules updated: MazeGenerator, MazePlayabilityValidator, WorldBuilder, DoorController, OrbManager, RelicManager, Server
- Dead-end detection updated: 5 walls = dead end (was 3 for rectangular)
- Flat-top hex rendering with cylinder floors and angled wall segments
- Python test harness updated and verified: 1000/1000 pass rate

**Impact:** More natural tier progression from center outward. 6 connections per cell = more paths, less bottlenecking for multiplayer.

**Obsolete:** `GRID_SIZE` config replaced with `HEX_RADIUS`. `PathValidator.lua` still deprecated (see above).

## Future Considerations
_To be filled during development_
