--!strict
-- PlayerDataTests.lua
-- Simple sanity tests for PlayerData core logic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerData = require(ReplicatedStorage.PlayerData)

local PlayerDataTests = {}

-- Very lightweight test helper
local function assertEqual(actual, expected, message)
	if actual ~= expected then
		warn("[PlayerDataTests] Assertion failed: " .. message .. string.format(" (expected %s, got %s)", tostring(expected), tostring(actual)))
	else
		print("[PlayerDataTests] OK: " .. message)
	end
end

function PlayerDataTests.run(player: Player)
	print("[PlayerDataTests] Running for player", player.Name)

	-- Assume PlayerData.load has already been called by the server on join
	local startLumin = PlayerData.get(player, "Lumin") or 0

	-- Test addLumin
	PlayerData.addLumin(player, 10)
	local afterAdd = PlayerData.get(player, "Lumin")
	assertEqual(afterAdd, startLumin + 10, "addLumin should increase Lumin by 10")

	-- Test subtractLumin (not going below zero in practice game logic is recommended)
	PlayerData.subtractLumin(player, 5)
	local afterSub = PlayerData.get(player, "Lumin")
	assertEqual(afterSub, startLumin + 5, "subtractLumin should decrease Lumin by 5")

	-- Test aura ownership and equip logic
	local testAura = "TestAura"
	PlayerData.addAura(player, testAura)
	local hasAura = PlayerData.hasAura(player, testAura)
	assertEqual(hasAura, true, "Player should own TestAura after addAura")

	PlayerData.setEquippedAura(player, testAura)
	local equippedAura = PlayerData.getEquippedAura(player)
	assertEqual(equippedAura, testAura, "Equipped aura should be TestAura after setEquippedAura")

	print("[PlayerDataTests] Completed for player", player.Name)
end

return PlayerDataTests
