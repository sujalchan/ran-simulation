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

local gridSize = 2

local gridOffsetX = 1
local gridOffsetZ = 1

local minimumY = 1.432

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
		warn("Could not find item:", selectedMaterialName)
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

	print("Selected material:", selectedMaterialName)
end

local function getPlacementCFrame()
	if not previewPart then
		return nil
	end

	local camera = workspace.CurrentCamera
	local mousePosition = UserInputService:GetMouseLocation()

	local cameraRay = camera:ViewportPointToRay(
		mousePosition.X,
		mousePosition.Y
	)

	local raycastParameters = RaycastParams.new()
	raycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	raycastParameters.FilterDescendantsInstances = {
		previewPart,
		player.Character,
	}

	local raycastResult = workspace:Raycast(
		cameraRay.Origin,
		cameraRay.Direction * 1000,
		raycastParameters
	)

	if not raycastResult then
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
	elseif input.KeyCode == Enum.KeyCode.X then
		placementEnabled = not placementEnabled

		if previewPart then
			previewPart.Parent = placementEnabled and workspace or nil
		end
	end
end)