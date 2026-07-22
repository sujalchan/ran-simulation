local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local roomOneZone = workspace:WaitForChild("RoomOneZone")
local roomTwoZone = workspace:WaitForChild("RoomTwoZone")

local CHECK_INTERVAL = 0.1

roomOneZone.CanCollide = false
roomOneZone.Anchored = true

local playerStates = {}

local function isPointInsideBox(point, boxPart)
	local localPoint = boxPart.CFrame:PointToObjectSpace(point)
	local halfSize = boxPart.Size / 2
	
	return math.abs(localPoint.X) <= halfSize.X
		and math.abs(localPoint.Y) <= halfSize.Y
		and math.abs(localPoint.Z) <= halfSize.Z
end

local function setupPlayer(player)
	playerStates[player] = {
		inRoomOne = false,
		inRoomTwo = false
	}
	player:SetAttribute("InRoomOne", false)
	player:SetAttribute("InRoomTwo", false)
	
	player.CharacterRemoving:Connect(function()
		playerStates[player] = {
			inRoomOne = false,
			inRoomTwo = false
		}
		player:SetAttribute("InRoomOne", false)
		player:SetAttribute("InRoomTwo", false)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

local timer = 0

RunService.Heartbeat:Connect(function(deltaTime)
	timer += deltaTime

	if timer < CHECK_INTERVAL then
		return
	end

	timer = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local rootPart = character
			and character:FindFirstChild("HumanoidRootPart")

		local inRoomOne = false
		local inRoomTwo = false

		if rootPart then
			inRoomOne = isPointInsideBox(
				rootPart.Position,
				roomOneZone
			)
			
			inRoomTwo = isPointInsideBox(
				rootPart.Position,
				roomTwoZone
			)
		end

		local state = playerStates[player]

		if state then
			if inRoomOne ~= state.inRoomOne then
				state.inRoomOne = inRoomOne
				player:SetAttribute("InRoomOne", inRoomOne)
			end

			if inRoomTwo ~= state.inRoomTwo then
				state.inRoomTwo = inRoomTwo
				player:SetAttribute("InRoomTwo", inRoomTwo)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerStates[player] = nil
end)