local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local startEvent = ReplicatedStorage:WaitForChild("StartGame")
local placeEvent = ReplicatedStorage:WaitForChild("PlaceAntenna")
local deleteEvent = ReplicatedStorage:WaitForChild("DeleteAntenna")
local antennaFolder = ReplicatedStorage:WaitForChild("AntennaModels")

local gameStarted = false
local selectedAntenna = "Antenna1"
local preview = nil
local currentAngle = 0  -- Rotation angle in degrees (0, 90, 180, 270)
local deleteMode = false
local antennaSelected = true  -- true when a button is blue/active
local baseToPivotOffset = Vector3.zero
local originalModelRotation = CFrame.identity

-- Exclude the preview model from the detection targets
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- The 4 antenna options
local antennaOptions = {
	{displayName = "Antenna 1", modelName = "Antenna1"},
	{displayName = "Antenna 2", modelName = "Antenna2"},
	{displayName = "Antenna 3", modelName = "Antenna3"},
	{displayName = "Antenna 4", modelName = "Antenna4"},
}

-- Calculate the center of the base (bottom face) of the antenna model
local function computeBaseCenter(model)
	local lowestY = math.huge
	-- First pass: find lowest Y among all corners
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local cf = part.CFrame
			local sz = part.Size
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

	-- Second pass: find X and Z center at the base level
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local cf = part.CFrame
			local sz = part.Size
			for sx = -1, 1, 2 do
				for szStep = -1, 1, 2 do
					local corner = cf * Vector3.new(sx * sz.X / 2, -sz.Y / 2, szStep * sz.Z / 2)
					if corner.Y <= lowestY + 0.5 then
						minX = math.min(minX, corner.X)
						maxX = math.max(maxX, corner.X)
						minZ = math.min(minZ, corner.Z)
						maxZ = math.max(maxZ, corner.Z)
					end
				end
			end
		end
	end

	if minX == math.huge then
		return Vector3.new(0, lowestY, 0)
	end

	return Vector3.new((minX + maxX) / 2, lowestY, (minZ + maxZ) / 2)
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
	originalModelRotation = pivot - pivot.Position

	-- Place model at origin with original rotation to compute base info
	preview:PivotTo(originalModelRotation)

	-- Compute base center and offset from base center to pivot
	local baseCenter = computeBaseCenter(preview)
	local pivotPos = preview:GetPivot().Position
	baseToPivotOffset = pivotPos - baseCenter

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

-- Move preview 
RunService.RenderStepped:Connect(function()
	if not gameStarted or not preview then
		return
	end

	local pos = getMousePosition()
	if pos then
		-- Rotate the offset from base center to pivot by current angle
		local rotCF = CFrame.Angles(0, math.rad(currentAngle), 0)
		local rotatedOffset = rotCF * baseToPivotOffset

		-- Position pivot such that base center is at the mouse position
		local pivotPos = pos + rotatedOffset
		preview:PivotTo(CFrame.new(pivotPos) * rotCF * originalModelRotation)
	end
end)

-- Rotate preview left or right by 90 degrees
local function rotatePreview(direction)
	if direction == "left" then
		currentAngle = (currentAngle - 90) % 360
	else
		currentAngle = (currentAngle + 90) % 360
	end
	-- Update rotation label in GUI
	local gui = player.PlayerGui:FindFirstChild("AntennaGUI")
	if gui then
		local rotLabel = gui:FindFirstChild("MainFrame"):FindFirstChild("RotationLabel")
		if rotLabel then
			rotLabel.Text = "Rotation: " .. currentAngle .. "°"
		end
	end
end

-- Place antenna or delete antenna
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameStarted or gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if player:GetAttribute("CanPlaceAntenna") == false then
			return
		end
		if deleteMode then
			local mouse = player:GetMouse()
			local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
			local placedFolder = workspace:FindFirstChild("PlacedAntennas")
			local filterList = {}
			if placedFolder then
				table.insert(filterList, placedFolder)
			end
			local delParams = RaycastParams.new()
			delParams.FilterType = Enum.RaycastFilterType.Include
			delParams.FilterDescendantsInstances = filterList
			local result = workspace:Raycast(ray.Origin, ray.Direction * 500, delParams)
			if result and result.Instance then
				local instance = result.Instance
				while instance and instance.Parent ~= workspace:FindFirstChild("PlacedAntennas") do
					instance = instance.Parent
				end
				if instance and instance.Parent == workspace:FindFirstChild("PlacedAntennas") then
					deleteEvent:FireServer(instance.Name)
				end
			end
		else
			-- Only place if an antenna button is selected (blue)
			if not antennaSelected then return end
			local pos = getMousePosition()
			if pos then
				placeEvent:FireServer(selectedAntenna, pos, currentAngle)
			end
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		-- R key to rotate right
		if not deleteMode then
			rotatePreview("right")
		end
	elseif input.KeyCode == Enum.KeyCode.Q then
		-- Q key to rotate left
		if not deleteMode then
			rotatePreview("left")
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
	frame.Size = UDim2.new(0, 220, 0, 305)
	frame.Position = UDim2.new(0, 15, 0.5, -155)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = frame

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
		button.Text = name.displayName
		button.BorderSizePixel = 0
		button.AutoButtonColor = true
		button.Parent = frame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = button

		-- Highlight the first button by default
		if i == 1 then
			button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			selectedButton = button
		end

		button.MouseButton1Click:Connect(function()
			if selectedButton == button then
				-- Deselect: turn dark and destroy preview
				button.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
				selectedButton = nil
				antennaSelected = false
				if preview then
					preview:Destroy()
					preview = nil
				end
				return
			end

			-- Reset previous selection
			if selectedButton then
				selectedButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			end

			-- Highlight new selection
			button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			selectedButton = button
			antennaSelected = true

			selectedAntenna = name.modelName
			createPreview()
		end)
	end

	-- Rotation section
	local rotLabel = Instance.new("TextLabel")
	rotLabel.Name = "RotationLabel"
	rotLabel.Size = UDim2.new(1, -20, 0, 24)
	rotLabel.Position = UDim2.new(0, 10, 0, 175)
	rotLabel.BackgroundTransparency = 1
	rotLabel.Text = "Rotation: " .. currentAngle .. "°"
	rotLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	rotLabel.Font = Enum.Font.GothamBold
	rotLabel.TextSize = 14
	rotLabel.TextXAlignment = Enum.TextXAlignment.Left
	rotLabel.Parent = frame

	local rotHint = Instance.new("TextLabel")
	rotHint.Size = UDim2.new(1, -20, 0, 18)
	rotHint.Position = UDim2.new(0, 10, 0, 195)
	rotHint.BackgroundTransparency = 1
	rotHint.Text = "Press R to rotate right, Q to rotate left"
	rotHint.TextColor3 = Color3.fromRGB(140, 140, 140)
	rotHint.Font = Enum.Font.Gotham
	rotHint.TextSize = 11
	rotHint.TextXAlignment = Enum.TextXAlignment.Left
	rotHint.Parent = frame

	-- Rotate Left button
	local rotLeftBtn = Instance.new("TextButton")
	rotLeftBtn.Name = "RotLeftBtn"
	rotLeftBtn.Size = UDim2.new(0, 95, 0, 28)
	rotLeftBtn.Position = UDim2.new(0, 10, 0, 215)
	rotLeftBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	rotLeftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	rotLeftBtn.Font = Enum.Font.GothamBold
	rotLeftBtn.TextSize = 13
	rotLeftBtn.Text = "Left"
	rotLeftBtn.BorderSizePixel = 0
	rotLeftBtn.AutoButtonColor = true
	rotLeftBtn.Parent = frame

	local rotLeftCorner = Instance.new("UICorner")
	rotLeftCorner.CornerRadius = UDim.new(0, 8)
	rotLeftCorner.Parent = rotLeftBtn

	rotLeftBtn.MouseButton1Click:Connect(function()
		if not deleteMode then
			rotatePreview("left")
		end
	end)

	-- Rotate Right button
	local rotRightBtn = Instance.new("TextButton")
	rotRightBtn.Name = "RotRightBtn"
	rotRightBtn.Size = UDim2.new(0, 95, 0, 28)
	rotRightBtn.Position = UDim2.new(0, 110, 0, 215)
	rotRightBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	rotRightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	rotRightBtn.Font = Enum.Font.GothamBold
	rotRightBtn.TextSize = 13
	rotRightBtn.Text = "Right"
	rotRightBtn.BorderSizePixel = 0
	rotRightBtn.AutoButtonColor = true
	rotRightBtn.Parent = frame

	local rotRightCorner = Instance.new("UICorner")
	rotRightCorner.CornerRadius = UDim.new(0, 8)
	rotRightCorner.Parent = rotRightBtn

	rotRightBtn.MouseButton1Click:Connect(function()
		if not deleteMode then
			rotatePreview("right")
		end
	end)

	-- Delete mode toggle button
	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Name = "DeleteButton"
	deleteBtn.Size = UDim2.new(1, -20, 0, 32)
	deleteBtn.Position = UDim2.new(0, 10, 0, 249)
	deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	deleteBtn.Font = Enum.Font.GothamBold
	deleteBtn.TextSize = 14
	deleteBtn.Text = "Delete Mode: OFF"
	deleteBtn.BorderSizePixel = 0
	deleteBtn.AutoButtonColor = true
	deleteBtn.Parent = frame

	local deleteBtnCorner = Instance.new("UICorner")
	deleteBtnCorner.CornerRadius = UDim.new(0, 8)
	deleteBtnCorner.Parent = deleteBtn

	deleteBtn.MouseButton1Click:Connect(function()
		deleteMode = not deleteMode
		if deleteMode then
			deleteBtn.Text = "Delete Mode: ON"
			deleteBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
			-- Hide preview when in delete mode
			if preview then
				preview.Parent = nil
			end
		else
			deleteBtn.Text = "Delete Mode: OFF"
			deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
			-- Show preview again
			if preview then
				preview.Parent = workspace
			end
		end
	end)

	local deleteHint = Instance.new("TextLabel")
	deleteHint.Size = UDim2.new(1, -20, 0, 18)
	deleteHint.Position = UDim2.new(0, 10, 0, 283)
	deleteHint.BackgroundTransparency = 1
	deleteHint.Text = "Click placed antenna to delete"
	deleteHint.TextColor3 = Color3.fromRGB(140, 140, 140)
	deleteHint.Font = Enum.Font.Gotham
	deleteHint.TextSize = 11
	deleteHint.TextXAlignment = Enum.TextXAlignment.Left
	deleteHint.Parent = frame
end

-- Start game
startEvent.OnClientEvent:Connect(function()
	gameStarted = true
	currentAngle = 0
	deleteMode = false
	createGUI()
	createPreview()
end)