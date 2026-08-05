local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local startEvent = ReplicatedStorage:WaitForChild("StartGame")
local placeEvent = ReplicatedStorage:WaitForChild("PlaceAntenna")
local deleteEvent = ReplicatedStorage:WaitForChild("DeleteAntenna")
local resetEvent = ReplicatedStorage:WaitForChild("ResetGame")
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

local INITIAL_BUDGET = 1000
local currentBudget = INITIAL_BUDGET

-- The 4 antenna options
local antennaOptions = {
	{displayName = "Rooftop Cell Site", modelName = "Antenna1", cost = 50},
	{displayName = "Monopole Cell Tower", modelName = "Antenna2", cost = 100},
	{displayName = "Panel Antenna Tower", modelName = "Antenna3", cost = 250},
	{displayName = "Lattice Tower", modelName = "Antenna4", cost = 500},
}

local function getSelectedCost()
	for _, opt in ipairs(antennaOptions) do
		if opt.modelName == selectedAntenna then
			return opt.cost
		end
	end
	return 0
end

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

	preview.Parent = workspace
end

-- Get mouse world position
local function getMousePosition()
	local mouse = player:GetMouse()
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)

	local excludeList = {}
	if preview then table.insert(excludeList, preview) end
	if player.Character then table.insert(excludeList, player.Character) end

	rayParams.FilterDescendantsInstances = excludeList

	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
	if result then
		return result.Position
	end
	return nil
end

-- Move preview 
RunService.RenderStepped:Connect(function()
	if not gameStarted or not preview or deleteMode or not antennaSelected then
		if preview then preview.Parent = nil end
		return
	end

	local pos = getMousePosition()
	if pos then
		preview.Parent = workspace
		-- Rotate the offset from base center to pivot by current angle
		local rotCF = CFrame.Angles(0, math.rad(currentAngle), 0)
		local rotatedOffset = rotCF * baseToPivotOffset

		-- Position pivot such that base center is at the mouse position
		local pivotPos = pos + rotatedOffset
		preview:PivotTo(CFrame.new(pivotPos) * rotCF * originalModelRotation)
	else
		preview.Parent = nil
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

-- Update budget text
local function updateBudgetDisplay()
	local gui = player.PlayerGui:FindFirstChild("AntennaGUI")
	if gui then
		local budgetLabel = gui:FindFirstChild("MainFrame"):FindFirstChild("BudgetLabel")
		if budgetLabel then
			budgetLabel.Text = "Budget: $" .. string.format("%d", currentBudget)
		end
	end
end

-- User Input Handling
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
			if not placedFolder then return end

			local delParams = RaycastParams.new()
			delParams.FilterType = Enum.RaycastFilterType.Include
			delParams.FilterDescendantsInstances = {placedFolder}

			local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, delParams)
			if result and result.Instance then
				local targetModel = result.Instance
				while targetModel and targetModel.Parent ~= placedFolder do
					targetModel = targetModel.Parent
				end

				if targetModel and targetModel.Parent == placedFolder then
					-- Identify antenna type via Attribute or Name
					local typeName = targetModel:GetAttribute("AntennaType") or targetModel.Name
					local refundCost = 0

					for _, opt in ipairs(antennaOptions) do
						if opt.modelName == typeName or string.find(targetModel.Name, opt.modelName) then
							refundCost = opt.cost
							break
						end
					end

					if refundCost > 0 then
						currentBudget = currentBudget + refundCost
						updateBudgetDisplay()
						print("[AntennaPlacer] Refunded: $" .. refundCost .. " | Current Budget: $" .. currentBudget)
					else
						warn("[AntennaPlacer] Could not determine antenna type for refund:", targetModel.Name)
					end

					deleteEvent:FireServer(targetModel.Name)
				end
			end
		else
			-- Only place if an antenna button is selected (blue)
			if not antennaSelected then return end
			local cost = getSelectedCost()

			if currentBudget < cost then
				warn("Not enough budget! Required cost: $" .. cost)
				return
			end

			local pos = getMousePosition()
			if pos then
				currentBudget = currentBudget - cost
				updateBudgetDisplay()
				print("[Client] Placement request sent:", selectedAntenna, pos)
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
	local existingGui = player.PlayerGui:FindFirstChild("AntennaGUI")
	if existingGui then
		existingGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AntennaGUI"
	gui.Parent = player.PlayerGui

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 230, 0, 320) 
	frame.Position = UDim2.new(1, -250, 0.5, -140)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = gui

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 26)
	title.BackgroundTransparency = 1
	title.Text = "Select Antenna"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.Parent = frame

	-- Budget Display
	local budgetLabel = Instance.new("TextLabel")
	budgetLabel.Name = "BudgetLabel"
	budgetLabel.Size = UDim2.new(1, -20, 0, 20)
	budgetLabel.Position = UDim2.new(0, 10, 0, 26)
	budgetLabel.BackgroundTransparency = 1
	budgetLabel.Text = "Budget: $" .. string.format("%d", currentBudget)
	budgetLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
	budgetLabel.Font = Enum.Font.GothamBold
	budgetLabel.TextSize = 14
	budgetLabel.TextXAlignment = Enum.TextXAlignment.Left
	budgetLabel.Parent = frame

	local selectedButton = nil

	-- Antenna Selection Buttons
	for i, opt in ipairs(antennaOptions) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -20, 0, 28)
		button.Position = UDim2.new(0, 10, 0, 52 + (i - 1) * 32)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = Enum.Font.Gotham
		button.TextSize = 12
		button.Text = opt.displayName .. " ($" .. opt.cost .. ")"
		button.BorderSizePixel = 0
		button.AutoButtonColor = true
		button.Parent = frame

		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

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

			selectedAntenna = opt.modelName
			print("[AntennaPlacer] Selection changed:", selectedAntenna)
			createPreview()
		end)
	end

	-- Rotation section
	local rotLabel = Instance.new("TextLabel")
	rotLabel.Name = "RotationLabel"
	rotLabel.Size = UDim2.new(1, -20, 0, 18)
	rotLabel.Position = UDim2.new(0, 10, 0, 186)
	rotLabel.BackgroundTransparency = 1
	rotLabel.Text = "Rotation: " .. currentAngle .. "°"
	rotLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	rotLabel.Font = Enum.Font.GothamBold
	rotLabel.TextSize = 12
	rotLabel.TextXAlignment = Enum.TextXAlignment.Left
	rotLabel.Parent = frame

	local rotHint = Instance.new("TextLabel")
	rotHint.Size = UDim2.new(1, -20, 0, 14)
	rotHint.Position = UDim2.new(0, 10, 0, 204)
	rotHint.BackgroundTransparency = 1
	rotHint.Text = "Press R/Q to rotate"
	rotHint.TextColor3 = Color3.fromRGB(140, 140, 140)
	rotHint.Font = Enum.Font.Gotham
	rotHint.TextSize = 10
	rotHint.TextXAlignment = Enum.TextXAlignment.Left
	rotHint.Parent = frame

	-- Rotate Left button
	local rotLeftBtn = Instance.new("TextButton")
	rotLeftBtn.Name = "RotLeftBtn"
	rotLeftBtn.Size = UDim2.new(0, 100, 0, 26)
	rotLeftBtn.Position = UDim2.new(0, 10, 0, 222)
	rotLeftBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	rotLeftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	rotLeftBtn.Font = Enum.Font.GothamBold
	rotLeftBtn.TextSize = 11
	rotLeftBtn.Text = "Left (Q)"
	rotLeftBtn.BorderSizePixel = 0
	rotLeftBtn.Parent = frame
	Instance.new("UICorner", rotLeftBtn).CornerRadius = UDim.new(0, 6)

	rotLeftBtn.MouseButton1Click:Connect(function()
		if not deleteMode then
			rotatePreview("left")
		end
	end)

	-- Rotate Right button
	local rotRightBtn = Instance.new("TextButton")
	rotRightBtn.Name = "RotRightBtn"
	rotRightBtn.Size = UDim2.new(0, 100, 0, 26)
	rotRightBtn.Position = UDim2.new(0, 115, 0, 222)
	rotRightBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	rotRightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	rotRightBtn.Font = Enum.Font.GothamBold
	rotRightBtn.TextSize = 11
	rotRightBtn.Text = "Right (R)"
	rotRightBtn.BorderSizePixel = 0
	rotRightBtn.Parent = frame
	Instance.new("UICorner", rotRightBtn).CornerRadius = UDim.new(0, 6)

	rotRightBtn.MouseButton1Click:Connect(function()
		if not deleteMode then
			rotatePreview("right")
		end
	end)

	-- Delete mode toggle button
	local deleteBtn = Instance.new("TextButton")
	deleteBtn.Name = "DeleteButton"
	deleteBtn.Size = UDim2.new(1, -20, 0, 28)
	deleteBtn.Position = UDim2.new(0, 10, 0, 256)
	deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	deleteBtn.Font = Enum.Font.GothamBold
	deleteBtn.TextSize = 12
	deleteBtn.Text = "Delete Mode: OFF"
	deleteBtn.BorderSizePixel = 0
	deleteBtn.Parent = frame
	Instance.new("UICorner", deleteBtn).CornerRadius = UDim.new(0, 6)

	deleteBtn.MouseButton1Click:Connect(function()
		deleteMode = not deleteMode
		if deleteMode then
			deleteBtn.Text = "Delete Mode: ON"
			deleteBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
		else
			deleteBtn.Text = "Delete Mode: OFF"
			deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
		end
	end)

		local deleteHint = Instance.new("TextLabel")
	deleteHint.Size = UDim2.new(1, -20, 0, 14)
	deleteHint.Position = UDim2.new(0, 10, 0, 288)
	deleteHint.BackgroundTransparency = 1
	deleteHint.Text = "Click placed antenna to delete"
	deleteHint.TextColor3 = Color3.fromRGB(140, 140, 140)
	deleteHint.Font = Enum.Font.Gotham
	deleteHint.TextSize = 10
	deleteHint.TextXAlignment = Enum.TextXAlignment.Left
	deleteHint.Parent = frame

	-- Reset / Exit button
	local resetBtn = Instance.new("TextButton")
	resetBtn.Name = "ResetButton"
	resetBtn.Size = UDim2.new(1, -20, 0, 30)
	resetBtn.Position = UDim2.new(0, 10, 0, 308)
	resetBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.TextSize = 13
	resetBtn.Text = "Reset / Exit game"
	resetBtn.BorderSizePixel = 0
	resetBtn.Parent = frame
	Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)

	resetBtn.MouseButton1Click:Connect(function()
		resetEvent:FireServer()
	end)

	-- Adjust frame height to fit the new button
	frame.Size = UDim2.new(0, 230, 0, 350)
end

-- Start game
startEvent.OnClientEvent:Connect(function()
	gameStarted = true
	selectedAntenna = "Antenna1"
	currentAngle = 0
	deleteMode = false
	currentBudget = INITIAL_BUDGET
	createGUI()
	createPreview()
end)

-- Handle reset from server
resetEvent.OnClientEvent:Connect(function()
	gameStarted = false
	selectedAntenna = "Antenna1"
	currentAngle = 0
	deleteMode = false
	antennaSelected = true
	currentBudget = INITIAL_BUDGET

	-- Destroy preview
	if preview then
		preview:Destroy()
		preview = nil
	end

	-- Destroy AntennaGUI
	local gui = player.PlayerGui:FindFirstChild("AntennaGUI")
	if gui then
		gui:Destroy()
	end

	print("[AntennaPlacer] Game reset complete.")
end)