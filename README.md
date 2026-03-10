# Aura Maze - Roblox Game

Multiplayer maze exploration game where players collect Lumens, craft Auras to unlock new zones, find hidden relics, and compete for Rebirth wins.

## Project Status

**Current Phase:** P0 Complete - Core gameplay loop functional
**Last Updated:** 2026-02-21

### ✅ Implemented (P0)
- 10x10 maze generation with Recursive Backtracker algorithm
- DataStore persistence (Wins, Lumens, Auras)
- Orb spawning system (Blue/Green/Red) with respawn
- Door access control based on equipped auras
- Full UI system (HUD, Crafting Menu)
- Player data synchronization

### 🚧 Next Steps (P1)
- Physical world generation (zone floors, walls with colors)
- Relic system (3 Prismatic Keys)
- Rebirth portal and mechanics
- Leaderboard integration

### 📋 Future (P2)
- Visual aura effects
- Anti-camping enhancements
- Cosmetic rewards for Rebirth
- Performance optimizations

## Architecture

```
src/
├── server/           # Server-side logic
│   ├── Server.server.lua          # Main entry point
│   ├── MazeGenerator.lua          # 10x10 maze generation
│   ├── WorldBuilder.lua           # Physical world (floors, walls)
│   ├── PlayerDataManager.lua      # DataStore & player data
│   ├── OrbManager.lua             # Orb spawning & collection
│   ├── DoorController.lua         # Door access control
│   └── RelicManager.lua           # 3 Prismatic Keys system
├── shared/           # Shared code (server + client)
│   ├── GameConfig.lua             # Constants & configuration
│   ├── ZoneTypes.lua              # Zone definitions
│   └── AuraData.lua               # Aura properties
└── client/           # Client-side UI
    ├── Client.client.lua          # Main entry point
    ├── HUDManager.lua             # Lumen counter & equipped aura
    ├── CraftingMenu.lua           # Aura crafting UI
    └── RelicTracker.lua           # Prismatic Keys tracker
```

## Development Workflow

### Running the Game

1. Start Rojo server:
   ```powershell
   start_server.bat
   ```
   or
   ```powershell
   aftman run rojo serve
   ```

2. Open Roblox Studio and connect via Rojo plugin

3. Press Play to test

### Building

Build a standalone `.rbxlx` file:
```powershell
aftman run rojo build default.project.json -o AuraMaze.rbxlx
```

## Game Design

See `Game Design Document.md` for full specification.

### Core Loop
1. Collect **Lumens** (⚡) from colored orbs
2. Craft **Auras** to unlock higher-tier zones
3. Find **3 Prismatic Keys** hidden in the maze
4. Enter **Rebirth Portal** to reset progress and earn +1 Win

### Economy
- **Blue Orbs:** 1 Lumen (15-30s respawn, 65% spawn rate)
- **Green Orbs:** 5 Lumens (60s respawn, 30% spawn rate)
- **Red Orbs:** 10 Lumens (120s respawn, 5% spawn rate)

### Auras
- **Blue Aura:** 10 Lumens → Access Blue zones
- **Green Aura:** 50 Lumens → Access Green zones
- **Red Aura:** 100 Lumens → Access Red zones

## Technical Decisions

### Maze Generation
- **Algorithm:** Recursive Backtracker (ensures perfect maze with one solution)
- **Loops:** +15% extra connections added for multiple paths
- **Zone Colors:** Assigned via BFS distance from start (Blue → Green → Red)

### Multiplayer Design
- **Orbs:** Global (shared) - collected by first player to touch
- **Relics:** Local (per-player) - everyone can collect independently
- **Doors:** Server-authoritative access control

### Performance
- **Grid Size:** 10x10 (100 zones total)
- **Zone Size:** 50 studs per zone
- **Orb Respawn:** Anti-camping via random position within zone

## Configuration

Edit `src/shared/GameConfig.lua` to adjust:
- Grid size
- Orb values & respawn times
- Aura costs
- DataStore settings

## Known Issues

See `docs/technical_debt.md`

## License

Private project - Game Design Document by Anton
