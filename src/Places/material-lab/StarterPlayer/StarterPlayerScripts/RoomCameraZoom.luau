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
    Room Camera Zoom

    Client-side material-lab camera controller. It tweens the local player's
    zoom when the server changes the InRoomOne attribute.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local NORMAL_MIN_ZOOM = player.CameraMinZoomDistance
local NORMAL_MAX_ZOOM = player.CameraMaxZoomDistance

local SHRUNK_ZOOM = 2.5
local NORMAL_ZOOM = 12

local TWEEN_INFO = TweenInfo.new(
	0.5,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

local currentTween 

-- tweens both camera zoom limits and optionally restores saved limits after completion
local function tweenCameraZoom(targetZoom, restoreNormalLimits)
	if currentTween then
		currentTween:Cancel()
	end
	
	local tween = TweenService:Create(
		player,
		TWEEN_INFO,
		{
			CameraMaxZoomDistance = targetZoom,
			CameraMinZoomDistance = targetZoom
		}
	)
	
	currentTween = tween
	tween:Play()
	
	tween.Completed:Once(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed then
			return
		end
		
		if currentTween ~= tween then
			return
		end
		
		if restoreNormalLimits and not player:GetAttribute("InRoomOne") then 
			player.CameraMaxZoomDistance = NORMAL_MAX_ZOOM
			player.CameraMinZoomDistance = NORMAL_MIN_ZOOM
		end
	end)
end

-- selects the close or normal camera zoom from the InRoomOne attribute
local function updateCameraZoom()
	local inRoomOne = player:GetAttribute("InRoomOne") == true
	
	if inRoomOne then
		tweenCameraZoom(SHRUNK_ZOOM, false)
	else
		tweenCameraZoom(NORMAL_ZOOM, true)
	end
end

player:GetAttributeChangedSignal("InRoomOne"):Connect(updateCameraZoom)

updateCameraZoom()