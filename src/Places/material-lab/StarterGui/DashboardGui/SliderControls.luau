local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local updateAntennaEvent = ReplicatedStorage:WaitForChild("UpdateAntennaEvent")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("AntennaControlGui") then
	playerGui.AntennaControlGui:Destroy()
end

-- create the screen gui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntennaControlGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- create the main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 205)
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.Position = UDim2.new(1, -20, 0.9, -400)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.25
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(75, 75, 95)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.4
mainStroke.Parent = mainFrame

-- create the title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -20, 0, 35)
titleLabel.Position = UDim2.new(0, 10, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Antenna Controls"
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local activeSlider = nil
local isHovering = false
local isDragging = false

local function updatePlacementState()
	local canPlace = not (isHovering or isDragging)
	player:SetAttribute("CanPlaceAntenna", canPlace)
end

-- create one slider section
local function createSlider(
	sliderName,
	displayName,
	minimumValue,
	maximumValue,
	defaultValue,
	positionY
)
	local sliderContainer = Instance.new("Frame")
	sliderContainer.Name = sliderName .. "Container"
	sliderContainer.Size = UDim2.new(1, -30, 0, 70)
	sliderContainer.Position = UDim2.new(0, 15, 0, positionY)
	sliderContainer.BackgroundTransparency = 1
	sliderContainer.Parent = mainFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = sliderName .. "Label"
	nameLabel.Size = UDim2.new(0.65, 0, 0, 25)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
	nameLabel.TextSize = 15
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = sliderContainer

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = sliderName .. "ValueLabel"
	valueLabel.Size = UDim2.new(0.35, 0, 0, 25)
	valueLabel.Position = UDim2.new(0.65, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(defaultValue) .. "°"
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextColor3 = Color3.fromRGB(0, 220, 130)
	valueLabel.TextSize = 15
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Parent = sliderContainer

	local sliderTrack = Instance.new("Frame")
	sliderTrack.Name = sliderName .. "Track"
	sliderTrack.Size = UDim2.new(1, 0, 0, 10)
	sliderTrack.Position = UDim2.new(0, 0, 0, 33)
	sliderTrack.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	sliderTrack.BorderSizePixel = 0
	sliderTrack.Active = true
	sliderTrack.Parent = sliderContainer

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 5)
	trackCorner.Parent = sliderTrack

	local sliderFill = Instance.new("Frame")
	sliderFill.Name = sliderName .. "Fill"
	sliderFill.Size = UDim2.new(0, 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 5)
	fillCorner.Parent = sliderFill

	local sliderKnob = Instance.new("Frame")
	sliderKnob.Name = sliderName .. "Knob"
	sliderKnob.Size = UDim2.new(0, 18, 0, 18)
	sliderKnob.Position = UDim2.new(0, -9, 0.5, -9)
	sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderKnob.BorderSizePixel = 0
	sliderKnob.Active = true
	sliderKnob.Parent = sliderTrack

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = sliderKnob

	local knobStroke = Instance.new("UIStroke")
	knobStroke.Color = Color3.fromRGB(0, 200, 100)
	knobStroke.Thickness = 2
	knobStroke.Parent = sliderKnob

	local minimumLabel = Instance.new("TextLabel")
	minimumLabel.Name = "MinimumLabel"
	minimumLabel.Size = UDim2.new(0, 60, 0, 18)
	minimumLabel.Position = UDim2.new(0, 0, 0, 48)
	minimumLabel.BackgroundTransparency = 1
	minimumLabel.Text = tostring(minimumValue) .. "°"
	minimumLabel.TextXAlignment = Enum.TextXAlignment.Left
	minimumLabel.TextColor3 = Color3.fromRGB(140, 140, 170)
	minimumLabel.TextSize = 11
	minimumLabel.Font = Enum.Font.Gotham
	minimumLabel.Parent = sliderContainer

	local maximumLabel = Instance.new("TextLabel")
	maximumLabel.Name = "MaximumLabel"
	maximumLabel.Size = UDim2.new(0, 60, 0, 18)
	maximumLabel.Position = UDim2.new(1, -60, 0, 48)
	maximumLabel.BackgroundTransparency = 1
	maximumLabel.Text = tostring(maximumValue) .. "°"
	maximumLabel.TextXAlignment = Enum.TextXAlignment.Right
	maximumLabel.TextColor3 = Color3.fromRGB(140, 140, 170)
	maximumLabel.TextSize = 11
	maximumLabel.Font = Enum.Font.Gotham
	maximumLabel.Parent = sliderContainer

	local sliderData = {
		name = sliderName,
		minimumValue = minimumValue,
		maximumValue = maximumValue,
		currentValue = defaultValue,
		container = sliderContainer,
		track = sliderTrack,
		fill = sliderFill,
		knob = sliderKnob,
		valueLabel = valueLabel,
	}

	local function updateSlider(value)
		value = math.clamp(
			math.round(value),
			minimumValue,
			maximumValue
		)

		sliderData.currentValue = value

		local ratio =
			(value - minimumValue)
			/ (maximumValue - minimumValue)

		sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
		sliderKnob.Position = UDim2.new(ratio, -9, 0.5, -9)
		valueLabel.Text = tostring(value) .. "°"

		-- ui only for now
		-- antenna behaviour can be added here later
	end

	sliderData.update = updateSlider

	local function beginDragging(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			activeSlider = sliderData
			isDragging = true
			updatePlacementState()

			local trackWidth = sliderTrack.AbsoluteSize.X

			if trackWidth > 0 then
				local relativeX =
					input.Position.X
				- sliderTrack.AbsolutePosition.X

				local ratio = math.clamp(
					relativeX / trackWidth,
					0,
					1
				)

				local value =
					minimumValue
					+ ratio
					* (maximumValue - minimumValue)

				updateSlider(value)
			end
		end
	end

	sliderTrack.InputBegan:Connect(beginDragging)
	sliderKnob.InputBegan:Connect(beginDragging)

	updateSlider(defaultValue)

	return sliderData
end

-- create the azimuth slider
local azimuthSlider = createSlider(
	"Azimuth",
	"Azimuth",
	-45,
	45,
	0,
	42
)

-- create the elevation slider
local elevationSlider = createSlider(
	"Elevation",
	"Elevation",
	-15,
	15,
	0,
	117
)

local function sendAntennaUpdate()
	local antennaType = player:GetAttribute("ClosestSignalSource")

	if antennaType ~= "Directional"
		and antennaType ~= "NarrowBeam" then
		return
	end

	updateAntennaEvent:FireServer(
		antennaType,
		elevationSlider.currentValue,
		azimuthSlider.currentValue
	)
end

-- detect when the mouse is over the ui
mainFrame.MouseEnter:Connect(function()
	isHovering = true
	updatePlacementState()
end)

mainFrame.MouseLeave:Connect(function()
	isHovering = false
	updatePlacementState()
end)

-- update the currently selected slider
UIS.InputChanged:Connect(function(input)
	if not isDragging or not activeSlider then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local track = activeSlider.track
	local trackWidth = track.AbsoluteSize.X

	if trackWidth <= 0 then
		return
	end

	local relativeX =
		input.Position.X
	- track.AbsolutePosition.X

	local ratio = math.clamp(
		relativeX / trackWidth,
		0,
		1
	)

	local newValue =
		activeSlider.minimumValue
		+ ratio
		* (
			activeSlider.maximumValue
			- activeSlider.minimumValue
		)

	activeSlider.update(newValue)
end)

-- stop dragging
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		if isDragging then
			sendAntennaUpdate()
		end

		isDragging = false
		activeSlider = nil
		updatePlacementState()
	end
end)

-- set the initial placement state
updatePlacementState()

local function updateVisibility()
	local inRoomTwo = player:GetAttribute("InRoomTwo") == true
	local antennaType = player:GetAttribute("ClosestSignalSource")

	-- hide everything outside room two
	if not inRoomTwo then
		mainFrame.Visible = false
		return
	end

	if antennaType == "Omnidirectional" then
		-- omnidirectional antennas have no controls
		mainFrame.Visible = false

	elseif antennaType == "Directional" then
		-- directional antennas only use elevation
		mainFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 250, 0, 130)

		azimuthSlider.container.Visible = false

		elevationSlider.container.Visible = true
		elevationSlider.container.Position = UDim2.new(0, 15, 0, 42)

	elseif antennaType == "NarrowBeam" then
		-- narrow beam antennas use both controls
		mainFrame.Visible = true
		mainFrame.Size = UDim2.new(0, 250, 0, 205)

		azimuthSlider.container.Visible = true
		azimuthSlider.container.Position = UDim2.new(0, 15, 0, 42)

		elevationSlider.container.Visible = true
		elevationSlider.container.Position = UDim2.new(0, 15, 0, 117)

	else
		-- hide controls when there is no valid closest source
		mainFrame.Visible = false
	end
end

player:GetAttributeChangedSignal("InRoomTwo"):Connect(updateVisibility)
player:GetAttributeChangedSignal("ClosestSignalSource"):Connect(updateVisibility)

updateVisibility()


player:GetAttributeChangedSignal("InRoomTwo"):Connect(updateVisibility)

updateVisibility()