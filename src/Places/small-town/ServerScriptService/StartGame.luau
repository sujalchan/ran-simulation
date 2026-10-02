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
    Start and Reset Game

    Server-side small-town game-session controller. A ProximityPrompt starts a
    session for one player; the ResetGame RemoteEvent removes that player's
    placed antennas and NPCs, restores the player, and notifies their client.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local startButton = workspace:FindFirstChild("StartButton", true)
local prompt = startButton and startButton:FindFirstChild("ProximityPrompt")
local startGame = ReplicatedStorage.StartGame
local resetGame = ReplicatedStorage.ResetGame

-- Track which player is currently in the game
local activePlayer = nil

-- starts the session for the player who activated the world prompt
prompt.Triggered:Connect(function(player)

	print(player.Name .. " started the game.")
	prompt.Enabled = false
	activePlayer = player

	startGame:FireClient(player)

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 130
		end
	end

end)

-- Handle reset/exit request
resetGame.OnServerEvent:Connect(function(player)
	if player ~= activePlayer then
		warn("[StartGame] Reset requested by non-active player:", player.Name)
		return
	end

	print(player.Name .. " reset the game.")

	-- Remove all antennas owned by this player
	local placedFolder = workspace:FindFirstChild("PlacedAntennas")
	if placedFolder then
		for _, antenna in placedFolder:GetChildren() do
			local ownerTag = antenna:FindFirstChild("Owner")
			if ownerTag and ownerTag.Value == player.Name then
				antenna.Parent = nil
			end
		end
	end

	-- Reset NPC count to 0
	local npcFolder = workspace:FindFirstChild("NPCs")
	if npcFolder then
		for _, npc in npcFolder:GetChildren() do
			npc.Parent = nil
		end
	end

	-- Reset player WalkSpeed to default
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
		end

		-- Teleport player back to spawn location
		local spawnLocation = workspace:FindFirstChild("SpawnLocation")
		if spawnLocation then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(spawnLocation.Position + Vector3.new(0, 5, 0))
			end
		end
	end

	-- Re-enable the StartButton ProximityPrompt
	if prompt then
		prompt.Enabled = true
	end

	-- Clear active player
	activePlayer = nil

	-- Notify that reset is complete
	resetGame:FireClient(player)

	-- Reset NPC count to 0 for player
	local npcSpawnEvent = ReplicatedStorage:FindFirstChild("NPCSpawnEvent")
	if npcSpawnEvent then
		npcSpawnEvent:FireClient(player, 0)
	end
end) 