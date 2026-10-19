-- Roblox AnalyticsService 래퍼. 어느 스테이지에서 떠나는지, 둥지를 쓰는지 Creator Dashboard에서 본다.
-- 관리자가 손댄 기록(AdminTouched)은 보내지 않는다.
local AnalyticsService = game:GetService("AnalyticsService")

local FunnelService = {}

local FUNNEL_NAME = "StageProgress"

local function skip(player)
	return player:GetAttribute("AdminTouched") == true
end

function FunnelService.step(player, step, stepName)
	if skip(player) then
		return
	end
	local ok, err = pcall(function()
		AnalyticsService:LogFunnelStepEvent(player, FUNNEL_NAME, nil, step, stepName)
	end)
	if not ok then
		warn("[Funnel] 기록 실패:", err)
	end
end

function FunnelService.custom(player, eventName, value)
	if skip(player) then
		return
	end
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value)
	end)
	if not ok then
		warn("[Funnel] 기록 실패:", err)
	end
end

return FunnelService
