-- OrbManager.lua
-- Manages orb spawning, collection, and respawn

local GameConfig = require(game.ReplicatedStorage.GameConfig)
local ZoneTypes = require(game.ReplicatedStorage.ZoneTypes)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

local CollectOrbEvent = game.ReplicatedStorage.CollectOrb

local OrbManager = {}

local activeOrbs = {} -- Track all active orbs

-- Orb types configuration
local OrbTypes = {
	Blue = {
		Value = GameConfig.BLUE_ORB_VALUE,
		RespawnMin = GameConfig.BLUE_ORB_RESPAWN_MIN,
		RespawnMax = GameConfig.BLUE_ORB_RESPAWN_MAX,
		Color = Color3.fromRGB(100, 150, 255),
		Frequency = GameConfig.BLUE_ORB_FREQUENCY,
	},
	Green = {
		Value = GameConfig.GREEN_ORB_VALUE,
		Respawn = GameConfig.GREEN_ORB_RESPAWN,
		Color = Color3.fromRGB(100, 255, 150),
		Frequency = GameConfig.GREEN_ORB_FREQUENCY,
	},
	Red = {
		Value = GameConfig.RED_ORB_VALUE,
		Respawn = GameConfig.RED_ORB_RESPAWN,
		Color = Color3.fromRGB(255, 100, 100),
		Frequency = GameConfig.RED_ORB_FREQUENCY,
	},
}

-- Determine orb type based on frequency
local function getRandomOrbType()
	local roll = math.random(1, 100)
	if roll <= OrbTypes.Blue.Frequency then
		return "Blue", OrbTypes.Blue
	elseif roll <= OrbTypes.Blue.Frequency + OrbTypes.Green.Frequency then
		return "Green", OrbTypes.Green
	else
		return "Red", OrbTypes.Red
	end
end

-- Create orb visual
local function createOrbPart(orbType, position)
	local orb = Instance.new("Part")
	orb.Name = orbType.."Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(2, 2, 2)
	orb.Position = position
	orb.Anchored = true
	orb.CanCollide = false
	orb.Material = Enum.Material.Neon
	orb.Color = OrbTypes[orbType].Color
	orb.Transparency = 0.3
	
	-- Add particle effect
	local particle = Instance.new("ParticleEmitter")
	particle.Color = ColorSequence.new(OrbTypes[orbType].Color)
	particle.Size = NumberSequence.new(0.5)
	particle.Lifetime = NumberRange.new(1, 2)
	particle.Rate = 20
	particle.Speed = NumberRange.new(2)
	particle.Parent = orb
	
	return orb
end

local sqrt3 = math.sqrt(3)

-- Convert axial (q, r) to world (x, z) for flat-top hexagons
local function hexToWorld(q, r)
	local size = GameConfig.ZONE_SIZE / 2
	local x = size * (3 / 2 * q)
	local z = size * (sqrt3 / 2 * q + sqrt3 * r)
	return x, z
end

-- Spawn a single orb in a zone
function OrbManager.SpawnOrb(zoneCell, parentFolder)
	local typeName, orbType = getRandomOrbType()
	
	-- Calculate spawn position (center of zone with some randomness)
	local zoneSize = GameConfig.ZONE_SIZE
	local baseX, baseZ = hexToWorld(zoneCell.q, zoneCell.r)
	
	-- Add random offset for anti-camping
	local offsetX = math.random(-zoneSize/3, zoneSize/3)
	local offsetZ = math.random(-zoneSize/3, zoneSize/3)
	
	local position = Vector3.new(baseX + offsetX, 5, baseZ + offsetZ)
	
	-- Create orb
	local orbPart = createOrbPart(typeName, position)
	orbPart.Parent = parentFolder
	
	-- Store orb data
	local orbData = {
		Part = orbPart,
		Type = typeName,
		Value = orbType.Value,
		ZoneCell = zoneCell,
		Active = true,
	}
	
	table.insert(activeOrbs, orbData)
	
	-- Setup touch detection
	orbPart.Touched:Connect(function(hit)
		if not orbData.Active then return end
		
		local character = hit.Parent
		if not character:FindFirstChildOfClass("Humanoid") then
			character = character.Parent
		end
		local player = game.Players:GetPlayerFromCharacter(character)
		
		if player then
			OrbManager.CollectOrb(player, orbData)
		end
	end)
	
	return orbData
end

-- Collect orb
function OrbManager.CollectOrb(player, orbData)
	if not orbData.Active then return end
	
	-- Mark as collected
	orbData.Active = false
	orbData.Part.Transparency = 1
	orbData.Part.CanCollide = false
	
	-- Disable particle emitter
	if orbData.Part:FindFirstChild("ParticleEmitter") then
		orbData.Part.ParticleEmitter.Enabled = false
	end
	
	-- Add lumens to player
	local newTotal = PlayerDataManager.AddLumens(player, orbData.Value)
	
	-- Notify client
	local SyncDataEvent = game.ReplicatedStorage.SyncPlayerData
	local playerData = PlayerDataManager.GetData(player)
	SyncDataEvent:FireClient(player, playerData)
	
	print("[OrbManager]", player.Name, "collected", orbData.Type, "orb, total lumens:", newTotal)
	
	-- Schedule respawn
	local respawnTime
	if orbData.Type == "Blue" then
		respawnTime = math.random(OrbTypes.Blue.RespawnMin, OrbTypes.Blue.RespawnMax)
	else
		respawnTime = OrbTypes[orbData.Type].Respawn
	end
	
	task.delay(respawnTime, function()
		OrbManager.RespawnOrb(orbData)
	end)
end

-- Respawn orb at new random location in same zone
function OrbManager.RespawnOrb(orbData)
	if not orbData.Part or not orbData.Part.Parent then return end
	
	-- Calculate new random position in same zone
	local zoneSize = GameConfig.ZONE_SIZE
	local baseX, baseZ = hexToWorld(orbData.ZoneCell.q, orbData.ZoneCell.r)
	
	local offsetX = math.random(-zoneSize/3, zoneSize/3)
	local offsetZ = math.random(-zoneSize/3, zoneSize/3)
	
	orbData.Part.Position = Vector3.new(baseX + offsetX, 5, baseZ + offsetZ)
	orbData.Part.Transparency = 0.3
	orbData.Part.CanCollide = false
	
	-- Re-enable particle emitter
	if orbData.Part:FindFirstChild("ParticleEmitter") then
		orbData.Part.ParticleEmitter.Enabled = true
	end
	
	orbData.Active = true
	
	print("[OrbManager] Respawned", orbData.Type, "orb in zone", orbData.ZoneCell.q, orbData.ZoneCell.r)
end

-- Spawn orbs in all zones
function OrbManager.SpawnAllOrbs(mazeGrid)
	local orbsFolder = Instance.new("Folder")
	orbsFolder.Name = "Orbs"
	orbsFolder.Parent = workspace
	
	print("[OrbManager] Spawning orbs in all zones...")
	
	-- Spawn multiple orbs per zone (3-5 orbs depending on zone tier)
	for _, k in ipairs(mazeGrid._cells) do
		local cell = mazeGrid[k]
		
		-- Determine orbs count based on zone tier
		local orbCount
		local tier = ZoneTypes.Tier[cell.zoneType] or 1
		if tier == 1 then
			orbCount = math.random(3, 5) -- Blue zones: 3-5 orbs
		elseif tier == 2 then
			orbCount = math.random(4, 6) -- Green zones: 4-6 orbs
		else
			orbCount = math.random(5, 7) -- Red zones: 5-7 orbs
		end
		
		-- Spawn multiple orbs in this zone
		for i = 1, orbCount do
			OrbManager.SpawnOrb(cell, orbsFolder)
		end
	end
	
	print("[OrbManager] Spawned", #activeOrbs, "orbs")
end

return OrbManager
