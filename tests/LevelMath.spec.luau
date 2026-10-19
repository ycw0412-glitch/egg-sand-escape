-- lune run tests/LevelMath.spec.luau
-- 레벨 곡선이 Config의 설계값과 어긋나지 않는지 확인한다.
local process = require("@lune/process")

local Config = require("../src/shared/Config")
local LevelMath = require("../src/shared/LevelMath")

local passed, failed = 0, 0

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print("PASS  " .. name)
	else
		failed += 1
		print("FAIL  " .. name .. "\n      " .. tostring(err))
	end
end

local function equal(actual, expected, label)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", label or "value", tostring(expected), tostring(actual)), 2)
	end
end

test("다음 레벨까지 XP: 1→2는 194, 24→25는 401", function()
	equal(LevelMath.xpToNext(1, Config), 194, "Lv1")
	equal(LevelMath.xpToNext(24, Config), 401, "Lv24")
end)

test("레벨 25까지 누적 XP는 7140", function()
	equal(LevelMath.totalXpToReach(25, Config), 7140)
end)

test("XP가 넘치면 여러 레벨이 한 번에 오르고 남은 XP는 이월된다", function()
	local level, xp, gained = LevelMath.addXp(1, 0, 194 + 203 + 10, Config)
	equal(level, 3, "level")
	equal(xp, 10, "xp")
	equal(gained, 2, "gained")
end)

test("모자란 XP로는 레벨이 오르지 않는다", function()
	local level, xp, gained = LevelMath.addXp(1, 100, 93, Config)
	equal(level, 1, "level")
	equal(xp, 193, "xp")
	equal(gained, 0, "gained")
end)

test("최대 레벨에서 멈춘다", function()
	local level, xp = LevelMath.addXp(Config.MaxLevel - 1, 0, 1e9, Config)
	equal(level, Config.MaxLevel, "level")
	equal(xp, 0, "xp")
end)

test("이동 속도: Lv1 17, Lv25 41, 상한 60", function()
	equal(LevelMath.walkSpeed(1, Config), 17, "Lv1")
	equal(LevelMath.walkSpeed(25, Config), 41, "Lv25")
	equal(LevelMath.walkSpeed(99, Config), Config.MaxWalkSpeed, "Lv99")
end)

test("더블점프 경계: Lv9 불가, Lv10 가능", function()
	equal(LevelMath.canDoubleJump(Config.DoubleJumpLevel - 1, Config), false, "Lv9")
	equal(LevelMath.canDoubleJump(Config.DoubleJumpLevel, Config), true, "Lv10")
end)

test("유사 늪(3스테이지) 입장 레벨과 더블점프 레벨이 같다", function()
	equal(Config.Stages[3].requiredLevel, Config.DoubleJumpLevel)
end)

test("스테이지 요구 레벨은 계속 오른다", function()
	for i = 2, #Config.Stages do
		assert(Config.Stages[i].requiredLevel > Config.Stages[i - 1].requiredLevel, "stage " .. i)
	end
end)

test("알 껍질: Lv25는 금빛(마지막 단계)", function()
	equal(LevelMath.shellIndex(25, Config), #Config.EggShells)
	equal(LevelMath.shellIndex(1, Config), 1)
end)

test("레벨 범위 보정", function()
	equal(LevelMath.clampLevel(0, Config), 1, "low")
	equal(LevelMath.clampLevel(500, Config), Config.MaxLevel, "high")
	equal(LevelMath.clampLevel(7.9, Config), 7, "floor")
end)

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
	process.exit(1)
end
