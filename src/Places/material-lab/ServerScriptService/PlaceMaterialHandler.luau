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

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local template = placeableMaterials:FindFirstChild(materialName)
	if not template or not template:IsA("BasePart") then
		return
	end

	-- snap everything again on the server
	local x = snap(cf.Position.X, GRID_OFFSET_X)
	local y = snapY(cf.Position.Y)
	local z = snap(cf.Position.Z, GRID_OFFSET_Z)

	local position = Vector3.new(x, y, z)

	-- distance check
	if (root.Position - position).Magnitude > MAX_DISTANCE then
		return
	end

	local placed = template:Clone()
	placed.CFrame = CFrame.new(position) * (cf - cf.Position)
	placed.Anchored = true
	placed.Parent = levelOneMaterials
end)