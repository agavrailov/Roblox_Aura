-- Client.client.lua
-- Main client entry point - manages UI and client-side logic

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Load UI modules
local HUDManager = require(script.Parent.HUDManager)
local CraftingMenu = require(script.Parent.CraftingMenu)
local RelicTracker = require(script.Parent.RelicTracker)

-- Remote events
local SyncPlayerDataEvent = game.ReplicatedStorage.SyncPlayerData
local EquipAuraEvent = game.ReplicatedStorage.EquipAura
local CollectRelicEvent = game.ReplicatedStorage.CollectRelic
local GetPlayerDataFunction = game.ReplicatedStorage.GetPlayerData

-- Local player data cache
local localPlayerData = nil
local localRelicsData = {Blue = false, Green = false, Red = false}

print("[Client] Initializing Aura Maze client...")

-- Create UI
HUDManager.CreateHUD()
CraftingMenu.CreateMenu()
RelicTracker.CreateTracker()

-- Connect craft button to menu
local craftButton = HUDManager.GetCraftButton()
if craftButton then
	craftButton.MouseButton1Click:Connect(function()
		CraftingMenu.Toggle()
	end)
end

-- Handle player data sync from server
SyncPlayerDataEvent.OnClientEvent:Connect(function(playerData)
	print("[Client] Received player data sync")
	
	localPlayerData = playerData
	
	-- Update UI
	HUDManager.UpdateLumens(playerData.Lumens)
	HUDManager.UpdateEquippedAura(playerData.EquippedAura)
	CraftingMenu.UpdateAuraButtons(playerData)
	
	print("[Client] Updated UI - Lumens:", playerData.Lumens, "Equipped:", playerData.EquippedAura or "None")
end)

-- Handle aura equip notification
EquipAuraEvent.OnClientEvent:Connect(function(auraName)
	print("[Client] Aura equipped:", auraName)
	
	-- Update UI
	HUDManager.UpdateEquippedAura(auraName)
	
	-- Update visual aura effect on character
	-- TODO: Implement visual aura effects in next phase
end)

-- Handle relic collection
CollectRelicEvent.OnClientEvent:Connect(function(relicType)
	print("[Client] Collected relic:", relicType)
	
	-- Update local cache
	localRelicsData[relicType] = true
	
	-- Update HUD first (most important)
	RelicTracker.UpdateRelic(relicType, true)
	print("[Client] Updated tracker for", relicType)
	
	-- Hide the relic in the world for this player (protected so it can't break handler)
	local ok, err = pcall(function()
		local relicsFolder = workspace:FindFirstChild("Relics")
		if not relicsFolder then return end
		local relicPart = relicsFolder:FindFirstChild(relicType .. "Relic")
		if not relicPart then return end
		
		relicPart.Transparency = 1
		for _, child in ipairs(relicPart:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = 1
			elseif child:IsA("ParticleEmitter") then
				child.Enabled = false
			elseif child:IsA("PointLight") then
				child.Enabled = false
			elseif child:IsA("BillboardGui") then
				child.Enabled = false
			end
		end
		print("[Client] Hidden relic", relicType, "from world")
	end)
	if not ok then
		warn("[Client] Failed to hide relic:", err)
	end
	
	-- Check if all collected
	if localRelicsData.Blue and localRelicsData.Green and localRelicsData.Red then
		print("[Client] ALL RELICS COLLECTED! Portal should be accessible")
		-- TODO: Show portal notification
	end
end)

-- Request initial player data on spawn
player.CharacterAdded:Connect(function(character)
	task.wait(1) -- Wait for server to be ready
	
	print("[Client] Requesting initial player data...")
	local success, playerData = pcall(function()
		return GetPlayerDataFunction:InvokeServer()
	end)
	
	if success and playerData then
		localPlayerData = playerData
		HUDManager.UpdateLumens(playerData.Lumens)
		HUDManager.UpdateEquippedAura(playerData.EquippedAura)
		CraftingMenu.UpdateAuraButtons(playerData)
		print("[Client] Initial data loaded")
	else
		warn("[Client] Failed to get initial player data")
	end
end)

print("[Client] Aura Maze client ready!")
