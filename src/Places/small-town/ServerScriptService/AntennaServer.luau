local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local antennaFolder = ReplicatedStorage:FindFirstChild("AntennaModels")
local placeEvent = ReplicatedStorage:FindFirstChild("PlaceAntenna")
local deleteEvent = ReplicatedStorage:FindFirstChild("DeleteAntenna")

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

-- Track which player placed which antenna 
local antennaOwners = {}

-- Calculate the lowest Y-coordinate of the model to correctly position the antenna on the ground
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

	-- Second pass: find X/Z center at the base level
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

placeEvent.OnServerEvent:Connect(function(player, antennaName, position, rotationAngle)
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

	-- Validate rotation angle (must be 0, 90, 180, or 270)
	if type(rotationAngle) ~= "number" then
		rotationAngle = 0
	end
	rotationAngle = math.floor(rotationAngle / 90 + 0.5) * 90 % 360

	-- Find the model to clone
	local template = antennaFolder and antennaFolder:FindFirstChild(antennaName)
	if not template then
		warn("[AntennaServer] Could not find antenna model:", antennaName)
		return
	end

	-- Clone and place the antenna with rotation around base center
	local model = template:Clone()
	local pivot = model:GetPivot()
	local originalRotation = pivot - pivot.Position

	-- Place model at origin with original rotation to compute base info
	model:PivotTo(originalRotation)
	local baseCenter = computeBaseCenter(model)
	local pivotPos = model:GetPivot().Position
	local baseToPivotOffset = pivotPos - baseCenter

	-- Rotate the offset and position so base center stays at the target position
	local rotCF = CFrame.Angles(0, math.rad(rotationAngle), 0)
	local rotatedOffset = rotCF * baseToPivotOffset
	local newPivotPos = position + rotatedOffset
	model:PivotTo(CFrame.new(newPivotPos) * rotCF * originalRotation)

	-- Tag the antenna with the player who placed it
	local ownerTag = Instance.new("StringValue")
	ownerTag.Name = "Owner"
	ownerTag.Value = player.Name
	ownerTag.Parent = model

	-- Give each placed antenna a unique name to avoid collisions
	local count = 0
	for _, child in placedFolder:GetChildren() do
		if child.Name:match("^" .. antennaName) then
			count = count + 1
		end
	end
	model.Name = antennaName .. "_" .. (count + 1)

	model.Parent = placedFolder
	antennaOwners[model] = player

	print("[AntennaServer]", player.Name, "placed", model.Name, "at", position, "rotation:", rotationAngle)
end)

-- Handle antenna deletion
deleteEvent.OnServerEvent:Connect(function(player, antennaInstanceName)
	if type(antennaInstanceName) ~= "string" then
		warn("[AntennaServer] Invalid delete request from", player.Name)
		return
	end

	local placedFolderCheck = Workspace:FindFirstChild("PlacedAntennas")
	if not placedFolderCheck then
		return
	end

	local antenna = placedFolderCheck:FindFirstChild(antennaInstanceName)
	if not antenna then
		warn("[AntennaServer] Could not find antenna to delete:", antennaInstanceName)
		return
	end

	-- Only allow the player who placed it to delete it
	local ownerTag = antenna:FindFirstChild("Owner")
	if ownerTag and ownerTag.Value == player.Name then
		antennaOwners[antenna] = nil
		antenna.Parent = nil
		print("[AntennaServer]", player.Name, "deleted", antennaInstanceName)
	else
		warn("[AntennaServer]", player.Name, "tried to delete antenna they don't own:", antennaInstanceName)
	end
end)