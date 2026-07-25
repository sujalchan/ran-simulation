local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local startEvent = ReplicatedStorage:WaitForChild("StartGame")
local placeEvent = ReplicatedStorage:WaitForChild("PlaceAntenna")
local antennaFolder = ReplicatedStorage:WaitForChild("AntennaModels")

local gameStarted = false
local selectedAntenna = "Antenna1"
local preview = nil
local previewRotation = CFrame.identity
local baseOffset = 0  -- Y distance from pivot to bottom of model

-- Exclude the preview model from the detection targets
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- The 4 antenna options
local antennaOptions = {"Antenna1", "Antenna2", "Antenna3", "Antenna4"}

-- Calculate the position of the base of the antenna model
local function computeBaseOffset(model, rotation)
	model:PivotTo(rotation)

	local lowestY = math.huge
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local cf = part.CFrame
			local sz = part.Size
			-- Check all 8 corners of the part's box
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for szStep = -1, 1, 2 do
						local cornerY = (cf * Vector3.new(sx * sz.X / 2, sy * sz.Y / 2, szStep * sz.Z / 2)).Y
						if cornerY < lowestY then
							lowestY = cornerY
						end
					end
				end
			end
		end
	end

	return lowestY  
end

-- Create a preview before positioning the antenna
local function createPreview()
	if preview then
		preview:Destroy()
		preview = nil
	end

	local template = antennaFolder:FindFirstChild(selectedAntenna)
	if not template then
		warn("[AntennaPlacer] Could not find antenna model:", selectedAntenna)
		return
	end

	preview = template:Clone()
	preview.Parent = workspace

	-- Get the model's original rotation
	local pivot = preview:GetPivot()
	previewRotation = pivot - pivot.Position

	-- Compute base offset (distance from pivot to bottom of model)
	baseOffset = computeBaseOffset(preview, previewRotation)

	for _, part in pairs(preview:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0.5
			part.CanCollide = false
		end
	end
end

-- Get mouse world position
local function getMousePosition()
	local mouse = player:GetMouse()
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)

	rayParams.FilterDescendantsInstances = {preview}

	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)
	if result then
		return result.Position
	end
	return nil
end

-- move preview
RunService.RenderStepped:Connect(function()
	if not gameStarted or not preview then
		return
	end

	local pos = getMousePosition()
	if pos then
		-- Move the base of the antenna along the ground
		preview:PivotTo(CFrame.new(pos.X, pos.Y - baseOffset, pos.Z) * previewRotation)
	end
end)

-- Place antenna
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameStarted or gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = getMousePosition()
		if pos then
			placeEvent:FireServer(selectedAntenna, pos)
		end
	end
end)

-- GUI
local function createGUI()
	-- Remove existing GUI if re-created
	local existingGui = player.PlayerGui:FindFirstChild("AntennaGUI")
	if existingGui then
		existingGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AntennaGUI"
	gui.Parent = player.PlayerGui

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 220, 0, 180)
	frame.Position = UDim2.new(0, 15, 0.5, -90)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Select Antenna"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.Parent = frame

	local selectedButton = nil

	for i, name in ipairs(antennaOptions) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -20, 0, 32)
		button.Position = UDim2.new(0, 10, 0, 30 + (i - 1) * 35)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = Enum.Font.Gotham
		button.TextSize = 14
		button.Text = name
		button.BorderSizePixel = 0
		button.AutoButtonColor = true
		button.Parent = frame

		-- Highlight the first button by default
		if i == 1 then
			button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			selectedButton = button
		end

		button.MouseButton1Click:Connect(function()
			-- Reset previous selection
			if selectedButton then
				selectedButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			end

			-- Highlight new selection
			button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			selectedButton = button

			selectedAntenna = name
			createPreview()
		end)
	end
end

-- Start game
startEvent.OnClientEvent:Connect(function()
	gameStarted = true
	createGUI()
	createPreview()
end)