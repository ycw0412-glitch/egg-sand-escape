-- 위험 요소: 유사 바다(가라앉다 사망), 좌우로 쓸고 다니는 모래공, 밟으면 가라앉는 타일.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HazardService = {}

local SINK_SECONDS = 1

local function humanoidFromHit(hit)
	local model = hit:FindFirstAncestorOfClass("Model")
	if model and Players:GetPlayerFromCharacter(model) then
		return model:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

local function sink(humanoid)
	if humanoid.Health <= 0 or humanoid:GetAttribute("Sinking") then
		return
	end
	humanoid:SetAttribute("Sinking", true)
	humanoid.WalkSpeed = 2
	humanoid.JumpHeight = 0
	task.delay(SINK_SECONDS, function()
		if humanoid.Parent then
			humanoid.Health = 0
		end
	end)
end

local function setupQuicksand(part)
	part.Touched:Connect(function(hit)
		local humanoid = humanoidFromHit(hit)
		if humanoid then
			sink(humanoid)
		end
	end)
end

-- 고정(Anchored) 파트를 트윈으로 움직이면 Touched가 불안정해서 거리로 판정한다.
local sweepers = {}

local function setupSweeper(ball)
	local distance = ball:GetAttribute("SweepDistance") or 8
	local period = ball:GetAttribute("SweepPeriod") or 2.5
	local start = ball.CFrame * CFrame.new(-distance, 0, 0)
	ball.CFrame = start
	local tween = TweenService:Create(
		ball,
		TweenInfo.new(period, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = start * CFrame.new(distance * 2, 0, 0) }
	)
	tween:Play()
	table.insert(sweepers, ball)
end

local function setupSinkingTile(tile)
	local home = tile.CFrame
	local busy = false
	tile.Touched:Connect(function(hit)
		if busy or not humanoidFromHit(hit) then
			return
		end
		busy = true
		local down = TweenService:Create(tile, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			CFrame = home * CFrame.new(0, -6, 0),
		})
		down:Play()
		down.Completed:Wait()
		task.wait(2)
		local up = TweenService:Create(tile, TweenInfo.new(0.5), { CFrame = home })
		up:Play()
		up.Completed:Wait()
		busy = false
	end)
end

function HazardService.Start()
	for _, part in ipairs(CollectionService:GetTagged("Quicksand")) do
		setupQuicksand(part)
	end
	for _, ball in ipairs(CollectionService:GetTagged("SweepHazard")) do
		setupSweeper(ball)
	end
	for _, tile in ipairs(CollectionService:GetTagged("SinkingTile")) do
		setupSinkingTile(tile)
	end

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				for _, ball in ipairs(sweepers) do
					if (ball.Position - root.Position).Magnitude < ball.Size.X / 2 + 1.4 then
						humanoid.Health = 0
						break
					end
				end
			end
		end
	end)
end

return HazardService
