local player = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera

local startGame = game:GetService("ReplicatedStorage"):WaitForChild("StartGame")

startGame.OnClientEvent:Connect(function()

	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")

	camera.CameraType = Enum.CameraType.Scriptable

	local townCenter = Vector3.new(0, 0, 0) 

	camera.CFrame = CFrame.new(
		townCenter + Vector3.new(0, 250, 0),
		townCenter
	)

end)