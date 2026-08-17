local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PhysicsService = game:GetService("PhysicsService")

-- Set up collision groups so NPCs don't collide with each other
PhysicsService:RegisterCollisionGroup("NPC")
PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)
PhysicsService:CollisionGroupSetCollidable("NPC", "Default", true)

local function applyCollisionGroupToNPC(npc)
	for _, part in npc:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "NPC"
		end
	end
end

local npcTemplate = ServerStorage:FindFirstChild("NPCTemplate")
local npcSpawnEvent = ReplicatedStorage:FindFirstChild("NPCSpawnEvent")
local npcFolder = Workspace:FindFirstChild("NPCs")

local MAX_NPCS = 50
local SPAWN_RADIUS = 40
local SPAWN_CENTER = Vector3.new(0, 5, 0)
local MIN_SPAWN_DISTANCE = 5 -- Minimum distance between NPCs when spawning

-- NPC colors for variety
local SHIRT_COLORS = {
	Color3.fromRGB(85, 170, 255),
	Color3.fromRGB(255, 85, 85),
	Color3.fromRGB(85, 255, 85),
	Color3.fromRGB(255, 170, 85),
	Color3.fromRGB(170, 85, 255),
	Color3.fromRGB(255, 255, 85),
	Color3.fromRGB(255, 85, 170),
	Color3.fromRGB(85, 255, 170),
	Color3.fromRGB(170, 255, 85),
	Color3.fromRGB(255, 85, 255),
	Color3.fromRGB(85, 85, 255),
	Color3.fromRGB(255, 170, 255),
	Color3.fromRGB(170, 170, 85),
	Color3.fromRGB(170, 85, 85),
	Color3.fromRGB(85, 170, 85),
	Color3.fromRGB(85, 85, 170),
	Color3.fromRGB(255, 255, 255),
}

local PANTS_COLORS = {
	Color3.fromRGB(45, 45, 135),
	Color3.fromRGB(45, 45, 45),
	Color3.fromRGB(135, 45, 45),
	Color3.fromRGB(45, 135, 45),
	Color3.fromRGB(90, 60, 30),
	Color3.fromRGB(135, 45, 135),
	Color3.fromRGB(135, 135, 45),
	Color3.fromRGB(45, 45, 135),
	Color3.fromRGB(135, 45, 45),
	Color3.fromRGB(45, 135, 45),
	Color3.fromRGB(90, 60, 30),
	Color3.fromRGB(135, 135, 45),
	Color3.fromRGB(45, 45, 135),
	Color3.fromRGB(135, 45, 135),
}

local function getRandomSpawnPosition(centerPos)
	local maxAttempts = 10

	for attempt = 1, maxAttempts do
		local angle = math.random() * math.pi * 2
		local distance = math.random(1, SPAWN_RADIUS)
		local x = centerPos.X + math.cos(angle) * distance
		local z = centerPos.Z + math.sin(angle) * distance

		-- Raycast down to find the ground
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {npcFolder}
		local result = Workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), rayParams)
		if result then
			local candidatePos = result.Position + Vector3.new(0, 3, 0)

			-- Check minimum distance from existing NPCs
			local tooClose = false
			if npcFolder then
				for _, existingNPC in npcFolder:GetChildren() do
					local existingHRP = existingNPC:FindFirstChild("HumanoidRootPart")
					if existingHRP and existingHRP:IsA("BasePart") then
						if (candidatePos - existingHRP.Position).Magnitude < MIN_SPAWN_DISTANCE then
							tooClose = true
							break
						end
					end
				end
			end

			if not tooClose then
				return candidatePos
			end
		end
	end

	-- Fallback: return a position even if too close (after max attempts)
	local angle = math.random() * math.pi * 2
	local distance = math.random(1, SPAWN_RADIUS)
	local x = centerPos.X + math.cos(angle) * distance
	local z = centerPos.Z + math.sin(angle) * distance
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {npcFolder}
	local result = Workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), rayParams)
	if result then
		return result.Position + Vector3.new(0, 3, 0)
	end
	return
end

local function applyRandomColors(npc)
	local shirtColor = SHIRT_COLORS[math.random(1, #SHIRT_COLORS)]
	local pantsColor = PANTS_COLORS[math.random(1, #PANTS_COLORS)]

	local torso = npc:FindFirstChild("Torso")
	if torso then torso.Color = shirtColor end

	local leftArm = npc:FindFirstChild("Left Arm")
	if leftArm then leftArm.Color = shirtColor end

	local rightArm = npc:FindFirstChild("Right Arm")
	if rightArm then rightArm.Color = shirtColor end

	local leftLeg = npc:FindFirstChild("Left Leg")
	if leftLeg then leftLeg.Color = pantsColor end

	local rightLeg = npc:FindFirstChild("Right Leg")
	if rightLeg then rightLeg.Color = pantsColor end
end

-- Track NPC connections per tower name
local towerConnections = {}

-- Find the nearest placed antenna to a position
local function findNearestTower(position)
	local nearestTowerName = nil
	local nearestDist = math.huge

	local function checkFolder(folder)
		if not folder then return end
		for _, model in folder:GetChildren() do
			if model:IsA("Model") then
				local origin = model:FindFirstChild("SignalOrigin", true)
				if origin and origin:IsA("BasePart") then
					local dist = (position - origin.Position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearestTowerName = model.Name
					end
				end
			end
		end
	end

	checkFolder(Workspace:FindFirstChild("CellTowers"))
	checkFolder(Workspace:FindFirstChild("PlacedAntennas"))

	return nearestTowerName
end

-- Update NPCConnections attribute on all towers and antennas
local function updateTowerConnectionAttributes()
	local function updateFolder(folder)
		if not folder then return end
		for _, model in folder:GetChildren() do
			if model:IsA("Model") then
				local count = towerConnections[model.Name] or 0
				model:SetAttribute("NPCConnections", count)
			end
		end
	end
	updateFolder(Workspace:FindFirstChild("CellTowers"))
	updateFolder(Workspace:FindFirstChild("PlacedAntennas"))
end

-- Re-evaluate all NPC connections 
local function reevaluateNPCConnections()
	if not npcFolder then return end
	for _, npc in npcFolder:GetChildren() do
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if hrp then
			local oldTower = npc:GetAttribute("ConnectedTower")
			local newTower = findNearestTower(hrp.Position)
			if newTower and newTower ~= oldTower then
				if oldTower and towerConnections[oldTower] then
					towerConnections[oldTower] = towerConnections[oldTower] - 1
					if towerConnections[oldTower] <= 0 then
						towerConnections[oldTower] = nil
					end
				end
				npc:SetAttribute("ConnectedTower", newTower)
				towerConnections[newTower] = (towerConnections[newTower] or 0) + 1
			end
		end
	end
	updateTowerConnectionAttributes()
end

local function spawnNPC(spawnCenter)
	if not npcTemplate or not npcFolder then return end
	if #npcFolder:GetChildren() >= MAX_NPCS then return end

	local npc = npcTemplate:Clone()
	npc.Name = "NPC_" .. tostring(math.random(1000, 9999))

	applyRandomColors(npc)
	applyCollisionGroupToNPC(npc)

	local spawnPos = getRandomSpawnPosition(spawnCenter or SPAWN_CENTER)
	npc:PivotTo(CFrame.new(spawnPos))
	npc.Parent = npcFolder

	-- Find nearest tower and track connection
	local npcHRP = npc:FindFirstChild("HumanoidRootPart")
	if npcHRP then
		local nearestTower = findNearestTower(npcHRP.Position)
		if nearestTower then
			npc:SetAttribute("ConnectedTower", nearestTower)
			towerConnections[nearestTower] = (towerConnections[nearestTower] or 0) + 1
			updateTowerConnectionAttributes()
		end
	end

	-- Simple wandering behavior
	task.spawn(function()
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if not humanoid or not hrp then return end

		while npc.Parent and humanoid.Health > 0 do
			-- Pick a random direction to walk
			local angle = math.random() * math.pi * 2
			local distance = math.random(10, 40)
			local targetPos = hrp.Position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)

			humanoid:MoveTo(targetPos)

			-- Wait until reached or timed out
			local reachedConnection
			local timeout = false

			reachedConnection = humanoid.MoveToFinished:Connect(function()
				timeout = true
			end)

			task.delay(math.random(4, 8), function()
				timeout = true
			end)

			-- Wait for either reaching destination or timeout
			while not timeout do
				task.wait(0.5)
				if not npc.Parent or humanoid.Health <= 0 then return end
			end

			if reachedConnection then
				reachedConnection:Disconnect()
			end

			-- Pause briefly before next walk
			task.wait(math.random(1, 4))
		end
	end)

	return npc
end

local function removeNPC()
	if not npcFolder then return end
	local npcs = npcFolder:GetChildren()
	if #npcs > 0 then
		local npc = npcs[#npcs]
		-- Update tower connection count
		local towerName = npc:GetAttribute("ConnectedTower")
		if towerName and towerConnections[towerName] then
			towerConnections[towerName] = towerConnections[towerName] - 1
			if towerConnections[towerName] <= 0 then
				towerConnections[towerName] = nil
			end
			updateTowerConnectionAttributes()
		end
		npc.Parent = nil
	end
end

local function getNPCCount()
	if not npcFolder then return 0 end
	return #npcFolder:GetChildren()
end

-- Handle client requests
npcSpawnEvent.OnServerEvent:Connect(function(player, action, targetCount)
	if action == "add" then
		-- Spawn around the requesting player's character
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local spawnCenter = hrp and hrp.Position or SPAWN_CENTER
		spawnNPC(spawnCenter)
	elseif action == "remove" then
		removeNPC()
	elseif action == "setCount" then
		-- Set NPC count to a specific target
		targetCount = math.clamp(tonumber(targetCount) or 0, 0, MAX_NPCS)
		local currentNPCCount = getNPCCount()
		if targetCount > currentNPCCount then
			-- Spawn more NPCs
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local spawnCenter = hrp and hrp.Position or SPAWN_CENTER
			for i = 1, targetCount - currentNPCCount do
				spawnNPC(spawnCenter)
				task.wait(0.3) -- Small delay between spawns to prevent overlap
			end
		elseif targetCount < currentNPCCount then
			-- Remove excess NPCs
			for i = 1, currentNPCCount - targetCount do
				removeNPC()
			end
		end
	elseif action == "getCount" then
		-- Send current count back to requesting player
		npcSpawnEvent:FireClient(player, getNPCCount())
	end

	-- Broadcast updated count to all players
	local count = getNPCCount()
	for _, p in Players:GetPlayers() do
		npcSpawnEvent:FireClient(p, count)
	end
end)

-- When a player joins, send them the current NPC count
Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	npcSpawnEvent:FireClient(player, getNPCCount())
end)

-- Also handle players already in the game
for _, player in Players:GetPlayers() do
	npcSpawnEvent:FireClient(player, getNPCCount())
end

-- Apply collision group to any NPCs that already exist in the folder
if npcFolder then
	for _, existingNPC in npcFolder:GetChildren() do
		applyCollisionGroupToNPC(existingNPC)
	end
end

-- Re-evaluate NPC connections when antennas are placed or removed
local placedFolder = Workspace:FindFirstChild("PlacedAntennas")
if placedFolder then
	placedFolder.ChildAdded:Connect(function()
		reevaluateNPCConnections()
	end)
	placedFolder.ChildRemoved:Connect(function()
		reevaluateNPCConnections()
	end)
end

-- Clear connections on game reset
ReplicatedStorage.ResetGame.OnServerEvent:Connect(function()
	if npcFolder then
		for _, npc in npcFolder:GetChildren() do
			local towerName = npc:GetAttribute("ConnectedTower")
			if towerName and towerConnections[towerName] then
				towerConnections[towerName] = towerConnections[towerName] - 1
				if towerConnections[towerName] <= 0 then
					towerConnections[towerName] = nil
				end
			end
		end
	end
	table.clear(towerConnections)
	updateTowerConnectionAttributes()
end)

print("NPC Spawner system loaded! Max NPCs: " .. MAX_NPCS)