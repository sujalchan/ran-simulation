local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Antenna type to max distance mapping
local antennaTypeMaxDistance = {
	["Antenna1"] = 20, -- Rooftop
	["Antenna2"] = 40, -- Monopole
	["Antenna3"] = 60, -- Panel
	["Antenna4"] = 90, -- Lattice
}

-- Pre-placed tower type mappings
local towerTypeMaxDistance = {
	["Rooftop"]  = 20,
	["Monopole"] = 40,
	["Panel"]    = 60,
	["Lattice"]  = 90,
}

local typeAliases = {
	["AAU Rooftop"] = "Rooftop",
	["Small Cell"]  = "Monopole",
	["Macro"]       = "Lattice",
	["Macro Tower"] = "Lattice",
}

local frequencyData = {
	["700 MHz"]  = { divisor = 1.2 },
	["1800 MHz"] = { divisor = 0.9 },
	["2100 MHz"] = { divisor = 0.7 },
	["3500 MHz"] = { divisor = 0.5 },
}

local DEFAULT_FREQUENCY = "2100 MHz"

local function getAntennaType(modelName)
	return string.match(modelName, "^(Antenna%d+)")
end

local function getSignalOriginPos(model)
	local origin = model:FindFirstChild("SignalOrigin", true)
	if origin and origin:IsA("BasePart") then
		return origin.Position
	end
	return model:GetPivot().Position
end

local function getOuterRadius(antennaName, freqDivisor)
	local antennaType = getAntennaType(antennaName)
	local maxDist = antennaTypeMaxDistance[antennaType] or 20
	return maxDist * 10 * freqDivisor
end

-- Get outer radius for pre-placed towers
local function getTowerOuterRadius(model, freqDivisor)
	local rawType = model:GetAttribute("TowerType")
	if not rawType then
		local origin = model:FindFirstChild("SignalOrigin", true)
		if origin then
			rawType = origin:GetAttribute("TowerType")
		end
	end
	local towerType = typeAliases[rawType] or rawType or "Rooftop"
	local maxDist = towerTypeMaxDistance[towerType] or 20
	return maxDist * 10 * freqDivisor
end

-- Get display name for pre-placed tower
local function getTowerDisplayName(model)
	return model:GetAttribute("TowerName") or model.Name
end

print("[AntennaSignalManager] Loaded.")

local timer = 0
RunService.Heartbeat:Connect(function(deltaTime)
	timer = timer + deltaTime
	if timer < 0.2 then return end
	timer = 0

	local placedFolder = Workspace:FindFirstChild("PlacedAntennas")
	local cellTowersFolder = Workspace:FindFirstChild("CellTowers")

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		local playerPos = hrp.Position
		local freqBand = player:GetAttribute("FrequencyBand") or DEFAULT_FREQUENCY
		local freqInfo = frequencyData[freqBand] or frequencyData[DEFAULT_FREQUENCY]
		local divisor = freqInfo.divisor

		-- Collect all antennas
		local allAntennas = {}

		-- Add pre-placed cell towers
		if cellTowersFolder then
			for _, tower in cellTowersFolder:GetChildren() do
				if tower:IsA("Model") then
					local originPos = getSignalOriginPos(tower)
					local dist = (playerPos - originPos).Magnitude
					local outerRadius = getTowerOuterRadius(tower, divisor)
					table.insert(allAntennas, {
						name = getTowerDisplayName(tower),
						pos = originPos,
						dist = dist,
						outerRadius = outerRadius,
						isPlaced = false,
						model = tower,
					})
				end
			end
		end

		-- Add player-placed antennas
		if placedFolder then
			for _, antenna in placedFolder:GetChildren() do
				if antenna:IsA("Model") then
					local originPos = getSignalOriginPos(antenna)
					local dist = (playerPos - originPos).Magnitude
					local outerRadius = getOuterRadius(antenna.Name, divisor)
					table.insert(allAntennas, {
						name = antenna.Name,
						pos = originPos,
						dist = dist,
						outerRadius = outerRadius,
						isPlaced = true,
						model = antenna,
					})
				end
			end
		end

		if #allAntennas > 0 then
			-- Find the closest antenna within range
			local closestInRange = nil
			local closestInRangeDist = math.huge

			-- Find the closest overall
			local closestOverall = nil
			local closestOverallDist = math.huge

			for _, ant in ipairs(allAntennas) do
				-- Track closest overall
				if ant.dist < closestOverallDist then
					closestOverallDist = ant.dist
					closestOverall = ant
				end
				-- Track closest within range
				if ant.dist <= ant.outerRadius and ant.dist < closestInRangeDist then
					closestInRangeDist = ant.dist
					closestInRange = ant
				end
			end

			-- Use the closest in-range antenna if available, otherwise use closest overall
			local closest = closestInRange or closestOverall
			local withinAnyRange = closestInRange ~= nil

			-- Calculate signal strength based on the selected antenna
			local scaledDistance = closest.dist / 10
			local baseSignal = -50 - (scaledDistance / divisor)

			-- Factor in NPC load for placed antennas
			local npcLoad = 0
			if closest.isPlaced then
				npcLoad = closest.model:GetAttribute("NPCConnections") or 0
			end
			local loadPenalty = npcLoad * 2
			local finalSignal = baseSignal - loadPenalty

			-- Add slight noise 
			local noise = (math.random() * 2 - 1) * 0.5
			finalSignal = math.max(-120, math.min(-50, finalSignal + noise))

			-- Set player attributes for the dashboard
			player:SetAttribute("PlacedAntennaName", closest.name)
			player:SetAttribute("PlacedAntennaSignal", math.floor(finalSignal))
			player:SetAttribute("PlacedAntennaNPCLoad", npcLoad)
			player:SetAttribute("PlacedAntennaInRange", withinAnyRange)
		else
			player:SetAttribute("PlacedAntennaName", nil)
			player:SetAttribute("PlacedAntennaSignal", nil)
			player:SetAttribute("PlacedAntennaNPCLoad", nil)
			player:SetAttribute("PlacedAntennaInRange", nil)
		end
	end
end)