local Players = game:GetService("Players")

local SHRINK_MULTIPLIER = 0.2
local RESET_UPWARD_OFFSET = 2.5

local originalScales = {}
local originalWalkSpeeds = {}
local attributeConnections = {}

local scaleNames = {
	"BodyHeightScale",
	"BodyWidthScale",
	"BodyDepthScale",
	"HeadScale",
}

local function saveOriginalValues(player, humanoid)
	originalScales[player] = {}

	for _, scaleName in ipairs(scaleNames) do
		local scaleValue = humanoid:FindFirstChild(scaleName)

		if scaleValue then
			originalScales[player][scaleName] = scaleValue.Value
		end
	end

	originalWalkSpeeds[player] = humanoid.WalkSpeed
end

local function shrinkPlayer(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if not originalScales[player] then
		saveOriginalValues(player, humanoid)
	end

	local savedScales = originalScales[player]
	if not savedScales then
		return
	end

	for _, scaleName in ipairs(scaleNames) do
		local scaleValue = humanoid:FindFirstChild(scaleName)
		local originalValue = savedScales[scaleName]

		if scaleValue and originalValue then
			scaleValue.Value = originalValue * SHRINK_MULTIPLIER
		end
	end

	local originalWalkSpeed = originalWalkSpeeds[player]

	if originalWalkSpeed then
		humanoid.WalkSpeed = originalWalkSpeed * SHRINK_MULTIPLIER
	end
end

local function resetPlayer(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid then
		return
	end

	local savedScales = originalScales[player]

	if savedScales then
		for scaleName, originalValue in pairs(savedScales) do
			local scaleValue = humanoid:FindFirstChild(scaleName)

			if scaleValue then
				scaleValue.Value = originalValue
			end
		end
	end

	local originalWalkSpeed = originalWalkSpeeds[player]

	if originalWalkSpeed then
		humanoid.WalkSpeed = originalWalkSpeed
	end

	if rootPart then
		rootPart.CFrame += Vector3.new(0, RESET_UPWARD_OFFSET, 0)
	end

	originalScales[player] = nil
	originalWalkSpeeds[player] = nil
end

local function updatePlayerSize(player)
	local isInRoom = player:GetAttribute("InRoomOne") == true

	if isInRoom then
		shrinkPlayer(player)
	else
		resetPlayer(player)
	end
end

local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")

	-- remove values belonging to the previous character
	originalScales[player] = nil
	originalWalkSpeeds[player] = nil

	if player:GetAttribute("InRoomOne") then
		shrinkPlayer(player)
	end
end

local function setupPlayer(player)
	attributeConnections[player] =
		player:GetAttributeChangedSignal("InRoomOne"):Connect(function()
			updatePlayerSize(player)
		end)

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)

	if player.Character then
		setupCharacter(player, player.Character)
	end

	updatePlayerSize(player)
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	if attributeConnections[player] then
		attributeConnections[player]:Disconnect()
		attributeConnections[player] = nil
	end

	originalScales[player] = nil
	originalWalkSpeeds[player] = nil
end)