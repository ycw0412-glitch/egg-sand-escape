-- 첫 스폰부터 황금 둥지까지 걸린 시간(접속한 시간만). 개인 최고 기록을 남긴다.
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerDataService = require(script.Parent.PlayerDataService)
local FunnelService = require(script.Parent.FunnelService)

local RunTimerService = {}

local function formatTime(seconds)
	seconds = math.floor(seconds)
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

local function publish(player, data)
	player:SetAttribute("RunSeconds", math.floor(data.RunSeconds))
	player:SetAttribute("BestSeconds", data.BestSeconds)
	player:SetAttribute("Finished", data.Finished)
	player:SetAttribute("AdminTouched", data.AdminTouched)
end

function RunTimerService.setupPlayer(player)
	publish(player, PlayerDataService.get(player))
end

function RunTimerService.Start()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 1 then
			return
		end
		local step = elapsed
		elapsed = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerDataService.get(player)
			if data and not data.Finished then
				data.RunSeconds += step
				player:SetAttribute("RunSeconds", math.floor(data.RunSeconds))
			end
		end
	end)
end

function RunTimerService.finish(player)
	local data = PlayerDataService.get(player)
	if not data or data.Finished then
		return
	end
	data.Finished = true

	local text = "황금 둥지 도착! 클리어 " .. formatTime(data.RunSeconds)
	if data.AdminTouched then
		text ..= " (관리자 기록 · 랭킹 제외)"
	elseif data.BestSeconds == 0 or data.RunSeconds < data.BestSeconds then
		data.BestSeconds = math.floor(data.RunSeconds)
		text ..= " · 최고 기록!"
	end
	publish(player, data)
	Remotes.Notify:FireClient(player, text)
	FunnelService.step(player, #Config.Stages + 1, "Clear")

	if Config.ClearBadgeId ~= 0 and not data.AdminTouched then
		task.spawn(function()
			local ok, err = pcall(function()
				BadgeService:AwardBadge(player.UserId, Config.ClearBadgeId)
			end)
			if not ok then
				warn("[Badge] 지급 실패:", err)
			end
		end)
	end
end

function RunTimerService.reset(player)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	data.RunSeconds = 0
	data.Finished = false
	publish(player, data)
end

function RunTimerService.markAdminTouched(player)
	local data = PlayerDataService.get(player)
	if data and not data.AdminTouched then
		data.AdminTouched = true
		publish(player, data)
	end
end

function RunTimerService.clearAdminTouched(player)
	local data = PlayerDataService.get(player)
	if data then
		data.AdminTouched = false
		publish(player, data)
	end
end

return RunTimerService
