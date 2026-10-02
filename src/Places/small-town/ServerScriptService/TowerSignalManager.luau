--[[
    Tower Signal Manager

    Server-side small-town signal estimator for fixed cell towers. It selects
    the nearest tower, applies the player's frequency and detected attenuation,
    and writes the resulting signal and tower details to player attributes.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local cellTowersFolder = Workspace:FindFirstChild("CellTowers")
if not cellTowersFolder then
	warn("CellTowers folder not found - TowerSignalManager will not work.")
	return
end

local towerTypeMaxDistance = {
	["Rooftop"]  = 20,
	["Monopole"] = 40,
	["Panel"]    = 60,
	["Lattice"]  = 140,
}

local typeAliases = {
	["AAU Rooftop"] = "Rooftop",
	["Small Cell"]  = "Monopole",
	["Macro"]       = "Lattice",
	["Macro Tower"] = "Lattice",
}

-- all towers
local towers = {}
for _, child in ipairs(cellTowersFolder:GetChildren()) do
	if child:IsA("Model") and child:FindFirstChild("SignalOrigin") then
		local origin = child.SignalOrigin
		local rawType = child:GetAttribute("TowerType") or "Rooftop"
		local towerType = typeAliases[rawType] or rawType

		local maxDist = towerTypeMaxDistance[towerType] or 20

		table.insert(towers, {
			Model = child,
			Origin = origin,
			Name = child:GetAttribute("TowerName") or child.Name,
			TowerType = towerType,
			MaxPower = child:GetAttribute("MaxPower") or -50,
			MaxDistance = maxDist
		})
	end
end

if #towers == 0 then
	warn("No towers found with SignalOrigin - TowerSignalManager will not work.")
	return
end

print("TowerSignalManager loaded. Found " .. #towers .. " cell towers.")

-- frequency divisor mapping (same as material lab)
local frequencyData = {
	["700 MHz"] = { divisor = 1.2, maxDistance = 45 },
	["1800 MHz"] = { divisor = 0.9, maxDistance = 40 },
	["2100 MHz"] = { divisor = 0.7, maxDistance = 35 },
	["3500 MHz"] = { divisor = 0.5, maxDistance = 30 }
}

-- default frequency if player doesn't have one
local DEFAULT_FREQUENCY = "2100 MHz"

-- returns the nearest cached tower and the distance to its signal origin
local function getClosestTower(origin)
	local closestTower = nil
	local closestDistance = math.huge

	for _, tower in ipairs(towers) do
		local dist = (origin - tower.Origin.Position).Magnitude
		if dist < closestDistance then
			closestDistance = dist
			closestTower = tower
		end
	end

	return closestTower, closestDistance
end

-- estimates this player's dashboard signal from nearest-tower distance, frequency divisor,
-- tower power offset, and material attenuation. This is the project's simulation model;
-- its result is bounded and receives a small random variation.
local function updatePlayerSignal(player)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local origin = hrp.Position

	-- finds closest tower
	local closestTower, distance = getClosestTower(origin)
	if not closestTower then return end

	-- get player's frequency (from dashboard) or use default
	local freqBand = player:GetAttribute("FrequencyBand") or DEFAULT_FREQUENCY
	local freqInfo = frequencyData[freqBand] or frequencyData[DEFAULT_FREQUENCY]

	-- get material attenuation from the raycasting system
	local attenuation = player:GetAttribute("Attenuation") or 0
	local materialName = player:GetAttribute("Material") or "None"

	-- get signal
	local maxPower = closestTower.MaxPower or -50
	local divisor = freqInfo.divisor
	local maxDist = closestTower.MaxDistance or freqInfo.maxDistance or 35

	-- convert studs to the smaller distance scale used by this signal estimate
	local scaledDistance = distance / 10

	-- start at the simulation baseline and lower it with distance; the frequency divisor sets the slope
	local baseSignal = -50 - (scaledDistance / divisor)
	-- shift relative to the -50 baseline according to the tower's configured maximum power
	baseSignal = baseSignal + (maxPower + 50)

	-- subtract the attenuation value supplied by the material raycast system
	local finalSignal = baseSignal - attenuation

	-- keep the simulation output within its displayed -120 to -50 dBm interval
	finalSignal = math.max(-120, math.min(-50, finalSignal))

	-- add a small random variation and clamp again so it stays in the display interval
	local noise = (math.random() * 2 - 1) * 0.5
	finalSignal = math.max(-120, math.min(-50, finalSignal + noise))

	-- get signal bars (0-5)
	local rsrp = finalSignal
	local barCount = rsrp >= -60 and 5
		or rsrp >= -70 and 4
		or rsrp >= -80 and 3
		or rsrp >= -90 and 2
		or rsrp >= -100 and 1
		or 0

	-- store on player attributes (for dashboard)
	player:SetAttribute("ConnectedTower", closestTower.Name)
	player:SetAttribute("ConnectedTowerType", closestTower.TowerType or "Macro")
	player:SetAttribute("RSRP", math.floor(finalSignal))
	player:SetAttribute("SignalBars", barCount)
	player:SetAttribute("TowerDistance", math.floor(distance))
	player:SetAttribute("FrequencyBand", freqBand)

	-- debug: print every time rsrp is set (only for first player)
	if player == Players:GetPlayers()[1] then
		print("setting rsrp:", math.floor(finalSignal), "for", player.Name, "dist:", math.floor(distance), "scaled:", math.floor(scaledDistance))
	end
end

-- update all players every 0.2 seconds
local timer = 0
RunService.Heartbeat:Connect(function(deltaTime)
	timer = timer + deltaTime
	if timer < 0.2 then return end
	timer = 0

	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerSignal(player)
	end
end)

print("TowerSignalManager loaded successfully")