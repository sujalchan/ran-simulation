local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local placeMaterialEvent = ReplicatedStorage:WaitForChild("PlaceItemEvent")
local placeableMaterials = ReplicatedStorage:WaitForChild("PlaceableMaterials")
local levelOneMaterials = workspace:WaitForChild("LevelOneMaterials")

local ALLOWED_MATERIALS = {
	Concrete = true,
	Metal = true,
	Wood = true,
}

local GRID_SIZE = 2
local GRID_OFFSET_X = 1
local GRID_OFFSET_Z = 1
local MINIMUM_Y = 1.432
local MAX_DISTANCE = 50

-- heatmap grid bounds
local HEATMAP_MIN_X = 3
local HEATMAP_MAX_X = 61
local HEATMAP_MIN_Z = -33
local HEATMAP_MAX_Z = 13

local function snap(value, offset)
	return math.round((value - offset) / GRID_SIZE) * GRID_SIZE + offset
end

local function snapY(value)
	if value < MINIMUM_Y then
		return MINIMUM_Y
	end

	local level = math.round((value - MINIMUM_Y) / GRID_SIZE)
	return MINIMUM_Y + level * GRID_SIZE
end

local function isPlayerOnHeatmap(player)
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

local function isPositionOnHeatmap(position)
	-- check bounds only 
	return position.X >= HEATMAP_MIN_X
		and position.X <= HEATMAP_MAX_X
		and position.Z >= HEATMAP_MIN_Z
		and position.Z <= HEATMAP_MAX_Z
end

placeMaterialEvent.OnServerEvent:Connect(function(player, materialName, cf)
	if typeof(materialName) ~= "string" then
		return
	end

	if typeof(cf) ~= "CFrame" then
		return
	end

	if not ALLOWED_MATERIALS[materialName] then
		return
	end

	if not isPlayerOnHeatmap(player) then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local template = placeableMaterials:FindFirstChild(materialName)
	if not template or not template:IsA("BasePart") then
		return
	end

	local x = snap(cf.Position.X, GRID_OFFSET_X)
	local y = snapY(cf.Position.Y)
	local z = snap(cf.Position.Z, GRID_OFFSET_Z)

	local position = Vector3.new(x, y, z)

	if (root.Position - position).Magnitude > MAX_DISTANCE then
		return
	end

	if not isPositionOnHeatmap(position) then
		return
	end

	local placed = template:Clone()
	placed.CFrame = CFrame.new(position) * (cf - cf.Position)
	placed.Anchored = true
	placed.Parent = levelOneMaterials
end)

print("place material handler loaded")