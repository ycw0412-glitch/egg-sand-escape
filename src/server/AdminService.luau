-- 관리자 명령. 채팅(/lvl 등)과 관리자 패널이 같은 처리 함수를 쓴다.
-- 모든 요청은 서버에서 권한을 다시 확인한다. 클라이언트의 IsAdmin 표시는 패널을 보여 줄지만 정한다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerDataService = require(script.Parent.PlayerDataService)
local LevelService = require(script.Parent.LevelService)
local StageService = require(script.Parent.StageService)
local RunTimerService = require(script.Parent.RunTimerService)
local NestService = require(script.Parent.NestService)

local AdminService = {}

local admins = {}

local function isAdmin(player)
	if Config.AllowAdminInStudio and RunService:IsStudio() then
		return true
	end
	if table.find(Config.AdminUserIds, player.UserId) then
		return true
	end
	local group = Config.AdminGroup
	if group and group.id and group.id ~= 0 then
		local ok, rank = pcall(player.GetRankInGroup, player, group.id)
		if ok and rank >= (group.minRank or 255) then
			return true
		end
	end
	return false
end

local function number(text)
	if type(text) ~= "string" then
		return nil
	end
	text = string.gsub(text, "^[%+xX]", "")
	local value = tonumber(text)
	return value and math.floor(value)
end

-- 이름 앞부분으로 대상 찾기. 없으면 명령한 사람 자신.
local function findTarget(caller, name)
	if type(name) ~= "string" or name == "" then
		return caller
	end
	local lower = string.lower(name)
	for _, player in ipairs(Players:GetPlayers()) do
		if
			string.sub(string.lower(player.Name), 1, #lower) == lower
			or string.sub(string.lower(player.DisplayName), 1, #lower) == lower
		then
			return player
		end
	end
	return nil
end

local function log(caller, target, text)
	print(string.format("[Admin] %s → %s → %s", caller.Name, target and target.Name or "-", text))
	Remotes.Notify:FireClient(caller, "[관리자] " .. text)
end

local handlers = {}

handlers.lvl = function(caller, args)
	local delta, target = number(args[1]), findTarget(caller, args[2])
	if not delta or not target then
		return
	end
	RunTimerService.markAdminTouched(target)
	LevelService.setLevel(target, PlayerDataService.get(target).Level + delta)
	log(caller, target, string.format("레벨 %+d → Lv %d", delta, PlayerDataService.get(target).Level))
end

handlers.setlvl = function(caller, args)
	local level, target = number(args[1]), findTarget(caller, args[2])
	if not level or not target then
		return
	end
	RunTimerService.markAdminTouched(target)
	LevelService.setLevel(target, level)
	log(caller, target, "레벨 설정 → Lv " .. PlayerDataService.get(target).Level)
end

handlers.xp = function(caller, args)
	local amount, target = number(args[1]), findTarget(caller, args[2])
	if not amount or amount <= 0 or not target then
		return
	end
	RunTimerService.markAdminTouched(target)
	LevelService.addXp(target, math.min(amount, 1000000))
	log(caller, target, "XP +" .. amount)
end

handlers.stage = function(caller, args)
	local stage, target = number(args[1]), findTarget(caller, args[2])
	if not stage or not target then
		return
	end
	RunTimerService.markAdminTouched(target)
	StageService.teleport(target, stage)
	log(caller, target, "스테이지 이동 → " .. PlayerDataService.get(target).Stage)
end

handlers.reset = function(caller, args)
	local target = findTarget(caller, args[1])
	if not target then
		return
	end
	target:SetAttribute("SpeedOverride", nil)
	target:SetAttribute("DoubleJumpOverride", nil)
	LevelService.setLevel(target, 1)
	StageService.teleport(target, 1)
	RunTimerService.reset(target)
	RunTimerService.clearAdminTouched(target) -- 리셋 뒤의 달리기는 정식 기록으로 센다
	log(caller, target, "초기화(레벨 1 · 스테이지 1 · 타이머 0)")
end

handlers.speed = function(caller, args)
	local target = findTarget(caller, args[2])
	if not target then
		return
	end
	if args[1] == "off" then
		target:SetAttribute("SpeedOverride", nil)
	else
		local speed = number(args[1])
		if not speed then
			return
		end
		RunTimerService.markAdminTouched(target)
		target:SetAttribute("SpeedOverride", math.clamp(speed, 0, 200))
	end
	LevelService.applyCharacter(target)
	log(caller, target, "임시 속도 → " .. tostring(target:GetAttribute("WalkSpeed")))
end

handlers.dj = function(caller, args)
	local mode, target = args[1], findTarget(caller, args[2])
	if not target or (mode ~= "on" and mode ~= "off" and mode ~= "auto") then
		return
	end
	if mode ~= "auto" then
		RunTimerService.markAdminTouched(target)
	end
	target:SetAttribute("DoubleJumpOverride", if mode == "auto" then nil else mode)
	LevelService.refresh(target)
	log(caller, target, "더블점프 " .. mode)
end

handlers.nest = function(caller, args)
	local value = number(args[1])
	if not value then
		return
	end
	NestService.setMultiplier(value)
	if NestService.getMultiplier() ~= 1 then
		for _, player in ipairs(Players:GetPlayers()) do
			RunTimerService.markAdminTouched(player)
		end
	end
	log(caller, nil, "둥지 XP 배율 x" .. NestService.getMultiplier())
end

local function run(caller, command, args)
	if not admins[caller] then
		warn(string.format("[Admin] 권한 없는 요청 무시: %s (%s)", caller.Name, tostring(command)))
		return
	end
	if type(command) ~= "string" or type(args) ~= "table" then
		return
	end
	local handler = handlers[command]
	if handler then
		handler(caller, args)
	end
end

local function createChatCommands()
	local folder = Instance.new("Folder")
	folder.Name = "EggAdminCommands"
	folder.Parent = TextChatService
	for name in pairs(handlers) do
		local command = Instance.new("TextChatCommand")
		command.Name = "Admin_" .. name
		command.PrimaryAlias = "/" .. name
		command.Parent = folder
		command.Triggered:Connect(function(textSource, text)
			local caller = Players:GetPlayerByUserId(textSource.UserId)
			if not caller then
				return
			end
			local args = string.split(text, " ")
			table.remove(args, 1)
			run(caller, name, args)
		end)
	end
end

function AdminService.setupPlayer(player)
	local allowed = isAdmin(player)
	admins[player] = allowed or nil
	player:SetAttribute("IsAdmin", allowed)
end

function AdminService.Start()
	createChatCommands()
	Remotes.AdminCommand.OnServerEvent:Connect(run)
	Players.PlayerRemoving:Connect(function(player)
		admins[player] = nil
	end)
end

return AdminService
