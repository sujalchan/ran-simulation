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
    Player Shrink Handler

    Server-side material-lab character controller. It saves original scale and
    walk-speed values, applies the room-one size change, and restores values
    when the player's InRoomOne state changes.
]]

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

-- caches the character scale values and walk speed before the room change
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

-- applies the configured scale multiplier to the current character and walk speed
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

-- restores cached character values and clears that player’s saved state
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

-- chooses the shrink or restore path from the player’s InRoomOne attribute
local function updatePlayerSize(player)
	local isInRoom = player:GetAttribute("InRoomOne") == true

	if isInRoom then
		shrinkPlayer(player)
	else
		resetPlayer(player)
	end
end

-- resets prior character cache and applies the current room state to a new character
local function setupCharacter(player, character)
	-- remove values belonging to the previous character
	originalScales[player] = nil
	originalWalkSpeeds[player] = nil

	if player:GetAttribute("InRoomOne") then
		shrinkPlayer(player)
	end
end

-- connects room-state and character lifecycle events for one player
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