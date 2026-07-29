local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FrequencyData = require(ReplicatedStorage:WaitForChild("FrequencyData"))

local player = Players.LocalPlayer
local dashboardGui = script.Parent
local room1Frame = dashboardGui:WaitForChild("Room1Frame")

local frequencyChangedEvent = ReplicatedStorage:WaitForChild("FrequencyChangedEvent")
local npcSpawnEvent = ReplicatedStorage:FindFirstChild("NPCSpawnEvent")

local npcCount = 0
local baseSignalValue = -120

-- room visibility

local VISIBLE_POSITION = UDim2.new(0.01, 0, 0.02, 0)
local HIDDEN_POSITION = UDim2.new(-0.5, 0, 0.02, 0)

local TWEEN_INFO = TweenInfo.new(
	0.5,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

local currentTween

room1Frame.Position = HIDDEN_POSITION
room1Frame.Visible = false
dashboardGui.Enabled = false

local function updateDashboardVisibility()
	local inRoomOne = player:GetAttribute("InRoomOne") == true
	local inRoomTwo = player:GetAttribute("InRoomTwo") == true

	dashboardGui.Enabled = inRoomOne or inRoomTwo

	if currentTween then
		currentTween:Cancel()
	end

	if inRoomOne then
		room1Frame.Visible = true

		currentTween = TweenService:Create(
			room1Frame,
			TWEEN_INFO,
			{ Position = VISIBLE_POSITION }
		)

		currentTween:Play()
	else
		room1Frame.Visible = false
		room1Frame.Position = HIDDEN_POSITION
	end
end

player:GetAttributeChangedSignal("InRoomOne"):Connect(updateDashboardVisibility)
player:GetAttributeChangedSignal("InRoomTwo"):Connect(updateDashboardVisibility)

updateDashboardVisibility()

-- npc count

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

-- ui elements

local metricsContainer = room1Frame:WaitForChild("MetricsContainer")

local cardSignal = metricsContainer:WaitForChild("Card_Signal")
local signalValue = cardSignal:WaitForChild("Value")
local signalStatusBadge = cardSignal:WaitForChild("StatusBadge")
local barsContainer = cardSignal:WaitForChild("BarsContainer")

local cardQuality = metricsContainer:WaitForChild("Card_Quality")
local qualityValue = cardQuality:WaitForChild("Value")
local progressFill = cardQuality.ProgressBar:WaitForChild("ProgressFill")
local qualityStatusBadge = cardQuality:WaitForChild("StatusBadge")

local cardTower = metricsContainer:WaitForChild("Card_Tower")
local towerNameLabel = cardTower:WaitForChild("TowerName")
local towerDetailsLabel = cardTower:WaitForChild("TowerDetails")
local capacityFill = cardTower.CapacityBar:WaitForChild("CapacityFill")
local capacityText = cardTower:WaitForChild("CapacityText")
local towerStatusBadge = cardTower:WaitForChild("StatusBadge")

local experimentFrame = room1Frame:WaitForChild("ExperimentFrame")
local beforeValue = experimentFrame:WaitForChild("BeforeValue")
local materialDisplay = experimentFrame:WaitForChild("MaterialDisplay")
local afterValue = experimentFrame:WaitForChild("AfterValue")
local insightLabel = experimentFrame:WaitForChild("InsightLabel")

local bars = {}

for i = 1, 5 do
	bars[i] = barsContainer:WaitForChild("Bar" .. i)
end

-- frequency slider logic
local slider = room1Frame:FindFirstChild("FrequencySlider")
if slider then
	local frequencyOptions = {
		{name = "700 MHz (4G)", band = "700 MHz", divisor = 1.2, maxDistance = 45},
		{name = "1800 MHz (4G)", band = "1800 MHz", divisor = 0.9, maxDistance = 40},
		{name = "2100 MHz (4G)", band = "2100 MHz", divisor = 0.7, maxDistance = 35},
		{name = "3500 MHz (5G)", band = "3500 MHz", divisor = 0.5, maxDistance = 30},
	}

	local knob = slider:FindFirstChild("Knob")
	local fill = slider:FindFirstChild("SliderFill")
	local freqLabel = room1Frame:FindFirstChild("FrequencyLabel")

	local currentIndex = 4
	local isDragging = false
	local lastSentIndex = 4

	-- get knob size
	local function getKnobOffset()
		local knobSize = knob and knob.AbsoluteSize.X or 24
		return knobSize / 2
	end

	-- update visual position
	local function updateSliderVisual(ratio)
		ratio = math.clamp(ratio, 0, 1)
		local halfKnob = getKnobOffset()

		if knob then
			knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		end
		if fill then
			fill.Size = UDim2.new(ratio, 0, 1, 0)
		end
	end

	-- snap to nearest frequency
	local function snapToIndex(index)
		local pos = (index - 1) / (#frequencyOptions - 1)
		local halfKnob = getKnobOffset()
		if knob then
			knob.Position = UDim2.new(pos, -halfKnob, 0.5, 0)
		end
		if fill then
			fill.Size = UDim2.new(pos, 0, 1, 0)
		end
		if freqLabel then
			freqLabel.Text = frequencyOptions[index].name
		end
	end

	local function sendFrequencyToServer(index)
		if index ~= lastSentIndex then
			lastSentIndex = index
			local freq = frequencyOptions[index]
			frequencyChangedEvent:FireServer(freq.band, freq.maxDistance)
			print("Frequency changed to:", freq.name)
		end
	end

	-- get ratio from mouse
	local function getRatioFromMouse(input)
		local relativeX = input.Position.X - slider.AbsolutePosition.X
		return math.clamp(relativeX / slider.AbsoluteSize.X, 0, 1)
	end

	local function getNearestIndexFromRatio(ratio)
		local index = math.floor(ratio * (#frequencyOptions - 1) + 0.5)
		return math.clamp(index + 1, 1, #frequencyOptions)
	end

	-- mouse down on slider
	slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			local ratio = getRatioFromMouse(input)
			updateSliderVisual(ratio)
			currentIndex = getNearestIndexFromRatio(ratio)
			if freqLabel then
				freqLabel.Text = frequencyOptions[currentIndex].name
			end
		end
	end)

	-- mouse down on knob
	if knob then
		knob.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				isDragging = true
				local ratio = getRatioFromMouse(input)
				updateSliderVisual(ratio)
				currentIndex = getNearestIndexFromRatio(ratio)
				if freqLabel then
					freqLabel.Text = frequencyOptions[currentIndex].name
				end
			end
		end)
	end

	-- mouse drag (smooth)
	local userInputService = game:GetService("UserInputService")
	userInputService.InputChanged:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local ratio = getRatioFromMouse(input)
			updateSliderVisual(ratio)
			currentIndex = getNearestIndexFromRatio(ratio)
			if freqLabel then
				freqLabel.Text = frequencyOptions[currentIndex].name
			end
		end
	end)

	-- mouse up
	userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = false
			snapToIndex(currentIndex)
			sendFrequencyToServer(currentIndex)
		end
	end)

	-- initial update
	snapToIndex(currentIndex)
end

-- room 1 ui updates

local function updateSignalBars(rsrp)
	local barCount =
		rsrp >= -60 and 5
		or rsrp >= -70 and 4
		or rsrp >= -80 and 3
		or rsrp >= -90 and 2
		or rsrp >= -100 and 1
		or 0

	for i = 1, 5 do
		bars[i].BackgroundTransparency =
			i <= barCount and 0 or 0.7
	end
end

local function updateUI(rsrp, sinr, materialName, towerDistance)
	-- SIGNAL STRENGTH (RSRP) UI
	signalValue.Text = rsrp .. " dBm"

	if rsrp >= -70 then
		signalValue.TextColor3 = Color3.fromRGB(46, 204, 113)
		signalStatusBadge.Text = "✅ Excellent"
		signalStatusBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
	elseif rsrp >= -90 then
		signalValue.TextColor3 = Color3.fromRGB(243, 156, 18)
		signalStatusBadge.Text = "⚠️ Fair"
		signalStatusBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
	else
		signalValue.TextColor3 = Color3.fromRGB(231, 76, 60)
		signalStatusBadge.Text = "❌ Poor"
		signalStatusBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
	end

	updateSignalBars(rsrp)

	-- SIGNAL QUALITY (SINR) UI
	
	local qualityPercent = sinr / 20

	qualityValue.Text = sinr .. " dB"
	progressFill.Size = UDim2.new(qualityPercent, 0, 1, 0)

	if sinr >= 15 then
		qualityStatusBadge.Text = "🎧 Clear"
		qualityStatusBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
	elseif sinr >= 8 then
		qualityStatusBadge.Text = "📻 Some interference"
		qualityStatusBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
	else
		qualityStatusBadge.Text = "⚠️ Poor quality"
		qualityStatusBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
	end
	
	-- TOWER AND CAPACITY UI 
	local towerName = player:GetAttribute("ClosestSignalSource")
	towerNameLabel.Text = towerName or "Searching..."
	towerDetailsLabel.Text = math.floor(towerDistance) .. "m away"

	local userCount = 1 + npcCount
	local loadPercent

	if npcCount > 0 then
		loadPercent = math.min(95, (userCount / 500) * 100)
	else
		loadPercent = math.max(5, 50 - towerDistance / 5)
	end

	capacityText.Text = userCount .. " / 50 users"
	capacityFill.Size = UDim2.new(loadPercent / 100, 0, 1, 0)

	if loadPercent < 30 then
		capacityText.TextColor3 = Color3.fromRGB(46, 204, 113)
		towerStatusBadge.Text = "📊 Light load"
		towerStatusBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
	elseif loadPercent < 70 then
		capacityText.TextColor3 = Color3.fromRGB(243, 156, 18)
		towerStatusBadge.Text = "📊 Medium load"
		towerStatusBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
	else
		capacityText.TextColor3 = Color3.fromRGB(231, 76, 60)
		towerStatusBadge.Text = "📊 Heavy load"
		towerStatusBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
	end

	-- material experiment

	if materialName == "SignalSource" then
		materialName = "None"
	end

	if materialName == "None" then
		baseSignalValue = rsrp
	end

	beforeValue.Text = baseSignalValue .. " dBm"
	afterValue.Text = rsrp .. " dBm"

	if materialName ~= "None" then
		materialDisplay.Text = materialName
		materialDisplay.TextColor3 = Color3.fromRGB(0, 163, 224)
	else
		materialDisplay.Text = "None"
		materialDisplay.TextColor3 = Color3.fromRGB(150, 160, 170)
	end

	if materialName == "Wood" then
		insightLabel.Text =
			"🚪 Wood blocks a little signal. Houses let most signal through!"
	elseif materialName == "Concrete" then
		insightLabel.Text =
			"🏢 Concrete blocks a lot of signal! That's why buildings need indoor antennas."
	elseif materialName == "Metal" then
		insightLabel.Text =
			"🎛️ Metal completely blocks radio waves - like an elevator!"
	elseif npcCount > 0 then
		insightLabel.Text =
			"👥 " .. npcCount .. " NPCs connected! More users = higher tower load!"
	else
		insightLabel.Text =
			"💡 Walk near different materials or change the frequency to see how they affect signal!"
	end
end

RunService.RenderStepped:Connect(function()
	local rsrp = player:GetAttribute("RSRP") or -120
	local sinr = math.clamp(
		player:GetAttribute("SINR") or 0,
		0,
		20
	)
	local materialName = player:GetAttribute("Material") or "None"
	local towerDistance = player:GetAttribute("TowerDistance") or 0

	updateUI(rsrp, sinr, materialName, towerDistance)
end)