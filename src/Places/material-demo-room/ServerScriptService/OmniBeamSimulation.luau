local Workspace = game:GetService("Workspace")

-- antenna position
local antenna = Instance.new("Part")
antenna.Name = "OmniPart"
antenna.Size = Vector3.new(1, 7, 1)
antenna.Position = Vector3.new(105.653, 7.729, -114.854)
antenna.Transparency = 1
antenna.Anchored = true
antenna.CanCollide = false
antenna.Parent = Workspace

-- visualization settings
local radius = 9
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

	return colors[colorIndex]:Lerp(
		colors[colorIndex + 1],
		alpha
	)
end

local function pointStrength(worldPosition)
	local direction = (worldPosition - antenna.Position).Unit

	local elevation = math.deg(
		math.asin(direction.Y)
	)

	-- vertical antenna pattern
	local maxGain = 8
	local verticalBeamwidth = 30
	local gainFloor = -15

	local gain =
		maxGain
	- 12 * (elevation / verticalBeamwidth) ^ 2

	local finalGain = math.max(gain, gainFloor)

	return math.clamp(
		(finalGain - gainFloor) / (maxGain - gainFloor),
		0,
		1
	)
end

local visualizationFolder = Instance.new("Folder")
visualizationFolder.Name = "OmniVisualization"
visualizationFolder.Parent = Workspace

for latitudeIndex = 0, density do
	local phi = math.pi * latitudeIndex / density

	local longitudeCount = density

	-- avoid creating many overlapping points at the poles
	if latitudeIndex == 0 or latitudeIndex == density then
		longitudeCount = 1
	end

	for longitudeIndex = 0, longitudeCount - 1 do
		local theta =
			2 * math.pi * longitudeIndex / density

		local sphereOffset = Vector3.new(
			radius * math.sin(phi) * math.cos(theta),
			radius * math.cos(phi),
			radius * math.sin(phi) * math.sin(theta)
		)

		local spherePosition =
			antenna.Position + sphereOffset

		local strength = pointStrength(spherePosition)

		local point = Instance.new("Part")
		point.Size = pointSize
		point.Position =
			antenna.Position + sphereOffset * strength

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
