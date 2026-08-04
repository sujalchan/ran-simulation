local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local toggleHeatmapEvent = ReplicatedStorage:WaitForChild("ToggleHeatmapEvent")

local playerGui = player:WaitForChild("PlayerGui")
local dashboardGui = playerGui:WaitForChild("DashboardGui")
local room1Frame = dashboardGui:WaitForChild("Room1Frame")
local heatmapButton:TextButton = room1Frame:WaitForChild("HeatmapButton")

heatmapButton.Text = "Heatmap: RSRP\n(click to switch)"
local showingSINR = false

heatmapButton.MouseEnter:Connect(function()
	heatmapButton.BackgroundTransparency = 0.1
end)

heatmapButton.MouseLeave:Connect(function()
	heatmapButton.BackgroundTransparency = 0.3
end)

heatmapButton.MouseButton1Click:Connect(function()
	showingSINR = not showingSINR

	if showingSINR then
		heatmapButton.Text = "Heatmap: SINR\n(click to switch)"
		toggleHeatmapEvent:FireServer("SINR")
	else
		heatmapButton.Text = "Heatmap: RSRP\n(click to switch)"
		toggleHeatmapEvent:FireServer("RSRP")
	end
end)
