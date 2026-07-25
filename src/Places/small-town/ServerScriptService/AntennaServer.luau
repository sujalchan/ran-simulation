local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local antennaFolder = ReplicatedStorage:FindFirstChild("AntennaModels")
local placeEvent = ReplicatedStorage:FindFirstChild("PlaceAntenna")

local placedFolder = Workspace:FindFirstChild("PlacedAntennas")
if not placedFolder then
	placedFolder = Instance.new("Folder")
	placedFolder.Name = "PlacedAntennas"
	placedFolder.Parent = Workspace
end

-- List of installable antennas
local validAntennas = {
	Antenna1 = true,
	Antenna2 = true,
	Antenna3 = true,
	Antenna4 = true,
}

-- Calculate the lowest Y-coordinate of the model to correctly position the antenna on the ground
local function computeBaseOffset(model, rotation)
	model:PivotTo(rotation)

	local lowestY = math.huge
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

	return lowestY
end

placeEvent.OnServerEvent:Connect(function(player, antennaName, position)
	-- Validate antenna name
	if type(antennaName) ~= "string" or not validAntennas[antennaName] then
		warn("[AntennaServer] Invalid antenna name from", player.Name)
		return
	end

	-- Validate position
	if typeof(position) ~= "Vector3" then
		warn("[AntennaServer] Invalid position from", player.Name)
		return
	end

	-- Find the model to clone
	local template = antennaFolder and antennaFolder:FindFirstChild(antennaName)
	if not template then
		warn("[AntennaServer] Could not find antenna model:", antennaName)
		return
	end

	-- Clone and place the antenna 
	local model = template:Clone()
	local pivot = model:GetPivot()
	local rotation = pivot - pivot.Position
	local baseOffset = computeBaseOffset(model, rotation)
	model:PivotTo(CFrame.new(position.X, position.Y - baseOffset, position.Z) * rotation)
	model.Parent = placedFolder

	print("[AntennaServer]", player.Name, "placed", antennaName, "at", position)
end)