local UIS = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local SPRINT_SPEED = 50 -- Default is 16
local WALK_SPEED = 16

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		humanoid.WalkSpeed = SPRINT_SPEED
	end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		humanoid.WalkSpeed = WALK_SPEED
	end
end)