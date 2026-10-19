-- 클라이언트 진입점. 컨트롤러 하나가 실패해도 나머지는 돌아가게 한다.
local CONTROLLERS = {
	"HudController",
	"PopupController",
	"DoubleJumpController",
	"EggWobbleController",
	"WindController",
	"GateController",
	"AdminPanelController",
}

for _, name in ipairs(CONTROLLERS) do
	local ok, err = pcall(function()
		require(script:WaitForChild(name)).Start()
	end)
	if not ok then
		warn(string.format("[Client] %s 시작 실패: %s", name, tostring(err)))
	end
end
