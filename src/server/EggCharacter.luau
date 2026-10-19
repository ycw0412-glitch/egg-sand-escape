-- 알 캐릭터를 코드로 만들어 StarterPlayer.StarterCharacter로 설치한다.
-- ReplicatedStorage.EggModel(Blender 공룡알)이 있으면 그 모델을, 없으면 구 메시를 세로로 늘린 알을 쓴다.
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

-- ReplicatedStorage.EggModel(Blender에서 가져온 MeshPart)이 있으면 그것을, 없으면 구 메시 알을 쓴다.
local function buildEgg()
	local template = ReplicatedStorage:FindFirstChild("EggModel")
	local source = template
		and (if template:IsA("MeshPart") then template else template:FindFirstChildWhichIsA("MeshPart", true))
	if source then
		local egg = source:Clone()
		egg.Name = "Egg"
		egg.Size = EGG_SIZE -- 게임 속 알 크기에 맞춘다(메시도 같이 늘어난다)
		egg.Anchored = false
		egg.CanCollide = false
		egg.CanTouch = false
		egg.CanQuery = false
		egg.Massless = true
		for _, child in ipairs(egg:GetChildren()) do
			if child:IsA("JointInstance") or child:IsA("WeldConstraint") then
				child:Destroy()
			end
		end
		return egg
	end

	if template then
		warn("[EggCharacter] EggModel 안에 MeshPart가 없어 기본 구 알을 씁니다.")
	end
	local egg = decorPart("Egg", EGG_SIZE, Color3.fromRGB(250, 243, 224))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere -- 파트 크기에 맞춰 늘어나 타원체(달걀)가 된다
	mesh.Parent = egg
	return egg
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

	local egg = buildEgg()
	egg.CFrame = root.CFrame
	egg.Parent = model

	-- 클라이언트가 C0을 움직여 흔들림 연출을 한다(EggWobbleController).
	local joint = Instance.new("Motor6D")
	joint.Name = "EggJoint"
	joint.Part0 = root
	joint.Part1 = egg
	joint.Parent = root

	-- Blender 공룡알 모델에는 눈이 없다. 기본 구 알일 때만 눈을 붙인다.
	for _, side in ipairs(if egg:IsA("MeshPart") then {} else { -1, 1 }) do
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

-- 레벨에 맞춰 껍질 색을 칠한다. 마지막 단계는 금빛으로 빛난다.
-- 무늬 그림이 있는 MeshPart는 그림이 색을 덮으므로, 마지막 단계의 빛으로 성장을 보여 준다.
function EggCharacter.paint(character, level)
	local egg = character and character:FindFirstChild("Egg")
	if not egg then
		return
	end
	local index = LevelMath.shellIndex(level, Config)
	local isGold = index == #Config.EggShells
	local rgb = Config.EggShells[index].rgb
	egg.Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
	egg.Reflectance = if isGold then 0.25 else 0

	local glow = egg:FindFirstChild("GoldGlow")
	if isGold and not glow then
		glow = Instance.new("PointLight")
		glow.Name = "GoldGlow"
		glow.Color = Color3.fromRGB(255, 205, 80)
		glow.Brightness = 2
		glow.Range = 10
		glow.Parent = egg
	elseif not isGold and glow then
		glow:Destroy()
	end
end

return EggCharacter
