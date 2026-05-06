-- RoleAnnouncementClient v2

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local roleAssignedRemote = ReplicatedStorage:WaitForChild("RoleAssigned")

local COLORS = {
	panel = Color3.fromRGB(10, 10, 14),
	grey = Color3.fromRGB(165, 165, 175),
	white = Color3.fromRGB(245, 245, 245),
	guardian = Color3.fromRGB(220, 60, 60),
	thief = Color3.fromRGB(40, 220, 200),
	guardianTint = Color3.fromRGB(80, 15, 15),
	thiefTint = Color3.fromRGB(10, 25, 60),
}

local function tweenIn(element, property, targetValue, duration)
	local props = {}
	props[property] = targetValue
	local tween = TweenService:Create(element, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

local function makePanel(size, position, parent, transparency)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = COLORS.panel
	f.BackgroundTransparency = transparency or 0.2
	f.Parent = parent

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = f

	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Transparency = 0.85
	s.Thickness = 1
	s.Parent = f

	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, 8)
	p.PaddingBottom = UDim.new(0, 8)
	p.PaddingLeft = UDim.new(0, 8)
	p.PaddingRight = UDim.new(0, 8)
	p.Parent = f

	return f
end

local function makeShadow(frame)
	local sh = Instance.new("Frame")
	sh.Size = frame.Size
	sh.Position = frame.Position + UDim2.fromOffset(2, 2)
	sh.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	sh.BackgroundTransparency = 0.6
	sh.ZIndex = frame.ZIndex - 1
	sh.Parent = frame.Parent

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = sh
	return sh
end

local function makeLabel(text, font, textColor, parent)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = font
	l.TextColor3 = textColor
	l.Parent = parent
	return l
end

local gui = Instance.new("ScreenGui")
gui.Name = "RoleAnnouncementUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = COLORS.guardianTint
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.Parent = gui

local panel = makePanel(UDim2.fromOffset(600, 200), UDim2.new(0.5, -300, 0.5, -70), overlay, 1)
panel.Visible = false
local shadow = makeShadow(panel)
shadow.Visible = false

local roleTag = makeLabel("YOUR ROLE", Enum.Font.GothamBold, COLORS.grey, panel)
roleTag.Size = UDim2.fromOffset(560, 24)
roleTag.Position = UDim2.fromOffset(20, 20)
roleTag.TextSize = 14
roleTag.TextXAlignment = Enum.TextXAlignment.Center

local icon = Instance.new("Frame")
icon.Size = UDim2.fromOffset(18, 18)
icon.Position = UDim2.fromOffset(150, 82)
icon.BorderSizePixel = 0
icon.Parent = panel
local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 4)
iconCorner.Parent = icon

local main = makeLabel("", Enum.Font.GothamBlack, COLORS.white, panel)
main.Size = UDim2.fromOffset(420, 70)
main.Position = UDim2.fromOffset(90, 66)
main.TextSize = 54
main.TextXAlignment = Enum.TextXAlignment.Center

local flavor = makeLabel("", Enum.Font.Gotham, COLORS.white, panel)
flavor.Size = UDim2.fromOffset(560, 30)
flavor.Position = UDim2.fromOffset(20, 150)
flavor.TextSize = 20
flavor.TextXAlignment = Enum.TextXAlignment.Center

local function show(role)
	local isGuardian = role == "Guardian"
	overlay.BackgroundColor3 = isGuardian and COLORS.guardianTint or COLORS.thiefTint
	icon.BackgroundColor3 = isGuardian and COLORS.guardian or COLORS.thief
	main.TextColor3 = isGuardian and COLORS.guardian or COLORS.thief
	main.Text = isGuardian and "GUARDIAN" or "THIEF"
	flavor.Text = isGuardian and "Hunt them down. Let none escape." or "Light the braziers. Steal the idol."

	overlay.Visible = true
	panel.Visible = true
	shadow.Visible = true

	overlay.BackgroundTransparency = 1
	panel.BackgroundTransparency = 1
	shadow.BackgroundTransparency = 1
	panel.Position = UDim2.new(0.5, -300, 0.5, -40)

	tweenIn(overlay, "BackgroundTransparency", 0.5, 0.3)
	tweenIn(panel, "BackgroundTransparency", 0.2, 0.3)
	tweenIn(shadow, "BackgroundTransparency", 0.6, 0.3)
	tweenIn(panel, "Position", UDim2.new(0.5, -300, 0.5, -70), 0.3)

	task.delay(3, function()
		tweenIn(overlay, "BackgroundTransparency", 1, 0.6)
		tweenIn(panel, "BackgroundTransparency", 1, 0.6)
		tweenIn(shadow, "BackgroundTransparency", 1, 0.6)
		tweenIn(panel, "Position", UDim2.new(0.5, -300, 0.5, -90), 0.6)
		task.delay(0.62, function()
			overlay.Visible = false
			panel.Visible = false
			shadow.Visible = false
		end)
	end)
end

roleAssignedRemote.OnClientEvent:Connect(show)
