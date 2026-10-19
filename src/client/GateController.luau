-- 레벨이 되면 내 화면에서만 게이트가 열린다. 우회 여부는 서버가 다음 체크포인트에서 확인한다.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local GateController = {}

local function update(gate)
	local required = gate:GetAttribute("RequiredLevel") or 1
	local open = (player:GetAttribute("Level") or 1) >= required
	gate.CanCollide = not open
	gate.Transparency = if open then 0.85 else 0.3
	local text = gate:FindFirstChild("Label", true)
	if text then
		text.Text = if open then "열림 · 앞으로!" else string.format("레벨 %d 필요", required)
		text.TextColor3 = if open then Color3.fromRGB(150, 255, 160) else Color3.fromRGB(255, 220, 120)
	end
end

local function updateAll()
	for _, gate in ipairs(CollectionService:GetTagged("Gate")) do
		update(gate)
	end
end

function GateController.Start()
	CollectionService:GetInstanceAddedSignal("Gate"):Connect(update)
	player:GetAttributeChangedSignal("Level"):Connect(updateAll)
	updateAll()
end

return GateController
