local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local frequencyChangedEvent = ReplicatedStorage:WaitForChild("FrequencyChangedEvent")
local player = Players.LocalPlayer

-- NPC count tracking
local npcCount = 0
local npcSpawnEvent = ReplicatedStorage:FindFirstChild("NPCSpawnEvent")

local function updateNPCCount(count)
	npcCount = count or 0
end

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

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local Source = workspace:WaitForChild("SignalSource")

local playerGui = player:WaitForChild("PlayerGui")
local dashboardGui = playerGui:WaitForChild("DashboardGui")
local room1Frame = dashboardGui:WaitForChild("Room1Frame")

local VISIBLE_POSITION = UDim2.new(0.01, 0, 0.02, 0)
local HIDDEN_POSITION = UDim2.new(-0.5, 0, 0.02, 0)

local TWEEN_INFO = TweenInfo.new(
	0.5,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

local currentTween

room1Frame.Position = HIDDEN_POSITION
dashboardGui.Enabled = false

local function updateDashboardVisibility()
	local inRoomOne = player:GetAttribute("InRoomOne") == true
	local inRoomTwo = player:GetAttribute("InRoomTwo") == true
	local inAnyRoom = inRoomOne or inRoomTwo
	
	if currentTween then
		currentTween:Cancel()
	end
	
	-- Only enable the GUI if the player is in ANY room
	dashboardGui.Enabled = inAnyRoom
	
	if not inAnyRoom then
		-- Not in any room -> hide everything
		return
	end
	
	-- Tween the main frame based on Room 1
	local targetPosition = inRoomOne
		and VISIBLE_POSITION
		or HIDDEN_POSITION

	currentTween = TweenService:Create(
		room1Frame,
		TWEEN_INFO,
		{
			Position = targetPosition
		}
	)

	currentTween:Play()
	
	-- ========== auto-switch rooms based on player location ==========
	if inRoomOne then
		switchToRoom("room1")
	elseif player:GetAttribute("InRoomTwo") == true then
		switchToRoom("room2")
	end
end

player:GetAttributeChangedSignal("InRoomOne"):Connect(updateDashboardVisibility)
player:GetAttributeChangedSignal("InRoomTwo"):Connect(updateDashboardVisibility)

updateDashboardVisibility()

-- ========== Room 2 UI elements ==========
local room2Frame = dashboardGui:FindFirstChild("Room2Frame")
local room2Elements = {}

if room2Frame then
	-- Get AntennaControls labels
	local antennaControls = room2Frame:FindFirstChild("AntennaControls")
	if antennaControls then
		room2Elements.AntennaTypeLabel = antennaControls:FindFirstChild("AntennaTypeLabel")
		room2Elements.BeamWidthLabel = antennaControls:FindFirstChild("BeamWidthLabel")
		room2Elements.TiltAngleLabel = antennaControls:FindFirstChild("TiltAngleLabel")
		room2Elements.AzimuthLabel = antennaControls:FindFirstChild("AzimuthLabel")      -- 🆕
		room2Elements.ElevationLabel = antennaControls:FindFirstChild("ElevationLabel")  -- 🆕
	end

	-- Get InsightBox
	local insightBox = room2Frame:FindFirstChild("InsightBox")
	if insightBox then
		room2Elements.InsightLabel = insightBox:FindFirstChild("InsightLabel")
	end

	-- Get MetricsContainer
	room2Elements.metricsContainer = room2Frame:FindFirstChild("MetricsContainer")
end

-- Hide Room2Frame by default
if room2Frame then
	room2Frame.Visible = false
end

-- ========== Room Switching ==========
local currentRoom = "room1"

function switchToRoom(roomName)
	currentRoom = roomName

	-- Hide all frames
	room1Frame.Visible = false
	if room2Frame then room2Frame.Visible = false end

	-- Show selected frame
	if roomName == "room1" then
		room1Frame.Visible = true
	elseif roomName == "room2" and room2Frame then
		room2Frame.Visible = true
	end
end

-- Start with Room 1
switchToRoom("room1")

-- ========== FIND EXISTING UI ELEMENTS ==========

local metricsContainer = room1Frame:FindFirstChild("MetricsContainer")

-- Card 1: Signal Strength
local cardSignal = metricsContainer and metricsContainer:FindFirstChild("Card_Signal")
local signalValue = cardSignal and cardSignal:FindFirstChild("Value")
local signalStatusBadge = cardSignal and cardSignal:FindFirstChild("StatusBadge")
local barsContainer = cardSignal and cardSignal:FindFirstChild("BarsContainer")

-- Card 2: Signal Quality
local cardQuality = metricsContainer and metricsContainer:FindFirstChild("Card_Quality")
local qualityValue = cardQuality and cardQuality:FindFirstChild("Value")
local progressBar = cardQuality and cardQuality:FindFirstChild("ProgressBar")
local progressFill = progressBar and progressBar:FindFirstChild("ProgressFill")
local qualityStatusBadge = cardQuality and cardQuality:FindFirstChild("StatusBadge")

-- Card 3: Tower & Capacity
local cardTower = metricsContainer and metricsContainer:FindFirstChild("Card_Tower")
local towerNameLabel = cardTower and cardTower:FindFirstChild("TowerName")
local towerDetailsLabel = cardTower and cardTower:FindFirstChild("TowerDetails")
local capacityBar = cardTower and cardTower:FindFirstChild("CapacityBar")
local capacityFill = capacityBar and capacityBar:FindFirstChild("CapacityFill")
local capacityText = cardTower and cardTower:FindFirstChild("CapacityText")
local towerStatusBadge = cardTower and cardTower:FindFirstChild("StatusBadge")

-- Experiment Section
local experimentFrame = room1Frame:FindFirstChild("ExperimentFrame")
local beforeValue = experimentFrame and experimentFrame:FindFirstChild("BeforeValue")
local materialDisplay = experimentFrame and experimentFrame:FindFirstChild("MaterialDisplay")
local afterValue = experimentFrame and experimentFrame:FindFirstChild("AfterValue")
local insightLabel = experimentFrame and experimentFrame:FindFirstChild("InsightLabel")

-- Get signal bars
local bars = {}
if barsContainer then
	for i = 1, 5 do
		local bar = barsContainer:FindFirstChild("Bar" .. i)
		if bar then bars[i] = bar end
	end
end

-- ========== TODO: FUTURE IMPROVEMENTS ==========

-- TODO (Sujal): Add player attributes
-- TODO (Team): Ask 2degrees for real tower names near AUT or their network (currently "Mt Eden")
-- TODO (Team): Ask 2degrees for realistic tower load data
-- TODO (Monica): Create TownFrame for the small town dashboard

-- ========== SCRIPT LOGIC ==========

local materialAttenuationValues = {
	Wood = {
		["700 MHz"] = 4,
		["1800 MHz"] = 6,
		["2100 MHz"] = 8,
		["3500 MHz"] = 12
	},

	Concrete = {
		["700 MHz"] = 12,
		["1800 MHz"] = 18,
		["2100 MHz"] = 22,
		["3500 MHz"] = 30
	},

	Metal = {
		["700 MHz"] = 25,
		["1800 MHz"] = 35,
		["2100 MHz"] = 40,
		["3500 MHz"] = 55
	}
}
local lastNoise = 0
local baseSignalValue = -68

-- Frequency data
local frequencyOptions = {
	{ name = "4G 700 MHz", band = "700 MHz", divisor = 1.2, maxDistance = 45 },
	{ name = "4G 1800 MHz", band = "1800 MHz", divisor = 0.9, maxDistance = 40 },
	{ name = "4G 2100 MHz", band = "2100 MHz", divisor = 0.7, maxDistance = 35 },
	{ name = "5G 3500 MHz", band = "3500 MHz", divisor = 0.5, maxDistance = 30 }
}

local currentFrequencyIndex = 4
local currentFrequency = frequencyOptions[currentFrequencyIndex]

-- Find dropdown elements
local modeButton = room1Frame:FindFirstChild("ModeButton")
local dropdownMenu = room1Frame:FindFirstChild("FrequencyDropdownMenu")

-- Update ModeButton text
if modeButton then
	modeButton.Text = currentFrequency.name .. " ▼"
end

-- Connect dropdown menu items
if dropdownMenu then
	for _, item in ipairs(dropdownMenu:GetChildren()) do
		if item:IsA("TextButton") then
			for i, freq in ipairs(frequencyOptions) do
				if item.Text:find(freq.name) then
					item.MouseButton1Click:Connect(function()
						currentFrequencyIndex = i
						currentFrequency = freq
						if modeButton then
							modeButton.Text = freq.name .. " ▼"
						end
						dropdownMenu.Visible = false
						frequencyChangedEvent:FireServer(freq.maxDistance)
						print("Frequency changed to:", freq.name, "| Divisor:", freq.divisor)
					end)
					break
				end
			end
		end
	end
end

-- Toggle dropdown when ModeButton is clicked
if modeButton and dropdownMenu then
	modeButton.MouseButton1Click:Connect(function()
		dropdownMenu.Visible = not dropdownMenu.Visible
	end)
end

local function calculateSignal(towerDistance, materialAttenuation)
	local rangeDivisor = currentFrequency.divisor
	local baseSignal = math.max(-120, math.min(-50, -50 - (towerDistance / rangeDivisor)))
	local finalSignal = math.max(-120, math.min(-50, baseSignal - materialAttenuation))
	local targetNoise = (math.random() * 2 - 1)
	lastNoise = lastNoise * 0.9 + targetNoise * 0.1
	return math.floor(math.max(-120, math.min(-50, finalSignal + lastNoise)))
end

local function updateSignalBars(rsrp)
	local barCount = rsrp >= -60 and 5 or rsrp >= -70 and 4 or rsrp >= -80 and 3 or rsrp >= -90 and 2 or rsrp >= -100 and 1 or 0
	for i = 1, 5 do
		local bar = bars[i]
		if bar then
			bar.BackgroundTransparency = i <= barCount and 0 or 0.7
		end
	end
end

local function updateQualityProgress(rsrq)
	if progressFill then
		local percent = math.max(0, math.min(100, ((rsrq + 20) / 17) * 100))
		progressFill.Size = UDim2.new(percent / 100, 0, 1, 0)
	end
end

local function updateCapacityFill(loadPercent)
	if capacityFill then
		capacityFill.Size = UDim2.new(loadPercent / 100, 0, 1, 0)
	end
end

-- ========== ROOM 2 UPDATE FUNCTION ==========
local function updateRoom2(rsrp, beamWidth, tiltAngle, antennaType)
	if not room2Frame then return end

	-- Update Antenna Type
	if room2Elements.AntennaTypeLabel then
		room2Elements.AntennaTypeLabel.Text = "📡 Antenna Type: " .. (antennaType or "Omnidirectional")
	end

	-- Update Beam Width
	if room2Elements.BeamWidthLabel then
		room2Elements.BeamWidthLabel.Text = "📐 Beam Width: " .. (beamWidth or "60") .. "°"
	end

	-- Update Tilt Angle
	if room2Elements.TiltAngleLabel then
		room2Elements.TiltAngleLabel.Text = "📐 Tilt Angle: " .. (tiltAngle or "0") .. "°"
	end
	
	-- NarrowBeam only: Azimuth/Elevation
	if room2Elements.AzimuthLabel then
		if antennaType == "NarrowBeam" then
			room2Elements.AzimuthLabel.Text = "📍 Azimuth: " .. (azimuth or "0") .. "°"
			room2Elements.AzimuthLabel.Visible = true
		else
			room2Elements.AzimuthLabel.Visible = false
		end
	end

	if room2Elements.ElevationLabel then
		if antennaType == "NarrowBeam" then
			room2Elements.ElevationLabel.Text = "📍 Elevation: " .. (elevation or "0") .. "°"
			room2Elements.ElevationLabel.Visible = true
		else
			room2Elements.ElevationLabel.Visible = false
		end
	end

	-- Room 2 Metrics
	local room2Metrics = room2Elements.metricsContainer
	if room2Metrics then
		-- Signal card
		local cardSignal = room2Metrics:FindFirstChild("Card_Signal")
		if cardSignal then
			local value = cardSignal:FindFirstChild("Value")
			if value then
				value.Text = rsrp .. " dBm"
				if rsrp >= -70 then
					value.TextColor3 = Color3.fromRGB(46, 204, 113)
				elseif rsrp >= -90 then
					value.TextColor3 = Color3.fromRGB(243, 156, 18)
				else
					value.TextColor3 = Color3.fromRGB(231, 76, 60)
				end
			end
			local badge = cardSignal:FindFirstChild("StatusBadge")
			if badge then
				if rsrp >= -70 then
					badge.Text = "✅ Excellent"
					badge.TextColor3 = Color3.fromRGB(46, 204, 113)
				elseif rsrp >= -90 then
					badge.Text = "⚠️ Fair"
					badge.TextColor3 = Color3.fromRGB(243, 156, 18)
				else
					badge.Text = "❌ Poor"
					badge.TextColor3 = Color3.fromRGB(231, 76, 60)
				end
			end
			-- Update signal bars
			local barsContainer = cardSignal:FindFirstChild("BarsContainer")
			if barsContainer then
				local barCount = rsrp >= -60 and 5 or rsrp >= -70 and 4 or rsrp >= -80 and 3 or rsrp >= -90 and 2 or rsrp >= -100 and 1 or 0
				for i = 1, 5 do
					local bar = barsContainer:FindFirstChild("Bar" .. i)
					if bar then
						bar.BackgroundTransparency = i <= barCount and 0 or 0.7
					end
				end
			end
		end

		-- Quality and Tower cards are deleted from Room 2, so no need to reference them
	end

	-- Insight Label (describes antenna types)
	if room2Elements.InsightLabel then
		local insightText = "💡 "
		if antennaType == "Omnidirectional" then
			insightText = insightText .. "Omnidirectional: signal radiates equally in all directions (donut pattern). Covers large areas, like open spaces or city centres."
		elseif antennaType == "Directional" then
			insightText = insightText .. "Directional: signal focused in one direction (32° beam). Best for corridors, streets, and targeted coverage."
		elseif antennaType == "NarrowBeam" then
			insightText = insightText .. "Narrow Beam: highly focused signal (microwave beam). Best for point-to-point links and backhaul."
		else
			insightText = insightText .. "Different antenna types shape the signal in different ways. Check the posters to learn more!"
		end
		room2Elements.InsightLabel.Text = insightText
	end
end

local function updateUI(rsrp, materialName, attenuation, towerDistance)
	-- Card 1: Signal Strength
	if signalValue then
		signalValue.Text = rsrp .. " dBm"
		if rsrp >= -70 then
			signalValue.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif rsrp >= -90 then
			signalValue.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			signalValue.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end

	if signalStatusBadge then
		if rsrp >= -70 then
			signalStatusBadge.Text = "✅ Excellent"
			signalStatusBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif rsrp >= -90 then
			signalStatusBadge.Text = "⚠️ Fair"
			signalStatusBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			signalStatusBadge.Text = "❌ Poor"
			signalStatusBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end

	updateSignalBars(rsrp)

	-- Card 2: Signal Quality
	local estimatedRsrq = math.max(-20, math.min(-3, rsrp + 10))
	if qualityValue then
		qualityValue.Text = estimatedRsrq .. " dB"
	end

	updateQualityProgress(estimatedRsrq)

	if qualityStatusBadge then
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
	end

	-- Card 3: Tower & Capacity
	if towerNameLabel then
		towerNameLabel.Text = "Mt Eden"
	end

	if towerDetailsLabel then
		towerDetailsLabel.Text = "Sector 2 · " .. math.floor(towerDistance) .. "m"
	end

	-- local loadPercent = math.min(80, math.max(5, math.floor(100 - (towerDistance / 2))))
	-- local userCount = math.floor(loadPercent * 5)
	local loadPercent = 0
	local userCount = 1 + npcCount
	if npcCount > 0 then
		loadPercent = math.min(95, (userCount / 500) * 100)
	else
		loadPercent = math.max(5, 50 - (towerDistance / 5))
	end
	
	if capacityText then
		capacityText.Text = userCount .. " / 50 users"
		if loadPercent < 30 then
			capacityText.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif loadPercent < 70 then
			capacityText.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			capacityText.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end

	updateCapacityFill(loadPercent)

	if towerStatusBadge then
		if loadPercent < 30 then
			towerStatusBadge.Text = "📊 Light load"
			towerStatusBadge.TextColor3 = Color3.fromRGB(46, 204, 113)
		elseif loadPercent < 70 then
			towerStatusBadge.Text = "📊 Medium load"
			towerStatusBadge.TextColor3 = Color3.fromRGB(243, 156, 18)
		else
			towerStatusBadge.Text = "📊 Heavy load"
			towerStatusBadge.TextColor3 = Color3.fromRGB(231, 76, 60)
		end
	end

	-- Experiment Section
	if materialName == "None" or materialName == nil then
		baseSignalValue = rsrp
	end

	if beforeValue then
		beforeValue.Text = baseSignalValue .. " dBm"
	end

	if materialDisplay then
		if materialName == "SignalSource" then
			materialName = "None"
		end
		if materialName and materialName ~= "None" then
			materialDisplay.Text = materialName
			materialDisplay.TextColor3 = Color3.fromRGB(0, 163, 224)
		else
			materialDisplay.Text = "None"
			materialDisplay.TextColor3 = Color3.fromRGB(150, 160, 170)
		end
	end

	if afterValue then
		afterValue.Text = rsrp .. " dBm"
	end

	if insightLabel then
		if materialName and materialName ~= "None" then
			if materialName == "Wood" then
				insightLabel.Text = "🌲 Wood blocks a little signal. Houses let most signal through!"
			elseif materialName == "Concrete" then
				insightLabel.Text = "🏢 Concrete blocks a lot of signal! That's why buildings need indoor antennas."
			elseif materialName == "Metal" then
				insightLabel.Text = "✨ METAL = FARADAY CAGE! ✨ Metal completely blocks radio waves - like an elevator!"
			end
		elseif npcCount > 0 then
			insightLabel.Text = "👥 " .. npcCount .. " NPCs connected! More users = higher tower load!"
		else
			insightLabel.Text = "💡 Walk near different materials to see how they affect signal!"
		end
	end
	
end

-- Main loop
RunService.RenderStepped:Connect(function()
	if not humanoidRootPart or not Source then return end
	local distanceToTower = (humanoidRootPart.Position - Source.Position).Magnitude

	local materialName = player:GetAttribute("Material") or "None"
	local materialAttenuation = 0

	if materialAttenuationValues[materialName] then
		materialAttenuation =
			materialAttenuationValues[materialName][currentFrequency.band] or 0
	end

	local rsrp = calculateSignal(distanceToTower, materialAttenuation)
	updateUI(rsrp, materialName, materialAttenuation, distanceToTower)

	-- Update Room 2
	local beamWidth = player:GetAttribute("BeamWidth") or 60
	local tiltAngle = player:GetAttribute("TiltAngle") or 0
	local antennaType = player:GetAttribute("AntennaType") or "Omnidirectional"
	local azimuth = player:GetAttribute("Azimuth") or 0
	local elevation = player:GetAttribute("Elevation") or 0

	updateRoom2(rsrp, beamWidth, tiltAngle, antennaType, azimuth, elevation)
end)
print("Dashboard Loaded!")