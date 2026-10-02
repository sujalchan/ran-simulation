--[[
    RAN Network Simulator
    Copyright © 2026 RAN Network Simulator Student Development Team.
    All rights reserved.

    Proprietary software. This file may be viewed for academic,
    educational, and evaluation purposes only. No permission is granted
    to copy, modify, redistribute, reuse, or commercially exploit this
    code without prior written permission from the copyright holders.

    See the repository LICENSE file for full terms.
]]

--[[
    Player Signal Handler

    Server-side material-lab signal estimator. It applies shared frequency data
    and material raycasts to per-player RSRP and SINR values, then publishes
    signal attributes and handles frequency selections from clients.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- load the shared frequency data
local FrequencyData = require(ReplicatedStorage:WaitForChild("FrequencyData"))

-- listen for frequency change events
local frequencyChangedEvent = ReplicatedStorage:WaitForChild("FrequencyChangedEvent")

-- find the signal sources and material walls
local signalSourcesFolder = workspace:WaitForChild("SignalSourcesFolder")
local materialWallsFolder = workspace:WaitForChild("LevelOneMaterials")

-- how often to update the signal values
local CHECK_INTERVAL = 0.1

-- only raycast through the material walls
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {
	materialWallsFolder,
}

-- track the timer and noise for each player
local timer = 0
local playerNoise = {}

-- background radio noise in dBm
local NOISE_FLOOR_DBM = -100

-- convert logarithmic dBm power to milliwatts so source powers can be added and compared
local function dbmToMilliwatts(dbm)
	return 10 ^ (dbm / 10)
end

-- caclulate attenuation between the player and one source
local function getMaterialAttenuation(playerPosition, sourcePosition)
	local direction = sourcePosition - playerPosition
	local result = workspace:Raycast(
		playerPosition,
		direction,
		raycastParams
	)	
	
	if result then
		return result.Instance:GetAttribute("Attenuation") or 0
	end
	
	return 0
end

-- estimate one source's simulation signal from distance and material loss, before per-player noise
local function calculateSourceSignal(player, distance, attenuation)
	local rangeDivisor =
		player:GetAttribute("FrequencyDivisor")
		or FrequencyData.Default.divisor

	-- the divisor changes how quickly distance lowers the estimate; bound the result to the dashboard range
	return math.clamp(
		-50 - distance / rangeDivisor - attenuation,
		-120,
		-50
	)
end

-- get a source position from a part or model
local function getSourcePosition(source)
	if source:IsA("BasePart") then
		return source.Position
	end

	if source:IsA("Model") then
		return source:GetPivot().Position
	end

	return nil
end

-- find the closest signal source to a point
local function findClosestSignalSource(position)
	local closestSource = nil
	local closestPosition = nil
	local closestDistance = math.huge

	for _, source in ipairs(signalSourcesFolder:GetChildren()) do
		local sourcePosition = getSourcePosition(source)

		if sourcePosition then
			local distance = (sourcePosition - position).Magnitude

			if distance < closestDistance then
				closestSource = source
				closestPosition = sourcePosition
				closestDistance = distance
			end
		end
	end

	return closestSource, closestPosition, closestDistance
end

-- estimate the player's RSRP-like display value from distance, material loss, and smoothed noise.
-- towerDistance is reduced by the selected frequency divisor, then material attenuation is subtracted;
-- the small per-player noise offset is blended with its previous value before the result is clamped.
local function calculateRSRP(player, towerDistance, materialAttenuation)
	local rangeDivisor = player:GetAttribute("FrequencyDivisor") or FrequencyData.Default.divisor

	-- apply frequency-specific distance scaling, then bound the estimate before material loss
	local baseSignal = math.clamp(
		-50 - towerDistance / rangeDivisor,
		-120,
		-50
	)

	local finalSignal = math.clamp(
		baseSignal - materialAttenuation,
		-120,
		-50
	)

	-- blend a new small random offset with the previous one so updates vary gradually
	local previousNoise = playerNoise[player] or 0
	local targetNoise = math.random() * 2 - 1
	local smoothedNoise = previousNoise * 0.9 + targetNoise * 0.1

	playerNoise[player] = smoothedNoise

	return math.floor(math.clamp(
		finalSignal + smoothedNoise,
		-120,
		-50
		))
end

-- estimate SINR by comparing the serving source with other sources and the configured noise floor.
-- source levels are converted from dBm to milliwatts, other sources are summed as interference,
-- and serving power is divided by interference plus noise before conversion back to dB.
local function calculateSINR(player, playerPosition, servingSource)
	local servingPower = 0
	local interferencePower = 0

	-- estimate each source at the player's position, separating the selected source from the others
	for _, source in ipairs(signalSourcesFolder:GetChildren()) do
		local sourcePosition = getSourcePosition(source)

		if sourcePosition then
			local distance = (sourcePosition - playerPosition).Magnitude

			local attenuation = getMaterialAttenuation(
				playerPosition,
				sourcePosition
			)

			local signalDbm = calculateSourceSignal(
				player,
				distance,
				attenuation
			)

			local signalPower = dbmToMilliwatts(signalDbm)

			if source == servingSource then
				servingPower = signalPower
			else
				interferencePower += signalPower
			end
		end
	end

	-- compare powers in linear units, then convert their ratio back to decibels for display
	local noisePower = dbmToMilliwatts(NOISE_FLOOR_DBM)

	local sinr = 10 * math.log10(
		servingPower / (interferencePower + noisePower)
	)

	-- cap the result to this simulation's dashboard range and return whole dB steps
	return math.floor(math.clamp(sinr, 0, 20))
end

-- update the signal data for one player
local function updatePlayerSignal(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local playerPosition = humanoidRootPart.Position

	local closestSource, sourcePosition, sourceDistance =
		findClosestSignalSource(playerPosition)

	if not closestSource or not sourcePosition then
		player:SetAttribute("ClosestSignalSource", "None")
		player:SetAttribute("TowerDistance", 0)
		player:SetAttribute("Material", "None")
		player:SetAttribute("Attenuation", 0)
		player:SetAttribute("RSRP", -120)
		player:SetAttribute("SINR", 0)
		return
	end

	local materialName = "None"
	local attenuation = 0

	local direction = sourcePosition - playerPosition
	local result = workspace:Raycast(
		playerPosition,
		direction,
		raycastParams
	)

	if result then
		local hitPart = result.Instance

		materialName = hitPart.Name:gsub("Wall", "")
		attenuation = hitPart:GetAttribute("Attenuation") or 0
	end

	local rsrp = calculateRSRP(
		player,
		sourceDistance,
		attenuation
	)

	local sinr = calculateSINR(
		player,
		playerPosition,
		closestSource
	)
	
	player:SetAttribute("ClosestSignalSource", closestSource.Name)
	player:SetAttribute("TowerDistance", sourceDistance)
	player:SetAttribute("Material", materialName)
	player:SetAttribute("Attenuation", attenuation)
	player:SetAttribute("RSRP", rsrp)
	player:SetAttribute("SINR", sinr)
end

-- set the default attributes for a player
local function setupPlayer(player)
	-- use the default frequency values
	local defaultFreq = FrequencyData.Default

	player:SetAttribute("FrequencyBand", defaultFreq.band)
	player:SetAttribute("FrequencyDivisor", defaultFreq.divisor)
	player:SetAttribute("FrequencyMaxDistance", defaultFreq.maxDistance)

	player:SetAttribute("ClosestSignalSource", "None")
	player:SetAttribute("TowerDistance", 0)
	player:SetAttribute("Material", "None")
	player:SetAttribute("Attenuation", 0)
	player:SetAttribute("RSRP", -120)
	player:SetAttribute("SINR", 0)
end

-- receives a selected band name and updates that player's simulation settings
frequencyChangedEvent.OnServerEvent:Connect(function(player, frequencyBand)
	-- look up the selected frequency settings
	local frequency = FrequencyData.ByBand[frequencyBand]

	if not frequency then
		warn(
			player.Name,
			"sent an invalid frequency:",
			frequencyBand
		)
		return
	end

	player:SetAttribute("FrequencyBand", frequencyBand)
	player:SetAttribute("FrequencyDivisor", frequency.divisor)
	player:SetAttribute("FrequencyMaxDistance", frequency.maxDistance)

	-- update the signal right away
	updatePlayerSignal(player)
end)

-- set up players when they join
Players.PlayerAdded:Connect(setupPlayer)

-- remove noise data when a player leaves
Players.PlayerRemoving:Connect(function(player)
	playerNoise[player] = nil
end)

-- initialize the players already in the game
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

-- update all players on a timer
RunService.Heartbeat:Connect(function(deltaTime)
	timer += deltaTime

	if timer < CHECK_INTERVAL then
		return
	end

	timer -= CHECK_INTERVAL

	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerSignal(player)
	end
end)