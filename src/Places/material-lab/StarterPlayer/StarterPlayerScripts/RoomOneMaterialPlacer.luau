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

	-- get the heatmap grid folder
	local heatmapGrid = workspace:FindFirstChild("HeatmapGrid")
	if not heatmapGrid then
		return nil
	end

	-- get the player's mouse position on screen
	local mousePosition = UserInputService:GetMouseLocation()
	local camera = workspace.CurrentCamera

	-- cast ray from camera through mouse position
	local cameraRay = camera:ViewportPointToRay(
		mousePosition.X,
		mousePosition.Y
	)

	-- only hit heatmap tiles
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {heatmapGrid}

	local raycastResult = workspace:Raycast(
		cameraRay.Origin,
		cameraRay.Direction * 1000,
		raycastParams
	)

	if not raycastResult then
		-- if the mouse ray doesn't hit a heatmap tile, cast it straight down from the player
		local character = player.Character
		if not character then
			return nil
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then
			return nil
		end

		local origin = root.Position + Vector3.new(0, 10, 0)
		local direction = Vector3.new(0, -20, 0)

		local fallbackResult = workspace:Raycast(origin, direction, raycastParams)

		if not fallbackResult then
			return nil
		end

		raycastResult = fallbackResult
	end

	local hitPart = raycastResult.Instance
	local isHeatmapTile = hitPart and hitPart.Parent and hitPart.Parent.Name == "HeatmapGrid"

	if not isHeatmapTile then
		return nil
	end

	local itemSize = previewPart.Size

	local x = snapToGrid(raycastResult.Position.X, gridOffsetX)
	local z = snapToGrid(raycastResult.Position.Z, gridOffsetZ)
	local desiredY = raycastResult.Position.Y + itemSize.Y / 2
	local y = snapY(desiredY)

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