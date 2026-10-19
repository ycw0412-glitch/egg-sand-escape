-- RemoteEvent는 default.project.json에서 만든다. 이름은 여기서만 참조한다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:WaitForChild("Remotes")

return {
	Popup = folder:WaitForChild("Popup") :: RemoteEvent, -- 서버 → 클라: (part, amount) +1 팝업
	Notify = folder:WaitForChild("Notify") :: RemoteEvent, -- 서버 → 클라: (text) 안내 토스트
	LevelUp = folder:WaitForChild("LevelUp") :: RemoteEvent, -- 서버 → 클라: (level)
	AdminCommand = folder:WaitForChild("AdminCommand") :: RemoteEvent, -- 클라 → 서버: (command, args)
}
