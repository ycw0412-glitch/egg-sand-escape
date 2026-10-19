-- 빈 Baseplate에서도 바로 플레이할 수 있게 5스테이지 테스트 맵을 코드로 만든다.
-- 장식 맵을 Studio에서 따로 만들면 같은 태그·이름(SandTile, Checkpoint, Gate, NestZone…)만 맞추면 된다.
--
-- 진행 방향은 +Z. 각 스테이지 = 체크포인트 → 모래밭 → 장애물 → 다음 스테이지 게이트.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapBuilder = {}

local BASE_Y = 40
local FIELD_COLS = 12
local FIELD_ROWS = 14

local SAND = {
	Color3.fromRGB(237, 201, 140),
	Color3.fromRGB(226, 187, 125),
	Color3.fromRGB(245, 214, 160),
	Color3.fromRGB(214, 176, 112),
}
local SANDSTONE = Color3.fromRGB(196, 160, 104)
local PATH = Color3.fromRGB(205, 170, 115)
local STAGE_COLORS = {
	Color3.fromRGB(120, 200, 230),
	Color3.fromRGB(240, 170, 90),
	Color3.fromRGB(120, 170, 110),
	Color3.fromRGB(190, 120, 90),
	Color3.fromRGB(255, 200, 60),
}

local folders = {}

local function make(className, props, parent, tag)
	local instance = Instance.new(className)
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.TopSurface = Enum.SurfaceType.Smooth
		instance.BottomSurface = Enum.SurfaceType.Smooth
		instance.Material = Enum.Material.SmoothPlastic
	end
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	if tag then
		CollectionService:AddTag(instance, tag)
	end
	return instance
end

-- 윗면이 topY에 오도록 놓는 블록
local function block(size, x, topY, zCenter, color, parent, name)
	return make("Part", {
		Name = name or "Block",
		Size = size,
		Position = Vector3.new(x, topY - size.Y / 2, zCenter),
		Color = color or PATH,
		Material = Enum.Material.Sandstone,
	}, parent or folders.Path)
end

-- (z0, y0)에서 (z1, y1)까지 오르내리는 경사로
local function ramp(z0, y0, z1, y1, width)
	local dz, dy = z1 - z0, y1 - y0
	local length = math.sqrt(dz * dz + dy * dy)
	local angle = math.atan2(dy, dz)
	return make("Part", {
		Name = "Ramp",
		Size = Vector3.new(width, 1, length),
		CFrame = CFrame.new(0, (y0 + y1) / 2, (z0 + z1) / 2) * CFrame.Angles(-angle, 0, 0) * CFrame.new(0, -0.5, 0),
		Color = PATH,
		Material = Enum.Material.Sandstone,
	}, folders.Path)
end

local function sign(adornee, text, offsetY, color)
	local gui = make("BillboardGui", {
		Name = "Sign",
		Size = UDim2.fromOffset(240, 50),
		StudsOffset = Vector3.new(0, offsetY or 6, 0),
		AlwaysOnTop = false,
		MaxDistance = 120,
		Adornee = adornee,
	}, adornee)
	make("TextLabel", {
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = color or Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.3,
	}, gui)
	return gui
end

local function buildCheckpoint(stage, z, y)
	block(Vector3.new(24, 2, 14), 0, y, z + 7, SANDSTONE)
	local spawn = make("SpawnLocation", {
		Name = "Checkpoint" .. stage,
		Size = Vector3.new(8, 1, 8),
		Position = Vector3.new(0, y + 0.5, z + 7),
		Color = STAGE_COLORS[stage],
		Material = Enum.Material.SmoothPlastic,
		Neutral = true,
		Duration = 0,
	}, folders.Checkpoints, "Checkpoint")
	spawn:SetAttribute("Stage", stage)
	sign(spawn, string.format("STAGE %d · %s", stage, Config.Stages[stage].name), 7, STAGE_COLORS[stage])
	return z + 14
end

local function buildField(stage, z, y)
	local random = Random.new(stage * 7919)
	local size = Config.TileSize
	local width = FIELD_COLS * size
	local length = FIELD_ROWS * size
	for row = 0, FIELD_ROWS - 1 do
		for col = 0, FIELD_COLS - 1 do
			make("Part", {
				Name = "SandTile",
				Size = Vector3.new(size, 1, size),
				Position = Vector3.new(col * size - width / 2 + size / 2, y - 0.5, z + row * size + size / 2),
				Color = SAND[random:NextInteger(1, #SAND)],
				Material = Enum.Material.Sand,
			}, folders.SandTiles, "SandTile")
		end
	end
	-- 옆으로 떨어지지 않게 낮은 벽
	for _, side in ipairs({ -1, 1 }) do
		block(
			Vector3.new(1, 4, length),
			side * (width / 2 + 0.5),
			y + 3,
			z + length / 2,
			SANDSTONE,
			folders.Decor,
			"FieldWall"
		)
	end
	if stage == 1 then
		-- 해변 조개(걸리적거리는 장식)
		for _ = 1, 6 do
			make("Part", {
				Name = "Shell",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2, 2, 2),
				Position = Vector3.new(random:NextInteger(-20, 20), y + 0.6, z + random:NextInteger(6, length - 6)),
				Color = Color3.fromRGB(250, 180, 190),
			}, folders.Decor)
		end
	end
	return z + length
end

local function buildGate(nextStage, z, y)
	block(Vector3.new(14, 2, 8), 0, y, z + 4, SANDSTONE)
	local required = Config.Stages[nextStage].requiredLevel
	local gate = make("Part", {
		Name = "Gate" .. nextStage,
		Size = Vector3.new(30, 16, 1), -- 발판보다 넓게 막아 옆으로 돌아가기 어렵게
		Position = Vector3.new(0, y + 8, z + 4),
		Color = Color3.fromRGB(255, 150, 60),
		Material = Enum.Material.ForceField,
		Transparency = 0.3,
	}, folders.Gates, "Gate")
	gate:SetAttribute("RequiredLevel", required)
	sign(gate, string.format("레벨 %d 필요", required), 9, Color3.fromRGB(255, 220, 120))
	return z + 8
end

-- 1 해변 모래밭: 작은 틈 두 개
local function obstacleBeach(z, y)
	block(Vector3.new(12, 2, 10), 0, y, z + 5)
	block(Vector3.new(12, 2, 10), 0, y, z + 21)
	block(Vector3.new(12, 2, 12), 0, y, z + 39)
	return z + 45, y
end

-- 2 사구 언덕: 오르막 → 모래공 두 개가 쓸고 다니는 꼭대기 → 내리막 → 모래공 하나
local function obstacleDunes(z, y)
	local top = y + 8
	block(Vector3.new(14, 2, 6), 0, y, z + 3)
	ramp(z + 6, y, z + 26, top, 14)
	block(Vector3.new(14, 2, 18), 0, top, z + 35)
	ramp(z + 44, top, z + 64, y, 14)
	block(Vector3.new(14, 2, 14), 0, y, z + 71)

	for _, spot in ipairs({ { top, z + 31, 2.2 }, { top, z + 39, 2.8 }, { y, z + 71, 2.4 } }) do
		local ball = make("Part", {
			Name = "SandBall",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(5, 5, 5),
			Position = Vector3.new(0, spot[1] + 2.5, spot[2]),
			Color = Color3.fromRGB(170, 130, 80),
			Material = Enum.Material.Sand,
			CanCollide = false,
		}, folders.Hazards, "SweepHazard")
		ball:SetAttribute("SweepDistance", 5)
		ball:SetAttribute("SweepPeriod", spot[3])
	end
	return z + 78, y
end

-- 3 유사 늪: 가라앉는 발판 → 9스터드씩 높아지는 턱(더블점프 필요)
local function obstacleSwamp(z, y)
	for i = 0, 3 do
		make("Part", {
			Name = "SinkingTile",
			Size = Vector3.new(6, 1, 6),
			Position = Vector3.new(0, y - 0.5, z + 4 + i * 9),
			Color = Color3.fromRGB(150, 120, 75),
			Material = Enum.Material.Sand,
		}, folders.Hazards, "SinkingTile")
	end
	local ledgeZ = z + 4 + 3 * 9 + 12
	local ledgeY = y
	for i = 1, 3 do
		ledgeY += 9
		block(Vector3.new(8, 2, 8), 0, ledgeY, ledgeZ + (i - 1) * 12)
	end
	local endZ = ledgeZ + 2 * 12 + 4
	block(Vector3.new(14, 2, 10), 0, ledgeY, endZ + 5)
	local hint = block(Vector3.new(1, 1, 1), 0, y + 2, z + 4, SANDSTONE, folders.Decor, "Hint")
	hint.Transparency = 1
	hint.CanCollide = false
	sign(hint, "더블점프로 턱을 오르세요", 4)
	return endZ + 10, ledgeY
end

-- 4 모래폭풍: 좁은 길 + 옆바람(앞 절반은 오른쪽, 뒤 절반은 왼쪽으로 민다)
local function obstacleStorm(z, y)
	block(Vector3.new(6, 2, 64), 0, y, z + 32)
	for i, direction in ipairs({ 1, -1 }) do
		local zone = make("Part", {
			Name = "WindZone",
			Size = Vector3.new(24, 16, 32),
			Position = Vector3.new(0, y + 6, z + (i - 0.5) * 32),
			Transparency = 1,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}, folders.Hazards, "WindZone")
		zone:SetAttribute("Direction", Vector3.new(direction, 0, 0))
		zone:SetAttribute("Strength", 9)
	end
	return z + 64, y
end

-- 5 피라미드 정상: 계단 여섯 단 → 황금 둥지
local function obstaclePyramid(z, y)
	local stepY = y
	for i = 0, 5 do
		stepY += 3
		local width = 36 - i * 4
		block(Vector3.new(width, stepY - y + 2, 6), 0, stepY, z + 3 + i * 6, SANDSTONE)
	end
	local topZ = z + 36 + 8
	block(Vector3.new(16, 2, 16), 0, stepY, topZ, Color3.fromRGB(230, 190, 90))
	local nest = make("Part", {
		Name = "GoldenNest",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.5, 12, 12),
		CFrame = CFrame.new(0, stepY + 0.75, topZ) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 200, 40),
		Material = Enum.Material.Foil,
	}, folders.Decor, "GoldenNest")
	make("PointLight", { Brightness = 2, Range = 24, Color = Color3.fromRGB(255, 210, 120) }, nest)
	sign(nest, "황금 둥지 · 골인!", 8, Color3.fromRGB(255, 220, 90))
	return topZ + 8, stepY
end

local OBSTACLES = { obstacleBeach, obstacleDunes, obstacleSwamp, obstacleStorm, obstaclePyramid }

-- 스폰 왼쪽의 둥지. 안에 있으면 NestService가 XP를 준다.
local function buildNest(y)
	local nest = make("Model", { Name = "Nest" }, folders.Map)
	block(Vector3.new(16, 1, 6), -20, y, 7, PATH, nest, "Bridge")
	local center = Vector3.new(-38, y, 7)
	block(Vector3.new(20, 2, 20), center.X, y, center.Z, SANDSTONE, nest, "NestGround")
	make("Part", {
		Name = "NestBase",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 14, 14),
		CFrame = CFrame.new(center.X, y + 0.5, center.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(150, 105, 60),
		Material = Enum.Material.WoodPlanks,
		CanCollide = false,
	}, nest)
	for i = 1, 14 do
		local angle = (i / 14) * math.pi * 2
		local position = center + Vector3.new(math.cos(angle) * 7, 1, math.sin(angle) * 7)
		make("Part", {
			Name = "Twig",
			Size = Vector3.new(1.2, 1.4, 4),
			CFrame = CFrame.lookAt(position, center + Vector3.new(0, 1, 0))
				* CFrame.Angles(0, math.rad(90), math.rad(15)),
			Color = Color3.fromRGB(120, 85, 50),
			Material = Enum.Material.Wood,
			CanCollide = false,
		}, nest)
	end
	local zone = make("Part", {
		Name = "NestZone",
		Size = Vector3.new(14, 8, 14),
		Position = center + Vector3.new(0, 4, 0),
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
	}, nest)
	sign(zone, string.format("둥지 · 쉬면 %d초마다 +%d", Config.NestTickSeconds, Config.NestXpPerTick), 5)
end

local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 130, 110)
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		make("Atmosphere", {
			Density = 0.3,
			Color = Color3.fromRGB(240, 215, 170),
			Decay = Color3.fromRGB(200, 160, 110),
			Haze = 1.5,
		}, Lighting)
	end
end

function MapBuilder.Build()
	local old = workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end

	local map = Instance.new("Model")
	map.Name = "Map"
	folders.Map = map
	for _, name in ipairs({ "SandTiles", "Checkpoints", "Gates", "Hazards", "Path", "Decor" }) do
		folders[name] = make("Folder", { Name = name }, map)
	end

	-- 맵 아래 전체를 덮는 유사 바다. 떨어지면 가라앉아 마지막 체크포인트로.
	make("Part", {
		Name = "QuicksandSea",
		Size = Vector3.new(900, 2, 1600),
		Position = Vector3.new(0, BASE_Y - 16, 600),
		Color = Color3.fromRGB(150, 112, 62),
		Material = Enum.Material.Sand,
	}, folders.Hazards, "Quicksand")

	local z, y = 0, BASE_Y
	for stage = 1, #Config.Stages do
		z = buildCheckpoint(stage, z, y)
		z = buildField(stage, z, y)
		z, y = OBSTACLES[stage](z, y)
		if stage < #Config.Stages then
			z = buildGate(stage + 1, z, y)
		end
	end
	buildNest(BASE_Y)
	setupLighting()

	map.Parent = workspace
	return map
end

return MapBuilder
