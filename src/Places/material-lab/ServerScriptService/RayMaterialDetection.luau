local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local source = workspace:WaitForChild("SignalSource")
local materialWallsFolder = workspace:WaitForChild("LevelOneMaterials")

local CHECK_INTERVAL = 0.1

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {materialWallsFolder}

local timer = 0 

local function updatePlayerMaterial(player)
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local origin = humanoidRootPart.Position
	local direction = (source.Position - origin).Unit * 1000
	
	local result = workspace:Raycast(origin, direction, raycastParams)
	
	local materialName = "None"
	local attenuation = 0
	
	if result then
		local hitPart = result.Instance
		
		materialName = hitPart.Name:gsub("Wall", "")
		attenuation = hitPart:GetAttribute("Attenuation") or 0
	end
	
	if player:GetAttribute("Material") ~= materialName then
		player:SetAttribute("Material", materialName)
	end
	
	if player:GetAttribute("Attenuation") ~= attenuation then
		player:SetAttribute("Attenuation", attenuation)
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