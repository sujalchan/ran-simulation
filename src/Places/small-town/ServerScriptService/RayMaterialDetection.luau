local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CHECK_INTERVAL = 0.1
local timer = 0

-- CellTowers folder
local cellTowersFolder = Workspace:FindFirstChild("CellTowers")
if not cellTowersFolder then
	warn("CellTowers folder not found - RayMaterialDetection will not work.")
	return
end

-- TownAttenuationZones folder
local townZonesFolder = Workspace:FindFirstChild("TownAttenuationZones")
if not townZonesFolder then
	warn("TownAttenuationZones folder not found - RayMaterialDetection will not work.")
	return
end

-- filter list from TownAttenuationZones
local filterList = {}
for _, part in ipairs(townZonesFolder:GetChildren()) do
	if part:IsA("BasePart") then
		table.insert(filterList, part)
	end
end

if #filterList == 0 then
	warn("No parts found in TownAttenuationZones")
	return
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {townZonesFolder}

-- get the closest tower for player
local function getClosestTower(origin)
	local closestTower = nil
	local closestDistance = math.huge

	for _, tower in ipairs(cellTowersFolder:GetChildren()) do
		if tower:IsA("Model") then
			local originPart = tower:FindFirstChild("SignalOrigin")
			if originPart then
				local dist = (origin - originPart.Position).Magnitude
				if dist < closestDistance then
					closestDistance = dist
					closestTower = tower
				end
			end
		end
	end

	return closestTower
end

local function updatePlayerMaterial(player)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local origin = humanoidRootPart.Position

	-- closest tower to cast ray toward
	local closestTower = getClosestTower(origin)
	if not closestTower then return end

	local signalOrigin = closestTower:FindFirstChild("SignalOrigin")
	if not signalOrigin then return end

	local direction = (signalOrigin.Position - origin).Unit * 1000

	local result = Workspace:Raycast(origin, direction, raycastParams)

	local materialName = "None"
	local attenuation = 0

	if result then
		local hitPart = result.Instance

		-- zone name and attenuation
		if hitPart.Parent == townZonesFolder then
			materialName = hitPart.Name:gsub(" Zone", "")
			attenuation = hitPart:GetAttribute("Attenuation") or 0
		end
	end

	if player:GetAttribute("Material") ~= materialName then
		player:SetAttribute("Material", materialName)
	end

	if player:GetAttribute("Attenuation") ~= attenuation then
		player:SetAttribute("Attenuation", attenuation)
	end

	-- store which tower the player is connected to (for dashboard)
	local towerName = closestTower:GetAttribute("TowerName") or closestTower.Name
	local towerType = closestTower:GetAttribute("TowerType") or "Unknown"

	if player:GetAttribute("ConnectedTower") ~= towerName then
		player:SetAttribute("ConnectedTower", towerName)
	end

	if player:GetAttribute("ConnectedTowerType") ~= towerType then
		player:SetAttribute("ConnectedTowerType", towerType)
	end
end

RunService.Heartbeat:Connect(function(deltaTime)
	timer += deltaTime

	if timer < CHECK_INTERVAL then
		return
	end

	timer = 0

	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerMaterial(player)
	end
end)

print("RayMaterialDetection loaded! Found " .. #filterList .. " attenuation zones.")