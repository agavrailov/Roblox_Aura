--!strict
-- PlayerData.lua
-- Manages player data, including Lumin and saved auras.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataStore = DataStoreService:GetDataStore("AuraCollectorPlayerData")

local PlayerData = {}

-- Default data for a new player
local DEFAULT_DATA = {
	Lumin = 0,
	Auras = {}, -- Table to store owned auras
	EquippedAura = nil, -- The currently equipped aura
}

-- Table to hold all active player data in memory
local playerDataCache = {}

function PlayerData.get(player: Player, key: string)
	local data = playerDataCache[player.UserId]
	if data then
		return data[key]
	end
	return nil
end

function PlayerData.set(player: Player, key: string, value: any)
	local data = playerDataCache[player.UserId]
	if data then
		data[key] = value
	end
end

function PlayerData.addLumin(player: Player, amount: number)
	local currentLumin = PlayerData.get(player, "Lumin")
	if currentLumin ~= nil then
		PlayerData.set(player, "Lumin", currentLumin + amount)
	end
end

function PlayerData.subtractLumin(player: Player, amount: number)
	local currentLumin = PlayerData.get(player, "Lumin")
	if currentLumin ~= nil then
		PlayerData.set(player, "Lumin", currentLumin - amount)
	end
end

function PlayerData.hasAura(player: Player, auraName: string)
	local auras = PlayerData.get(player, "Auras")
	if auras then
		for _, ownedAura in ipairs(auras) do
			if ownedAura == auraName then
				return true
			end
		end
	end
	return false
end

function PlayerData.addAura(player: Player, auraName: string)
	local auras = PlayerData.get(player, "Auras")
	if auras and not PlayerData.hasAura(player, auraName) then
		table.insert(auras, auraName)
	end
end

function PlayerData.load(player: Player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		-- Merge loaded data with default data to ensure new fields are added
		playerDataCache[player.UserId] = table.clone(DEFAULT_DATA)
		for k, v in pairs(data) do
			playerDataCache[player.UserId][k] = v
		end
		print("Loaded data for " .. player.Name .. ": " .. game.HttpService:JSONEncode(playerDataCache[player.UserId]))
	else
		playerDataCache[player.UserId] = table.clone(DEFAULT_DATA)
		warn("Could not load data for " .. player.Name .. ". Using default data. Error: " .. tostring(data))
	end
end

function PlayerData.save(player: Player)
	local data = playerDataCache[player.UserId]
	if data then
		local success, err = pcall(function()
			PlayerDataStore:SetAsync(player.UserId, data)
		end)

		if success then
			print("Saved data for " .. player.Name)
		else
			warn("Could not save data for " .. player.Name .. ". Error: " .. tostring(err))
		end
	end
	playerDataCache[player.UserId] = nil -- Clear from cache after saving
end

-- Connect to PlayerAdded and PlayerRemoving events
Players.PlayerAdded:Connect(PlayerData.load)
Players.PlayerRemoving:Connect(PlayerData.save)

return PlayerData
