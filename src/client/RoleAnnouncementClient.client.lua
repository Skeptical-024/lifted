local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local roleAssignedRemote = ReplicatedStorage:WaitForChild("RoleAssigned")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoleAnnouncementGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.Position = UDim2.fromScale(0, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = screenGui

local label = Instance.new("TextLabel")
label.Name = "RoleLabel"
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1, 1)
label.Position = UDim2.fromScale(0, 0)
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextTransparency = 1
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.TextStrokeTransparency = 0.5
label.Text = ""
label.Parent = overlay

local currentTweenToken = 0

local function showRole(role)
	currentTweenToken += 1
	local token = currentTweenToken

	local text
	local tint
	if role == "Guardian" then
		text = "YOU ARE THE GUARDIAN"
		tint = Color3.fromRGB(130, 15, 15)
	else
		text = "YOU ARE A THIEF"
		tint = Color3.fromRGB(18, 34, 84)
	end

	overlay.BackgroundColor3 = tint
	overlay.BackgroundTransparency = 0.35
	label.Text = text
	label.TextTransparency = 0
	overlay.Visible = true

	task.wait(3)
	if token ~= currentTweenToken then
		return
	end

	local fadeInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeOverlay = TweenService:Create(overlay, fadeInfo, { BackgroundTransparency = 1 })
	local fadeText = TweenService:Create(label, fadeInfo, { TextTransparency = 1 })
	fadeOverlay:Play()
	fadeText:Play()
	fadeText.Completed:Wait()

	if token == currentTweenToken then
		overlay.Visible = false
	end
end

roleAssignedRemote.OnClientEvent:Connect(function(role)
	if type(role) ~= "string" then
		return
	end
	task.spawn(showRole, role)
end)
