local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local toggleHeatmapEvent = ReplicatedStorage:WaitForChild("ToggleHeatmapEvent")

local playerGui = player:WaitForChild("PlayerGui")
local dashboardGui = playerGui:WaitForChild("DashboardGui")
local room1Frame = dashboardGui:WaitForChild("Room1Frame")
local heatmapButton:TextButton = room1Frame:WaitForChild("HeatmapButton")

heatmapButton.Text = "Heatmap:  RSRP"
local showingSINR = false

heatmapButton.MouseButton1Click:Connect(function()
	showingSINR = not showingSINR

	if showingSINR then
		heatmapButton.Text = "Heatmap: SINR"
		toggleHeatmapEvent:FireServer("SINR")
	else
		heatmapButton.Text = "Heatmap: RSRP"
		toggleHeatmapEvent:FireServer("RSRP")
	end
end)
