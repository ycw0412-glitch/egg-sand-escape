-- +1 숫자 팝업, 밟은 모래 타일이 살짝 눌리는 연출, 모래 튀김.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer

local PopupController = {}

local pressing = {}

local function popup(part, amount)
	local gui = Instance.new("BillboardGui")
	gui.Adornee = part
	gui.Size = UDim2.fromOffset(70, 44)
	gui.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 2.5, 0)
	gui.AlwaysOnTop = true
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.Text = "+" .. amount
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeColor3 = Color3.fromRGB(90, 60, 25)
	text.TextStrokeTransparency = 0
	text.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")

	local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffset = gui.StudsOffset + Vector3.new(0, 2.5, 0) }):Play()
	TweenService:Create(text, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.75, function()
		gui:Destroy()
	end)
end

local function press(tile)
	if pressing[tile] then
		return
	end
	pressing[tile] = true
	local home = tile.CFrame
	local down = TweenService:Create(tile, TweenInfo.new(0.08), { CFrame = home * CFrame.new(0, -0.3, 0) })
	down:Play()
	down.Completed:Wait()
	local up = TweenService:Create(tile, TweenInfo.new(0.15), { CFrame = home })
	up:Play()
	up.Completed:Wait()
	pressing[tile] = nil

	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 0.5, 0)
	attachment.Parent = tile
	local dust = Instance.new("ParticleEmitter")
	dust.Color = ColorSequence.new(tile.Color)
	dust.Size = NumberSequence.new(0.4, 0)
	dust.Lifetime = NumberRange.new(0.3, 0.5)
	dust.Speed = NumberRange.new(4, 7)
	dust.SpreadAngle = Vector2.new(60, 60)
	dust.Rate = 0
	dust.Parent = attachment
	dust:Emit(6)
	task.delay(0.6, function()
		attachment:Destroy()
	end)
end

function PopupController.Start()
	Remotes.Popup.OnClientEvent:Connect(function(part, amount)
		if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
			return
		end
		popup(part, amount or 1)
		if CollectionService:HasTag(part, "SandTile") then
			task.spawn(press, part)
		end
	end)
end

return PopupController
