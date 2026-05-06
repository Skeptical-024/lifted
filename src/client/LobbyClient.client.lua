local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local lobbyUpdateRemote = ReplicatedStorage:WaitForChild("LobbyUpdate")
local roundStartedRemote = ReplicatedStorage:WaitForChild("RoundStarted")
local roleAssignedRemote = ReplicatedStorage:WaitForChild("RoleAssigned")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LobbyUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 420, 0, 220)
panel.Position = UDim2.new(0.5, -210, 0.5, -110)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
panel.BackgroundTransparency = 0.25
panel.Visible = false
panel.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 64)
title.Position = UDim2.new(0, 0, 0, 22)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Text = "WAITING FOR PLAYERS"
title.Parent = panel

local countdownText = Instance.new("TextLabel")
countdownText.Size = UDim2.new(1, 0, 0, 80)
countdownText.Position = UDim2.new(0, 0, 0, 74)
countdownText.BackgroundTransparency = 1
countdownText.TextColor3 = Color3.fromRGB(255, 255, 255)
countdownText.Font = Enum.Font.GothamBlack
countdownText.TextScaled = true
countdownText.Text = ""
countdownText.Parent = panel

local subtext = Instance.new("TextLabel")
subtext.Size = UDim2.new(1, 0, 0, 36)
subtext.Position = UDim2.new(0, 0, 1, -52)
subtext.BackgroundTransparency = 1
subtext.TextColor3 = Color3.fromRGB(230, 230, 230)
subtext.Font = Enum.Font.GothamBold
subtext.TextScaled = true
subtext.Text = ""
subtext.Parent = panel

local waitingDots = 0
local waitingActive = false

task.spawn(function()
	while true do
		if waitingActive and panel.Visible then
			waitingDots = (waitingDots % 3) + 1
			title.Text = "WAITING FOR PLAYERS" .. string.rep(".", waitingDots)
		end
		task.wait(0.5)
	end
end)

local function hidePanel()
	panel.Visible = false
	waitingActive = false
end

local function pulseCountdown()
	countdownText.Size = UDim2.new(1, 0, 0, 80)
	TweenService:Create(countdownText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1.15, 0, 0, 92)
	}):Play()
end

lobbyUpdateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	local status = payload.status
	if status == "waiting" then
		panel.Visible = true
		waitingActive = true
		title.Text = "WAITING FOR PLAYERS"
		countdownText.Text = ""
		subtext.Text = string.format("%d / %d players", payload.playerCount or 0, payload.required or 0)
	elseif status == "countdown" then
		panel.Visible = true
		waitingActive = false
		title.Text = "ROUND STARTING"
		countdownText.Text = tostring(payload.countdown or "")
		subtext.Text = "Get ready..."
		pulseCountdown()
	end
end)

roundStartedRemote.OnClientEvent:Connect(hidePanel)
roleAssignedRemote.OnClientEvent:Connect(hidePanel)
