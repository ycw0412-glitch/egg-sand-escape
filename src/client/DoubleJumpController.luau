-- 공중에서 한 번 더 점프. 자격(CanDoubleJump)은 서버가 레벨로 정한다.
-- PC 스페이스바와 모바일 점프 버튼 모두 JumpRequest로 들어온다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer

local DoubleJumpController = {}

local MIN_DELAY = 0.18 -- 첫 점프 직후 같은 입력이 두 번 들어오는 것을 막는다

local humanoid, root, dust
local used = false
local jumpedAt = 0

local function bind(character)
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
	used = false

	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, -1.6, 0)
	attachment.Parent = root
	dust = Instance.new("ParticleEmitter")
	dust.Color = ColorSequence.new(Color3.fromRGB(235, 205, 150))
	dust.Size = NumberSequence.new(0.6, 0)
	dust.Lifetime = NumberRange.new(0.3, 0.5)
	dust.Speed = NumberRange.new(5, 9)
	dust.SpreadAngle = Vector2.new(180, 10)
	dust.Rate = 0
	dust.Parent = attachment

	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			used = false
		elseif new == Enum.HumanoidStateType.Jumping then
			jumpedAt = os.clock()
		end
	end)
end

function DoubleJumpController.Start()
	if player.Character then
		task.spawn(bind, player.Character)
	end
	player.CharacterAdded:Connect(bind)

	UserInputService.JumpRequest:Connect(function()
		if not humanoid or not root or humanoid.Health <= 0 then
			return
		end
		if not player:GetAttribute("CanDoubleJump") or used then
			return
		end
		local state = humanoid:GetState()
		if state ~= Enum.HumanoidStateType.Freefall and state ~= Enum.HumanoidStateType.Jumping then
			return
		end
		if os.clock() - jumpedAt < MIN_DELAY then
			return
		end

		used = true
		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, Config.DoubleJumpVelocity, velocity.Z)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		if dust then
			dust:Emit(14)
		end
	end)
end

return DoubleJumpController
