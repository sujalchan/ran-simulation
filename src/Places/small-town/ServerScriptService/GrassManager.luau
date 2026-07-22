-- Consolidated Grass Animation Manager
-- Replaces 12 individual grass scripts with a single loop

local grassParts = {}

-- Find all grass parts by attribute
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") and obj:GetAttribute("IsGrass") then
		local pos = obj.Position
		local tall = obj.Size.Y / 2
		table.insert(grassParts, {
			part = obj,
			baseX = pos.X,
			baseY = pos.Y - 0.2,
			baseZ = pos.Z,
			tall = tall,
			rand = (math.random(0, 20)) / 10,
		})
	end
end

local T = -99999

-- Run at a lower frequency (every 2 frames instead of every frame)
local frameCount = 0

while task.wait() do
	frameCount = frameCount + 1
	if frameCount % 2 ~= 0 then
		continue
	end

	T = T + 0.12

	for _, data in ipairs(grassParts) do
		local part = data.part
		if part and part.Parent then
			local x = data.baseX + (math.sin(T + (data.baseX / 5)) * math.sin(T / 9)) / 3
			local z = data.baseZ + (math.sin(T + (data.baseZ / 6)) * math.sin(T / 12)) / 4
			part.CFrame = CFrame.new(x, data.baseY, z)
				* CFrame.Angles((z - data.baseZ) / data.tall, 0, (x - data.baseX) / -data.tall)
		end
	end
end