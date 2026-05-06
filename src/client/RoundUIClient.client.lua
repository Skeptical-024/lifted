local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Types = require(ReplicatedStorage:WaitForChild("Types"))

local localPlayer = Players.LocalPlayer
local roundStartedRemote = ReplicatedStorage:WaitForChild("RoundStarted")
local roundEndedRemote = ReplicatedStorage:WaitForChild("RoundEnded")
local thiefCountUpdateRemote = ReplicatedStorage:WaitForChild("ThiefCountUpdate")
local brazierProgressUpdateRemote = ReplicatedStorage:WaitForChild("BrazierProgressUpdate")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local timerContainer = Instance.new("Frame")
timerContainer.Size = UDim2.new(0, 120, 0, 36)
timerContainer.Position = UDim2.new(0.5, -60, 0, 28)
timerContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
timerContainer.BackgroundTransparency = 0.25
timerContainer.Visible = false
timerContainer.Parent = screenGui

local timerTitle = Instance.new("TextLabel")
timerTitle.Size = UDim2.new(0, 180, 0, 16)
timerTitle.Position = UDim2.new(0.5, -90, 0, -18)
timerTitle.BackgroundTransparency = 1
timerTitle.Text = "TIME REMAINING"
timerTitle.Font = Enum.Font.GothamBold
timerTitle.TextScaled = true
timerTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
timerTitle.Visible = false
timerTitle.Parent = timerContainer

local timerText = Instance.new("TextLabel")
timerText.Size = UDim2.fromScale(1, 1)
timerText.BackgroundTransparency = 1
timerText.Text = "8:00"
timerText.Font = Enum.Font.GothamBlack
timerText.TextScaled = true
timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
timerText.Parent = timerContainer

local roleBadge = Instance.new("TextLabel")
roleBadge.Size = UDim2.new(0, 150, 0, 32)
roleBadge.Position = UDim2.new(0, 16, 0, 20)
roleBadge.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
roleBadge.BackgroundTransparency = 0.2
roleBadge.Text = ""
roleBadge.Font = Enum.Font.GothamBold
roleBadge.TextScaled = true
roleBadge.Visible = false
roleBadge.Parent = screenGui

local thiefCountLabel = Instance.new("TextLabel")
thiefCountLabel.Size = UDim2.new(0, 260, 0, 32)
thiefCountLabel.Position = UDim2.new(1, -276, 1, -52)
thiefCountLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
thiefCountLabel.BackgroundTransparency = 0.2
thiefCountLabel.Text = "THIEVES REMAINING: 0"
thiefCountLabel.Font = Enum.Font.GothamBold
thiefCountLabel.TextScaled = true
thiefCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
thiefCountLabel.Visible = false
thiefCountLabel.Parent = screenGui

local brazierProgressLabel = Instance.new("TextLabel")
brazierProgressLabel.Size = UDim2.new(0, 200, 0, 32)
brazierProgressLabel.Position = UDim2.new(0, 16, 1, -52)
brazierProgressLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
brazierProgressLabel.BackgroundTransparency = 0.2
brazierProgressLabel.Text = "BRAZIERS: 0/4"
brazierProgressLabel.Font = Enum.Font.GothamBold
brazierProgressLabel.TextScaled = true
brazierProgressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
brazierProgressLabel.Visible = false
brazierProgressLabel.Parent = screenGui

local resultOverlay = Instance.new("Frame")
resultOverlay.Size = UDim2.fromScale(1, 1)
resultOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
resultOverlay.BackgroundTransparency = 1
resultOverlay.Visible = false
resultOverlay.Parent = screenGui

local resultTitle = Instance.new("TextLabel")
resultTitle.Size = UDim2.new(0.8, 0, 0, 90)
resultTitle.Position = UDim2.new(0.1, 0, 0.38, 0)
resultTitle.BackgroundTransparency = 1
resultTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
resultTitle.Font = Enum.Font.GothamBlack
resultTitle.TextScaled = true
resultTitle.TextTransparency = 1
resultTitle.Parent = resultOverlay

local resultSubtext = Instance.new("TextLabel")
resultSubtext.Size = UDim2.new(0.8, 0, 0, 50)
resultSubtext.Position = UDim2.new(0.1, 0, 0.5, 0)
resultSubtext.BackgroundTransparency = 1
resultSubtext.TextColor3 = Color3.fromRGB(255, 255, 255)
resultSubtext.Font = Enum.Font.GothamBold
resultSubtext.TextScaled = true
resultSubtext.TextTransparency = 1
resultSubtext.Parent = resultOverlay

local roundActive = false
local roundEndTime = 0
local pulseOn = false

local function getRole()
	return localPlayer:GetAttribute("Role")
end

local function updateRoleBadge()
	local role = getRole()
	if not role or not roundActive then
		roleBadge.Visible = false
		thiefCountLabel.Visible = false
		brazierProgressLabel.Visible = false
		return
	end

	roleBadge.Visible = true
	if role == Types.PlayerRole.Guardian then
		roleBadge.Text = "GUARDIAN"
		roleBadge.TextColor3 = Color3.fromRGB(220, 70, 70)
		thiefCountLabel.Visible = true
		brazierProgressLabel.Visible = false
	elseif role == Types.PlayerRole.Thief then
		roleBadge.Text = "THIEF"
		roleBadge.TextColor3 = Color3.fromRGB(50, 220, 200)
		thiefCountLabel.Visible = false
		brazierProgressLabel.Visible = true
	end
end

local function formatTime(seconds)
	seconds = math.max(0, seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

local function startTimer(duration)
	roundActive = true
	roundEndTime = os.clock() + duration
	timerContainer.Visible = true
	timerTitle.Visible = true
	updateRoleBadge()

	task.spawn(function()
		while roundActive do
			local remaining = math.max(0, math.floor(roundEndTime - os.clock() + 0.5))
			timerText.Text = formatTime(remaining)
			if remaining <= 60 then
				timerText.TextColor3 = Color3.fromRGB(255, 80, 80)
				if not pulseOn then
					pulseOn = true
					task.spawn(function()
						while pulseOn and roundActive do
							local up = TweenService:Create(timerContainer, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, 132, 0, 40)})
							local down = TweenService:Create(timerContainer, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Size = UDim2.new(0, 120, 0, 36)})
							up:Play()
							up.Completed:Wait()
							down:Play()
							down.Completed:Wait()
						end
					end)
				end
			else
				timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
				pulseOn = false
				timerContainer.Size = UDim2.new(0, 120, 0, 36)
			end
			task.wait(1)
		end
	end)
end

local function showResult(result, winner)
	roundActive = false
	pulseOn = false
	timerContainer.Visible = false
	timerTitle.Visible = false
	roleBadge.Visible = false
	thiefCountLabel.Visible = false
	brazierProgressLabel.Visible = false

	local overlayColor = Color3.fromRGB(40, 40, 40)
	local titleText = "TIME'S UP"
	local subtext = "The guardian holds the temple"

	if winner == "Guardian" then
		overlayColor = Color3.fromRGB(70, 20, 20)
		titleText = "GUARDIAN WINS"
		subtext = result
	elseif winner == "Thieves" then
		overlayColor = Color3.fromRGB(20, 70, 70)
		titleText = "THIEVES WIN"
		subtext = result
	elseif winner == "Time" then
		overlayColor = Color3.fromRGB(45, 45, 45)
		titleText = "TIME'S UP"
		subtext = "The guardian holds the temple"
	end

	resultOverlay.BackgroundColor3 = overlayColor
	resultTitle.Text = titleText
	resultSubtext.Text = subtext
	resultOverlay.Visible = true
	resultOverlay.BackgroundTransparency = 1
	resultTitle.TextTransparency = 1
	resultSubtext.TextTransparency = 1

	TweenService:Create(resultOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.35}):Play()
	TweenService:Create(resultTitle, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	TweenService:Create(resultSubtext, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

	task.wait(3)

	TweenService:Create(resultOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(resultTitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(resultSubtext, TweenInfo.new(0.5), {TextTransparency = 1}):Play()

	task.wait(0.5)
	resultOverlay.Visible = false
end

roundStartedRemote.OnClientEvent:Connect(function(roundDurationSeconds)
	if type(roundDurationSeconds) ~= "number" then
		return
	end
	startTimer(roundDurationSeconds)
end)

roundEndedRemote.OnClientEvent:Connect(function(result, winner)
	showResult(tostring(result), tostring(winner))
end)

thiefCountUpdateRemote.OnClientEvent:Connect(function(remaining)
	if type(remaining) == "number" then
		thiefCountLabel.Text = string.format("THIEVES REMAINING: %d", math.max(0, remaining))
	end
end)

brazierProgressUpdateRemote.OnClientEvent:Connect(function(litCount)
	if type(litCount) == "number" then
		brazierProgressLabel.Text = string.format("BRAZIERS: %d/4", math.clamp(litCount, 0, 4))
	end
end)

localPlayer:GetAttributeChangedSignal("Role"):Connect(function()
	updateRoleBadge()
end)
