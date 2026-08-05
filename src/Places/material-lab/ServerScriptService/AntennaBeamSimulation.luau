local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local updateAntennaEvent = ReplicatedStorage:WaitForChild("UpdateAntennaEvent")

local directionalBeam
local narrowBeam

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

local function createDirectionalBeam(settings)
	local antenna = Instance.new("Part")
	antenna.Name = settings.partName
	antenna.Size = Vector3.new(3, 7, 1)
	antenna.CFrame = settings.cframe
	antenna.Transparency = 1
	antenna.Anchored = true
	antenna.CanCollide = false
	antenna.Parent = Workspace

	local baseCFrame = settings.cframe
	local points = {}

	local visualizationFolder = Instance.new("Folder")
	visualizationFolder.Name = settings.folderName
	visualizationFolder.Parent = Workspace

	local function pointStrength(worldPosition)
		local localPosition =
			antenna.CFrame:PointToObjectSpace(worldPosition)

		if localPosition.Magnitude == 0 then
			return 1
		end

		local localDirection = localPosition.Unit

		local pointAzimuth = math.deg(
			math.atan2(
				localDirection.X,
				localDirection.Z
			)
		)

		local pointElevation = math.deg(
			math.asin(localDirection.Y)
		)

		local maxGain = 15.4
		local gainFloor =
			maxGain - settings.frontToBackRatio

		local gain =
			maxGain
		- 12
			* (
				pointAzimuth
				/ settings.horizontalBeamwidth
			) ^ 2
		- 12
			* (
				pointElevation
				/ settings.verticalBeamwidth
			) ^ 2

		local finalGain = math.max(gain, gainFloor)

		return math.clamp(
			(finalGain - gainFloor)
				/ (maxGain - gainFloor),
			0,
			1
		)
	end

	for latitudeIndex = 0, settings.density do
		local phi =
			math.pi * latitudeIndex / settings.density

		local longitudeCount = settings.density

		if latitudeIndex == 0
			or latitudeIndex == settings.density then

			longitudeCount = 1
		end

		for longitudeIndex = 0, longitudeCount - 1 do
			local theta =
				2
				* math.pi
				* longitudeIndex
				/ settings.density

			local sphereOffset = Vector3.new(
				settings.radius
					* math.sin(phi)
					* math.cos(theta),

				settings.radius
					* math.cos(phi),

				settings.radius
					* math.sin(phi)
					* math.sin(theta)
			)

			local point = Instance.new("Part")
			point.Size = settings.pointSize
			point.Material = Enum.Material.Neon
			point.Transparency = 0.5
			point.Anchored = true
			point.CanCollide = false
			point.CanTouch = false
			point.CanQuery = false
			point.Parent = visualizationFolder

			table.insert(points, {
				part = point,
				offset = sphereOffset,
			})
		end
	end

	local beam = {}

	function beam.update(elevation, azimuth)
		elevation = math.clamp(elevation, -90, 90)
		
		if azimuth < 0 then
			azimuth = 360 + azimuth
		end
		
		-- rotate from the antenna's original orientation
		antenna.CFrame =
			baseCFrame
			* CFrame.Angles(
				math.rad(-elevation),
				math.rad(azimuth),
				0
			)

		for _, pointData in ipairs(points) do
			local worldOffset =
				antenna.CFrame:VectorToWorldSpace(
					pointData.offset
				)

			local spherePosition =
				antenna.Position + worldOffset

			local strength =
				pointStrength(spherePosition)

			pointData.part.Position =
				antenna.Position
				+ worldOffset * strength

			pointData.part.Color =
				numberToColor(strength)
		end
	end

	function beam.getAntenna()
		return antenna
	end

	beam.update(0, 0)

	return beam
end

directionalBeam = createDirectionalBeam({
	partName = "DirectionalPart",
	folderName = "DirectionalVisualization",

	cframe = CFrame.new(
		103.583,
		3.677,
		-95.912
	),

	radius = 9,
	density = 80,
	pointSize = Vector3.new(0.3, 0.3, 0.3),

	horizontalBeamwidth = 30,
	verticalBeamwidth = 20,
	frontToBackRatio = 25,
})

narrowBeam = createDirectionalBeam({
	partName = "MainPart",
	folderName = "NarrowVisualization",

	cframe = CFrame.new(
		100.637,
		3.787,
		-73.968
	),

	radius = 15,
	density = 80,
	pointSize = Vector3.new(0.3, 0.3, 0.3),

	horizontalBeamwidth = 15,
	verticalBeamwidth = 9,
	frontToBackRatio = 25,
})

-- omni beam antenna
do
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
end

local validAntennaTypes = {
	Directional = true,
	NarrowBeam = true,
}

updateAntennaEvent.OnServerEvent:Connect(function(
	player,
	antennaType,
	elevation,
	azimuth
)
	if not validAntennaTypes[antennaType] then
		return
	end

	if typeof(elevation) ~= "number"
		or typeof(azimuth) ~= "number" then
		return
	end

	-- verify the player is controlling the antenna
	-- they are currently closest to
	if player:GetAttribute("ClosestSignalSource")
		~= antennaType then
		return
	end

	elevation = math.clamp(
		math.round(elevation),
		-90,
		90
	)


	if antennaType == "Directional" then
		-- directional only responds to elevation
		directionalBeam.update(elevation, 0)

	elseif antennaType == "NarrowBeam" then
		-- narrow beam responds to both sliders
		narrowBeam.update(elevation, azimuth)
	end
end)

print("all antenna beam simulations loaded")