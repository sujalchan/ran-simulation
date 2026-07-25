local startButton = workspace:FindFirstChild("StartButton", true)
local prompt = startButton and startButton:FindFirstChild("ProximityPrompt")
local startGame = game.ReplicatedStorage.StartGame

prompt.Triggered:Connect(function(player)

	print(player.Name .. " started the game.")

	startGame:FireClient(player)

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 130
		end
	end

end)