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

local modeButton = room1Frame:WaitForChild("ModeButton")
local dropdownMenu = room1Frame:WaitForChild("FrequencyDropdownMenu")

modeButton.Text = FrequencyData.Default.name .. " ▼"

-- Populate/bind dropdown buttons using module options
for _, item in ipairs(dropdownMenu:GetChildren()) do
	if item:IsA("TextButton") then
		for _, frequency in ipairs(FrequencyData.Options) do
			if item.Text:find(frequency.name) then
				item.MouseButton1Click:Connect(function()
					modeButton.Text = frequency.name .. " ▼"
					dropdownMenu.Visible = false

					frequencyChangedEvent:FireServer(
						frequency.band,
						frequency.maxDistance
					)

					print(
						"Frequency changed to:",
						frequency.name,
						"| Divisor:",
						frequency.divisor
					)
				end)

				break
			end
		end
	end
end

modeButton.MouseButton1Click:Connect(function()
	dropdownMenu.Visible = not dropdownMenu.Visible
end)

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

local function updateUI(rsrp, materialName, towerDistance)
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

	-- signal quality

	local estimatedRsrq = math.clamp(rsrp + 10, -20, -3)
	local qualityPercent = math.clamp((estimatedRsrq + 20) / 17, 0, 1)

	qualityValue.Text = estimatedRsrq .. " dB"
	progressFill.Size = UDim2.new(qualityPercent, 0, 1, 0)

	if estimatedRsrq >= -10 then
		qualityStatusBadge.Text = "🎧 Clear"
		qualityStatusBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
	elseif estimatedRsrq >= -15 then
		qualityStatusBadge.Text = "📻 Some interference"
		qualityStatusBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
	else
		qualityStatusBadge.Text = "⚠️ Poor quality"
		qualityStatusBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
	end

	-- tower and capacity

	towerNameLabel.Text = "Mt Eden"
	towerDetailsLabel.Text =
		"Sector 2 · " .. math.floor(towerDistance) .. "m"

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
			"🌲 Wood blocks a little signal. Houses let most signal through!"
	elseif materialName == "Concrete" then
		insightLabel.Text =
			"🏢 Concrete blocks a lot of signal! That's why buildings need indoor antennas."
	elseif materialName == "Metal" then
		insightLabel.Text =
			"✨ METAL = FARADAY CAGE! ✨ Metal completely blocks radio waves - like an elevator!"
	elseif npcCount > 0 then
		insightLabel.Text =
			"👥 " .. npcCount .. " NPCs connected! More users = higher tower load!"
	else
		insightLabel.Text =
			"💡 Walk near different materials to see how they affect signal!"
	end
end

RunService.RenderStepped:Connect(function()
	local rsrp = player:GetAttribute("RSRP") or -120
	local materialName = player:GetAttribute("Material") or "None"
	local towerDistance = player:GetAttribute("TowerDistance") or 0

	updateUI(rsrp, materialName, towerDistance)
end)