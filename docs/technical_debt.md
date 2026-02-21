# Technical Debt

## Current Issues

### 1. Unused Collision Group System
**Date:** 2026-02-21
**Status:** To Review

The legacy wall collision system (`WallAura1-10` groups) created in the original `MapGenerator.lua` is no longer used after switching from maze to honeycomb structure. These groups are still registered but serve no purpose.

**Impact:** Low - groups exist but don't affect functionality
**Effort:** Low - can be removed during cleanup
**Files affected:** 
- `src/server/MapGenerator.lua` (partially cleaned)
- `src/server/ZoneBarrier.lua` (still references aura tiers)

**Recommendation:** Remove `ZoneBarrier.lua` aura tier system if not needed for future features.

---

## Resolved Issues

### ✅ Map Generation Complexity
**Date:** 2026-02-21
**Status:** Resolved

**Original Issue:** Map used complex maze generation algorithm (Randomized DFS) that created walls between unconnected zones, making navigation confusing.

**Solution:** Switched to simple honeycomb structure where all zones are connected to neighbors. Only gates (30% of connections) control access based on aura requirements.

**Benefits:**
- Simpler code (~50 lines removed)
- Easier for players to navigate
- Clearer game design - gates are the only barriers
- Better matches "пчелна пита" (honeycomb) visual metaphor

---

## Future Considerations

### Player Spawn System
Currently there's no defined spawn system for placing players in the Starting Zone (zone 1). Should implement:
- Spawn location in center of zone 1
- Multiple spawn points for multiple players
- Respawn logic

### Performance Optimization
With 100 zones + orbs + gates, consider:
- Object pooling for orbs
- LOD (Level of Detail) for distant zones
- Spatial partitioning for collision detection

### Visual Improvements
- Particle effects at zone boundaries
- Better gate visual feedback (animations, sounds)
- Mini-map UI showing zone layout
- Zone labels/numbers for navigation
