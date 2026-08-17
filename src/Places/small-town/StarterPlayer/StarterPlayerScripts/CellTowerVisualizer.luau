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
local updateCoverageDisplay

-- Map boundaries
local MAP_BOUNDS = {
	minX = -623,
	maxX = 655,
	minZ = -817,
	maxZ = 698
}

-- Calculate signal distance
local function calculateDistanceForRSRP(targetRSRP, maxPower, divisor)
	local scaledDist = (maxPower - targetRSRP) * divisor
	return math.max(10, scaledDist * 10)
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

-- Collect all outer sphere data from antennas 
local function collectCoverageSpheres()
	local spheres = {}
	local freqBand = player:GetAttribute("FrequencyBand") or DEFAULT_FREQUENCY
	local freqInfo = frequencyData[freqBand] or frequencyData[DEFAULT_FREQUENCY]
	local divisor = freqInfo.divisor

	local function processModel(model)
		if not model:IsA("Model") then return end
		local originPos = getSignalOriginPos(model)
		local maxPower = model:GetAttribute("MaxPower") or -50
		local outerRadius = calculateDistanceForRSRP(-100, maxPower, divisor)
		table.insert(spheres, { center = originPos, radius = outerRadius })
	end

	local cellTowersFolder = Workspace:FindFirstChild("CellTowers")
	if cellTowersFolder then
		for _, tower in ipairs(cellTowersFolder:GetChildren()) do
			processModel(tower)
		end
	end

	local placedAntennasFolder = Workspace:FindFirstChild("PlacedAntennas")
	if placedAntennasFolder then
		for _, antenna in ipairs(placedAntennasFolder:GetChildren()) do
			processModel(antenna)
		end
	end

	return spheres
end

-- Calculate coverage percentage using grid sampling
local function calculateCoverage()
	local redSpheres = collectCoverageSpheres()
	if #redSpheres == 0 then return 0 end

	-- Grid sampling: 50x50 grid
	local gridSize = 50
	local totalPoints = gridSize * gridSize
	local coveredPoints = 0
	local groundY = 0

	local stepX = (MAP_BOUNDS.maxX - MAP_BOUNDS.minX) / gridSize
	local stepZ = (MAP_BOUNDS.maxZ - MAP_BOUNDS.minZ) / gridSize

	for i = 0, gridSize - 1 do
		local x = MAP_BOUNDS.minX + stepX * (i + 0.5)
		for j = 0, gridSize - 1 do
			local z = MAP_BOUNDS.minZ + stepZ * (j + 0.5)
			local point = Vector3.new(x, groundY, z)

			for _, sphere in ipairs(redSpheres) do
				local dist = (point - sphere.center).Magnitude
				if dist <= sphere.radius then
					coveredPoints = coveredPoints + 1
					break
				end
			end
		end
	end

	return math.floor((coveredPoints / totalPoints) * 100 + 0.5)
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

	-- Coverage indicator label
	local coverageLabel = Instance.new("TextLabel")
	coverageLabel.Name = "CoverageLabel"
	coverageLabel.Size = UDim2.new(0, 160, 0, 36)
	coverageLabel.Position = UDim2.new(1, -200, 0, 142)
	coverageLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	coverageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	coverageLabel.Font = Enum.Font.GothamBold
	coverageLabel.TextSize = 12
	coverageLabel.Text = "Coverage: 0 / 100"
	coverageLabel.Visible = true
	coverageLabel.Parent = gui

	Instance.new("UICorner", coverageLabel).CornerRadius = UDim.new(0, 8)

	-- Coverage progress bar background
	local barBg = Instance.new("Frame")
	barBg.Name = "CoverageBarBg"
	barBg.Size = UDim2.new(0, 140, 0, 6)
	barBg.Position = UDim2.new(0, 10, 1, -10)
	barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	barBg.BorderSizePixel = 0
	barBg.Parent = coverageLabel

	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 3)

	-- Coverage progress bar fill
	local barFill = Instance.new("Frame")
	barFill.Name = "CoverageBarFill"
	barFill.Size = UDim2.new(0, 0, 0, 6)
	barFill.Position = UDim2.new(0, 0, 0, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 3)

	-- Function to update coverage display
	updateCoverageDisplay = function()
		local coverage = calculateCoverage()
		coverageLabel.Text = string.format("Coverage: %d / 100", coverage)
		player:SetAttribute("CoverageScore", coverage)

		-- Update progress bar
		local barWidth = math.clamp(coverage / 100, 0, 1) * 140
		barFill.Size = UDim2.new(0, barWidth, 0, 6)

		-- Color based on coverage level
		if coverage >= 75 then
			barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		elseif coverage >= 50 then
			barFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
		elseif coverage >= 25 then
			barFill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
		else
			barFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		end
	end

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
		updateCoverageDisplay()
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
		-- Always update coverage display 
		if updateCoverageDisplay then
			updateCoverageDisplay()
		end
		task.wait(0.5)
	end
end)