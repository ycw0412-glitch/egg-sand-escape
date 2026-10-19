-- 체크포인트·스테이지 진행·게이트 우회 방지·황금 둥지 클리어.
-- 게이트 벽은 클라이언트가 레벨에 맞춰 열고, 서버는 다음 체크포인트에서 레벨을 다시 확인한다.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerDataService = require(script.Parent.PlayerDataService)
local RunTimerService = require(script.Parent.RunTimerService)
local FunnelService = require(script.Parent.FunnelService)

local StageService = {}

local checkpoints = {}
local touchDebounce = {}

local function playerFromHit(hit)
	local model = hit:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

local function debounced(player, seconds)
	local now = os.clock()
	if touchDebounce[player] and now - touchDebounce[player] < seconds then
		return true
	end
	touchDebounce[player] = now
	return false
end

local function publish(player, data)
	player:SetAttribute("Stage", data.Stage)
	player.RespawnLocation = checkpoints[data.Stage]
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Stage.Value = data.Stage
	end
end

local function moveTo(player, stage)
	local character = player.Character
	local checkpoint = checkpoints[stage]
	if character and checkpoint then
		character:PivotTo(checkpoint.CFrame + Vector3.new(0, 4, 0))
	end
end

local function onCheckpoint(stage, hit)
	local player = playerFromHit(hit)
	local data = player and PlayerDataService.get(player)
	if not data or stage <= data.Stage or debounced(player, 1) then
		return
	end

	local info = Config.Stages[stage]
	if data.Level < info.requiredLevel then
		-- 게이트를 거치지 않고 넘어온 경우
		moveTo(player, data.Stage)
		Remotes.Notify:FireClient(player, string.format("레벨 %d부터 갈 수 있어요", info.requiredLevel))
		return
	end

	data.Stage = stage
	publish(player, data)
	Remotes.Notify:FireClient(player, string.format("스테이지 %d · %s", stage, info.name))
	FunnelService.step(player, stage, "Stage" .. stage)
end

local function onGoldenNest(hit)
	local player = playerFromHit(hit)
	local data = player and PlayerDataService.get(player)
	if data and data.Stage == #Config.Stages then
		RunTimerService.finish(player)
	end
end

function StageService.Init()
	for _, checkpoint in ipairs(CollectionService:GetTagged("Checkpoint")) do
		checkpoints[checkpoint:GetAttribute("Stage")] = checkpoint
	end
end

function StageService.setupPlayer(player)
	local data = PlayerDataService.get(player)
	data.Stage = math.clamp(data.Stage, 1, #Config.Stages)
	publish(player, data)
end

function StageService.Start()
	for stage, checkpoint in pairs(checkpoints) do
		checkpoint.Touched:Connect(function(hit)
			onCheckpoint(stage, hit)
		end)
	end
	for _, nest in ipairs(CollectionService:GetTagged("GoldenNest")) do
		nest.Touched:Connect(onGoldenNest)
	end
	Players.PlayerRemoving:Connect(function(player)
		touchDebounce[player] = nil
	end)
end

-- 관리자 이동. 레벨 확인 없이 스테이지를 바꾼다.
function StageService.teleport(player, stage)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	data.Stage = math.clamp(stage, 1, #Config.Stages)
	publish(player, data)
	moveTo(player, data.Stage)
end

return StageService
