local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local npcSpawnEvent = ReplicatedStorage:WaitForChild("NPCSpawnEvent")

local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("NPCControlGui") then
	playerGui.NPCControlGui:Destroy()
end

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NPCControlGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 100)
mainFrame.Position = UDim2.new(0, 20, 0.9, -50)
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
titleLabel.Text = "NPC Spawner"
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Slider Track (background)
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

-- Slider Fill (colored portion)
local sliderFill = Instance.new("Frame")
sliderFill.Name = "SliderFill"
sliderFill.Size = UDim2.new(0, 0, 1, 0) -- starts at 0/50
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 180, 239)
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
knobStroke.Color = Color3.fromRGB(0, 180, 239)
knobStroke.Thickness = 2
knobStroke.Parent = sliderKnob

sliderKnob.Parent = sliderTrack

-- Count Label (shows current value)
local countLabel = Instance.new("TextLabel")
countLabel.Name = "CountLabel"
countLabel.Size = UDim2.new(0, 40, 0, 20)
countLabel.Position = UDim2.new(0.5, -20, 0, 65)
countLabel.BackgroundTransparency = 1
countLabel.Text = "0"
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
maxLabel.Text = "Max: 50"
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
minLabel.Text = "0"
minLabel.TextColor3 = Color3.fromRGB(140, 140, 170)
minLabel.TextSize = 11
minLabel.Font = Enum.Font.Gotham
minLabel.Parent = mainFrame

screenGui.Parent = playerGui

-- Slider logic
local MAX_NPCS = 50
local currentCount = 0
local isDragging = false
local lastSentCount = 0
local isHovering = false
local isDragging = false

local function updatePlacementState()
	-- Disable placement if hovering OR dragging
	local canPlace = not (isHovering or isDragging)
	player:SetAttribute("CanPlaceAntenna", canPlace)
end

-- Hover Detection on the Main Frame
mainFrame.MouseEnter:Connect(function()
	isHovering = true
	updatePlacementState()
end)

mainFrame.MouseLeave:Connect(function()
	isHovering = false
	updatePlacementState()
end)

local function updateSlider(count)
	count = math.clamp(count, 0, MAX_NPCS)
	currentCount = count
	local ratio = count / MAX_NPCS
	sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
	sliderKnob.Position = UDim2.new(ratio, -9, 0.5, -9)
	countLabel.Text = tostring(count)
end

local function sendCountToServer(count)
	if count ~= lastSentCount then
		lastSentCount = count
		npcSpawnEvent:FireServer("setCount", count)
	end
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

local userInputService = game:GetService("UserInputService")

userInputService.InputChanged:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local trackAbsSize = sliderTrack.AbsoluteSize.X
		if trackAbsSize > 0 then
			local relX = input.Position.X - sliderTrack.AbsolutePosition.X
			local ratio = math.clamp(relX / trackAbsSize, 0, 1)
			local newCount = math.round(ratio * MAX_NPCS)
			updateSlider(newCount)
		end
	end
end)

userInputService.InputEnded:Connect(function(input)
	if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		isDragging = false
		sendCountToServer(currentCount)
	end
end)

-- Listen for count updates from server
npcSpawnEvent.OnClientEvent:Connect(function(count)
	currentCount = count
	lastSentCount = count
	updateSlider(count)
end)

-- Request initial count on load
task.wait(1)
npcSpawnEvent:FireServer("getCount")

-- Reset NPC slider to 0 when game resets
game.ReplicatedStorage.ResetGame.OnClientEvent:Connect(function()
	currentCount = 0
	lastSentCount = 0
	updateSlider(0)
end)