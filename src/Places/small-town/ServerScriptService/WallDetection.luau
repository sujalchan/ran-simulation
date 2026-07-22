local Players = game:GetService("Players")
local Source = workspace:WaitForChild("Source")
local CellTower = workspace:WaitForChild("Cell Tower")

local function updateRay(player, origin, targetPos)
	
	local partName = player.Name .. "_RayVisual"
	local visualPart = workspace:FindFirstChild(partName)
	
	if not visualPart then
		visualPart = Instance.new("Part")
		visualPart.Name = partName
		visualPart.Anchored = true
		visualPart.CanCollide = false
		visualPart.Transparency = 0.8
		visualPart.Material = Enum.Material.Neon
		visualPart.BrickColor = BrickColor.new("Bright red")
		visualPart.Parent = workspace
	end
	
	local distance = (origin - targetPos).Magnitude
	visualPart.Size = Vector3.new(0.2,0.2, distance)
	visualPart.CFrame = CFrame.lookAt(origin, targetPos) * CFrame.new(0, 0, -distance / 2)
	
	local overlappingParts = workspace:GetPartsInPart(visualPart)

	-- WALL DETECTION HAPPENS HERE
	local hit = false
	for _, part in pairs(overlappingParts) do
		-- filter out the player's own character and the visual part itself
		if not part:IsDescendantOf(player.Character) and part ~= visualPart and part ~= Source and part ~= CellTower then
			local materialName = part.Name:gsub("Wall", "")
			local attenuation = part:GetAttribute("Attenuation") or 0
			player:SetAttribute("Material", materialName)
			player:SetAttribute("Attenuation", attenuation)
			hit = true
		end
	end
	
	if not hit then
		player:SetAttribute("Material", "None")
		player:SetAttribute("Attenuation", 0)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local hrp = character:WaitForChild("HumanoidRootPart")
		local sourcePart = workspace:WaitForChild("Source")

		
		while character:IsDescendantOf(workspace) do
			local startPos = hrp.Position
			local endPos = sourcePart.Position

			updateRay(player, startPos, endPos)
			task.wait() 
		end
	end)
end)

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
	local visualPart = workspace:FindFirstChild(player.Name .. "_RayVisual")
	if visualPart then
		visualPart:Destroy()
	end
end)