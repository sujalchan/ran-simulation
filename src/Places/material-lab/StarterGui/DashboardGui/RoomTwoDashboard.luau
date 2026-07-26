local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local dashboardGui = script.Parent
local room2Frame = dashboardGui:WaitForChild("Room2Frame")
local popUpFrame = dashboardGui:WaitForChild("PopUpFrame")
local antennaControls = popUpFrame:WaitForChild("AntennaControls")

local antennaTypeLabel =
	antennaControls:WaitForChild("AntennaTypeLabel")

local beamWidthLabel =
	antennaControls:WaitForChild("BeamWidthLabel")

local tiltAngleLabel =
	antennaControls:WaitForChild("TiltAngleLabel")

local azimuthLabel =
	antennaControls:WaitForChild("AzimuthLabel")

local elevationLabel =
	antennaControls:WaitForChild("ElevationLabel")

local insightLabel =
	room2Frame.InsightBox:WaitForChild("InsightLabel")

local signalCard =
	room2Frame.MetricsContainer:WaitForChild("Card_Signal")

local signalValue = signalCard:WaitForChild("Value")
local signalStatusBadge = signalCard:WaitForChild("StatusBadge")
local barsContainer = signalCard:WaitForChild("BarsContainer")

local bars = {}

for i = 1, 5 do
	bars[i] = barsContainer:WaitForChild("Bar" .. i)
end

local function updateVisibility()
	room2Frame.Visible =
		player:GetAttribute("InRoomTwo") == true
		and player:GetAttribute("InRoomOne") ~= true
end

player:GetAttributeChangedSignal("InRoomOne"):Connect(updateVisibility)
player:GetAttributeChangedSignal("InRoomTwo"):Connect(updateVisibility)

updateVisibility()

local function updateRoom2(
	rsrp,
	beamWidth,
	tiltAngle,
	antennaType,
	azimuth,
	elevation
)
	antennaTypeLabel.Text =
		"📡 Antenna Type: " .. antennaType

	beamWidthLabel.Text =
		"📐 Beam Width: " .. beamWidth .. "°"

	tiltAngleLabel.Text =
		"📐 Tilt Angle: " .. tiltAngle .. "°"

	local narrowBeam = antennaType == "NarrowBeam"

	azimuthLabel.Visible = narrowBeam
	elevationLabel.Visible = narrowBeam

	if narrowBeam then
		azimuthLabel.Text =
			"📍 Azimuth: " .. azimuth .. "°"

		elevationLabel.Text =
			"📍 Elevation: " .. elevation .. "°"
	end

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

	-- insight labels based on antenna types
	if antennaType == "Omnidirectional" then
		insightLabel.Text =
			"💡 Omnidirectional - click 'Antenna Details' for more info!"
	elseif antennaType == "Directional" then
		insightLabel.Text =
			"💡 Directional - click 'Antenna Details' for more info!"
	elseif antennaType == "NarrowBeam" then
		insightLabel.Text =
			"💡 Narrow Beam - click 'Antenna Details' for more info!"
	else
		insightLabel.Text =
			"💡 Walk near different antennas to see how they shape signals."
	end
end

RunService.RenderStepped:Connect(function()
	local rsrp = player:GetAttribute("RSRP") or -120
	local beamWidth = player:GetAttribute("BeamWidth") or 60
	local tiltAngle = player:GetAttribute("TiltAngle") or 0
	local antennaType =
		player:GetAttribute("AntennaType") or "Omnidirectional"

	local azimuth = player:GetAttribute("Azimuth") or 0
	local elevation = player:GetAttribute("Elevation") or 0

	updateRoom2(
		rsrp,
		beamWidth,
		tiltAngle,
		antennaType,
		azimuth,
		elevation
	)
end)