local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local startGame = ReplicatedStorage:WaitForChild("StartGame")

local defaultDistance = 150
local minDistance = 0
local maxDistance = 400

startGame.OnClientEvent:Connect(function()

	camera.CameraType = Enum.CameraType.Custom
	player.CameraMode = Enum.CameraMode.Classic

	player.CameraMinZoomDistance = defaultDistance
	player.CameraMaxZoomDistance = defaultDistance
	task.wait(0.1)

	player.CameraMinZoomDistance = minDistance
	player.CameraMaxZoomDistance = maxDistance
end)