-- 알 캐릭터를 코드로 만들어 StarterPlayer.StarterCharacter로 설치한다.
-- 3D 에셋 없이 구 메시를 세로로 늘려 달걀 모양을 만든다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelMath = require(Shared:WaitForChild("LevelMath"))

local EggCharacter = {}

local ROOT_SIZE = Vector3.new(2, 2, 1)
local EGG_SIZE = Vector3.new(2.6, 3.2, 2.6)
local HIP_HEIGHT = 0.6 -- 루트 바닥이 땅에서 0.6 위 → 알 바닥(루트 중심 -1.6)이 땅에 닿는다

local function decorPart(name, size, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

function EggCharacter.Install()
	local existing = StarterPlayer:FindFirstChild("StarterCharacter")
	if existing then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "StarterCharacter"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = ROOT_SIZE
	root.Transparency = 1
	root.CanCollide = true
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.CFrame = CFrame.new(0, 5, 0)
	root.Parent = model

	local egg = decorPart("Egg", EGG_SIZE, Color3.fromRGB(250, 243, 224))
	egg.CFrame = root.CFrame
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere -- 파트 크기에 맞춰 늘어나 타원체(달걀)가 된다
	mesh.Parent = egg
	egg.Parent = model

	-- 클라이언트가 C0을 움직여 흔들림 연출을 한다(EggWobbleController).
	local joint = Instance.new("Motor6D")
	joint.Name = "EggJoint"
	joint.Part0 = root
	joint.Part1 = egg
	joint.Parent = root

	for _, side in ipairs({ -1, 1 }) do
		local eye = decorPart("Eye", Vector3.new(0.35, 0.35, 0.35), Color3.fromRGB(35, 30, 30))
		eye.Shape = Enum.PartType.Ball
		eye.CFrame = egg.CFrame * CFrame.new(0.45 * side, 0.45, -1.2)
		eye.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = egg
		weld.Part1 = eye
		weld.Parent = eye
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = HIP_HEIGHT
	humanoid.WalkSpeed = Config.BaseWalkSpeed
	humanoid.Parent = model

	model.PrimaryPart = root
	model.Parent = StarterPlayer
end

-- 레벨에 맞춰 껍질 색을 칠한다. 마지막 단계는 금빛.
function EggCharacter.paint(character, level)
	local egg = character and character:FindFirstChild("Egg")
	if not egg then
		return
	end
	local index = LevelMath.shellIndex(level, Config)
	local rgb = Config.EggShells[index].rgb
	egg.Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
	egg.Reflectance = if index == #Config.EggShells then 0.25 else 0
end

return EggCharacter
