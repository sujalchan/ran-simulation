local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local startGame = ReplicatedStorage:WaitForChild("StartGame")

local defaultDistance = 150
local minDistance = 0.5
local maxDistance = 400
local ZOOM_STEP = 10

-- On-screen Controls UI 
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZoomInfoGui"
screenGui.ResetOnSpawn = false

local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "ZoomInfoLabel"
infoLabel.Size = UDim2.new(0, 200, 0, 50)
infoLabel.Position = UDim2.new(1, -220, 0, 20) 
infoLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
infoLabel.BackgroundTransparency = 0.4
infoLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
infoLabel.TextSize = 14
infoLabel.Font = Enum.Font.GothamBold
infoLabel.Text = "Press O to Zoom Out\nPress I to Zoom In"

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = infoLabel

infoLabel.Parent = screenGui
screenGui.Parent = playerGui


-- Camera Control Logic
startGame.OnClientEvent:Connect(function()
	camera.CameraType = Enum.CameraType.Custom
	player.CameraMode = Enum.CameraMode.Classic

	player.CameraMinZoomDistance = defaultDistance
	player.CameraMaxZoomDistance = defaultDistance
	task.wait(0.1)

	player.CameraMinZoomDistance = minDistance
	player.CameraMaxZoomDistance = maxDistance
end)

-- Function to adjust camera zoom distance
local function setZoom(targetZoom)
	targetZoom = math.clamp(targetZoom, minDistance, maxDistance)

	player.CameraMinZoomDistance = targetZoom
	player.CameraMaxZoomDistance = targetZoom

	task.defer(function()
		player.CameraMinZoomDistance = minDistance
		player.CameraMaxZoomDistance = maxDistance
	end)
end

-- Mouse Wheel Zoom Control
UIS.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		local currentZoom = player.CameraZoomDistance
		local direction = input.Position.Z 
		local newZoom = currentZoom - (direction * ZOOM_STEP)
		setZoom(newZoom)
	end
end)

-- O / I Key Zoom Control
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	local currentZoom = player.CameraZoomDistance

	if input.KeyCode == Enum.KeyCode.O then
		setZoom(currentZoom + ZOOM_STEP)
	elseif input.KeyCode == Enum.KeyCode.P then
		setZoom(currentZoom - ZOOM_STEP)
	end
end)