-- Server.server.lua
-- Main server script for Aura Collector Simulator

print("Aura Collector Simulator Server Script Loaded")

game.Players.PlayerAdded:Connect(function(player)
	print("Player " .. player.Name .. " has joined.")
end)

game.Players.PlayerRemoving:Connect(function(player)
	print("Player " .. player.Name .. " has left.")
end)
