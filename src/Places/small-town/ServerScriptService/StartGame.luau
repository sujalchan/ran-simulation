local prompt = workspace.StartButton.ProximityPrompt
local startGame = game.ReplicatedStorage.StartGame

prompt.Triggered:Connect(function(player)

	print(player.Name .. " started the game.")

	startGame:FireClient(player)

end)