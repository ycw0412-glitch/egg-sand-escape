-- 플레이어 기록 불러오기·저장. DataStore를 쓸 수 없으면 메모리 저장으로 진행한다.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PlayerDataService = {}

local profiles = {}
local noSave = {} -- 불러오기에 실패한 플레이어는 기존 기록을 덮지 않도록 저장하지 않는다
local store = nil

local function defaults()
	return {
		Level = 1,
		Xp = 0,
		Stage = 1,
		RunSeconds = 0,
		Finished = false,
		BestSeconds = 0, -- 0이면 기록 없음
		AdminTouched = false, -- 관리자가 손댄 기록은 랭킹·분석에서 뺀다
	}
end

local function key(player)
	return "player_" .. player.UserId
end

local function isAccessDenied(err)
	local text = tostring(err)
	return string.find(text, "403", 1, true) ~= nil or string.find(text, "not allowed", 1, true) ~= nil
end

local function withRetry(label, fn)
	for attempt = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		if isAccessDenied(result) then
			warn("[Data] DataStore 접근이 막혀 메모리 저장으로 바꿉니다:", result)
			store = nil
			return false, result
		end
		warn(string.format("[Data] %s 실패 (%d/3): %s", label, attempt, tostring(result)))
		task.wait(attempt)
	end
	return false, nil
end

function PlayerDataService.Init()
	if not Config.UseDataStore then
		return
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[Data] DataStore를 쓸 수 없어 메모리 저장으로 진행합니다:", result)
	end

	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for player in pairs(profiles) do
				task.spawn(PlayerDataService.save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				PlayerDataService.save(player)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 20 do
			task.wait(0.1)
		end
	end)
end

function PlayerDataService.load(player)
	local data = defaults()
	if store then
		local ok, saved = withRetry("불러오기", function()
			return store:GetAsync(key(player))
		end)
		if ok and type(saved) == "table" then
			for field, value in pairs(saved) do
				if data[field] ~= nil and type(value) == type(data[field]) then
					data[field] = value
				end
			end
		elseif not ok and store then
			noSave[player] = true
		end
	end
	profiles[player] = data
	return data
end

function PlayerDataService.get(player)
	return profiles[player]
end

function PlayerDataService.save(player)
	local data = profiles[player]
	if not data or not store or noSave[player] then
		return
	end
	local snapshot = table.clone(data)
	withRetry("저장", function()
		store:UpdateAsync(key(player), function()
			return snapshot
		end)
	end)
end

function PlayerDataService.release(player)
	PlayerDataService.save(player)
	profiles[player] = nil
	noSave[player] = nil
end

return PlayerDataService
