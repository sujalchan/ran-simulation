local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local roomOneZone = workspace:WaitForChild("RoomOneZone")

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

local npcTemplate = ReplicatedStorage:FindFirstChild("NPCTemplate")
local npcSpawnEvent = ReplicatedStorage:FindFirstChild("NPCSpawnEvent")
local npcFolder = Workspace:FindFirstChild("NPCs")

local MAX_NPCS = 50
local SPAWN_RADIUS = 5
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

local ZONE_EDGE_PADDING = 2
local halfSize = roomOneZone.Size / 2

local minX = -halfSize.X + ZONE_EDGE_PADDING
local maxX = halfSize.X - ZONE_EDGE_PADDING
local minZ = -halfSize.Z + ZONE_EDGE_PADDING
local maxZ = halfSize.Z - ZONE_EDGE_PADDING

local function getRandomPositionInRoomOne(currentY) 
	
	local localX = math.random(minX, maxX)
	local localZ = math.random(minZ, maxZ)
	
	local worldPosition = roomOneZone.CFrame:PointToWorldSpace(
		Vector3.new(localX, 0, localZ)
	)
	
	return Vector3.new(
		worldPosition.X,
		currentY,
		worldPosition.Z
	)
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

local function spawnNPC(spawnCenter)
	if not npcTemplate or not npcFolder then return end
	if #npcFolder:GetChildren() >= MAX_NPCS then return end

	local npc = npcTemplate:Clone()
	npc.Name = "NPC_" .. tostring(math.random(1000, 9999))

	applyRandomColors(npc)
	applyCollisionGroupToNPC(npc)

	npc:PivotTo(CFrame.new(spawnCenter))
	npc.Parent = npcFolder

	-- Simple wandering behavior
	task.spawn(function()
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if not humanoid or not hrp then return end

		while npc.Parent and humanoid.Health > 0 do
			-- Pick a random direction to walk
			local targetPos = getRandomPositionInRoomOne(hrp.Position.Y)
			
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
		npc.Parent = nil
	end
end

local function getNPCCount()
	if not npcFolder then return 0 end
	return #npcFolder:GetChildren()
end

-- Handle client requests
npcSpawnEvent.OnServerEvent:Connect(function(player, action, targetCount)
	if action == "setCount" then
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

print("NPC Spawner system loaded! Max NPCs: " .. MAX_NPCS)