-- 모래폭풍 구간: WindZone 안에서 옆으로 밀고, 시야를 모래빛 안개로 흐린다.
-- 캐릭터 물리는 클라이언트 소유라 클라이언트에서 위치를 민다.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local WindController = {}

local STORM_FOG = { FogStart = 0, FogEnd = 90, FogColor = Color3.fromRGB(215, 180, 125) }

local function isInside(zone, position)
	local localPos = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z
end

function WindController.Start()
	local clearFog = { FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd, FogColor = Lighting.FogColor }
	local inStorm = false

	RunService.Heartbeat:Connect(function(dt)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local now = false
		if root then
			for _, zone in ipairs(CollectionService:GetTagged("WindZone")) do
				if isInside(zone, root.Position) then
					now = true
					local direction = zone:GetAttribute("Direction") or Vector3.zero
					local strength = zone:GetAttribute("Strength") or 0
					root.CFrame += direction * strength * dt
				end
			end
		end
		if now ~= inStorm then
			inStorm = now
			TweenService:Create(Lighting, TweenInfo.new(0.8), if now then STORM_FOG else clearFog):Play()
		end
	end)
end

return WindController
