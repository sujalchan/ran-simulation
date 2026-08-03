local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Speed range
local MIN_SPEED = 16
local MAX_SPEED = 130
local SPRINT_MULTIPLIER = 3

if playerGui:FindFirstChild("SpeedControlGui") then
	playerGui.SpeedControlGui:Destroy()
end

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedControlGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 100)
mainFrame.Position = UDim2.new(0, 20, 0.9, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.5

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

mainFrame.Parent = screenGui

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Walk Speed"
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Slider Track 
local sliderTrack = Instance.new("Frame")
sliderTrack.Name = "SliderTrack"
sliderTrack.Size = UDim2.new(1, -30, 0, 10)
sliderTrack.Position = UDim2.new(0, 15, 0, 45)
sliderTrack.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
sliderTrack.BorderSizePixel = 0

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 5)
trackCorner.Parent = sliderTrack

sliderTrack.Parent = mainFrame

-- Slider Fill 
local sliderFill = Instance.new("Frame")
sliderFill.Name = "SliderFill"
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
sliderFill.BorderSizePixel = 0

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 5)
fillCorner.Parent = sliderFill

sliderFill.Parent = sliderTrack

-- Slider Knob
local sliderKnob = Instance.new("Frame")
sliderKnob.Name = "SliderKnob"
sliderKnob.Size = UDim2.new(0, 18, 0, 18)
sliderKnob.Position = UDim2.new(0, -9, 0.5, -9)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.BorderSizePixel = 0

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(0, 9)
knobCorner.Parent = sliderKnob

local knobStroke = Instance.new("UIStroke")
knobStroke.Color = Color3.fromRGB(0, 200, 100)
knobStroke.Thickness = 2
knobStroke.Parent = sliderKnob

sliderKnob.Parent = sliderTrack

-- Count Label 
local countLabel = Instance.new("TextLabel")
countLabel.Name = "CountLabel"
countLabel.Size = UDim2.new(0, 40, 0, 20)
countLabel.Position = UDim2.new(0.5, -20, 0, 65)
countLabel.BackgroundTransparency = 1
countLabel.Text = tostring(MIN_SPEED)
countLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
countLabel.TextSize = 16
countLabel.Font = Enum.Font.GothamBold
countLabel.Parent = mainFrame

-- Max Label
local maxLabel = Instance.new("TextLabel")
maxLabel.Name = "MaxLabel"
maxLabel.Size = UDim2.new(0, 40, 0, 20)
maxLabel.Position = UDim2.new(1, -50, 0, 65)
maxLabel.BackgroundTransparency = 1
maxLabel.Text = "Max: " .. MAX_SPEED
maxLabel.TextColor3 = Color3.fromRGB(140, 140, 170)
maxLabel.TextSize = 11
maxLabel.Font = Enum.Font.Gotham
maxLabel.Parent = mainFrame

-- Min Label
local minLabel = Instance.new("TextLabel")
minLabel.Name = "MinLabel"
minLabel.Size = UDim2.new(0, 30, 0, 20)
minLabel.Position = UDim2.new(0, 10, 0, 65)
minLabel.BackgroundTransparency = 1
minLabel.Text = tostring(MIN_SPEED)
minLabel.TextColor3 = Color3.fromRGB(140, 140, 170)
minLabel.TextSize = 11
minLabel.Font = Enum.Font.Gotham
minLabel.Parent = mainFrame

screenGui.Parent = playerGui

-- Slider logic
local currentSpeed = MIN_SPEED
local isDragging = false
local isSprinting = false

local function updateSlider(speed)
	speed = math.clamp(speed, MIN_SPEED, MAX_SPEED)
	currentSpeed = speed
	local ratio = (speed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
	sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
	sliderKnob.Position = UDim2.new(ratio, -9, 0.5, -9)
	countLabel.Text = tostring(math.round(speed))
end

local function applySpeed()
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if isSprinting then
				humanoid.WalkSpeed = currentSpeed * SPRINT_MULTIPLIER
			else
				humanoid.WalkSpeed = currentSpeed
			end
		end
	end
end

local function setBaseSpeed(speed)
	updateSlider(speed)
	applySpeed()
end

sliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = true
	end
end)

sliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDragging = true
	end
end)

UIS.InputChanged:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local trackAbsSize = sliderTrack.AbsoluteSize.X
		if trackAbsSize > 0 then
			local relX = input.Position.X - sliderTrack.AbsolutePosition.X
			local ratio = math.clamp(relX / trackAbsSize, 0, 1)
			local newSpeed = MIN_SPEED + math.round(ratio * (MAX_SPEED - MIN_SPEED))
			setBaseSpeed(newSpeed)
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		isDragging = false
	end
end)

-- Set speed to 130 when game starts
game.ReplicatedStorage.StartGame.OnClientEvent:Connect(function()
	setBaseSpeed(130)
end)

-- Apply initial speed
local character = player.Character
if character then
	task.wait(0.5)
	applySpeed()
end