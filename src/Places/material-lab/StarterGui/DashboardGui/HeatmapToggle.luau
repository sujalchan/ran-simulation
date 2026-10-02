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
    Heatmap Toggle

    Client-side material-lab dashboard control that switches the displayed
    heatmap type between RSRP and SINR through ToggleHeatmapEvent.
]]

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

-- switches the requested heatmap mode and updates the button label
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
