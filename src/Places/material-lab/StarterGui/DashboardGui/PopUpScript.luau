-- Room 2 Pop-up Dashboard
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local dashboardGui = playerGui:WaitForChild("DashboardGui")

local popUpFrame = script.Parent
local room2Frame = dashboardGui:FindFirstChild("Room2Frame")

if not room2Frame then
	warn("Room2Frame not found")
	return
end

-- hide pop-up by default
popUpFrame.Visible = false

-- find buttons
local openButton = room2Frame:FindFirstChild("OpenPopUpButton")
local closeButton = popUpFrame:FindFirstChild("CloseButton")

-- find labels for content updates
local popUpControls = popUpFrame:FindFirstChild("AntennaControls")
local insightLabel = popUpFrame:FindFirstChild("InsightLabelPopUp")

local labels = {}
if popUpControls then
	labels.AntennaType = popUpControls:FindFirstChild("AntennaTypeLabel")
	labels.BeamWidth = popUpControls:FindFirstChild("BeamWidthLabel")
	labels.TiltAngle = popUpControls:FindFirstChild("TiltAngleLabel")
	labels.Azimuth = popUpControls:FindFirstChild("AzimuthLabel")
	labels.Elevation = popUpControls:FindFirstChild("ElevationLabel")
end

-- update content
local function updatePopUp()
	local antennaType = player:GetAttribute("AntennaType") or "Omnidirectional"
	local beamWidth = player:GetAttribute("BeamWidth") or 60
	local tiltAngle = player:GetAttribute("TiltAngle") or 0
	local azimuth = player:GetAttribute("Azimuth") or 0
	local elevation = player:GetAttribute("Elevation") or 0

	if labels.AntennaType then
		labels.AntennaType.Text = "📡 Antenna Type: " .. antennaType
	end

	if labels.BeamWidth then
		labels.BeamWidth.Text = "📐 Beam Width: " .. beamWidth .. "°"
	end

	if labels.TiltAngle then
		labels.TiltAngle.Text = "📐 Tilt Angle: " .. tiltAngle .. "°"
	end

	-- only show Azimuth and Elevation for NarrowBeam
	local narrowBeam = antennaType == "NarrowBeam"

	if labels.Azimuth then
		labels.Azimuth.Visible = narrowBeam
		if narrowBeam then
			labels.Azimuth.Text = "📍 Azimuth: " .. azimuth .. "°"
		end
	end

	if labels.Elevation then
		labels.Elevation.Visible = narrowBeam
		if narrowBeam then
			labels.Elevation.Text = "📍 Elevation: " .. elevation .. "°"
		end
	end

	if insightLabel then
		local text = "💡 "
		if antennaType == "Omnidirectional" then
			text = text .. "Omnidirectional: Signal radiates equally in all directions (donut pattern). Covers large areas."
		elseif antennaType == "Directional" then
			text = text .. "Directional: Signal focused in one direction (32° beam). Best for corridors and targeted coverage."
		elseif antennaType == "NarrowBeam" then
			text = text .. "Narrow Beam: Highly focused signal (microwave beam). Best for point-to-point links."
		else
			text = text .. "Different antenna types shape the signal in different ways."
		end
		insightLabel.Text = text
	end
end

-- buttons
if openButton then
	openButton.MouseButton1Click:Connect(function()
		updatePopUp()
		popUpFrame.Visible = true
		print("Pop-up opened!")
	end)
end

if closeButton then
	closeButton.MouseButton1Click:Connect(function()
		popUpFrame.Visible = false
		print("Pop-up closed")
	end)
end

-- auto-update
player:GetAttributeChangedSignal("AntennaType"):Connect(updatePopUp)
player:GetAttributeChangedSignal("BeamWidth"):Connect(updatePopUp)
player:GetAttributeChangedSignal("TiltAngle"):Connect(updatePopUp)
player:GetAttributeChangedSignal("Azimuth"):Connect(updatePopUp)
player:GetAttributeChangedSignal("Elevation"):Connect(updatePopUp)

-- initial update
task.wait(1)
updatePopUp()

print("Room 2 pop-up loaded!")