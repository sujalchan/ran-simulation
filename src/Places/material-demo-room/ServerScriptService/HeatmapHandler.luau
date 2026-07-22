local RunService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local frequencyChangedEvent = replicatedStorage:WaitForChild("FrequencyChangedEvent")
local levelOne = replicatedStorage:WaitForChild("LevelOne") -- objects cloned from replicated storage
local levelOneMaterials = workspace:WaitForChild("LevelOneMaterials") -- materials in level one

local signalSource = workspace:WaitForChild("SignalSource")
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

-- this can be any coordinate in the world
local targetPosition = signalSource.Position

-- how far away should count as max default 3500mhz
local maxDistance = 30


local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {levelOneMaterials}

local ATTENUATION_SCALE = 0.01
local SHADOW_FALLOFF_DISTANCE = 10
RunService.Heartbeat:Connect(function()
	for i = 1, updatesPerFrame do
		local randomIndex = rng:NextInteger(1, #heatmapTiles)
		local randomTile = heatmapTiles[randomIndex]
		-- get distance from tile to target
		local distance = (randomTile.Position - targetPosition).Magnitude
		
		local rayOrigin = randomTile.Position + Vector3.new(0, 1, 0)
		local rayDirection = targetPosition - rayOrigin
		
		local raycastResult = workspace:Raycast(
			rayOrigin,
			rayDirection,
			raycastParams
		)
		
		local distanceValue = distance / maxDistance
		
		if raycastResult then
			local hitPart = raycastResult.Instance
			local attenuation = hitPart:GetAttribute("Attenuation") or 0
			
			local distanceFromMaterial = raycastResult.Distance
			local shadowStrength = math.exp(
				-distanceFromMaterial / SHADOW_FALLOFF_DISTANCE
			)
			distanceValue += ATTENUATION_SCALE * attenuation * shadowStrength
		end
		
		-- convert distance into 0 to 1
		distanceValue = math.clamp(distanceValue, 0, 1)
		
		local heatValue = 1 - distanceValue
		randomTile.Color = valueToColour(heatValue)
	end
end)

frequencyChangedEvent.OnServerEvent:Connect(function(player, newMaxDistance)
	maxDistance = newMaxDistance
	print("Max distance changed to:", maxDistance)
end)