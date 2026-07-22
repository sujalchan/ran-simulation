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