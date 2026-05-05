local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local thiefCaughtRemote = ReplicatedStorage:WaitForChild("ThiefCaught")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CaughtFeedbackGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "FeedbackLabel"
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1, 1)
label.Position = UDim2.fromScale(0, 0)
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.Text = ""
label.TextTransparency = 1
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.TextStrokeTransparency = 0.4
label.Parent = screenGui

local function playCaughtBuzzer()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://4612263052"
	sound.Volume = 1
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

local function showMessage(text, color, duration)
	label.Text = text
	label.TextColor3 = color
	label.TextTransparency = 0

	local tween = TweenService:Create(
		label,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	)
	tween:Play()
end

thiefCaughtRemote.OnClientEvent:Connect(function(guardianPlayer, caughtPlayer)
	if typeof(guardianPlayer) ~= "Instance" or typeof(caughtPlayer) ~= "Instance" then
		return
	end
	if not guardianPlayer:IsA("Player") or not caughtPlayer:IsA("Player") then
		return
	end

	if localPlayer == caughtPlayer then
		showMessage("YOU WERE CAUGHT", Color3.fromRGB(220, 40, 40), 2)
		playCaughtBuzzer()
	elseif localPlayer == guardianPlayer then
		showMessage("THIEF CAUGHT!", Color3.fromRGB(70, 220, 90), 1.5)
	end
end)
