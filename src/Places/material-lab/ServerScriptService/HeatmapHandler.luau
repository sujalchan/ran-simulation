local RunService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local frequencyChangedEvent = replicatedStorage:WaitForChild("FrequencyChangedEvent")
local toggleHeatmapEvent = replicatedStorage:WaitForChild("ToggleHeatmapEvent")
local levelOne = replicatedStorage:WaitForChild("LevelOne") -- objects cloned from replicated storage
local levelOneMaterials = workspace:WaitForChild("LevelOneMaterials") -- materials in level one

local signalSourcesFolder = workspace:WaitForChild("SignalSourcesFolder")
local signalSources = signalSourcesFolder:GetChildren()

local heatmapTile = levelOne:WaitForChild("HeatmapTile")

-- generate a grid folder for the heatmap tiles
local gridFolder = Instance.new("Folder")
gridFolder.Name = "HeatmapGrid"
gridFolder.Parent = workspace

-- keeps track of every tile in the grid
local heatmapTiles = {}

-- random number generator
local rng = Random.new()

-- grid description
local ROWS = 24
local COLUMNS = 30
local SPACING = 2
local XOFFSET = ((COLUMNS - 1) * SPACING) / 2
local ZOFFSET = ((ROWS - 1) * SPACING) / 2
local STARTPOSITION = Vector3.new(32, 0.5, -10)

-- function to convert a value to a color
local NOISEAMOUNT = 0.02

local function valueToColour(value)
	value = value + rng:NextNumber(-NOISEAMOUNT, NOISEAMOUNT)
	value = math.clamp(value, 0, 1)
	local red
	local green
	if value < 0.5 then
		-- red to yellow
		red = 1
		green = value * 2
	else
		-- yellow to green
		red = 1 - ((value - 0.5) * 2)
		green = 1
	end
	return Color3.new(red, green, 0)
end

-- generate the heatmap grid
for row = 1, ROWS do
	for column = 1, COLUMNS do
		local tile = heatmapTile:Clone()
		tile.Name = "HeatmapTile_" .. row .. "_" .. column
		tile.Anchored = true
		tile.Parent = gridFolder

		local x = STARTPOSITION.X + ((column - 1) * SPACING) - XOFFSET
		local y = STARTPOSITION.Y
		local z = STARTPOSITION.Z + ((row - 1) * SPACING) - ZOFFSET
		local position = Vector3.new(x, y, z)

		tile.Position = position
		tile.Color = valueToColour(0)

		table.insert(heatmapTiles, tile)
	end
end

-- constantly update random tiles
local updatesPerFrame = 30

-- how far away should count as max default 3500mhz
local maxDistance = 30

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = {levelOneMaterials}

local ATTENUATION_SCALE = 0.01
local SHADOW_FALLOFF_DISTANCE = 10
local TRANSMIT_POWER_DBM = -30
local MINIMUM_RSRP_DBM = -120
local MAXIMUM_RSRP_DBM = -50

local materialPriority = {
	Metal = 3,
	Concrete = 2,
	Wood = 1,
}

local function getPreferredMaterial(origin, target)
	local direction = target - origin
	local length = direction.Magnitude

	local cframe = CFrame.lookAt(origin + direction / 2, target)

	local parts = workspace:GetPartBoundsInBox(
		cframe,
		Vector3.new(0.2, 0.2, length),
		overlapParams
	)

	local bestPart = nil
	local bestPriority = 0

	for _, part in ipairs(parts) do
		local priority = materialPriority[part.Name] or 0

		if priority > bestPriority then
			bestPriority = priority
			bestPart = part
		end
	end

	return bestPart
end

local function calculateRSRPDbm(tilePosition, antenna)
	local distance = (tilePosition - antenna.Position).Magnitude
	distance = math.max(distance, 1)

	local distanceRatio = math.clamp(distance / maxDistance, 0, 1)

	local rsrpDbm = MAXIMUM_RSRP_DBM
		+ distanceRatio * (MINIMUM_RSRP_DBM - MAXIMUM_RSRP_DBM)
	
	-- already at the minimum, so attenuation can't change the heatmap
	if rsrpDbm <= MINIMUM_RSRP_DBM then
		return rsrpDbm
	end


	local rayOrigin = tilePosition + Vector3.new(0, 1, 0)
	local rayDirection = antenna.Position - rayOrigin

	local raycastResult = getPreferredMaterial(rayOrigin, antenna.Position)

	if raycastResult then
		local attenuation = raycastResult:GetAttribute("Attenuation") or 0
		
		local distanceFromMaterial = (rayOrigin - raycastResult.Position).Magnitude
		
		local shadowStrength = math.exp(
			-distanceFromMaterial / SHADOW_FALLOFF_DISTANCE
		)

		rsrpDbm -= attenuation * shadowStrength
	end

	return rsrpDbm
end

local function rsrpToValue(rsrpDbm)
	return math.clamp(
		(rsrpDbm - MINIMUM_RSRP_DBM)
			/ (MAXIMUM_RSRP_DBM - MINIMUM_RSRP_DBM),
		0,
		1
	)
end

local function updateRSRP()
	local randomIndex = rng:NextInteger(1, #heatmapTiles)
	local randomTile = heatmapTiles[randomIndex]

	local strongestRSRP = -math.huge

	for _, antenna in ipairs(signalSources) do
		local rsrpDbm = calculateRSRPDbm(
			randomTile.Position,
			antenna
		)

		if rsrpDbm > strongestRSRP then
			strongestRSRP = rsrpDbm
		end
	end

	local heatValue = rsrpToValue(strongestRSRP)
	randomTile.Color = valueToColour(heatValue)
end

local function dBmToMilliwatts(dBm)
	return 10 ^ (dBm / 10)
end

local function milliwattsToDb(milliwatts)
	return 10 * math.log10(milliwatts)
end

local NOISE_FLOOR_DBM = -104

local MINIMUM_SINR_DB = -10
local MAXIMUM_SINR_DB = 30

local function sinrToValue(sinrDb)
	return math.clamp(
		(sinrDb - MINIMUM_SINR_DB)
			/ (MAXIMUM_SINR_DB - MINIMUM_SINR_DB),
		0,
		1
	)
end


local function updateSINR()
	local randomIndex = rng:NextInteger(1, #heatmapTiles)
	local randomTile = heatmapTiles[randomIndex]

	if #signalSources == 0 then
		return
	end

	local strongestSignalPower = 0
	local totalReceivedPower = 0

	for _, antenna in ipairs(signalSources) do
		local rsrpDbm = calculateRSRPDbm(
			randomTile.Position,
			antenna
		)

		local receivedPower = dBmToMilliwatts(rsrpDbm)

		totalReceivedPower += receivedPower

		if receivedPower > strongestSignalPower then
			strongestSignalPower = receivedPower
		end
	end

	-- everything except the strongest signal is interference
	local interferencePower = totalReceivedPower - strongestSignalPower

	local noisePower = dBmToMilliwatts(NOISE_FLOOR_DBM)

	local sinrLinear = strongestSignalPower
		/ (interferencePower + noisePower)

	local sinrDb = milliwattsToDb(sinrLinear)

	randomTile.Color = valueToColour(
		sinrToValue(sinrDb)
	)
end

local showingSINR = false

RunService.Heartbeat:Connect(function()
	for i = 1, updatesPerFrame do
		if showingSINR  then
			updateSINR()
		else
			updateRSRP()
		end
	end
end)

frequencyChangedEvent.OnServerEvent:Connect(function(player, frequencyBand, newMaxDistance)
	maxDistance = newMaxDistance
	print("Max distance changed to:", maxDistance)
end)

toggleHeatmapEvent.OnServerEvent:Connect(function(player, update)
	showingSINR = (update == "SINR")
	print("Heatmap toggled to:", update)
end)