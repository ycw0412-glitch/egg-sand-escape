-- 레벨 계산 순수 함수. Roblox API를 쓰지 않는다(Lune 테스트 대상).
-- 모든 함수는 Config 테이블을 인자로 받는다.

local LevelMath = {}

function LevelMath.xpToNext(level, cfg)
	return math.floor(cfg.XpBase + cfg.XpPerLevel * level + 0.5)
end

-- XP를 더하고 (새 레벨, 남은 XP, 오른 레벨 수)를 돌려준다.
function LevelMath.addXp(level, xp, amount, cfg)
	local gained = 0
	xp += amount
	while level < cfg.MaxLevel do
		local need = LevelMath.xpToNext(level, cfg)
		if xp < need then
			break
		end
		xp -= need
		level += 1
		gained += 1
	end
	if level >= cfg.MaxLevel then
		level = cfg.MaxLevel
		xp = 0
	end
	return level, xp, gained
end

-- 레벨 1에서 해당 레벨에 이르기까지 필요한 누적 XP
function LevelMath.totalXpToReach(level, cfg)
	local total = 0
	for l = 1, level - 1 do
		total += LevelMath.xpToNext(l, cfg)
	end
	return total
end

function LevelMath.walkSpeed(level, cfg)
	return math.min(cfg.BaseWalkSpeed + cfg.SpeedPerLevel * level, cfg.MaxWalkSpeed)
end

function LevelMath.canDoubleJump(level, cfg)
	return level >= cfg.DoubleJumpLevel
end

function LevelMath.shellIndex(level, cfg)
	local index = 1
	for i, shell in ipairs(cfg.EggShells) do
		if level >= shell.minLevel then
			index = i
		end
	end
	return index
end

function LevelMath.clampLevel(level, cfg)
	return math.clamp(math.floor(level), 1, cfg.MaxLevel)
end

return LevelMath
