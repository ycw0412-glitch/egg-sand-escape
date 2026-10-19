-- 둥지 안에 머물면 NestTickSeconds마다 XP. 방치 성장 구간.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local LevelService = require(script.Parent.LevelService)
local FunnelService = require(script.Parent.FunnelService)

local NestService = {}

local CHECK_INTERVAL = 0.5

local multiplier = 1
local restTimers = {} -- 다음 지급까지 쌓인 시간
local stayTimers = {} -- 이번에 둥지에 머문 전체 시간(분석용)

local function isInside(zone, position)
	local localPos = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z
end

function NestService.setMultiplier(value)
	multiplier = math.clamp(value, 1, 100)
end

function NestService.getMultiplier()
	return multiplier
end

function NestService.Start()
	local zone = workspace:WaitForChild("Map"):WaitForChild("Nest"):WaitForChild("NestZone")

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CHECK_INTERVAL then
			return
		end
		local step = elapsed
		elapsed = 0

		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local inside = root ~= nil and isInside(zone, root.Position)

			if inside then
				restTimers[player] = (restTimers[player] or 0) + step
				stayTimers[player] = (stayTimers[player] or 0) + step
				if restTimers[player] >= Config.NestTickSeconds then
					restTimers[player] -= Config.NestTickSeconds
					local amount = Config.NestXpPerTick * multiplier
					LevelService.addXp(player, amount)
					Remotes.Popup:FireClient(player, root, amount)
				end
			else
				if (stayTimers[player] or 0) >= Config.NestTickSeconds then
					FunnelService.custom(player, "NestStaySeconds", math.floor(stayTimers[player]))
				end
				restTimers[player] = 0
				stayTimers[player] = 0
			end

			if player:GetAttribute("InNest") ~= inside then
				player:SetAttribute("InNest", inside)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		restTimers[player] = nil
		stayTimers[player] = nil
	end)
end

return NestService
