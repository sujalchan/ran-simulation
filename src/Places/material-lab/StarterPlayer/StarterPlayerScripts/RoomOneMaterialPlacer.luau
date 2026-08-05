local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local placeMaterialEvent = ReplicatedStorage:WaitForChild("PlaceItemEvent")
local placeableMaterials = ReplicatedStorage:WaitForChild("PlaceableMaterials")

local selectedMaterialName = "Concrete"

local materialKeys = {
	[Enum.KeyCode.One] = "Concrete",
	[Enum.KeyCode.Two] = "Metal",
	[Enum.KeyCode.Three] = "Wood",
}

local gridSize = 2
local rotationY = 0

local previewPart = nil
local currentPlacementCFrame = nil
local placementEnabled = true

local gridOffsetX = 1
local gridOffsetZ = 1
local minimumY = 1.432

-- heatmap grid bounds
local HEATMAP_MIN_X = 3
local HEATMAP_MAX_X = 61
local HEATMAP_MIN_Z = -33
local HEATMAP_MAX_Z = 13

local function snapY(value)
	if value < minimumY then
		return minimumY
	end

	local level = math.round((value - minimumY) / gridSize)
	return minimumY + level * gridSize
end

local function snapToGrid(value, offset)
	return math.round((value - offset) / gridSize) * gridSize + offset
end

local function setPreviewAppearance(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 0.2
end

local function createPreview()
	if previewPart then
		previewPart:Destroy()
	end

	local itemTemplate = placeableMaterials:FindFirstChild(selectedMaterialName)

	if not itemTemplate then
		warn("could not find item:", selectedMaterialName)
		return
	end

	if not itemTemplate:IsA("BasePart") then
		warn(selectedMaterialName .. " must be a Part")
		return
	end

	previewPart = itemTemplate:Clone()
	previewPart.Name = "PlacementPreview"

	setPreviewAppearance(previewPart)

	previewPart.Parent = workspace
end

local function selectMaterial(materialName)
	if selectedMaterialName == materialName then
		return
	end

	selectedMaterialName = materialName
	createPreview()

	print("selected material:", selectedMaterialName)
end

local function isPlayerOnHeatmap()
	local character = player.Character
	if not character then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	local pos = root.Position

	local inRoomOne = player:GetAttribute("InRoomOne") == true
	if not inRoomOne then
		return false
	end

	local isOnHeatmap = pos.X >= HEATMAP_MIN_X
		and pos.X <= HEATMAP_MAX_X
		and pos.Z >= HEATMAP_MIN_Z
		and pos.Z <= HEATMAP_MAX_Z

	return isOnHeatmap
end

local function getPlacementCFrame()
	if not previewPart then
		return nil
	end

	local mousePosition = UserInputService:GetMouseLocation()
	local camera = workspace.CurrentCamera

	local cameraRay = camera:ViewportPointToRay(
		mousePosition.X,
		mousePosition.Y
	)

	-- exclude the preview part and the player's character
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {
		previewPart,
		player.Character,
	}

	local raycastResult = workspace:Raycast(
		cameraRay.Origin,
		cameraRay.Direction * 1000,
		raycastParams
	)

	if not raycastResult then
		return nil
	end

	local hitPart = raycastResult.Instance
	local hitPosition = raycastResult.Position
	local hitNormal = raycastResult.Normal

	-- check if we hit a placed block (in levelonematerials)
	local isPlacedBlock = hitPart and hitPart.Parent and hitPart.Parent.Name == "LevelOneMaterials"

	-- check if we hit a heatmap tile
	local isHeatmapTile = hitPart and hitPart.Parent and hitPart.Parent.Name == "HeatmapGrid"

	if not isPlacedBlock and not isHeatmapTile then
		return nil
	end

	local itemSize = previewPart.Size
	local x, y, z

	if isPlacedBlock then
		-- placing on or next to an existing block
		local blockPos = hitPart.Position
		local blockSize = hitPart.Size

		-- determine which face was hit using the normal
		local normal = hitNormal
		local absX = math.abs(normal.X)
		local absY = math.abs(normal.Y)
		local absZ = math.abs(normal.Z)

		-- snap x and z to grid based on block position
		x = snapToGrid(blockPos.X, gridOffsetX)
		z = snapToGrid(blockPos.Z, gridOffsetZ)

		if absY > absX and absY > absZ then
			-- top or bottom face
			local sign = math.sign(normal.Y)
			y = blockPos.Y + sign * (blockSize.Y/2 + itemSize.Y/2)
			y = snapY(y)
		elseif absX > absZ then
			-- left or right face
			local sign = math.sign(normal.X)
			x = blockPos.X + sign * (blockSize.X/2 + itemSize.X/2)
			-- round x to grid
			x = snapToGrid(x, gridOffsetX)
			-- align y to block's y (same height)
			y = blockPos.Y
			y = snapY(y)
		else
			-- front or back face
			local sign = math.sign(normal.Z)
			z = blockPos.Z + sign * (blockSize.Z/2 + itemSize.Z/2)
			-- round z to grid
			z = snapToGrid(z, gridOffsetZ)
			-- align y to block's y (same height)
			y = blockPos.Y
			y = snapY(y)
		end
	else
		-- placing on the floor (heatmap tile)
		x = snapToGrid(hitPosition.X, gridOffsetX)
		z = snapToGrid(hitPosition.Z, gridOffsetZ)
		local desiredY = hitPosition.Y + itemSize.Y / 2
		y = snapY(desiredY)
	end

	local position = Vector3.new(x, y, z)
	local rotation = CFrame.Angles(0, math.rad(rotationY), 0)

	return CFrame.new(position) * rotation
end

local function placeItem()
	if not placementEnabled then
		return
	end

	if not isPlayerOnHeatmap() then
		return
	end

	currentPlacementCFrame = getPlacementCFrame()

	if not currentPlacementCFrame then
		return
	end

	placeMaterialEvent:FireServer(
		selectedMaterialName,
		currentPlacementCFrame
	)
end

createPreview()

RunService.RenderStepped:Connect(function()
	if not placementEnabled or not previewPart then
		return
	end

	if not isPlayerOnHeatmap() then
		if previewPart.Parent then
			previewPart.Parent = nil
		end
		return
	else
		if not previewPart.Parent then
			previewPart.Parent = workspace
		end
	end

	currentPlacementCFrame = getPlacementCFrame()

	if currentPlacementCFrame then
		previewPart.CFrame = currentPlacementCFrame
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local materialName = materialKeys[input.KeyCode]

	if materialName then
		selectMaterial(materialName)
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		placeItem()
	elseif input.KeyCode == Enum.KeyCode.R then
		rotationY = (rotationY + 90) % 360
	elseif input.KeyCode == Enum.KeyCode.M then
		placementEnabled = not placementEnabled

		if previewPart then
			previewPart.Parent = placementEnabled and workspace or nil
		end
	end
end)

print("room one material placer loaded")