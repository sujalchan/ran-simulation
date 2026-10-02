--[[
    Signal Ray Visual

    Client-side material-lab visualization that draws a local beam from the
    player's character to SignalSource while the player is in room one.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local source = workspace:WaitForChild("SignalSource")

-- visualpart description
local visualPart = Instance.new("Part")
visualPart.Name = "RayVisual"
visualPart.Anchored = true
visualPart.CanCollide = false
visualPart.CanTouch = false
visualPart.CanQuery = false
visualPart.CastShadow = false
visualPart.Transparency = 0.8
visualPart.Material = Enum.Material.Neon
visualPart.Color = Color3.fromRGB(255, 0, 0)
visualPart.Parent = workspace

local humanoidRootPart

-- caches the character root part used as the visual ray origin
local function setupCharacter(character)
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

player.CharacterAdded:Connect(setupCharacter)

-- initialize the origin immediately when this LocalScript starts after the character has spawned
if player.Character then
	setupCharacter(player.Character)
end

-- redraw the local source-to-player indicator each frame while room one is active
RunService.RenderStepped:Connect(function()
	if not humanoidRootPart then
		return
	end
	
	if not player:GetAttribute("InRoomOne") then
		visualPart.Transparency = 1
		return
	end
	
	visualPart.Transparency = 0.8
	local origin = humanoidRootPart.Position
	local targetPosition = source.Position
	
	-- use the endpoint separation as the beam length, then place its center halfway along the ray
	local distance = (targetPosition - origin).Magnitude

	visualPart.Size = Vector3.new(
		0.1,
		0.1,
		distance
	)

	-- face the part toward the source and offset it along local -Z so it spans both endpoints
	visualPart.CFrame =
		CFrame.lookAt(origin, targetPosition)
		* CFrame.new(0, 0, -distance / 2)
end)