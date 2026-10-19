-- XP·레벨·이동 속도·더블점프 자격을 서버에서만 바꾼다.
-- 클라이언트는 플레이어 Attribute(Level, Xp, XpNeeded, WalkSpeed, CanDoubleJump)만 읽는다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local LevelMath = require(Shared:WaitForChild("LevelMath"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerDataService = require(script.Parent.PlayerDataService)
local EggCharacter = require(script.Parent.EggCharacter)

local LevelService = {}

local function canDoubleJump(player, level)
	local override = player:GetAttribute("DoubleJumpOverride")
	if override == "on" then
		return true
	elseif override == "off" then
		return false
	end
	return LevelMath.canDoubleJump(level, Config)
end

local function publish(player, data)
	player:SetAttribute("Level", data.Level)
	player:SetAttribute("Xp", data.Xp)
	player:SetAttribute("XpNeeded", LevelMath.xpToNext(data.Level, Config))
	player:SetAttribute("CanDoubleJump", canDoubleJump(player, data.Level))

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Level.Value = data.Level
	end
end

function LevelService.setupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Parent = leaderstats
	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Parent = leaderstats
	leaderstats.Parent = player

	publish(player, PlayerDataService.get(player))
end

-- 현재 레벨을 캐릭터(속도·껍질 색)에 반영한다.
function LevelService.applyCharacter(player)
	local data = PlayerDataService.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not humanoid then
		return
	end
	local speed = player:GetAttribute("SpeedOverride") or LevelMath.walkSpeed(data.Level, Config)
	humanoid.WalkSpeed = speed
	player:SetAttribute("WalkSpeed", speed)
	EggCharacter.paint(character, data.Level)
end

function LevelService.refresh(player)
	local data = PlayerDataService.get(player)
	if data then
		publish(player, data)
		LevelService.applyCharacter(player)
	end
end

function LevelService.addXp(player, amount)
	local data = PlayerDataService.get(player)
	if not data or amount <= 0 then
		return
	end
	local level, xp, gained = LevelMath.addXp(data.Level, data.Xp, amount, Config)
	data.Level = level
	data.Xp = xp
	publish(player, data)
	if gained > 0 then
		LevelService.applyCharacter(player)
		Remotes.LevelUp:FireClient(player, level)
	end
end

function LevelService.setLevel(player, level)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	local before = data.Level
	data.Level = LevelMath.clampLevel(level, Config)
	data.Xp = 0
	publish(player, data)
	LevelService.applyCharacter(player)
	if data.Level > before then
		Remotes.LevelUp:FireClient(player, data.Level)
	end
end

return LevelService
