local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Frequency data 
local frequencyData = {
	["700 MHz"]  = { divisor = 1.2 },
	["1800 MHz"] = { divisor = 0.9 },
	["2100 MHz"] = { divisor = 0.7 },
	["3500 MHz"] = { divisor = 0.5 }
}
local DEFAULT_FREQUENCY = "2100 MHz"

-- Folder for visual spheres
local visualFolder = Workspace:FindFirstChild("AllSignalVisuals")
if not visualFolder then
	visualFolder = Instance.new("Folder")
	visualFolder.Name = "AllSignalVisuals"
	visualFolder.Parent = Workspace
end

local isVisible = false 

-- Calculate signal distance
local function calculateDistanceForRSRP(targetRSRP, maxPower, divisor)
	local scaledDist = (maxPower - targetRSRP) * divisor
	return math.max(10, scaledDist * 10)
end

-- Create and update visual sphere parts
local function updateSpherePart(sphereName, radius, originPos, color, transparency)
	local sphere = visualFolder:FindFirstChild(sphereName)
	if not sphere then
		sphere = Instance.new("Part")
		sphere.Name = sphereName
		sphere.Shape = Enum.PartType.Ball
		sphere.Material = Enum.Material.SmoothPlastic
		sphere.CanCollide = false
		sphere.CanTouch = false
		sphere.CanQuery = false -- Prevents raycast interference
		sphere.CastShadow = false -- Prevents shadows in dark areas
		sphere.Anchored = true
		sphere.Parent = visualFolder
		print("[SignalVisualizer] Created sphere:", sphereName)
	end

	sphere.Color = color
	sphere.Transparency = transparency
	sphere.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	sphere.CFrame = CFrame.new(originPos)
	return sphere
end

-- Get antenna origin position
local function getSignalOriginPos(model)
	local origin = model:FindFirstChild("SignalOrigin", true)
	if origin then
		if origin:IsA("BasePart") then
			return origin.Position
		elseif origin:IsA("Attachment") then
			return origin.WorldPosition
		end
	end
	if model.PrimaryPart then
		return model.PrimaryPart.Position
	end
	return model:GetPivot().Position
end

-- Update spheres for antennas
local function updateTowerVisuals()
	if not isVisible then
		visualFolder:ClearAllChildren()
		return
	end

	local freqBand = player:GetAttribute("FrequencyBand") or DEFAULT_FREQUENCY
	local freqInfo = frequencyData[freqBand] or frequencyData[DEFAULT_FREQUENCY]
	local divisor = freqInfo.divisor

	local activeSpheres = {}

	local function processModel(model, prefix)
		if not model:IsA("Model") then return end

		-- Unique identifier key
		local key = prefix .. "_" .. model.Name
		local originPos = getSignalOriginPos(model)
		local maxPower = model:GetAttribute("MaxPower") or -50

		local innerRadius  = calculateDistanceForRSRP(-60,  maxPower, divisor) -- Green
		local middleRadius = calculateDistanceForRSRP(-80,  maxPower, divisor) -- Yellow
		local outerRadius  = calculateDistanceForRSRP(-100, maxPower, divisor) -- Red

		activeSpheres[key .. "_Inner"] = true
		activeSpheres[key .. "_Middle"] = true
		activeSpheres[key .. "_Outer"] = true

		-- Center (Green)
		updateSpherePart(key .. "_Inner", innerRadius, originPos, Color3.fromRGB(0, 255, 120), 0.7)

		-- Middle (Yellow)
		updateSpherePart(key .. "_Middle", middleRadius, originPos, Color3.fromRGB(255, 220, 0), 0.8)

		-- Outer (Red)
		updateSpherePart(key .. "_Outer", outerRadius, originPos, Color3.fromRGB(255, 60, 60), 0.88)
	end

	-- Fixed town towers 
	local cellTowersFolder = Workspace:FindFirstChild("CellTowers")
	if cellTowersFolder then
		for index, tower in ipairs(cellTowersFolder:GetChildren()) do
			processModel(tower, "Town_" .. index)
		end
	end

	-- Player-placed antennas 
	local placedAntennasFolder = Workspace:FindFirstChild("PlacedAntennas")
	if placedAntennasFolder then
		for index, antenna in ipairs(placedAntennasFolder:GetChildren()) do
			processModel(antenna, "Placed_" .. index)
		end
	end

	-- Clean up spheres for removed antennas
	for _, sphere in ipairs(visualFolder:GetChildren()) do
		if not activeSpheres[sphere.Name] then
			sphere:Destroy()
		end
	end
end

-- Create toggle UI
local function createToggleUI()
	local playerGui = player:WaitForChild("PlayerGui")

	local oldGui = playerGui:FindFirstChild("CellTowerVisualizerGUI")
	if oldGui then oldGui:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "CellTowerVisualizerGUI"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Name = "ToggleButton"
	button.Size = UDim2.new(0, 160, 0, 36)
	button.Position = UDim2.new(1, -200, 0, 100)
	button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.Text = "Signal Range: OFF"
	button.Parent = gui

	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

	button.MouseButton1Click:Connect(function()
		isVisible = not isVisible
		if isVisible then
			button.Text = "Signal Range: ON"
			button.BackgroundColor3 = Color3.fromRGB(0, 120, 210)
		else
			button.Text = "Signal Range: OFF"
			button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		end
		updateTowerVisuals()
	end)
end

-- Initialize UI
createToggleUI()

-- Refreshes every 0.5s
task.spawn(function()
	while true do
		if isVisible then
			updateTowerVisuals()
		end
		task.wait(0.5)
	end
end)