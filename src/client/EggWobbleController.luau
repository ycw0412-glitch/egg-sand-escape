-- 알의 움직임 연출. Config.EggMotion에 따라
--   "roll"   : 이동한 거리만큼 앞으로 굴러가고, 멈추면 똑바로 선다
--   "wobble" : 팔다리 없이 걷는 것처럼 좌우로 기우뚱, 통통
-- 둥지에서 가만히 있으면 부화하려는 듯 가끔 몸을 떤다.
-- 모든 플레이어의 알을 각자 화면에서 움직인다(EggJoint.C0은 복제되지 않는 연출 값).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local EggWobbleController = {}

local HALF_HEIGHT = 1.6 -- 알 세로 반지름 (EggCharacter의 EGG_SIZE.Y / 2)
local HALF_WIDTH = 1.3 -- 알 가로 반지름
local TAU = math.pi * 2

local rollAngles = setmetatable({}, { __mode = "k" }) -- character → 누적 회전각

-- 기울어진 타원의 아래 끝이 늘 땅에 닿도록 중심 높이를 맞춘다.
local function groundOffset(angle)
	local extent = math.sqrt((HALF_HEIGHT * math.cos(angle)) ^ 2 + (HALF_WIDTH * math.sin(angle)) ^ 2)
	return extent - HALF_HEIGHT
end

-- 둥지에서 가만히 있을 때: 3초마다 0.4초 동안 파르르 떤다.
local function idleTilt(owner, now)
	if owner:GetAttribute("InNest") and now % 3 < 0.4 then
		return CFrame.Angles(0, 0, math.sin(now * 40) * 0.09)
	end
	return CFrame.Angles(0, 0, math.sin(now * 1.3) * 0.03)
end

local function roll(character, root, owner, now, dt)
	local localVelocity = root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)
	local forwardSpeed = -localVelocity.Z -- 캐릭터 앞쪽은 -Z
	local angle = rollAngles[character] or 0
	local tilt = CFrame.identity

	if math.abs(forwardSpeed) >= 1 then
		angle = (angle + forwardSpeed * dt / Config.EggRollRadius) % TAU
	else
		-- 멈추면 가장 가까운 「똑바로 선」 자세로 부드럽게 돌아온다
		local upright = math.floor(angle / TAU + 0.5) * TAU
		angle += (upright - angle) * math.min(dt * 6, 1)
		if math.abs(upright - angle) < 0.05 then
			tilt = idleTilt(owner, now)
		end
	end

	rollAngles[character] = angle
	return CFrame.new(0, groundOffset(angle), 0) * CFrame.Angles(-angle, 0, 0) * tilt
end

local function wobble(root, owner, now)
	local velocity = root.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	if speed < 1 then
		return CFrame.new(0, math.sin(now * 2) * 0.04, 0) * idleTilt(owner, now)
	end
	local amount = math.clamp(speed / 30, 0.3, 1)
	local phase = now * (6 + speed * 0.25)
	local tiltAngle = math.sin(phase) * 0.22 * amount
	local bob = math.abs(math.sin(phase)) * 0.35 * amount
	return CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, tiltAngle)
end

local function animate(owner, now, dt)
	local character = owner.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local joint = root and root:FindFirstChild("EggJoint")
	if not joint then
		return
	end
	if Config.EggMotion == "roll" then
		joint.C0 = roll(character, root, owner, now, dt)
	else
		joint.C0 = wobble(root, owner, now)
	end
end

function EggWobbleController.Start()
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		for _, owner in ipairs(Players:GetPlayers()) do
			animate(owner, now, dt)
		end
	end)
end

return EggWobbleController
