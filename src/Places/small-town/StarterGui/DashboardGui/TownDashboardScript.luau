local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- NPC count tracking
local npcSpawnEvent = ReplicatedStorage:FindFirstChild("NPCSpawnEvent")
local npcCount = 0

if npcSpawnEvent then
	npcSpawnEvent.OnClientEvent:Connect(function(...)
		local args = { ... }

		if args[1] == "countUpdate" then
			npcCount = args[2] or 0
		elseif type(args[1]) == "number" then
			npcCount = args[1]
		end
	end)

	task.wait(1)
	npcSpawnEvent:FireServer("getCount")
end

-- find ui elements
local function findUIElements()
	local ui = {}

	local metricsContainer = townFrame:FindFirstChild("MetricsContainer")
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
		-- find capacity related elements in the town tower card
		ui.capacityText = cardTower:FindFirstChild("CapacityText")
		ui.capacityFill = cardTower:FindFirstChild("CapacityBar")
		if ui.capacityFill then
			ui.capacityFill = ui.capacityFill:FindFirstChild("CapacityFill")
		end
		ui.towerBadge = cardTower:FindFirstChild("StatusBadge")
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

-- update functions
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
	local towerName = player:GetAttribute("ConnectedTower") or "Searching..."
	local rsrp = player:GetAttribute("RSRP") or -120
	local towerDistance = player:GetAttribute("TowerDistance") or 0

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
		ui.towerDetails.Text = "Distance: " .. math.floor(towerDistance) .. "m"
	end
	
	-- update tower load
	local userCount = 1 + npcCount
	local loadPercent

	if npcCount > 0 then
		loadPercent = math.min(95, (userCount / 500) * 100)
	else
		loadPercent = math.max(5, 50 - towerDistance / 5)
	end

	if ui.capacityText then
		ui.capacityText.Text = userCount .. " / 50 users"
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
			ui.towerBadge.Text = "📊 Light load"
			ui.towerBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif loadPercent < 70 then
			ui.towerBadge.Text = "📊 Medium load"
			ui.towerBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			ui.towerBadge.Text = "📊 Heavy load"
			ui.towerBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end
end)

print("Small Town dashboard loaded!")