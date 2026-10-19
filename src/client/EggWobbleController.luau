-- 팔다리가 없는 알이 걷는 것처럼 보이게: 속도에 맞춰 좌우로 기우뚱, 통통 튄다.
-- 모든 플레이어의 알을 각자 화면에서 움직인다(EggJoint.C0은 복제되지 않는 연출 값).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EggWobbleController = {}

local function animate(owner, now)
	local character = owner.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local joint = root and root:FindFirstChild("EggJoint")
	if not joint then
		return
	end

	local velocity = root.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

	if speed < 1 then
		-- 가만히 있을 때(둥지 포함)는 숨 쉬듯 천천히
		local breath = math.sin(now * 2) * 0.04
		joint.C0 = CFrame.new(0, breath, 0) * CFrame.Angles(0, 0, math.sin(now * 1.3) * 0.03)
		return
	end

	local amount = math.clamp(speed / 30, 0.3, 1)
	local phase = now * (6 + speed * 0.25)
	local tilt = math.sin(phase) * 0.22 * amount
	local bob = math.abs(math.sin(phase)) * 0.35 * amount
	joint.C0 = CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, tilt)
end

function EggWobbleController.Start()
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for _, owner in ipairs(Players:GetPlayers()) do
			animate(owner, now)
		end
	end)
end

return EggWobbleController
