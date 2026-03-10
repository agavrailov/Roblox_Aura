-- PlayerDataManager.lua
-- Manages player data persistence using DataStore

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local GameConfig = require(game.ReplicatedStorage.GameConfig)

local PlayerDataManager = {}

-- DataStore instance
local playerDataStore = DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)

-- In-memory cache of player data
local playerDataCache = {}

-- Default player data template
local DEFAULT_DATA = {
	Wins = 0, -- Number of successful rebirths
	Lumens = GameConfig.STARTING_LUMENS, -- Current currency
	Auras = {
		BlueAura = false,
		GreenAura = false,
		RedAura = false,
	},
	EquippedAura = nil, -- Currently equipped aura (string or nil)
	-- Note: Keys (relics) are NOT persisted - must be collected in one session
}

-- Load player data from DataStore
function PlayerDataManager.LoadData(player)
	local userId = player.UserId
	
	-- TESTING: Skip DataStore and always create fresh data
	-- Comment these lines to re-enable DataStore
	-- local success, data = pcall(function()
	-- 	return playerDataStore:GetAsync(userId)
	-- end)
	-- if success and data then
	if false then  -- TESTING: Always create fresh data
		-- Merge saved data with defaults (in case new fields were added)
		local mergedData = {}
		for key, value in pairs(DEFAULT_DATA) do
			if type(value) == "table" then
				mergedData[key] = {}
				for subKey, subValue in pairs(value) do
					mergedData[key][subKey] = data[key] and data[key][subKey] or subValue
				end
			else
				mergedData[key] = data[key] or value
			end
		end
		playerDataCache[userId] = mergedData
		print("[PlayerDataManager] Loaded data for", player.Name)
	else
		-- New player or error - use defaults
		playerDataCache[userId] = {}
		for key, value in pairs(DEFAULT_DATA) do
			if type(value) == "table" then
				playerDataCache[userId][key] = {}
				for subKey, subValue in pairs(value) do
					playerDataCache[userId][key][subKey] = subValue
				end
			else
		playerDataCache[userId][key] = value
		end
	end
	print("[PlayerDataManager] Created new data for", player.Name)
	print("  - Starting Lumens:", playerDataCache[userId].Lumens)
end

print("[PlayerDataManager] Final data for", player.Name, "- Lumens:", playerDataCache[userId].Lumens)
return playerDataCache[userId]
end

-- Save player data to DataStore
function PlayerDataManager.SaveData(player)
	local userId = player.UserId
	local data = playerDataCache[userId]

	if not data then
		warn("[PlayerDataManager] No data to save for", player.Name)
		return false
	end

	local success, err = pcall(function()
		playerDataStore:SetAsync(userId, data)
	end)

	if success then
		print("[PlayerDataManager] Saved data for", player.Name)
		return true
	else
		warn("[PlayerDataManager] Failed to save data for", player.Name, ":", err)
		return false
	end
end

-- Get player data from cache
function PlayerDataManager.GetData(player)
	return playerDataCache[player.UserId]
end

-- Update specific field in player data
function PlayerDataManager.SetField(player, field, value)
	local data = playerDataCache[player.UserId]
	if data then
		data[field] = value
		return true
	end
	return false
end

-- Add lumens to player
function PlayerDataManager.AddLumens(player, amount)
	local data = playerDataCache[player.UserId]
	if data then
		data.Lumens = data.Lumens + amount
		return data.Lumens
	end
	return 0
end

-- Subtract lumens from player
function PlayerDataManager.SubtractLumens(player, amount)
	local data = playerDataCache[player.UserId]
	if data and data.Lumens >= amount then
		data.Lumens = data.Lumens - amount
		return true, data.Lumens
	end
	return false, data and data.Lumens or 0
end

-- Check if player has an aura
function PlayerDataManager.HasAura(player, auraName)
	local data = playerDataCache[player.UserId]
	return data and data.Auras[auraName] == true
end

-- Give aura to player
function PlayerDataManager.GiveAura(player, auraName)
	local data = playerDataCache[player.UserId]
	if data and data.Auras[auraName] ~= nil then
		data.Auras[auraName] = true
		return true
	end
	return false
end

-- Get equipped aura
function PlayerDataManager.GetEquippedAura(player)
	local data = playerDataCache[player.UserId]
	local equipped = data and data.EquippedAura or nil
	print("[PlayerDataManager] GetEquippedAura for", player.Name, ":", equipped)
	return equipped
end

-- Set equipped aura
function PlayerDataManager.SetEquippedAura(player, auraName)
	local data = playerDataCache[player.UserId]
	if data then
		data.EquippedAura = auraName
		return true
	end
	return false
end

-- Increment wins (called on rebirth)
function PlayerDataManager.IncrementWins(player)
	local data = playerDataCache[player.UserId]
	if data then
		data.Wins = data.Wins + 1
		return data.Wins
	end
	return 0
end

-- Reset player progress (for rebirth) - keeps Wins
function PlayerDataManager.ResetProgress(player)
	local data = playerDataCache[player.UserId]
	if data then
		data.Lumens = GameConfig.STARTING_LUMENS
		data.Auras = {
			BlueAura = false,
			GreenAura = false,
			RedAura = false,
		}
		data.EquippedAura = nil
		return true
	end
	return false
end

-- Lifecycle: Player joins
Players.PlayerAdded:Connect(function(player)
	PlayerDataManager.LoadData(player)
end)

-- Lifecycle: Player leaves
Players.PlayerRemoving:Connect(function(player)
	PlayerDataManager.SaveData(player)
	playerDataCache[player.UserId] = nil
end)

-- Lifecycle: Server shutdown
game:BindToClose(function()
	print("[PlayerDataManager] Server shutting down, saving all player data...")
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataManager.SaveData(player)
	end
end)

return PlayerDataManager
