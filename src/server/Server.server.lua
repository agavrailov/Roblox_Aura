-- Server.server.lua
-- Main server entry point - orchestrates all game systems

local Players = game:GetService("Players")

-- Load modules
local MazeGenerator = require(script.Parent.MazeGenerator)
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local OrbManager = require(script.Parent.OrbManager)
local DoorController = require(script.Parent.DoorController)
local RelicManager = require(script.Parent.RelicManager)

local AuraData = require(game.ReplicatedStorage.AuraData)

-- Remote events
local CraftAuraEvent = game.ReplicatedStorage.CraftAura
local EquipAuraEvent = game.ReplicatedStorage.EquipAura
local SyncPlayerDataEvent = game.ReplicatedStorage.SyncPlayerData
local GetPlayerDataFunction = game.ReplicatedStorage.GetPlayerData

-- Store maze grid globally for reference
local mazeGrid = nil

print("[Server] Initializing Aura Maze server...")

-- Generate world
local function generateWorld()
	print("[Server] Generating world...")
	
	-- Step 1: Generate maze
	mazeGrid = MazeGenerator.Generate()
	
	-- Step 2: Build physical world (zones, floors, walls)
	WorldBuilder.BuildWorld(mazeGrid)
	
	-- Step 3: Generate doors
	DoorController.GenerateDoors(mazeGrid)
	
	-- Step 4: Spawn orbs
	OrbManager.SpawnAllOrbs(mazeGrid)
	
	-- Step 5: Spawn relics
	RelicManager.SpawnRelics(mazeGrid)
	
	-- Step 6: Create spawn location at center hex (0,0) which maps to world (0,0)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "StartingSpawn"
	spawnLocation.Position = Vector3.new(0, 3.5, 0)
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = false
	spawnLocation.Transparency = 1
	spawnLocation.Duration = 0 -- No respawn delay
	spawnLocation.Parent = workspace
	
	print("[Server] World generation complete")
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	print("[Server] Player joined:", player.Name)
	
	-- Load player data (handled by PlayerDataManager)
	task.wait(1) -- Wait for data to load
	
	-- Initialize relic tracking
	RelicManager.InitializePlayer(player)
	
	-- Send initial data to client
	local playerData = PlayerDataManager.GetData(player)
	if playerData then
		print("[Server] Sending player data - Lumens:", playerData.Lumens, "Auras:", playerData.Auras)
		SyncPlayerDataEvent:FireClient(player, playerData)
	end
	
	-- Spawn player at starting zone
	player.CharacterAdded:Connect(function(character)
		task.wait(1) -- Wait longer for world to fully load
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				-- Spawn at center hex (0,0)
				local spawnPos = Vector3.new(0, 5, 0)
				humanoidRootPart.CFrame = CFrame.new(spawnPos)
				print("[Server] Spawned", player.Name, "at position", spawnPos)
				
				-- Debug: Check if there's a floor below
				local rayOrigin = spawnPos
				local rayDirection = Vector3.new(0, -10, 0)
				local raycastParams = RaycastParams.new()
				local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
				if result then
					print("[Server] Floor found below spawn:", result.Instance.Name, "at Y =", result.Position.Y)
				else
					warn("[Server] NO FLOOR FOUND BELOW SPAWN POSITION!")
				end
			end
	end)
end)

-- Handle craft aura request
CraftAuraEvent.OnServerEvent:Connect(function(player, auraName)
	print("[Server] Craft aura request from", player.Name, ":", auraName)
	
	local playerData = PlayerDataManager.GetData(player)
	if not playerData then
		warn("[Server] No player data for", player.Name)
		return
	end
	
	-- Check if aura exists
	local aura = AuraData.GetAura(auraName)
	if not aura then
		warn("[Server] Invalid aura:", auraName)
		return
	end
	
	-- Check if already owned
	if playerData.Auras[auraName] then
		print("[Server] Player already owns", auraName)
		return
	end
	
	-- Check if player has enough lumens
	if playerData.Lumens < aura.Cost then
		print("[Server] Not enough lumens. Has:", playerData.Lumens, "Needs:", aura.Cost)
		return
	end
	
	-- Craft aura
	local success, newLumens = PlayerDataManager.SubtractLumens(player, aura.Cost)
	if success then
		PlayerDataManager.GiveAura(player, auraName)
		PlayerDataManager.SetEquippedAura(player, auraName)
		
		print("[Server] Crafted and equipped", auraName, "for", player.Name)
		
		-- Send updated data to client
		local updatedData = PlayerDataManager.GetData(player)
		SyncPlayerDataEvent:FireClient(player, updatedData)
		EquipAuraEvent:FireClient(player, auraName)
	end
end)

-- Handle equip aura request
EquipAuraEvent.OnServerEvent:Connect(function(player, auraName)
	print("[Server] Equip aura request from", player.Name, ":", auraName)
	
	-- Check if player owns the aura
	if not PlayerDataManager.HasAura(player, auraName) then
		warn("[Server] Player doesn't own", auraName)
		return
	end
	
	-- Equip aura
	PlayerDataManager.SetEquippedAura(player, auraName)
	
	print("[Server] Equipped", auraName, "for", player.Name)
	print("[Server] Verification - GetEquippedAura returns:", PlayerDataManager.GetEquippedAura(player))
	
	-- Send updated data to client
	local updatedData = PlayerDataManager.GetData(player)
	SyncPlayerDataEvent:FireClient(player, updatedData)
	EquipAuraEvent:FireClient(player, auraName)
end)

-- Handle get player data request
GetPlayerDataFunction.OnServerInvoke = function(player)
	return PlayerDataManager.GetData(player)
end

-- Initialize server
generateWorld()

print("[Server] Aura Maze server ready!")
