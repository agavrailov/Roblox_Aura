-- ZoneBarrier.lua
-- Prevents players from entering zones without proper aura

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneAccess = require(script.Parent.ZoneAccess)
local RectGrid = require(ReplicatedStorage.RectGrid)

local ZoneBarrier = {}

-- Store active zone tracking per player
local playerCurrentZone = {}

-- Get which zone a position is in
local function GetZoneAtPosition(position)
	local x, z = RectGrid.WorldToGrid(position)
	if RectGrid.IsValidCoord(x, z) then
		return x, z
	end
	return nil, nil
end

-- Check if player can be in this zone
local function CanPlayerBeInZone(player, zoneType)
	return ZoneAccess.CanEnterZone(player, zoneType)
end

-- Find nearest accessible zone and teleport player there
local function TeleportToNearestAccessibleZone(player, currentX, currentZ, allZones)
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Find closest accessible zone
	local closestZone = nil
	local closestDist = math.huge
	
	for _, zone in ipairs(allZones) do
		if CanPlayerBeInZone(player, zone.Type) then
			local dx = zone.GridX - currentX
			local dz = zone.GridZ - currentZ
			local dist = math.sqrt(dx*dx + dz*dz)
			
			if dist < closestDist then
				closestDist = dist
				closestZone = zone
			end
		end
	end
	
	if closestZone then
		humanoidRootPart.CFrame = CFrame.new(closestZone.Position + Vector3.new(0, 5, 0))
		warn(player.Name .. " teleported to " .. closestZone.Type .. " zone")
	else
		-- No accessible zones, teleport to spawn
		humanoidRootPart.CFrame = CFrame.new(0, 50, 0)
		warn(player.Name .. " has no accessible zones!")
	end
end

-- Setup zone monitoring for all zones
function ZoneBarrier.Setup(zones)
	game.Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
			
			-- Monitor player position constantly
			task.spawn(function()
				while character.Parent do
					local x, z = GetZoneAtPosition(humanoidRootPart.Position)
					
					if x and z then
						-- Find which zone player is in
						for _, zone in ipairs(zones) do
							if zone.GridX == x and zone.GridZ == z then
								-- Check if player has access
								if not CanPlayerBeInZone(player, zone.Type) then
									-- Teleport them out
									TeleportToNearestAccessibleZone(player, x, z, zones)
									
									-- Show message
									warn(player.Name .. " blocked from " .. zone.Type .. " zone - need " .. zone.Type .. " aura or higher")
								end
								break
							end
						end
					end
					
					task.wait(0.5) -- Check twice per second
				end
			end)
		end)
	end)
end

return ZoneBarrier
