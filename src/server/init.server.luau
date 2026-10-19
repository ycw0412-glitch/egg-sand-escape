-- 서버 진입점. 서비스 준비 → 맵 생성 → 알 캐릭터 설치 → 플레이어 수명 주기 연결.
local Players = game:GetService("Players")

local PlayerDataService = require(script.PlayerDataService)
local MapBuilder = require(script.MapBuilder)
local EggCharacter = require(script.EggCharacter)
local LevelService = require(script.LevelService)
local SandTileService = require(script.SandTileService)
local NestService = require(script.NestService)
local StageService = require(script.StageService)
local HazardService = require(script.HazardService)
local RunTimerService = require(script.RunTimerService)
local AdminService = require(script.AdminService)
local FunnelService = require(script.FunnelService)

-- 캐릭터 모델이 준비되기 전에 스폰되지 않도록 직접 LoadCharacter를 부른다.
Players.CharacterAutoLoads = false

PlayerDataService.Init()
MapBuilder.Build()
EggCharacter.Install()
StageService.Init()

SandTileService.Start()
NestService.Start()
StageService.Start()
HazardService.Start()
RunTimerService.Start()
AdminService.Start()

local function spawnCharacter(player)
	if player.Parent ~= Players then
		return
	end
	player:LoadCharacter()
end

local function onCharacterAdded(player, character)
	-- 관리자 임시 속도는 재스폰하면 풀린다.
	player:SetAttribute("SpeedOverride", nil)
	LevelService.applyCharacter(player)

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		task.wait(Players.RespawnTime)
		spawnCharacter(player)
	end)
end

local function onPlayerAdded(player)
	PlayerDataService.load(player)
	if player.Parent ~= Players then
		return
	end

	LevelService.setupPlayer(player)
	StageService.setupPlayer(player)
	RunTimerService.setupPlayer(player)
	AdminService.setupPlayer(player)
	FunnelService.step(player, 1, "Spawn")

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	spawnCharacter(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.release(player)
end)
