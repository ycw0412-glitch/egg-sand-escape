-- 모래 타일을 밟으면 XP +1. 서버가 캐릭터 발밑을 직접 확인한다(Touched에 의존하지 않음).
-- 규칙: 직전 타일과 다른 타일이어야 하고, 같은 타일은 TileCooldown 뒤에 다시 인정, 초당 상한 MaxXpPerSecond.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local LevelService = require(script.Parent.LevelService)

local SandTileService = {}

local CHECK_INTERVAL = 0.1
local RAY = Vector3.new(0, -5, 0)

local states = {}

local function stateFor(player, now)
	local state = states[player]
	if not state then
		state = {
			lastTile = nil,
			lastTimes = setmetatable({}, { __mode = "k" }),
			windowStart = now,
			windowCount = 0,
		}
		states[player] = state
	end
	return state
end

local function onStep(player, tile, now)
	local state = stateFor(player, now)
	if tile == state.lastTile then
		return
	end
	state.lastTile = tile

	local last = state.lastTimes[tile]
	if last and now - last < Config.TileCooldown then
		return
	end
	if now - state.windowStart >= 1 then
		state.windowStart = now
		state.windowCount = 0
	end
	if state.windowCount >= Config.MaxXpPerSecond then
		return
	end

	state.windowCount += 1
	state.lastTimes[tile] = now
	LevelService.addXp(player, Config.XpPerTile)
	Remotes.Popup:FireClient(player, tile, Config.XpPerTile)
end

function SandTileService.Start()
	local tiles = workspace:WaitForChild("Map"):WaitForChild("SandTiles")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { tiles }

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed = 0

		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				local result = workspace:Raycast(root.Position, RAY, params)
				if result then
					onStep(player, result.Instance, now)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return SandTileService
