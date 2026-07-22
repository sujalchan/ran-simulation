-- SMALL TOWN DASHBOARD SCRIPT

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local npcSpawnEvent = ReplicatedStorage:FindFirstChild("NPCSpawnEvent")
local player = Players.LocalPlayer

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Get UI elements
local playerGui = player:WaitForChild("PlayerGui")
local dashboardGui = playerGui:WaitForChild("DashboardGui")
local townFrame = dashboardGui:WaitForChild("TownFrame")

-- Find SignalSource
local cellTower = workspace:FindFirstChild("Cell Tower")
local signalSource = nil

if cellTower then
	signalSource = cellTower:FindFirstChild("SignalSource")
	if not signalSource then
		signalSource = cellTower:WaitForChild("SignalSource", 5)
	end
else
	signalSource = workspace:FindFirstChild("SignalSource")
	if not signalSource then
		signalSource = workspace:WaitForChild("SignalSource", 5)
	end
end

if not signalSource then
	warn("⚠️ SignalSource not found! Signal won't update!")
end

-- Track NPC count
local npcCount = 0

-- Find UI elements
local function findUIElements()
	local ui = {}

	local metricsContainer = townFrame:FindFirstChild("MetricsContainer")
	if not metricsContainer then
		warn("⚠️ MetricsContainer not found in TownFrame")
		return ui
	end

	-- Card 1: Signal Strength
	local cardSignal = metricsContainer:FindFirstChild("Card_Signal")
	if cardSignal then
		ui.signalValue = cardSignal:FindFirstChild("Value")
		ui.signalBadge = cardSignal:FindFirstChild("StatusBadge")
		ui.barsContainer = cardSignal:FindFirstChild("BarsContainer")
	end

	-- Card 2: Signal Quality
	local cardQuality = metricsContainer:FindFirstChild("Card_Quality")
	if cardQuality then
		ui.qualityValue = cardQuality:FindFirstChild("Value")
		ui.qualityBadge = cardQuality:FindFirstChild("StatusBadge")
		local progressBar = cardQuality:FindFirstChild("ProgressBar")
		if progressBar then
			ui.qualityFill = progressBar:FindFirstChild("ProgressFill")
		end
	end

	-- Card 3: Tower & Capacity
	local cardTower = metricsContainer:FindFirstChild("Card_Tower")
	if cardTower then
		ui.towerName = cardTower:FindFirstChild("TowerName")
		ui.towerDetails = cardTower:FindFirstChild("TowerDetails")
		ui.capacityText = cardTower:FindFirstChild("CapacityText")
		ui.towerBadge = cardTower:FindFirstChild("StatusBadge")
		local capacityBar = cardTower:FindFirstChild("CapacityBar")
		if capacityBar then
			ui.capacityFill = capacityBar:FindFirstChild("CapacityFill")
		end
	end

	-- Insight Label
	ui.insightLabel = townFrame:FindFirstChild("InsightLabel")
	
	return ui
end

local ui = findUIElements()

-- Get signal bars
local bars = {}
if ui.barsContainer then
	for i = 1, 5 do
		local bar = ui.barsContainer:FindFirstChild("Bar" .. i)
		if bar then bars[i] = bar end
	end
end

-- Signal calculation
local function calculateSignal(towerDistance)
	local baseSignal = -50 - (towerDistance / 5)
	baseSignal = math.max(-120, math.min(-50, baseSignal))
	return math.floor(baseSignal)
end

-- Update functions
local function updateSignalBars(rsrp)
	local barCount = rsrp >= -60 and 5 or rsrp >= -70 and 4 or rsrp >= -80 and 3 or rsrp >= -90 and 2 or rsrp >= -100 and 1 or 0
	for i = 1, 5 do
		local bar = bars[i]
		if bar then
			bar.BackgroundTransparency = i <= barCount and 0 or 0.7
		end
	end
end

local function updateUI(rsrp, towerDistance)
	-- Card 1: Signal Strength
	if ui.signalValue then
		ui.signalValue.Text = rsrp .. " dBm"
		if rsrp >= -70 then
			ui.signalValue.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif rsrp >= -90 then
			ui.signalValue.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			ui.signalValue.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end

	if ui.signalBadge then
		if rsrp >= -70 then
			ui.signalBadge.Text = "✅ Excellent"
			ui.signalBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif rsrp >= -90 then
			ui.signalBadge.Text = "⚠️ Fair"
			ui.signalBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			ui.signalBadge.Text = "❌ Poor"
			ui.signalBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end

	-- Insight label
	if ui.insightLabel then
		if npcCount and npcCount > 0 then
			ui.insightLabel.Text = "👥 " .. npcCount .. " NPCs connected! More users = higher tower load & more interference!"
		else
			ui.insightLabel.Text = "💡 Move around the town to see how signal changes with distance!"
		end
	end
	
	updateSignalBars(rsrp)

	-- Card 2: Signal Quality (affected by NPCs)
	local estimatedRsrq = math.max(-20, math.min(-3, rsrp + 10))

	-- Add interference from NPCs (more NPCs = worse quality)
	if npcCount and npcCount > 0 then
		local interference = math.min(8, npcCount / 5)
		estimatedRsrq = math.max(-20, estimatedRsrq - interference)
	end

	if ui.qualityValue then
		ui.qualityValue.Text = math.floor(estimatedRsrq) .. " dB"
	end

	if ui.qualityFill then
		local percent = math.max(0, math.min(100, ((estimatedRsrq + 20) / 17) * 100))
		ui.qualityFill.Size = UDim2.new(percent / 100, 0, 1, 0)
	end

	if ui.qualityBadge then
		if estimatedRsrq >= -10 then
			ui.qualityBadge.Text = "Clear"
			ui.qualityBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif estimatedRsrq >= -15 then
			ui.qualityBadge.Text = "Some interference"
			ui.qualityBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			ui.qualityBadge.Text = "Poor quality"
			ui.qualityBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end

	-- Card 3: Tower & Capacity (affected by NPCs)
	if ui.towerName then
		ui.towerName.Text = "Mt Eden"
	end

	if ui.towerDetails then
		ui.towerDetails.Text = "Sector 2 · " .. math.floor(towerDistance) .. "m"
	end

	-- Calculate tower load based on NPC count
	local loadPercent = 0
	local userCount = 1 -- Yourself

	if npcCount and npcCount > 0 then
		userCount = 1 + npcCount
		loadPercent = math.min(95, (userCount / 500) * 100)
	else
		loadPercent = math.max(5, 50 - (towerDistance / 5))
	end

	if ui.capacityText then
		ui.capacityText.Text = userCount .. " / 500 users"
		if loadPercent < 30 then
			ui.capacityText.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif loadPercent < 70 then
			ui.capacityText.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			ui.capacityText.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end

	if ui.capacityFill then
		ui.capacityFill.Size = UDim2.new(loadPercent / 100, 0, 1, 0)
	end

	if ui.towerBadge then
		if loadPercent < 30 then
			ui.towerBadge.Text = "Light load"
			ui.towerBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif loadPercent < 70 then
			ui.towerBadge.Text = "Medium load"
			ui.towerBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			ui.towerBadge.Text = "Heavy load"
			ui.towerBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end
end

-- NPC COUNT TRACKING
local function updateNPCCount(count)
	npcCount = count or 0
end

-- Listen for NPC count updates from server
if npcSpawnEvent then
	npcSpawnEvent.OnClientEvent:Connect(function(...)
		local args = {...}
		if args[1] == "countUpdate" then
			updateNPCCount(args[2])
		elseif type(args[1]) == "number" then
			updateNPCCount(args[1])
		end
	end)
end

-- Request initial NPC count
task.wait(1)
if npcSpawnEvent then
	npcSpawnEvent:FireServer("getCount")
end

-- MAIN LOOP
RunService.RenderStepped:Connect(function()
	if not humanoidRootPart or not signalSource then
		if not signalSource then
			local cellTower = workspace:FindFirstChild("Cell Tower")
			if cellTower then
				signalSource = cellTower:FindFirstChild("SignalSource")
			end
		end
		return
	end

	local towerDistance = (humanoidRootPart.Position - signalSource.Position).Magnitude
	local rsrp = calculateSignal(towerDistance)
	updateUI(rsrp, towerDistance, npcCount)  -- ← Fixed!
end)

print("Small Town Dashboard Loaded!")