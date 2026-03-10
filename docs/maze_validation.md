# Maze Playability Validation System

## Overview

The `MazePlayabilityValidator` ensures that every generated maze is fully playable without dead ends, impossible situations, or areas that trap players. This replaces the previous `PathValidator` which only checked path length.

## Why Playability Validation?

The game has a progression system where players:
1. Start with **no aura** (can only move through Blue zones)
2. Buy **Blue aura** for 10 Lumens (unlocks Green zones)
3. Buy **Green aura** for 50 Lumens (unlocks Red zones)
4. Buy **Red aura** for 100 Lumens (no additional access, just completion)

A maze is **unplayable** if:
- Players get trapped in dead ends they can't escape
- Zones are completely isolated with no connections
- Players can't progress through tiers (e.g., can't reach any Green zones even with Blue aura)
- The starting position blocks immediate gameplay

## Validation Checks

The validator performs **5 critical checks** on every generated maze:

### 1. **Starting Position Validation**
- Ensures cell (1,1) is a Blue zone
- Verifies the starting cell has at least one connection
- **Why**: Players must be able to start playing immediately

### 2. **No Isolated Cells**
- Checks every cell has at least one open wall/door
- **Why**: Completely walled-off cells are unreachable and waste space

### 3. **Full Connectivity**
- Uses BFS to verify all 100 cells are reachable with Red aura (tier 3)
- **Why**: Players should eventually be able to explore the entire maze

### 4. **Tier Progression**
- Validates that each aura tier unlocks **more** areas than the previous:
  - Tier 0 (no aura): Can reach some Blue zones
  - Tier 1 (Blue aura): Can reach more zones including Greens
  - Tier 2 (Green aura): Can reach even more including Reds
  - Tier 3 (Red aura): Can reach all 100 zones
- **Why**: Ensures the progression system works and players are rewarded for upgrading

### 5. **No Problematic Dead Ends**
- Identifies dead ends (cells with only 1 exit)
- Flags dead ends where the only exit leads to a **higher tier** zone
- **Why**: Prevents player traps (e.g., a Blue dead end that only connects to a Green zone traps players without Blue aura)

## How It Works

### Door Access Logic
```lua
function canPassDoor(fromZone, toZone, auraTier)
    -- Same zone = always passable
    if fromZone == toZone then return true end
    
    -- Check if player's aura tier >= required tier
    local requiredTier = ZoneTypes.Tier[toZone]
    return auraTier >= requiredTier
end
```

### Reachability Algorithm
Uses **Breadth-First Search (BFS)** to simulate player movement:
1. Start at cell (1,1)
2. For each cell, check all 4 directions
3. If wall is open AND player can pass the door (based on aura tier), add neighbor to queue
4. Count all reachable cells

This is run **4 times** (once per tier level) to validate progression.

## Integration with MazeGenerator

The validator is called in `MazeGenerator.Generate()` after:
1. Maze carving (Recursive Backtracker)
2. Adding loops
3. Assigning zone colors
4. Ensuring zone connectivity
5. Adding escape routes
6. Adding alternate paths

If validation fails, the **entire maze is regenerated** from scratch.

## Example Output

```
[PlayabilityValidator] ========================================
[PlayabilityValidator] Starting maze playability validation...
[PlayabilityValidator] ========================================
[PlayabilityValidator] Checking starting position...
[PlayabilityValidator] ✓ Starting position valid (Blue zone with connections)
[PlayabilityValidator] Checking for isolated cells...
[PlayabilityValidator] ✓ No isolated cells
[PlayabilityValidator] Checking full connectivity...
[PlayabilityValidator] ✓ All 100 cells are reachable
[PlayabilityValidator] Checking tier progression...
[PlayabilityValidator] ✓ Tier 0 (no aura): 12 cells, 12 blue zones
[PlayabilityValidator] ✓ Tier 1 (blue aura): 45 cells, 28 green zones
[PlayabilityValidator] ✓ Tier 2 (green aura): 89 cells, 32 red zones
[PlayabilityValidator] Checking for problematic dead ends...
[PlayabilityValidator] ✓ No problematic dead ends
[PlayabilityValidator] ========================================
[PlayabilityValidator] ✓✓✓ ALL CHECKS PASSED - MAZE IS PLAYABLE ✓✓✓
[PlayabilityValidator] ========================================
```

## Statistics

The validator also provides detailed statistics via `GetStats()`:

```lua
{
    noAura = 12,      -- Zones reachable without any aura
    blueAura = 45,    -- Zones reachable with Blue aura
    greenAura = 89,   -- Zones reachable with Green aura
    redAura = 100,    -- Zones reachable with Red aura (should be all)
    totalCells = 100  -- Total cells in maze
}
```

## Future Improvements

Potential enhancements:
- **Balance validation**: Ensure zone distribution roughly matches config (45 Blue, 30 Green, 25 Red)
- **Relic placement validation**: Verify keys are reachable with appropriate aura tiers
- **Difficulty scoring**: Rate maze difficulty based on required tier switches
- **Loop density validation**: Ensure loops are well-distributed for multiplayer gameplay

## Technical Notes

- All validation checks are **non-destructive** - they only read the maze, never modify it
- BFS is used instead of DFS for consistent shortest-path-like exploration
- Tier system: 0 = no aura, 1 = Blue, 2 = Green, 3 = Red
- Validation runs on server only (not replicated to clients)
