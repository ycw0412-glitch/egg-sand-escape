-- 화면 아래: 레벨·XP 바·속도·더블점프 / 위: 스테이지·타이머 / 가운데: 안내 토스트.
-- 서버가 정한 플레이어 Attribute만 읽는다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local HudController = {}

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(70, 45, 20)
local CREAM = Color3.fromRGB(255, 246, 228)
local SAND = Color3.fromRGB(232, 190, 120)

local function new(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function label(parent, props)
	local base = {
		BackgroundTransparency = 1,
		Font = FONT,
		TextColor3 = INK,
		TextScaled = true,
	}
	for key, value in pairs(props) do
		base[key] = value
	end
	return new("TextLabel", base, parent)
end

local function corner(parent, radius)
	new("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

local function formatTime(seconds)
	seconds = math.floor(seconds or 0)
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

function HudController.Start()
	local gui = new(
		"ScreenGui",
		{ Name = "Hud", ResetOnSpawn = false, IgnoreGuiInset = false },
		player:WaitForChild("PlayerGui")
	)
	local scale = new("UIScale", {}, gui)
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(camera.ViewportSize.X / 1100, 0.65, 1)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	-- 아래 패널
	local panel = new("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(460, 78),
		BackgroundColor3 = CREAM,
		BackgroundTransparency = 0.08,
	}, gui)
	corner(panel, 16)
	new("UIStroke", { Color = SAND, Thickness = 3 }, panel)

	local levelText =
		label(panel, { Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(90, 40), Text = "Lv 1" })
	local bar = new("Frame", {
		Position = UDim2.fromOffset(110, 14),
		Size = UDim2.fromOffset(334, 26),
		BackgroundColor3 = Color3.fromRGB(225, 210, 185),
	}, panel)
	corner(bar, 13)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = SAND }, bar)
	corner(fill, 13)
	local xpText = label(bar, { Size = UDim2.fromScale(1, 1), Text = "0 / 0", ZIndex = 2 })
	local speedText = label(panel, {
		Position = UDim2.fromOffset(110, 46),
		Size = UDim2.fromOffset(150, 24),
		Text = "속도 17",
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local jumpText = label(panel, {
		Position = UDim2.fromOffset(264, 46),
		Size = UDim2.fromOffset(180, 24),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- 위쪽: 스테이지와 타이머
	local top = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(360, 64),
		BackgroundColor3 = CREAM,
		BackgroundTransparency = 0.08,
	}, gui)
	corner(top, 14)
	local stageText = label(top, { Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 4), Text = "" })
	local timerText =
		label(top, { Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 38), Text = "00:00" })

	-- 둥지 상태
	local nestText = label(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.fromOffset(420, 30),
		Text = string.format(
			"둥지에서 쉬는 중 · %d초마다 +%d",
			Config.NestTickSeconds,
			Config.NestXpPerTick
		),
		TextColor3 = CREAM,
		TextStrokeTransparency = 0.2,
		Visible = false,
	})

	-- 안내 토스트
	local toast = label(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 86),
		Size = UDim2.fromOffset(520, 40),
		Text = "",
		TextColor3 = CREAM,
		TextStrokeTransparency = 0.1,
		TextTransparency = 1,
		TextStrokeColor3 = INK,
	})
	local toastToken = 0
	local function showToast(text)
		toastToken += 1
		local token = toastToken
		toast.Text = text
		toast.TextTransparency = 0
		toast.TextStrokeTransparency = 0.1
		task.delay(2.5, function()
			if token == toastToken then
				TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 })
					:Play()
			end
		end)
	end

	local function refresh()
		local level = player:GetAttribute("Level") or 1
		local xp = player:GetAttribute("Xp") or 0
		local need = player:GetAttribute("XpNeeded") or 1
		levelText.Text = "Lv " .. level
		xpText.Text = string.format("%d / %d", xp, need)
		TweenService:Create(fill, TweenInfo.new(0.15), { Size = UDim2.fromScale(math.clamp(xp / need, 0, 1), 1) })
			:Play()
		speedText.Text = "속도 " .. math.floor(player:GetAttribute("WalkSpeed") or Config.BaseWalkSpeed)
		if player:GetAttribute("CanDoubleJump") then
			jumpText.Text = "더블점프 ON"
			jumpText.TextColor3 = Color3.fromRGB(40, 140, 70)
		else
			jumpText.Text = string.format("더블점프 Lv %d", Config.DoubleJumpLevel)
			jumpText.TextColor3 = Color3.fromRGB(150, 130, 110)
		end

		local stage = player:GetAttribute("Stage") or 1
		local info = Config.Stages[stage]
		stageText.Text = string.format("%d/%d · %s", stage, #Config.Stages, info and info.name or "")
		local best = player:GetAttribute("BestSeconds") or 0
		local timer = formatTime(player:GetAttribute("RunSeconds"))
		if player:GetAttribute("Finished") then
			timer ..= " · 클리어"
		end
		if best > 0 then
			timer ..= " · 최고 " .. formatTime(best)
		end
		timerText.Text = timer
		nestText.Visible = player:GetAttribute("InNest") == true
	end

	for _, name in ipairs({
		"Level",
		"Xp",
		"XpNeeded",
		"WalkSpeed",
		"CanDoubleJump",
		"Stage",
		"RunSeconds",
		"BestSeconds",
		"Finished",
		"InNest",
	}) do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()

	Remotes.Notify.OnClientEvent:Connect(showToast)
	Remotes.LevelUp.OnClientEvent:Connect(function(level)
		local text = "레벨 업! Lv " .. level
		if level == Config.DoubleJumpLevel then
			text ..= " · 더블점프를 쓸 수 있어요"
		end
		showToast(text)
		levelText.TextColor3 = Color3.fromRGB(230, 140, 20)
		TweenService:Create(levelText, TweenInfo.new(0.8), { TextColor3 = INK }):Play()
	end)
end

return HudController
