-- services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- room zones
local roomOneZone = workspace:WaitForChild("RoomOneZone")
local roomTwoZone = workspace:WaitForChild("RoomTwoZone")

-- detection interval in seconds
local CHECK_INTERVAL = 0.1

-- disable collision and anchor zones
roomOneZone.CanCollide = false
roomOneZone.Anchored = true

-- tracks player room presence state
local playerStates = {}

-- antenna definitions
local ANTENNA_DETECTION_RADIUS = 25
local antennas = {
	{
		name = "Omnidirectional",
		part = workspace:FindFirstChild("OmniPart"),
		beamWidth = 360,
		tiltAngle = 0,
		azimuth = 0,
		elevation = 0,
	},
	{
		name = "Directional",
		part = workspace:FindFirstChild("DirectionalPart"),
		beamWidth = 32,
		tiltAngle = 5,
		azimuth = 0,
		elevation = 0,
	},
	{
		name = "NarrowBeam",
		part = workspace:FindFirstChild("MainPart"),
		beamWidth = 10,
		tiltAngle = 8,
		azimuth = 45,
		elevation = 10,
	},
}
		
-- checks if a point is inside a box volume
local function isPointInsideBox(point, boxPart)
	-- convert point to local space relative to box
	local localPoint = boxPart.CFrame:PointToObjectSpace(point)
	local halfSize = boxPart.Size / 2

	-- check if point is within box bounds on all axes
	return math.abs(localPoint.X) <= halfSize.X
		and math.abs(localPoint.Y) <= halfSize.Y
		and math.abs(localPoint.Z) <= halfSize.Z
end

-- find the closest antenna to a player
local function getClosestAntenna(playerPosition)
	local closestAntenna = nil
	local closestDistance = ANTENNA_DETECTION_RADIUS

	for _, antenna in ipairs(antennas) do
		if antenna.part and antenna.part.Parent then
			local dist = (playerPosition - antenna.part.Position).Magnitude
			if dist < closestDistance then
				closestDistance = dist
				closestAntenna = antenna
			end
		end
	end

	return closestAntenna
end

-- initializes player state and attributes on join
local function setupPlayer(player)
	playerStates[player] = {
		inRoomOne = false,
		inRoomTwo = false
	}
	player:SetAttribute("InRoomOne", false)
	player:SetAttribute("InRoomTwo", false)

	-- set default antenna attributes
	player:SetAttribute("AntennaType", "Omnidirectional")
	player:SetAttribute("BeamWidth", 360)
	player:SetAttribute("TiltAngle", 0)
	player:SetAttribute("Azimuth", 0)
	player:SetAttribute("Elevation", 0)
	
	-- reset state when character is removed
	player.CharacterRemoving:Connect(function()
		playerStates[player] = {
			inRoomOne = false,
			inRoomTwo = false
		}
		player:SetAttribute("InRoomOne", false)
		player:SetAttribute("InRoomTwo", false)
	end)
end

-- setup new players when they join
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
			
			-- antenna detection (room 2)
			if inRoomTwo then
				local closestAntenna = getClosestAntenna(rootPart.Position)
				if closestAntenna then
					player:SetAttribute("AntennaType", closestAntenna.name)
					player:SetAttribute("BeamWidth", closestAntenna.beamWidth)
					player:SetAttribute("TiltAngle", closestAntenna.tiltAngle)
					player:SetAttribute("Azimuth", closestAntenna.azimuth)
					player:SetAttribute("Elevation", closestAntenna.elevation)
				end
			end
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