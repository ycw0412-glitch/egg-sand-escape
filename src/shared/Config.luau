-- 게임의 모든 수치는 이 파일에서만 바꾼다.
-- Roblox 전용 타입(Color3 등)을 쓰지 않아 Lune 테스트에서도 그대로 읽힌다.

local Config = {}

-- 처음 하는 플레이어가 5스테이지를 깨는 목표 시간(분)
Config.TargetClearMinutes = 30

-- 이동 속도: BaseWalkSpeed + SpeedPerLevel * level, 최대 MaxWalkSpeed
Config.BaseWalkSpeed = 16
Config.SpeedPerLevel = 1
Config.MaxWalkSpeed = 60

-- 더블점프
Config.DoubleJumpLevel = 10
Config.DoubleJumpVelocity = 52

-- 레벨 곡선: 다음 레벨까지 XpBase + XpPerLevel * level
-- 시뮬레이션(타일 위 70%, 둥지 제외): Lv5 4.3분 · Lv10 9.4분 · Lv18 17.4분 · Lv25 24.1분
Config.XpBase = 185
Config.XpPerLevel = 9
Config.MaxLevel = 99

-- 모래 타일
Config.TileSize = 4
Config.XpPerTile = 1
Config.TileCooldown = 0.35 -- 같은 타일을 다시 밟아 XP를 받기까지(초, 플레이어별)
Config.MaxXpPerSecond = 12 -- 악용 방지 상한

-- 둥지(방치 성장)
Config.NestXpPerTick = 1
Config.NestTickSeconds = 5

Config.Stages = {
	{ name = "해변 모래밭", requiredLevel = 1, targetMinute = 0 },
	{ name = "사구 언덕", requiredLevel = 5, targetMinute = 4 },
	{ name = "유사 늪", requiredLevel = 10, targetMinute = 10 }, -- 더블점프가 필요한 구간
	{ name = "모래폭풍", requiredLevel = 18, targetMinute = 17 },
	{ name = "피라미드 정상", requiredLevel = 25, targetMinute = 24 },
}

-- 레벨에 따라 바뀌는 알 껍질 색(RGB)
Config.EggShells = {
	{ minLevel = 1, rgb = { 250, 243, 224 } },
	{ minLevel = 5, rgb = { 240, 224, 186 } },
	{ minLevel = 10, rgb = { 218, 192, 144 } },
	{ minLevel = 18, rgb = { 196, 156, 104 } },
	{ minLevel = 25, rgb = { 255, 196, 40 } }, -- 금빛 알
}

-- 관리자
Config.AdminUserIds = {} -- 예: { 123456789 }
Config.AdminGroup = nil -- 예: { id = 1234567, minRank = 254 }
Config.AllowAdminInStudio = true

-- 저장
Config.UseDataStore = true
Config.DataStoreName = "EggSandEscape_v1"
Config.AutosaveSeconds = 120

-- 클리어 배지 (0이면 지급하지 않음)
Config.ClearBadgeId = 0

return Config
