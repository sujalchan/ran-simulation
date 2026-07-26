local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- wait for character
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- get ui elements
local playerGui = player:WaitForChild("PlayerGui")
local dashboardGui = playerGui:WaitForChild("DashboardGui")
local townFrame = dashboardGui:WaitForChild("TownFrame")

-- make dashboard visible
dashboardGui.Enabled = true
townFrame.Visible = true

-- hide unwanted ui elements
local metricsContainer = townFrame:FindFirstChild("MetricsContainer")
if metricsContainer then
	local cardQuality = metricsContainer:FindFirstChild("Card_Quality")
	if cardQuality then cardQuality.Visible = false end

	local cardTower = metricsContainer:FindFirstChild("Card_Tower")
	if cardTower then
		local capacityBar = cardTower:FindFirstChild("CapacityBar")
		if capacityBar then capacityBar.Visible = false end
		local capacityText = cardTower:FindFirstChild("CapacityText")
		if capacityText then capacityText.Visible = false end
		local statusBadge = cardTower:FindFirstChild("StatusBadge")
		if statusBadge then statusBadge.Visible = false end
	end
end

local insightLabel = townFrame:FindFirstChild("InsightLabel")
if insightLabel then insightLabel.Visible = false end

-- find ui elements
local function findUIElements()
	local ui = {}

	if not metricsContainer then
		warn("metrics container not found")
		return ui
	end

	local cardSignal = metricsContainer:FindFirstChild("Card_Signal")
	if cardSignal then
		ui.signalValue = cardSignal:FindFirstChild("Value")
		ui.barsContainer = cardSignal:FindFirstChild("BarsContainer")
	end

	local cardTower = metricsContainer:FindFirstChild("Card_Tower")
	if cardTower then
		ui.towerName = cardTower:FindFirstChild("TowerName")
		ui.towerDetails = cardTower:FindFirstChild("TowerDetails")
	end

	return ui
end

local ui = findUIElements()

-- get signal bars
local bars = {}
if ui.barsContainer then
	for i = 1, 5 do
		local bar = ui.barsContainer:FindFirstChild("Bar" .. i)
		if bar then bars[i] = bar end
	end
end

-- update signal bars
local function updateSignalBars(rsrp)
	local barCount = rsrp >= -60 and 5
		or rsrp >= -70 and 4
		or rsrp >= -80 and 3
		or rsrp >= -90 and 2
		or rsrp >= -100 and 1
		or 0

	for i = 1, 5 do
		local bar = bars[i]
		if bar then
			bar.BackgroundTransparency = i <= barCount and 0 or 0.7
		end
	end
end

-- main update loop
RunService.RenderStepped:Connect(function()
	if not humanoidRootPart then return end

	-- read attributes from the player
	local towerName = player:GetAttribute("ConnectedTower") or "searching..."
	local rsrp = player:GetAttribute("RSRP") or -120
	local towerDistance = player:GetAttribute("TowerDistance") or 0

	-- debug: print what we're reading
	print("dashboard: tower=", towerName, "rsrp=", rsrp, "distance=", towerDistance)

	-- update signal strength
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

	-- update signal bars
	updateSignalBars(rsrp)

	-- update tower name
	if ui.towerName then
		ui.towerName.Text = towerName
	end

	-- update tower distance
	if ui.towerDetails then
		ui.towerDetails.Text = "distance: " .. math.floor(towerDistance) .. "m"
	end
end)

print("small town dashboard loaded")