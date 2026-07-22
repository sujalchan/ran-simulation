local workspace = game:GetService("Workspace")

-- antenna position and orientation
local antenna = Instance.new("Part")
antenna.Name = "MainPart"
antenna.Size = Vector3.new(3, 7, 1)
antenna.CFrame = CFrame.new(100.637, 3.787, -73.968)
antenna.Transparency = 1
antenna.Anchored = true
antenna.CanCollide = false
antenna.Parent = workspace

-- visualization settings
local radius = 15
local density = 80
local pointSize = Vector3.new(0.3, 0.3, 0.3)

local colors = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(0, 255, 255),
	Color3.fromRGB(0, 0, 255),
}

local function numberToColor(value)
	value = math.clamp(value, 0, 1)

	local scaled = value * (#colors - 1)
	local colorIndex = math.floor(scaled) + 1
	local alpha = scaled % 1

	if colorIndex >= #colors then
		return colors[#colors]
	end

	return colors[colorIndex]:Lerp(colors[colorIndex + 1], alpha)
end

local function pointStrength(worldPosition)
	-- get the direction in the antenna's local coordinate system
	local localPosition = antenna.CFrame:PointToObjectSpace(worldPosition)
	local localDirection = localPosition.Unit

	local azimuth = math.deg(
		math.atan2(localDirection.X, localDirection.Z)
	)

	local elevation = math.deg(
		math.asin(localDirection.Y)
	)

	-- antenna pattern values
	local maxGain = 15.4
	local horizontalBeamwidth = 15
	local verticalBeamwidth = 9
	local frontToBackRatio = 25
	local gainFloor = maxGain - frontToBackRatio

	local gain =
		maxGain
	- 12 * (azimuth / horizontalBeamwidth) ^ 2
	- 12 * (elevation / verticalBeamwidth) ^ 2

	local finalGain = math.max(gain, gainFloor)

	return math.clamp(
		(finalGain - gainFloor) / (maxGain - gainFloor),
		0,
		1
	)
end

local visualizationFolder = Instance.new("Folder")
visualizationFolder.Name = "AntennaVisualization"
visualizationFolder.Parent = workspace

for latitudeIndex = 0, density do
	local phi = math.pi * latitudeIndex / density

	-- only create one point at each pole
	local longitudeCount = density

	if latitudeIndex == 0 or latitudeIndex == density then
		longitudeCount = 1
	end

	for longitudeIndex = 0, longitudeCount - 1 do
		local theta = 2 * math.pi * longitudeIndex / density

		local sphereOffset = Vector3.new(
			radius * math.sin(phi) * math.cos(theta),
			radius * math.cos(phi),
			radius * math.sin(phi) * math.sin(theta)
		)

		local spherePosition = antenna.Position + sphereOffset
		local strength = pointStrength(spherePosition)

		local point = Instance.new("Part")
		point.Size = pointSize
		point.Position = antenna.Position + sphereOffset * strength
		point.Color = numberToColor(strength)
		point.Material = Enum.Material.Neon
		point.Transparency = 0.5
		point.Anchored = true
		point.CanCollide = false
		point.CanTouch = false
		point.CanQuery = false
		point.Parent = visualizationFolder
	end
end