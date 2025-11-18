# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project overview

This repository contains the code for **Aura Collector Simulator**, a Roblox experience centered on collecting orbs to craft and equip cosmetic auras. Design goals (from `GEMINI.md`) emphasize infinite progression, cosmetic status items (auras), collection/scarcity, and simple but extensible core loops.

The project is structured as a Rojo-based Roblox game project with clear separation between server logic, client/UI, and shared configuration/data modules.

## Tooling and common commands

### Dependencies and tooling

- **Rojo** is managed via `aftman` (see `aftman.toml`).
- A Windows batch helper `start_server.bat` runs a local Rojo server.
- `package.json` only declares a dependency on the GitHub CLI (`gh`); there are no Node-based build or test scripts.

### Environment setup

From the repo root (`Roblox_Aura`):

- Install Rojo (and any other aftman tools):
  - PowerShell:
    - `aftman install`

### Running the Rojo server for live development

From the repo root:

- Using aftman-managed Rojo (recommended):
  - PowerShell:
    - `aftman run rojo serve`

- Using the local batch script (Windows only):
  - PowerShell / CMD:
    - `start_server.bat`

This serves the game defined in `default.project.json` for live syncing with Roblox Studio via the Rojo plugin.

### Building a place file (offline play/publishing)

From the repo root, to build a place file from `default.project.json`:

- PowerShell:
  - `aftman run rojo build default.project.json -o AuraCollectorSimulator.rbxlx`

You can then open `AuraCollectorSimulator.rbxlx` in Roblox Studio or publish it to Roblox.

### Testing and linting

- There is currently **no automated test suite or linting configuration** in this repository (no TestEZ project, no Luau lint config, and no test scripts in `package.json`).
- If you introduce a test framework later, document the commands here (e.g., how to run all tests and a single test file).

## High-level architecture

### Rojo project mapping (`default.project.json`)

Rojo maps the local `src` tree into the Roblox DataModel as follows:

- `src/server` → `ServerScriptService`
  - Includes server-side scripts/module scripts such as `Server.server.lua`, `AuraManager.lua`, `ZoneManager.lua`, `ZoneBarrier.lua`, `OrbManager.server.lua`, and `BarrierCreator.server.lua`.
- `src/shared` → `ReplicatedStorage`
  - Contains shared configuration and logic modules: `AuraConfig.lua`, `ZoneConfig.lua`, `PlayerData.lua`, `Orb.lua`, etc.
  - Defines RemoteEvents/RemoteFunctions in `ReplicatedStorage` via the project file:
    - `UpdateLumin` (RemoteEvent)
    - `CraftAura` (RemoteEvent)
    - `EquipAura` (RemoteEvent)
    - `UpdateAuras` (RemoteEvent)
    - `GetEquippedAura` (RemoteFunction)
- `src/client` → `StarterPlayer.StarterPlayerScripts`
  - Contains client-side scripts and UI modules, including `Client.client.lua`, `AuraVisuals.lua`, and `UI` submodules (e.g., `LuminDisplay`, `AuraInventoryGui`).

### Core gameplay flow

**Orbs and Lumin (currency)**

- `src/shared/Orb.lua` defines a single orb instance:
  - Creates a neon spherical `Part` with a `ParticleEmitter`.
  - Tracks `luminAmount`, `respawnTime`, and enabled/disabled state.
  - `:collect()` hides the orb, schedules a respawn via `task.delay`, and returns the awarded Lumin.

- `src/server/OrbManager.server.lua` manages all orbs:
  - Requires `Orb`, `PlayerData`, and `ZoneConfig`.
  - On startup, iterates over `ZoneConfig.Zones` and spawns orbs at each zone’s `SpawnPoints` using `spawnOrb(...)`.
  - Connects `Touched` events on orb parts:
    - On a valid player touch, calls `orbModule:collect()`.
    - On successful collection, updates the player’s Lumin via `PlayerData.addLumin`, logs, and fires `UpdateLumin` to the client.

- `src/shared/ZoneConfig.lua` defines zones such as **Starting Zone** and **Forest Zone**:
  - Each zone lists `OrbTypes` (name, `LuminValue`, `RespawnTime`) and `SpawnPoints` (world `Vector3` positions).

**Player data and persistence**

- `src/shared/PlayerData.lua` is the central data layer:
  - Uses `DataStoreService` with the store `"AuraCollectorPlayerData"`.
  - Maintains an in-memory `playerDataCache` keyed by `UserId`.
  - Exposes helpers:
    - `get` / `set` for arbitrary keys.
    - `addLumin` / `subtractLumin`.
    - `hasAura`, `addAura`.
    - `setEquippedAura`, `getEquippedAura`.
  - `load(player)`:
    - Fetches data from the DataStore; merges it into `DEFAULT_DATA`.
    - If `EquippedAura` is nil but the player owns auras, auto-equips the first owned aura.
  - `save(player)`:
    - Persists the current cached data and clears it from memory.
  - Wires into lifecycle events:
    - `Players.PlayerAdded:Connect(PlayerData.load)`.
    - `Players.PlayerRemoving:Connect(PlayerData.save)`.

**Auras and crafting**

- `src/shared/AuraConfig.lua` defines the available auras (`Basic Aura`, `Green Aura`, `Blue Aura`, `Red Aura`):
  - Each entry includes `Cost`, `LuminMultiplier`, `ParticleEffect` (asset id placeholder), `Description`, and optional `PreviousAura` / `NextAura` links to form chains.

- `src/server/AuraManager.lua` is the server-side aura system:
  - Depends on `PlayerData`, `AuraConfig`, and the RemoteEvents `CraftAura`, `UpdateLumin`, `EquipAura`, and `UpdateAuras`.
  - `sendAuraDataToClient(player)` packages `ownedAuras` and `equippedAura` and fires `UpdateAuras` to that client.
  - `onCraftAura(player, auraName)`:
    - Validates the requested aura exists, isn’t already owned, and the player has enough Lumin.
    - Deducts the cost, adds the aura, equips it, updates Lumin, and fires both `UpdateLumin` and `EquipAura`, as well as updating the aura inventory via `sendAuraDataToClient`.
  - `onEquipAura(player, auraName)`:
    - Validates ownership, updates `EquippedAura` in `PlayerData`, then fires `EquipAura` and `UpdateAuras` so the client updates visuals and inventory UI.
  - Exposes `AuraManager.sendAuraDataToClient` for other server code (notably `Server.server.lua`).

**Zones and barriers**

- `src/server/ZoneManager.lua` encapsulates zone-entrance rules:
  - Uses `ZoneConfig` and `PlayerData`.
  - `ZoneManager.canEnterZone(player, zoneName)` returns `(bool, reason?)`:
    - If the zone doesn’t exist, denies with a message.
    - If `RequiredAura` is nil, grants access.
    - Otherwise, compares the player’s `EquippedAura` to `RequiredAura` and returns allow/deny plus a textual reason.

- `src/server/ZoneBarrier.lua` defines a reusable barrier object for gating access:
  - Uses `PhysicsService` collision groups to differentiate pass/block behavior:
    - `ZoneBarrier`, `PlayerPassBarrier`, `PlayerBlockBarrier` groups are created/configured at module load.
  - `ZoneBarrier.new(barrierPart, targetZoneName)`:
    - Wraps a physical barrier `Part`, assigning it to the `ZoneBarrier` group and setting default visuals.
    - Connects `Touched` / `TouchEnded` to track players currently interacting with the barrier.
    - On touch, calls `ZoneManager.canEnterZone` and delegates to `self:setPassableForPlayer(player, passable)`.
  - `setPassableForPlayer(player, passable)`:
    - Sets all character `BasePart` collision groups to `PlayerPassBarrier` or `PlayerBlockBarrier`.
    - Reapplies the group on respawn and cleans up connections on `CharacterRemoving`.
    - Updates barrier color/transparency to signal passable (green, more transparent) vs blocked (red, less transparent).

- `src/server/BarrierCreator.server.lua` ensures the `ForestBarrier` part exists in `workspace`:
  - If missing, creates a force-field style barrier `Part` at a fixed position/size and parents it to `workspace`.
  - This barrier is then wrapped by `ZoneBarrier` in `Server.server.lua`.

### Client-side flow and UI

- `src/client/Client.client.lua` is the main client entrypoint:
  - Requires:
    - `ReplicatedStorage` RemoteEvents/RemoteFunction: `UpdateLumin`, `EquipAura`, `UpdateAuras`, `GetEquippedAura`.
    - UI modules: `UI.LuminDisplay`, `UI.AuraInventoryGui`.
    - Visuals module: `AuraVisuals`.
  - On startup:
    - Creates the Lumin HUD via `LuminDisplay.new()` and parents it to `PlayerGui`.
    - Creates the aura inventory GUI via `AuraInventoryGui.new()` and parents it to `PlayerGui`.
    - Subscribes to `UpdateLumin` to keep the HUD in sync.
    - Subscribes to `EquipAura` to refresh the currently displayed aura effects via `AuraVisuals.create` / local tracking of `currentAuraEffect`.
    - Subscribes to `UpdateAuras` to rebuild the aura inventory list (frames and equip buttons) and adjust the scroll area.
  - Adds a top-right "Auras" toggle `TextButton` that shows/hides the inventory UI, plus a close button inside the inventory frame.
  - On character spawn/respawn, calls `GetEquippedAura:InvokeServer()` and updates the visual aura accordingly.

- `src/client/AuraVisuals.lua` centralizes aura visual effects:
  - Defines `AuraEffectCreators[...]` functions per aura (e.g., `"Basic Aura"`, `"Green Aura"`, `"Blue Aura"`) that create a transparent `Part` with a `ParticleEmitter`, weld it to the character's torso, and return the effect part.
  - `AuraVisuals.create(auraName, character)` locates `UpperTorso`/`Torso`, picks the correct creator, and attaches the visual.
  - `AuraVisuals.remove(character)` cleans up any existing `AuraEffectPart`.

### Server entrypoint and integration

- `src/server/Server.server.lua` ties together the major server systems:
  - Requires `PlayerData`, `AuraManager`, and `ZoneBarrier`, and binds to the `UpdateLumin`, `EquipAura`, and `GetEquippedAura` remotes.
  - On `Players.PlayerAdded`, loads player data, sends initial Lumin and aura inventory via `AuraManager.sendAuraDataToClient`, and fires `EquipAura` with the initial equipped aura so the client can display it.
  - Locates the `ForestBarrier` `Part` in `workspace` and, if found, wraps it with `ZoneBarrier.new(forestBarrierPart, "Forest Zone")` to enforce access rules defined in `ZoneManager` / `ZoneConfig`.

This structure makes it straightforward to extend the game by adding new zones (via `ZoneConfig` + physical barriers), new auras (via `AuraConfig` + `AuraVisuals`), or additional orb types (via `ZoneConfig.OrbTypes`).
