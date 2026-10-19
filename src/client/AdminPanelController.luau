-- 관리자에게만 보이는 패널. 버튼은 요청만 보내고, 권한 확인과 처리는 서버(AdminService)가 한다.
-- 채팅 명령(/lvl, /setlvl, /xp, /stage, /reset, /speed, /dj, /nest)은 서버에서 직접 처리한다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local AdminPanelController = {}

local built = false

local BUTTONS = {
	{ "Lv +1", "lvl", { "1" } },
	{ "Lv +5", "lvl", { "5" } },
	{ "Lv -1", "lvl", { "-1" } },
	{ "XP +500", "xp", { "500" } },
	{ "더블점프 ON", "dj", { "on" } },
	{ "더블점프 자동", "dj", { "auto" } },
	{ "속도 60", "speed", { "60" } },
	{ "속도 원래대로", "speed", { "off" } },
	{ "둥지 x10", "nest", { "10" } },
	{ "둥지 x1", "nest", { "1" } },
	{ "리셋", "reset", {} },
}

local function button(parent, text, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 30)
	b.BackgroundColor3 = Color3.fromRGB(255, 240, 215)
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = Color3.fromRGB(70, 45, 20)
	b.Text = text
	Instance.new("UICorner").Parent = b
	b.Parent = parent
	b.Activated:Connect(onClick)
	return b
end

local function build()
	if built then
		return
	end
	built = true

	local gui = Instance.new("ScreenGui")
	gui.Name = "AdminPanel"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local toggle = Instance.new("TextButton")
	toggle.AnchorPoint = Vector2.new(1, 1)
	toggle.Position = UDim2.new(1, -12, 1, -12)
	toggle.Size = UDim2.fromOffset(84, 34)
	toggle.BackgroundColor3 = Color3.fromRGB(70, 45, 20)
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.Font = Enum.Font.FredokaOne
	toggle.TextScaled = true
	toggle.Text = "ADMIN"
	Instance.new("UICorner").Parent = toggle
	toggle.Parent = gui

	local frame = Instance.new("ScrollingFrame")
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Position = UDim2.new(1, -12, 1, -54)
	frame.Size = UDim2.fromOffset(170, 360)
	frame.CanvasSize = UDim2.new()
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.ScrollBarThickness = 4
	frame.BackgroundColor3 = Color3.fromRGB(70, 45, 20)
	frame.BackgroundTransparency = 0.15
	frame.Visible = false
	Instance.new("UICorner").Parent = frame
	local padding = Instance.new("UIPadding")
	for _, side in ipairs({ "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" }) do
		padding[side] = UDim.new(0, 8)
	end
	padding.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	frame.Parent = gui

	for _, spec in ipairs(BUTTONS) do
		button(frame, spec[1], function()
			Remotes.AdminCommand:FireServer(spec[2], spec[3])
		end)
	end
	for stage = 1, #Config.Stages do
		button(frame, "스테이지 " .. stage, function()
			Remotes.AdminCommand:FireServer("stage", { tostring(stage) })
		end)
	end

	toggle.Activated:Connect(function()
		frame.Visible = not frame.Visible
	end)
end

function AdminPanelController.Start()
	if player:GetAttribute("IsAdmin") then
		build()
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
		if player:GetAttribute("IsAdmin") then
			build()
		end
	end)
end

return AdminPanelController
