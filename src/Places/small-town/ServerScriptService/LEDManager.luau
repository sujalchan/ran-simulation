-- Consolidated LED Manager
-- Replaces 68 individual LED scripts with a single script

local Lighting = game:GetService("Lighting")

local ledBoxes = {}

-- Find all SelectionBoxes marked as LEDs
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("SelectionBox") and obj:GetAttribute("IsLED") then
		table.insert(ledBoxes, obj)
	end
end

-- Also find any SelectionBoxes whose parent is named "LED"
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("SelectionBox") and obj.Parent and string.find(obj.Parent.Name:lower(), "led") and not obj:GetAttribute("IsLED") then
		obj:SetAttribute("IsLED", true)
		table.insert(ledBoxes, obj)
	end
end

local function updateLEDs()
	local timeOfDay = Lighting.TimeOfDay
	local isNight = timeOfDay >= "18:00:00" or timeOfDay < "06:00:00"
	for _, box in ipairs(ledBoxes) do
		if box and box.Parent then
			box.Visible = isNight
		end
	end
end

-- Update on lighting changes
Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(updateLEDs)
Lighting.Changed:Connect(updateLEDs)

-- Initial update
updateLEDs()