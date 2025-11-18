--!strict
-- PlayerData.lua
-- Manages player data, including Lumin and saved auras.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataStore = DataStoreService:GetDataStore("AuraCollectorPlayerData")

local PlayerData = {}

12+local MAX_DATASTORE_RETRIES = 3
13+local RETRY_BACKOFF_SECONDS = 2
14+
15+local function retryDataStore(operationName: string, fn)
16+	local lastError
17+	for attempt = 1, MAX_DATASTORE_RETRIES do
18+		local success, result = pcall(fn)
19+		if success then
20+			return true, result
21+		end
22+		lastError = result
23+		warn(string.format("[PlayerData] %s failed (attempt %d/%d): %s", operationName, attempt, MAX_DATASTORE_RETRIES, tostring(result)))
24+		if attempt < MAX_DATASTORE_RETRIES then
25+			task.wait(RETRY_BACKOFF_SECONDS)
26+		end
27+	end
28+	return false, lastError
29+end
30+
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

function PlayerData.setEquippedAura(player: Player, auraName: string?)
	local data = playerDataCache[player.UserId]
	if data then
		data.EquippedAura = auraName
	end
end

function PlayerData.getEquippedAura(player: Player): string?
	local data = playerDataCache[player.UserId]
	if data then
		return data.EquippedAura
	end
	return nil
end

function PlayerData.load(player: Player)
	local success, data = retryDataStore("GetAsync", function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		-- Merge loaded data with default data to ensure new fields are added
		playerDataCache[player.UserId] = table.clone(DEFAULT_DATA)
		for k, v in pairs(data) do
			playerDataCache[player.UserId][k] = v
		end
		
		-- Fallback: If EquippedAura is nil but player owns auras, equip the first one
		if not playerDataCache[player.UserId].EquippedAura and #playerDataCache[player.UserId].Auras > 0 then
			playerDataCache[player.UserId].EquippedAura = playerDataCache[player.UserId].Auras[1]
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
		local dataCopy = table.clone(data)
		local success, err = retryDataStore("SetAsync", function()
			PlayerDataStore:SetAsync(player.UserId, dataCopy)
		end)

		if success then
			print("Saved data for " .. player.Name)
		else
			warn("Could not save data for " .. player.Name .. ". Error: " .. tostring(err))
		end
	end
	playerDataCache[player.UserId] = nil -- Clear from cache after saving
end

return PlayerData
