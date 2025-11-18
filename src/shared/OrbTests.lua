--!strict
-- OrbTests.lua
-- Simple sanity tests for Orb behavior in isolation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Orb = require(ReplicatedStorage.Orb)

local OrbTests = {}

local function assertEqual(actual, expected, message)
	if actual ~= expected then
		warn("[OrbTests] Assertion failed: " .. message .. string.format(" (expected %s, got %s)", tostring(expected), tostring(actual)))
	else
		print("[OrbTests] OK: " .. message)
	end
end

function OrbTests.run()
	print("[OrbTests] Running")

	local orbType = {
		Name = "TestOrb",
		LuminValue = 25,
		RespawnTime = 1,
	}

	local orb, part = Orb.new(Vector3.new(0, 5, 0), orbType)
	assertEqual(orb.luminAmount, 25, "Orb should store LuminValue from orbType")

	-- Collect once
	local value = orb:collect()
	assertEqual(value, 25, "First collect should return lumin amount")
	assertEqual(orb.enabled, false, "Orb should be disabled immediately after collect")

	-- Second collect should do nothing
	local value2 = orb:collect()
	assertEqual(value2, false, "Second collect should return false when disabled")

	print("[OrbTests] Completed")
end

return OrbTests
