-- MainMenuClient v6

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local roleAssignedRemote = ReplicatedStorage:WaitForChild("RoleAssigned")

local playClickedBindable = ReplicatedStorage:FindFirstChild("PlayClicked")
if not playClickedBindable then
	local bindable = Instance.new("BindableEvent")
	bindable.Name = "PlayClicked"
	bindable.Parent = ReplicatedStorage
	playClickedBindable = bindable
end

local C = {
	bg = Color3.fromRGB(6, 7, 13),
	gold = Color3.fromRGB(180, 230, 255),
	titleColor = Color3.fromRGB(220, 235, 255),
	text = Color3.fromRGB(220, 220, 230),
	textMuted = Color3.fromRGB(170, 170, 190),
	textDim = Color3.fromRGB(130, 130, 150),
	blue = Color3.fromRGB(100, 160, 255),
	white = Color3.fromRGB(238, 240, 248),
	card = Color3.fromRGB(10, 11, 18),
	cardMuted = Color3.fromRGB(14, 15, 23),
}

local activeTweens = {}
local function playTween(key, inst, info, props)
	if activeTweens[key] then
		activeTweens[key]:Cancel()
	end
	local t = TweenService:Create(inst, info, props)
	activeTweens[key] = t
	t:Play()
	return t
end

local function makeCorner(radius, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function makeFrame(size, pos, color, transparency, z, parent)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = parent
	return f
end

local function makeLabel(text, font, size, color, transparency, align, z, parent)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Text = text
	l.Font = font
	l.TextSize = size
	l.TextColor3 = color
	l.TextTransparency = transparency
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.ZIndex = z
	l.Parent = parent
	return l
end

local gui = Instance.new("ScreenGui")
gui.Name = "MainMenuUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local menuMusic = Instance.new("Sound")
menuMusic.SoundId = "rbxassetid://87773819933629"
menuMusic.Volume = 0
menuMusic.Looped = true
menuMusic.RollOffMaxDistance = 0
menuMusic.Parent = gui

menuMusic:Play()

-- Fade in over 2 seconds
local musicTween = TweenService:Create(menuMusic, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Volume = 0.35})
musicTween:Play()

-- Shared background
local bg = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 0, 1, gui)

local leftEllipse = makeFrame(UDim2.fromOffset(600, 600), UDim2.new(0, -180, 1, 220), Color3.fromRGB(30, 18, 5), 0.92, 1, gui)
leftEllipse.AnchorPoint = Vector2.new(0, 1)
makeCorner(300, leftEllipse)

local centerEllipse = makeFrame(UDim2.fromOffset(800, 400), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(8, 12, 25), 0.8, 1, gui)
centerEllipse.AnchorPoint = Vector2.new(0.5, 0.5)
makeCorner(200, centerEllipse)

local rightEllipse = makeFrame(UDim2.fromOffset(500, 500), UDim2.new(1, 180, 1, 180), Color3.fromRGB(15, 8, 3), 0.78, 1, gui)
rightEllipse.AnchorPoint = Vector2.new(1, 1)
makeCorner(250, rightEllipse)

local stripes = {}
local stripeDurations = {3, 3.5, 4, 4.5, 5, 3.2, 3.8, 4.2}
for i = 1, 8 do
	local x = (i - 1) / 7
	local stripe = makeFrame(UDim2.new(0, 3, 1.4, 0), UDim2.new(x, -1, -0.2, 0), C.gold, 0.88, 1, gui)
	stripe.Rotation = 25
	table.insert(stripes, stripe)
end

local vignette = makeFrame(UDim2.new(1, 0, 0, 200), UDim2.new(0, 0, 1, -200), C.bg, 0.1, 1, gui)
local vignetteGrad = Instance.new("UIGradient")
vignetteGrad.Rotation = 90
vignetteGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0.1),
})
vignetteGrad.Parent = vignette

for i, stripe in ipairs(stripes) do
	task.spawn(function()
		local d = stripeDurations[i] or 4
		local up = true
		while gui.Enabled do
			if up then
				local t = TweenService:Create(stripe, TweenInfo.new(d, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.96})
				t:Play()
				t.Completed:Wait()
			else
				local t = TweenService:Create(stripe, TweenInfo.new(d, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.88})
				t:Play()
				t.Completed:Wait()
			end
			up = not up
		end
	end)
end

task.spawn(function()
	local up = true
	while gui.Enabled do
		if up then
			local t2 = TweenService:Create(centerEllipse, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.65})
			local t3 = TweenService:Create(rightEllipse, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.63})
			t2:Play()
			t3:Play()
			t2.Completed:Wait()
		else
			local t2 = TweenService:Create(centerEllipse, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.95})
			local t3 = TweenService:Create(rightEllipse, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.93})
			t2:Play()
			t3:Play()
			t2.Completed:Wait()
		end
		up = not up
	end
end)

-- Particles layer
local particlesLayer = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 1, 2, gui)

local function animateParticle(p)
	task.spawn(function()
		task.wait(math.random() * 5)
		while gui.Enabled do
			local sx = math.random(5, 95) / 100
			local startY = 1 + (math.random(0, 20) / 100)
			local endY = startY - (math.random(80, 140) / math.max(gui.AbsoluteSize.Y, 1))
			local dur = math.random(50, 80) / 10
			p.Position = UDim2.new(sx, 0, startY, 0)
			p.BackgroundTransparency = 0.85

			local t1 = TweenService:Create(p, TweenInfo.new(dur * 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.new(sx, 0, (startY + endY) * 0.5, 0),
				BackgroundTransparency = 0.4,
			})
			local t2 = TweenService:Create(p, TweenInfo.new(dur * 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Position = UDim2.new(sx, 0, endY, 0),
				BackgroundTransparency = 0.85,
			})
			t1:Play()
			t1.Completed:Wait()
			t2:Play()
			t2.Completed:Wait()
		end
	end)
end

for i = 1, 28 do
	local particleSize = 3
	if i > 10 and i <= 18 then
		particleSize = 2
	elseif i > 18 then
		particleSize = 4
	end
	local p = makeFrame(UDim2.fromOffset(particleSize, particleSize), UDim2.new(math.random(), 0, math.random(), 0), C.gold, math.random(20, 70) / 100, 2, particlesLayer)
	makeCorner(99, p)
	animateParticle(p)
end

-- Transition overlay
local transitionOverlay = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 1, 20, gui)

-- Splash screen
local splashScreen = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 1, 10, gui)
splashScreen.Visible = true

local splashContainer = makeFrame(UDim2.fromOffset(600, 340), UDim2.new(0.5, 0, 0.5, 0), C.bg, 1, 11, splashScreen)
splashContainer.AnchorPoint = Vector2.new(0.5, 0.5)

local splashLayout = Instance.new("UIListLayout")
splashLayout.FillDirection = Enum.FillDirection.Vertical
splashLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
splashLayout.SortOrder = Enum.SortOrder.LayoutOrder
splashLayout.Padding = UDim.new(0, 16)
splashLayout.Parent = splashContainer

local logoLabel = makeLabel("LIFTED", Enum.Font.GothamBlack, 96, C.titleColor, 1, Enum.TextXAlignment.Center, 12, splashContainer)
logoLabel.Size = UDim2.new(1, 0, 0, 100)
logoLabel.LayoutOrder = 1

local taglineLabel = makeLabel("Steal the idol. Don't get caught.", Enum.Font.Gotham, 16, Color3.fromRGB(200, 200, 210), 1, Enum.TextXAlignment.Center, 12, splashContainer)
taglineLabel.Size = UDim2.new(1, 0, 0, 22)
taglineLabel.LayoutOrder = 2

local ornamentFrame = makeFrame(UDim2.fromOffset(300, 20), UDim2.fromOffset(0, 0), C.bg, 1, 12, splashContainer)
ornamentFrame.LayoutOrder = 3

local lineL = makeFrame(UDim2.fromOffset(80, 1), UDim2.new(0.5, -40, 0.5, 0), C.gold, 1, 12, ornamentFrame)
lineL.AnchorPoint = Vector2.new(1, 0.5)
local lineR = makeFrame(UDim2.fromOffset(80, 1), UDim2.new(0.5, 40, 0.5, 0), C.gold, 1, 12, ornamentFrame)
lineR.AnchorPoint = Vector2.new(0, 0.5)
local diamonds = {}
for _, xo in ipairs({-12, 0, 12}) do
	local d = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0.5, xo, 0.5, 0), C.gold, 1, 12, ornamentFrame)
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Rotation = 45
	table.insert(diamonds, d)
end

local playLabel = makeLabel("PRESS TO PLAY", Enum.Font.GothamBold, 12, C.gold, 1, Enum.TextXAlignment.Center, 13, splashContainer)
playLabel.Size = UDim2.fromOffset(200, 44)
playLabel.LayoutOrder = 4

local clickAnywhere = Instance.new("TextButton")
clickAnywhere.BackgroundTransparency = 1
clickAnywhere.Size = UDim2.fromScale(1, 1)
clickAnywhere.Position = UDim2.fromScale(0, 0)
clickAnywhere.Text = ""
clickAnywhere.ZIndex = 15
clickAnywhere.Parent = splashScreen
local logoScale = Instance.new("UIScale")
logoScale.Scale = 1
logoScale.Parent = logoLabel

-- Menu screen
local menuScreen = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 1, 10, gui)
menuScreen.Visible = false
menuScreen.Active = true

local scanLines = {}
for _, sy in ipairs({0.1, 0.45, 0.75}) do
	local line = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, sy, 0), C.gold, 0.97, 3, menuScreen)
	table.insert(scanLines, {frame = line, speed = 0.02 + math.random() * 0.015})
end

local identityZone = makeFrame(UDim2.fromOffset(700, 150), UDim2.new(0.47, 0, 0, 32), C.bg, 1, 11, menuScreen)
identityZone.AnchorPoint = Vector2.new(0.45, 0)
local identityLayout = Instance.new("UIListLayout")
identityLayout.FillDirection = Enum.FillDirection.Vertical
identityLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
identityLayout.SortOrder = Enum.SortOrder.LayoutOrder
identityLayout.Padding = UDim.new(0, 8)
identityLayout.Parent = identityZone

local wordmark = makeLabel("LIFTED", Enum.Font.GothamBlack, 72, C.titleColor, 0, Enum.TextXAlignment.Center, 12, identityZone)
wordmark.Size = UDim2.new(1, 0, 0, 80)
wordmark.LayoutOrder = 1
local dividerLine = makeFrame(UDim2.fromOffset(140, 1), UDim2.fromOffset(0, 0), C.gold, 0.55, 12, identityZone)
dividerLine.LayoutOrder = 2
local seasonLabel = makeLabel("SEASON 1 — THE CURSED TEMPLE", Enum.Font.GothamBold, 12, C.gold, 0.35, Enum.TextXAlignment.Center, 12, identityZone)
seasonLabel.Size = UDim2.new(1, 0, 0, 14)
seasonLabel.LayoutOrder = 3
local tagLabel = makeLabel("Infiltrate. Steal. Escape.", Enum.Font.Gotham, 15, Color3.fromRGB(200, 210, 230), 0.18, Enum.TextXAlignment.Center, 12, identityZone)
tagLabel.Size = UDim2.new(1, 0, 0, 16)
tagLabel.LayoutOrder = 4
local asymLabel = makeLabel("4V1 ASYMMETRIC HEIST", Enum.Font.GothamBold, 10, C.gold, 0.55, Enum.TextXAlignment.Center, 12, identityZone)
asymLabel.Size = UDim2.new(1, 0, 0, 14)
asymLabel.LayoutOrder = 5

local navZone = makeFrame(UDim2.fromOffset(460, 260), UDim2.new(0.16, 0, 0.52, 0), C.bg, 1, 11, menuScreen)
navZone.AnchorPoint = Vector2.new(0, 0.5)
local navTitle = makeLabel("MAIN MENU", Enum.Font.GothamBold, 11, C.gold, 0.5, Enum.TextXAlignment.Left, 12, navZone)
navTitle.Size = UDim2.new(1, 0, 0, 14)
navTitle.Position = UDim2.new(0, 0, 0, 0)
local navTopSep = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 28), C.gold, 0.88, 12, navZone)

local navRows = makeFrame(UDim2.new(1, 0, 1, -30), UDim2.new(0, 0, 0, 30), C.bg, 1, 12, navZone)
local navRowsList = Instance.new("UIListLayout")
navRowsList.FillDirection = Enum.FillDirection.Vertical
navRowsList.SortOrder = Enum.SortOrder.LayoutOrder
navRowsList.Padding = UDim.new(0, 0)
navRowsList.Parent = navRows

local centerSeparator = makeFrame(UDim2.new(0, 1, 0, 180), UDim2.new(0.60, 0, 0.52, 0), C.gold, 0.85, 11, menuScreen)
centerSeparator.AnchorPoint = Vector2.new(0.5, 0.5)

local infoZone = makeFrame(UDim2.fromOffset(300, 0), UDim2.new(0.84, 0, 0.28, 0), C.bg, 1, 11, menuScreen)
infoZone.AnchorPoint = Vector2.new(1, 0)
infoZone.AutomaticSize = Enum.AutomaticSize.Y
local infoBacking = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(8, 10, 18), 0.5, 12, infoZone)
infoBacking.AutomaticSize = Enum.AutomaticSize.Y
makeCorner(10, infoBacking)
local infoPad = Instance.new("UIPadding")
infoPad.PaddingTop = UDim.new(0, 20)
infoPad.PaddingBottom = UDim.new(0, 20)
infoPad.PaddingLeft = UDim.new(0, 20)
infoPad.PaddingRight = UDim.new(0, 20)
infoPad.Parent = infoBacking
local infoTopBorder = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.7, 13, infoBacking)
local infoBottomBorder = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -1), C.gold, 0.7, 13, infoBacking)

local infoContent = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 0), C.bg, 1, 13, infoBacking)
infoContent.AutomaticSize = Enum.AutomaticSize.Y
local infoLayout = Instance.new("UIListLayout")
infoLayout.FillDirection = Enum.FillDirection.Vertical
infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoLayout.Padding = UDim.new(0, 12)
infoLayout.Parent = infoContent
local infoPanelLabel = makeLabel("DEPLOYMENT", Enum.Font.GothamBlack, 15, C.gold, 0, Enum.TextXAlignment.Left, 14, infoContent)
infoPanelLabel.Size = UDim2.new(1, 0, 0, 18)
infoPanelLabel.LayoutOrder = 1
local infoDivider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.82, 14, infoContent)
infoDivider.LayoutOrder = 2
local infoMainLines = {}
for i = 1, 4 do
	local ln = makeLabel("", Enum.Font.Gotham, 14, Color3.fromRGB(195, 210, 235), 0.05, Enum.TextXAlignment.Left, 14, infoContent)
	ln.Size = UDim2.new(1, 0, 0, 20)
	ln.LayoutOrder = 2 + i
	table.insert(infoMainLines, ln)
end
local infoGap = makeFrame(UDim2.new(1, 0, 0, 12), UDim2.new(0, 0, 0, 0), C.bg, 1, 14, infoContent)
infoGap.LayoutOrder = 7
local infoSecondaryLabel = makeLabel("MATCH INFO", Enum.Font.GothamBold, 12, C.gold, 0.2, Enum.TextXAlignment.Left, 14, infoContent)
infoSecondaryLabel.Size = UDim2.new(1, 0, 0, 16)
infoSecondaryLabel.LayoutOrder = 8
local infoSecondaryDivider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.88, 14, infoContent)
infoSecondaryDivider.LayoutOrder = 9
local infoSecondaryLines = {}
for i = 1, 3 do
	local ln = makeLabel("", Enum.Font.Gotham, 13, Color3.fromRGB(155, 170, 195), 0.08, Enum.TextXAlignment.Left, 14, infoContent)
	ln.Size = UDim2.new(1, 0, 0, 18)
	ln.LayoutOrder = 9 + i
	table.insert(infoSecondaryLines, ln)
end

local footer = makeFrame(UDim2.new(1, -60, 0, 24), UDim2.new(0.5, 0, 1, -14), C.bg, 1, 11, menuScreen)
footer.AnchorPoint = Vector2.new(0.5, 1)
local footerLine = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.88, 12, footer)
local onlineDot = makeFrame(UDim2.fromOffset(5, 5), UDim2.new(0, 14, 0.5, 2), C.blue, 0.4, 12, footer)
onlineDot.AnchorPoint = Vector2.new(0, 0.5)
makeCorner(99, onlineDot)
local footerLeft = makeLabel("EARLY ACCESS", Enum.Font.Gotham, 11, Color3.fromRGB(170, 185, 210), 0.4, Enum.TextXAlignment.Left, 12, footer)
footerLeft.AnchorPoint = Vector2.new(0, 0.5)
footerLeft.Position = UDim2.new(0, 26, 0.5, 2)
footerLeft.Size = UDim2.fromOffset(220, 16)
local footerCenter = makeLabel("SEASON 1 — THE CURSED TEMPLE", Enum.Font.Gotham, 11, C.gold, 0.4, Enum.TextXAlignment.Center, 12, footer)
footerCenter.AnchorPoint = Vector2.new(0.5, 0.5)
footerCenter.Position = UDim2.new(0.5, 0, 0.5, 2)
footerCenter.Size = UDim2.fromOffset(320, 16)
local footerRight = makeLabel("v0.1.0", Enum.Font.Gotham, 11, Color3.fromRGB(130, 145, 165), 0.4, Enum.TextXAlignment.Right, 12, footer)
footerRight.AnchorPoint = Vector2.new(1, 0.5)
footerRight.Position = UDim2.new(1, 0, 0.5, 2)
footerRight.Size = UDim2.fromOffset(100, 16)

local cornerFrames = {}
local function addCornerFrame(size, pos)
	local f = makeFrame(size, pos, C.gold, 0.65, 11, menuScreen)
	table.insert(cornerFrames, f)
	return f
end
addCornerFrame(UDim2.fromOffset(28, 1), UDim2.new(0, 0, 0, 0))
addCornerFrame(UDim2.fromOffset(1, 28), UDim2.new(0, 0, 0, 0))
addCornerFrame(UDim2.fromOffset(28, 1), UDim2.new(1, -28, 0, 0))
addCornerFrame(UDim2.fromOffset(1, 28), UDim2.new(1, -1, 0, 0))
addCornerFrame(UDim2.fromOffset(28, 1), UDim2.new(0, 0, 1, -1))
addCornerFrame(UDim2.fromOffset(1, 28), UDim2.new(0, 0, 1, -28))
addCornerFrame(UDim2.fromOffset(28, 1), UDim2.new(1, -28, 1, -1))
addCornerFrame(UDim2.fromOffset(1, 28), UDim2.new(1, -1, 1, -28))

local selectedOption = "findmatch"
local optionRefs = {}
local infoBySelection = {
	findmatch = {
		mainHeading = "DEPLOYMENT",
		mainLines = {"4v1 Asymmetric Heist", "Current Season: The Cursed Temple", "Status: Early Access", "Round Time: 8:00"},
		secondaryHeading = "MATCH INFO",
		secondaryLines = {"5 Players Required", "4 Thieves / 1 Guardian", "Current Map: Cursed Temple"},
	},
	howtoplay = {
		mainHeading = "OVERVIEW",
		mainLines = {"4 thieves infiltrate the temple", "Solve the brazier puzzle", "Steal the idol and extract", "1 guardian hunts them all"},
		secondaryHeading = "ROLES",
		secondaryLines = {"Thieves: Stealth / Objective", "Guardian: Hunt / Eliminate", "Win: Extract the idol"},
	},
	credits = {
		mainHeading = "DEVELOPERS",
		mainLines = {"IMPLECTE2 — Dev / Design", "SHOTSON_YOU — World / Art", "Season 1: The Cursed Temple", "Early Access Build"},
		secondaryHeading = "SEASON",
		secondaryLines = {"Map in development", "Sound design coming", "Testing coming soon"},
	},
}

local function applyRowStyle(rowKey, immediate)
	for key, ref in pairs(optionRefs) do
		local isActive = key == rowKey
		local ti = TweenInfo.new(immediate and 0 or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if isActive then
			playTween("row_" .. key .. "_acc_on", ref.accent, TweenInfo.new(immediate and 0 or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
			playTween("row_" .. key .. "_fill_on", ref.fill, TweenInfo.new(immediate and 0 or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.91})
			playTween("row_" .. key .. "_num_on", ref.num, ti, {TextTransparency = 0, TextColor3 = C.gold})
			playTween("row_" .. key .. "_title_on", ref.title, ti, {TextColor3 = C.titleColor, TextTransparency = 0, TextSize = 22})
			playTween("row_" .. key .. "_arrow_on", ref.arrow, ti, {TextTransparency = 0, Position = UDim2.new(1, -10, 0.5, 0), TextColor3 = C.gold})
			playTween("row_" .. key .. "_sub_on", ref.subtitle, ti, {TextColor3 = C.gold, TextTransparency = 0.2})
		else
			playTween("row_" .. key .. "_acc_off", ref.accent, ti, {BackgroundTransparency = 1})
			playTween("row_" .. key .. "_fill_off", ref.fill, ti, {BackgroundTransparency = 0.96})
			playTween("row_" .. key .. "_num_off", ref.num, ti, {TextTransparency = 0.45, TextColor3 = C.gold})
			playTween("row_" .. key .. "_title_off", ref.title, ti, {TextColor3 = C.titleColor, TextTransparency = 0.08, TextSize = 20})
			playTween("row_" .. key .. "_arrow_off", ref.arrow, ti, {TextTransparency = 0.65, Position = UDim2.new(1, -16, 0.5, 0), TextColor3 = C.gold})
			playTween("row_" .. key .. "_sub_off", ref.subtitle, ti, {TextColor3 = Color3.fromRGB(165, 175, 195), TextTransparency = 0.12})
			playTween("row_" .. key .. "_pos_off", ref.button, ti, {Position = UDim2.new(0, 0, 0, 0)})
		end
	end
	selectedOption = rowKey
end

local function updateInfoPanel(rowKey)
	local info = infoBySelection[rowKey]
	if not info then return end
	playTween("info_lbl_out", infoPanelLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
	playTween("info_div_out", infoDivider, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	playTween("info_backing_out", infoBacking, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	playTween("info_topborder_out", infoTopBorder, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	playTween("info_bottomborder_out", infoBottomBorder, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	playTween("info_slabel_out", infoSecondaryLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
	playTween("info_sdiv_out", infoSecondaryDivider, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	for i, ln in ipairs(infoMainLines) do playTween("info_mln_out_" .. i, ln, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}) end
	for i, ln in ipairs(infoSecondaryLines) do playTween("info_sln_out_" .. i, ln, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}) end
	task.delay(0.11, function()
		infoPanelLabel.Text = info.mainHeading
		infoSecondaryLabel.Text = info.secondaryHeading
		for i, ln in ipairs(infoMainLines) do ln.Text = info.mainLines[i] or "" end
		for i, ln in ipairs(infoSecondaryLines) do ln.Text = info.secondaryLines[i] or "" end
		playTween("info_backing_in", infoBacking, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
		playTween("info_topborder_in", infoTopBorder, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7})
		playTween("info_bottomborder_in", infoBottomBorder, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7})
		playTween("info_lbl_in", infoPanelLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
		playTween("info_div_in", infoDivider, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.82})
		playTween("info_slabel_in", infoSecondaryLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.2})
		playTween("info_sdiv_in", infoSecondaryDivider, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.88})
		for i, ln in ipairs(infoMainLines) do playTween("info_mln_in_" .. i, ln, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.05}) end
		for i, ln in ipairs(infoSecondaryLines) do playTween("info_sln_in_" .. i, ln, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.08}) end
	end)
end

local function makeOption(order, num, title, subtitle, key)
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(1, 0, 0, 72)
	btn.Text = ""
	btn.ZIndex = 12
	btn.LayoutOrder = order
	btn.Parent = navRows
	local rowStroke = Instance.new("UIStroke")
	rowStroke.Color = C.gold
	rowStroke.Thickness = 0.5
	rowStroke.Transparency = 0.88
	rowStroke.Parent = btn
	local fill = makeFrame(UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.gold, 0.96, 11, btn)
	local sepTop = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.88, 13, btn)
	local accent = makeFrame(UDim2.new(0, 3, 0.7, 0), UDim2.new(0, 0, 0.5, 0), C.gold, 1, 13, btn)
	accent.AnchorPoint = Vector2.new(0, 0.5)
	local numLabel = makeLabel(num, Enum.Font.GothamBlack, 12, C.gold, 0.5, Enum.TextXAlignment.Left, 13, btn)
	numLabel.Position = UDim2.new(0, 14, 0.5, -10)
	numLabel.Size = UDim2.fromOffset(26, 18)
	local titleLabel = makeLabel(title, Enum.Font.GothamBlack, 20, C.titleColor, 0.05, Enum.TextXAlignment.Left, 13, btn)
	titleLabel.Position = UDim2.new(0, 48, 0, 10)
	titleLabel.Size = UDim2.new(1, -90, 0, 26)
	local subtitleLabel = makeLabel(subtitle, Enum.Font.Gotham, 13, Color3.fromRGB(165, 175, 195), 0.05, Enum.TextXAlignment.Left, 13, btn)
	subtitleLabel.Position = UDim2.new(0, 48, 0, 38)
	subtitleLabel.Size = UDim2.new(1, -90, 0, 18)
	local subtitlePad = Instance.new("UIPadding")
	subtitlePad.PaddingTop = UDim.new(0, 2)
	subtitlePad.Parent = subtitleLabel
	local arrowLabel = makeLabel("›", Enum.Font.GothamBold, 18, C.gold, 0.65, Enum.TextXAlignment.Center, 13, btn)
	arrowLabel.AnchorPoint = Vector2.new(1, 0.5)
	arrowLabel.Position = UDim2.new(1, -16, 0.5, 0)
	arrowLabel.Size = UDim2.fromOffset(16, 20)
	optionRefs[key] = {button = btn, fill = fill, sep = sepTop, accent = accent, num = numLabel, title = titleLabel, subtitle = subtitleLabel, arrow = arrowLabel, stroke = rowStroke}
	btn.MouseEnter:Connect(function()
		if selectedOption == key then return end
		playTween("hover_fill_" .. key, fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.95})
		playTween("hover_title_" .. key, titleLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(200, 215, 240)})
		playTween("hover_arrow_" .. key, arrowLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.2, Position = UDim2.new(1, -11, 0.5, 0)})
		playTween("hover_row_" .. key, btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 6, 0, 0)})
	end)
	btn.MouseLeave:Connect(function()
		if selectedOption == key then return end
		playTween("hover_fill_out_" .. key, fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.96})
		playTween("hover_title_out_" .. key, titleLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = C.titleColor})
		playTween("hover_arrow_out_" .. key, arrowLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.65, Position = UDim2.new(1, -16, 0.5, 0)})
		playTween("hover_row_out_" .. key, btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
	end)
	btn.MouseButton1Down:Connect(function() playTween("click_row_down_" .. key, btn, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 4, 0, 0)}) end)
	btn.MouseButton1Up:Connect(function() playTween("click_row_up_" .. key, btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}) end)
	return btn
end

local findMatchBtn = makeOption(1, "01", "FIND MATCH", "Queue into a heist", "findmatch")
local howToBtn = makeOption(2, "02", "HOW TO PLAY", "Learn rules and roles", "howtoplay")
local creditsBtn = makeOption(3, "03", "CREDITS", "Meet the developers", "credits")
local navBottomSep = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.88, 12, navRows)
navBottomSep.LayoutOrder = 4
-- Overlays
local function makeOverlay(name, titleText)
	local overlay = makeFrame(UDim2.fromScale(1, 1), UDim2.new(1, 0, 0, 0), C.bg, 0, 20, gui)
	overlay.Visible = false
	overlay.Name = name

	local backBtn = Instance.new("TextButton")
	backBtn.AutoButtonColor = false
	backBtn.BackgroundColor3 = Color3.fromRGB(10, 11, 18)
	backBtn.BackgroundTransparency = 0.6
	backBtn.BorderSizePixel = 0
	backBtn.Size = UDim2.fromOffset(100, 32)
	backBtn.Position = UDim2.new(0, 40, 0, 56)
	backBtn.Text = ""
	backBtn.ZIndex = 25
	makeCorner(6, backBtn)

	local backLabel = makeLabel("← BACK", Enum.Font.GothamBold, 13, C.gold, 0, Enum.TextXAlignment.Left, 22, backBtn)
	backLabel.Size = UDim2.new(1, 0, 1, 0)
	backLabel.TextTransparency = 0

	backBtn.Parent = overlay

	local content = makeFrame(UDim2.fromOffset(700, 0), UDim2.new(0.5, 0, 0, 120), C.bg, 1, 21, overlay)
	content.AnchorPoint = Vector2.new(0.5, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.ClipsDescendants = false
	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingTop = UDim.new(0, 80)
	contentPad.Parent = content

	return overlay, backBtn, content, contentPad
end

local howOverlay, howBackBtn, howContent, howContentPad = makeOverlay("HowOverlay", "HOW TO PLAY")
local creditsOverlay, creditsBackBtn, creditsContent, creditsContentPad = makeOverlay("CreditsOverlay", "CREDITS")
howContentPad.PaddingTop = UDim.new(0, 0)
creditsContentPad.PaddingTop = UDim.new(0, 0)

local function makeOverlayFooter(parent)
	local footer = makeFrame(UDim2.new(1, -60, 0, 24), UDim2.new(0.5, 0, 1, -14), C.bg, 1, 22, parent)
	footer.AnchorPoint = Vector2.new(0.5, 1)
	local line = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.88, 23, footer)
	local left = makeLabel("EARLY ACCESS", Enum.Font.Gotham, 11, Color3.fromRGB(170, 185, 210), 0.4, Enum.TextXAlignment.Left, 23, footer)
	left.AnchorPoint = Vector2.new(0, 0.5)
	left.Position = UDim2.new(0, 14, 0.5, 2)
	left.Size = UDim2.fromOffset(220, 16)
	local center = makeLabel("SEASON 1 — THE CURSED TEMPLE", Enum.Font.Gotham, 11, C.gold, 0.4, Enum.TextXAlignment.Center, 23, footer)
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.Position = UDim2.new(0.5, 0, 0.5, 2)
	center.Size = UDim2.fromOffset(320, 16)
	local right = makeLabel("v0.1.0", Enum.Font.Gotham, 11, Color3.fromRGB(130, 145, 165), 0.4, Enum.TextXAlignment.Right, 23, footer)
	right.AnchorPoint = Vector2.new(1, 0.5)
	right.Position = UDim2.new(1, 0, 0.5, 2)
	right.Size = UDim2.fromOffset(100, 16)
	return footer, line, left, center, right
end

local howTitle = makeLabel("HOW TO PLAY", Enum.Font.GothamBlack, 32, C.white, 0, Enum.TextXAlignment.Center, 22, howOverlay)
howTitle.AnchorPoint = Vector2.new(0.5, 0)
howTitle.Position = UDim2.new(0.5, 0, 0, 44)
howTitle.Size = UDim2.fromOffset(500, 40)
local howSubtitle = makeLabel("Learn the basics before your first heist", Enum.Font.Gotham, 13, Color3.fromRGB(160, 175, 200), 0.2, Enum.TextXAlignment.Center, 22, howOverlay)
howSubtitle.AnchorPoint = Vector2.new(0.5, 0)
howSubtitle.Position = UDim2.new(0.5, 0, 0, 82)
howSubtitle.Size = UDim2.fromOffset(500, 20)
local howTitleDivider = makeFrame(UDim2.fromOffset(200, 1), UDim2.new(0.5, 0, 0, 108), C.gold, 0.7, 22, howOverlay)
howTitleDivider.AnchorPoint = Vector2.new(0.5, 0)

howContent.Size = UDim2.fromOffset(640, 0)
howContent.AnchorPoint = Vector2.new(0.5, 0)
howContent.Position = UDim2.new(0.5, 0, 0, 130)
howContent.BackgroundTransparency = 1
local howList = Instance.new("UIListLayout")
howList.Padding = UDim.new(0, 14)
howList.SortOrder = Enum.SortOrder.LayoutOrder
howList.Parent = howContent

local function makeChip(parent, text)
	local chip = makeFrame(UDim2.fromOffset(0, 28), UDim2.fromOffset(0, 0), Color3.fromRGB(20, 25, 40), 0.3, 24, parent)
	chip.AutomaticSize = Enum.AutomaticSize.X
	makeCorner(6, chip)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = chip
	local lbl = makeLabel(text, Enum.Font.GothamBold, 12, C.gold, 0.1, Enum.TextXAlignment.Center, 25, chip)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	return chip
end

local function makeHowCard(order, num, title, lines, chips)
	local card = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), Color3.fromRGB(10, 12, 20), 0.55, 22, howContent)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.LayoutOrder = order
	makeCorner(10, card)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.gold
	stroke.Thickness = 0.5
	stroke.Transparency = 0.82
	stroke.Parent = card
	local cardPad = Instance.new("UIPadding")
	cardPad.PaddingTop = UDim.new(0, 16)
	cardPad.PaddingBottom = UDim.new(0, 16)
	cardPad.PaddingLeft = UDim.new(0, 20)
	cardPad.PaddingRight = UDim.new(0, 20)
	cardPad.Parent = card
	local accent = makeFrame(UDim2.new(0, 3, 0.65, 0), UDim2.new(0, 0, 0.5, 0), C.gold, 0, 23, card)
	accent.AnchorPoint = Vector2.new(0, 0.5)
	local inner = makeFrame(UDim2.new(1, -18, 0, 0), UDim2.new(0, 18, 0, 0), C.bg, 1, 23, card)
	inner.AutomaticSize = Enum.AutomaticSize.Y
	local innerList = Instance.new("UIListLayout")
	innerList.FillDirection = Enum.FillDirection.Vertical
	innerList.SortOrder = Enum.SortOrder.LayoutOrder
	innerList.Padding = UDim.new(0, 8)
	innerList.Parent = inner
	local numLabel = makeLabel(num, Enum.Font.GothamBlack, 24, C.gold, 0.25, Enum.TextXAlignment.Left, 24, inner)
	numLabel.Size = UDim2.new(1, 0, 0, 28)
	numLabel.LayoutOrder = 1
	local titleLabel = makeLabel(title, Enum.Font.GothamBold, 15, C.white, 0, Enum.TextXAlignment.Left, 24, inner)
	titleLabel.Size = UDim2.new(1, 0, 0, 20)
	titleLabel.LayoutOrder = 2
	for i, line in ipairs(lines) do
		local bl = makeLabel(line, Enum.Font.Gotham, 13, Color3.fromRGB(170, 185, 210), 0.08, Enum.TextXAlignment.Left, 24, inner)
		bl.Size = UDim2.new(1, 0, 0, 18)
		bl.LayoutOrder = 2 + i
	end
	if chips then
		local chipRow = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.bg, 1, 24, inner)
		chipRow.AutomaticSize = Enum.AutomaticSize.Y
		chipRow.LayoutOrder = 6
		local chipList = Instance.new("UIListLayout")
		chipList.FillDirection = Enum.FillDirection.Horizontal
		chipList.SortOrder = Enum.SortOrder.LayoutOrder
		chipList.Padding = UDim.new(0, 8)
		chipList.Parent = chipRow
		for _, chipText in ipairs(chips) do
			makeChip(chipRow, chipText)
		end
	end
	return card
end

local howCard1 = makeHowCard(1, "01", "THE OBJECTIVE", {
	"Light the braziers in the correct order.",
	"Steal the idol from the vault.",
	"Extract before the 8 minute timer ends.",
}, nil)
local howCard2 = makeHowCard(2, "02", "THE BRAZIERS", {
	"Press F near a brazier to light it.",
	"All 4 must be lit in the right sequence.",
	"Wrong order resets your progress.",
}, {"[F]  Light / Extinguish", "[Guardian] Extinguish yours"})
local howCard3 = makeHowCard(3, "03", "THE GUARDIAN", {
	"Hunt thieves across the temple.",
	"Press E to catch a thief.",
	"Press F to extinguish braziers.",
}, {"[E]  Catch", "[F]  Extinguish", "[Shift]  Sprint"})

local _, _, _, _, _ = makeOverlayFooter(howOverlay)

local creditsTitle = makeLabel("CREDITS", Enum.Font.GothamBlack, 32, C.white, 0, Enum.TextXAlignment.Center, 22, creditsOverlay)
creditsTitle.AnchorPoint = Vector2.new(0.5, 0)
creditsTitle.Position = UDim2.new(0.5, 0, 0, 44)
creditsTitle.Size = UDim2.fromOffset(500, 40)
local creditsSubtitle = makeLabel("The team behind Lifted", Enum.Font.Gotham, 13, Color3.fromRGB(160, 175, 200), 0.2, Enum.TextXAlignment.Center, 22, creditsOverlay)
creditsSubtitle.AnchorPoint = Vector2.new(0.5, 0)
creditsSubtitle.Position = UDim2.new(0.5, 0, 0, 82)
creditsSubtitle.Size = UDim2.fromOffset(500, 20)
local creditsTitleDivider = makeFrame(UDim2.fromOffset(200, 1), UDim2.new(0.5, 0, 0, 108), C.gold, 0.7, 22, creditsOverlay)
creditsTitleDivider.AnchorPoint = Vector2.new(0.5, 0)

creditsContent.Size = UDim2.fromOffset(740, 0)
creditsContent.AnchorPoint = Vector2.new(0.5, 0)
creditsContent.Position = UDim2.new(0.5, 0, 0, 130)
creditsContent.BackgroundTransparency = 1
local creditsList = Instance.new("UIListLayout")
creditsList.Padding = UDim.new(0, 14)
creditsList.SortOrder = Enum.SortOrder.LayoutOrder
creditsList.Parent = creditsContent

local devRow = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.bg, 1, 22, creditsContent)
devRow.LayoutOrder = 1
devRow.AutomaticSize = Enum.AutomaticSize.Y
local devRowList = Instance.new("UIListLayout")
devRowList.FillDirection = Enum.FillDirection.Horizontal
devRowList.SortOrder = Enum.SortOrder.LayoutOrder
devRowList.Padding = UDim.new(0, 14)
devRowList.Parent = devRow

local function makeCreditsCard(order, name, role, roleColor, skills, dotColor)
	local card = makeFrame(UDim2.new(0.5, -7, 0, 0), UDim2.fromOffset(0, 0), Color3.fromRGB(10, 12, 20), 0.55, 23, devRow)
	card.LayoutOrder = order
	card.AutomaticSize = Enum.AutomaticSize.Y
	makeCorner(10, card)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.gold
	stroke.Thickness = 0.5
	stroke.Transparency = 0.82
	stroke.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 20)
	pad.PaddingBottom = UDim.new(0, 20)
	pad.PaddingLeft = UDim.new(0, 20)
	pad.PaddingRight = UDim.new(0, 20)
	pad.Parent = card
	local accent = makeFrame(UDim2.new(0, 3, 0.65, 0), UDim2.new(0, 0, 0.5, 0), C.gold, 0, 24, card)
	accent.AnchorPoint = Vector2.new(0, 0.5)
	local inner = makeFrame(UDim2.new(1, -18, 0, 0), UDim2.new(0, 18, 0, 0), C.bg, 1, 24, card)
	inner.AutomaticSize = Enum.AutomaticSize.Y
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = inner
	local dot = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(1, 0, 0, 0), dotColor, 0, 25, inner)
	dot.AnchorPoint = Vector2.new(1, 0)
	makeCorner(99, dot)
	local nm = makeLabel(name, Enum.Font.GothamBlack, 16, C.white, 0, Enum.TextXAlignment.Left, 25, inner)
	nm.Size = UDim2.new(1, 0, 0, 20)
	local rl = makeLabel(role, Enum.Font.GothamBold, 12, roleColor, 0.1, Enum.TextXAlignment.Left, 25, inner)
	rl.Size = UDim2.new(1, 0, 0, 18)
	local sk = makeLabel(skills, Enum.Font.Gotham, 12, Color3.fromRGB(160, 175, 200), 0.1, Enum.TextXAlignment.Left, 25, inner)
	sk.Size = UDim2.new(1, 0, 0, 0)
	sk.AutomaticSize = Enum.AutomaticSize.Y
	sk.TextWrapped = true
	return card
end

local creditsCard1 = makeCreditsCard(1, "IMPLECTE2", "Lead Developer & Game Designer", C.gold, "Systems · Networking · UI · Game Logic", C.gold)
local creditsCard2 = makeCreditsCard(2, "SHOTSON_YOU", "World Builder & Visual Designer", C.blue, "Map Design · Lighting · Environment Art", C.blue)

local statusCard = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), Color3.fromRGB(10, 12, 20), 0.55, 22, creditsContent)
statusCard.LayoutOrder = 2
statusCard.AutomaticSize = Enum.AutomaticSize.Y
makeCorner(10, statusCard)
local statusStroke = Instance.new("UIStroke")
statusStroke.Color = C.gold
statusStroke.Thickness = 0.5
statusStroke.Transparency = 0.82
statusStroke.Parent = statusCard
local statusPad = Instance.new("UIPadding")
statusPad.PaddingTop = UDim.new(0, 20)
statusPad.PaddingBottom = UDim.new(0, 20)
statusPad.PaddingLeft = UDim.new(0, 20)
statusPad.PaddingRight = UDim.new(0, 20)
statusPad.Parent = statusCard
local statusAccent = makeFrame(UDim2.new(0, 3, 0.65, 0), UDim2.new(0, 0, 0.5, 0), C.gold, 0, 23, statusCard)
statusAccent.AnchorPoint = Vector2.new(0, 0.5)
local statusInner = makeFrame(UDim2.new(1, -18, 0, 0), UDim2.new(0, 18, 0, 0), C.bg, 1, 23, statusCard)
statusInner.AutomaticSize = Enum.AutomaticSize.Y
local statusList = Instance.new("UIListLayout")
statusList.FillDirection = Enum.FillDirection.Vertical
statusList.SortOrder = Enum.SortOrder.LayoutOrder
statusList.Padding = UDim.new(0, 10)
statusList.Parent = statusInner
local statusMicro = makeLabel("PROJECT STATUS", Enum.Font.GothamBold, 10, C.gold, 0.45, Enum.TextXAlignment.Left, 24, statusInner)
statusMicro.Size = UDim2.new(1, 0, 0, 14)
local statusDivider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.82, 24, statusInner)
local statusRow = makeFrame(UDim2.new(1, 0, 0, 50), UDim2.fromOffset(0, 0), C.bg, 1, 24, statusInner)
local statusRowList = Instance.new("UIListLayout")
statusRowList.FillDirection = Enum.FillDirection.Horizontal
statusRowList.HorizontalAlignment = Enum.HorizontalAlignment.Center
statusRowList.SortOrder = Enum.SortOrder.LayoutOrder
statusRowList.Parent = statusRow
local function makeStatusCol(title, subtitle, order)
	local col = makeFrame(UDim2.new(1/3, 0, 1, 0), UDim2.fromOffset(0, 0), C.bg, 1, 24, statusRow)
	col.LayoutOrder = order
	local top = makeLabel(title, Enum.Font.GothamBold, 13, C.white, 0, Enum.TextXAlignment.Center, 25, col)
	top.Size = UDim2.new(1, 0, 0, 24)
	top.Position = UDim2.new(0, 0, 0, 4)
	local bot = makeLabel(subtitle, Enum.Font.Gotham, 11, Color3.fromRGB(160, 175, 200), 0.2, Enum.TextXAlignment.Center, 25, col)
	bot.Size = UDim2.new(1, 0, 0, 18)
	bot.Position = UDim2.new(0, 0, 0, 28)
end
makeStatusCol("CORE SYSTEMS", "Complete", 1)
makeStatusCol("MAP", "In Development", 2)
makeStatusCol("TESTING", "Coming Soon", 3)
local v1 = makeFrame(UDim2.new(0, 1, 0, 30), UDim2.new(1/3, 0, 0.5, 0), C.gold, 0.88, 25, statusRow)
v1.AnchorPoint = Vector2.new(0.5, 0.5)
local v2 = makeFrame(UDim2.new(0, 1, 0, 30), UDim2.new(2/3, 0, 0.5, 0), C.gold, 0.88, 25, statusRow)
v2.AnchorPoint = Vector2.new(0.5, 0.5)

local seasonStrip = makeFrame(UDim2.new(1, 0, 0, 48), UDim2.fromOffset(0, 0), Color3.fromRGB(10, 12, 20), 0.6, 22, creditsContent)
seasonStrip.LayoutOrder = 3
makeCorner(10, seasonStrip)
local stripStroke = Instance.new("UIStroke")
stripStroke.Color = C.gold
stripStroke.Thickness = 0.5
stripStroke.Transparency = 0.82
stripStroke.Parent = seasonStrip
local stripPad = Instance.new("UIPadding")
stripPad.PaddingLeft = UDim.new(0, 20)
stripPad.PaddingRight = UDim.new(0, 20)
stripPad.Parent = seasonStrip
local stripLeft = makeLabel("SEASON 1", Enum.Font.GothamBlack, 13, C.gold, 0.1, Enum.TextXAlignment.Left, 23, seasonStrip)
stripLeft.Size = UDim2.new(0, 140, 1, 0)
local stripCenter = makeLabel("THE CURSED TEMPLE", Enum.Font.GothamBold, 12, Color3.fromRGB(200, 215, 235), 0.15, Enum.TextXAlignment.Center, 23, seasonStrip)
stripCenter.AnchorPoint = Vector2.new(0.5, 0.5)
stripCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
stripCenter.Size = UDim2.fromOffset(220, 18)
local stripRight = makeLabel("EARLY ACCESS", Enum.Font.GothamBold, 11, Color3.fromRGB(130, 145, 165), 0.3, Enum.TextXAlignment.Right, 23, seasonStrip)
stripRight.AnchorPoint = Vector2.new(1, 0.5)
stripRight.Position = UDim2.new(1, 0, 0.5, 0)
stripRight.Size = UDim2.fromOffset(140, 18)

local _, _, _, _, _ = makeOverlayFooter(creditsOverlay)

local function fadeOverlayCard(card, key, targetTransparency)
	playTween(key .. "_bg", card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = targetTransparency})
	for _, d in ipairs(card:GetDescendants()) do
		if d:IsA("TextLabel") then
			playTween(key .. "_txt_" .. d:GetDebugId(), d, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
		elseif d:IsA("UIStroke") then
			playTween(key .. "_stroke_" .. d:GetDebugId(), d, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.82})
		end
	end
end

local function setOverlayCardsHidden(cards)
	for _, card in ipairs(cards) do
		card.BackgroundTransparency = 1
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("TextLabel") then
				d.TextTransparency = 1
			elseif d:IsA("UIStroke") then
				d.Transparency = 1
			elseif d:IsA("Frame") and d ~= card then
				d.BackgroundTransparency = 1
			end
		end
	end
end

local howCards = {howCard1, howCard2, howCard3}
local creditsCards = {creditsCard1, creditsCard2, statusCard, seasonStrip}

local function animateHowOverlayCards()
	setOverlayCardsHidden(howCards)
	task.delay(0.00, function() fadeOverlayCard(howCard1, "how_card1", 0.55) end)
	task.delay(0.08, function() fadeOverlayCard(howCard2, "how_card2", 0.55) end)
	task.delay(0.16, function() fadeOverlayCard(howCard3, "how_card3", 0.55) end)
end

local function animateCreditsOverlayCards()
	setOverlayCardsHidden(creditsCards)
	task.delay(0.00, function() fadeOverlayCard(creditsCard1, "cr_card1", 0.55) end)
	task.delay(0.08, function() fadeOverlayCard(creditsCard2, "cr_card2", 0.55) end)
	task.delay(0.20, function() fadeOverlayCard(statusCard, "cr_status", 0.55) end)
	task.delay(0.28, function() fadeOverlayCard(seasonStrip, "cr_strip", 0.6) end)
end

local function openOverlay(overlay)
	task.delay(0.05, function()
		if overlay.Visible then
			menuScreen.Active = false
		end
	end)
	overlay.Visible = true
	overlay.Position = UDim2.new(1, 0, 0, 0)
	playTween("open_" .. overlay.Name, overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	})
	task.delay(0.31, function()
		if not overlay.Visible then
			return
		end
		if overlay == howOverlay then
			animateHowOverlayCards()
		elseif overlay == creditsOverlay then
			animateCreditsOverlayCards()
		end
	end)
end

local function closeOverlay(overlay)
	playTween("close_" .. overlay.Name, overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 0, 0, 0),
	})
	task.delay(0.26, function()
		overlay.Visible = false
		menuScreen.Active = true
	end)
end

howBackBtn.Activated:Connect(function()
	closeOverlay(howOverlay)
end)
creditsBackBtn.Activated:Connect(function()
	closeOverlay(creditsOverlay)
end)

local function menuEntrance()
	wordmark.TextTransparency = 1
	seasonLabel.TextTransparency = 1
	tagLabel.TextTransparency = 1
	asymLabel.TextTransparency = 1
	dividerLine.BackgroundTransparency = 1
	navTitle.TextTransparency = 1
	footerLeft.TextTransparency = 1
	footerCenter.TextTransparency = 1
	footerRight.TextTransparency = 1
	footerLine.BackgroundTransparency = 1
	navTopSep.BackgroundTransparency = 1
	navBottomSep.BackgroundTransparency = 1
	onlineDot.BackgroundTransparency = 1
	centerSeparator.BackgroundTransparency = 1
	infoPanelLabel.TextTransparency = 1
	infoDivider.BackgroundTransparency = 1
	infoSecondaryLabel.TextTransparency = 1
	infoSecondaryDivider.BackgroundTransparency = 1
	infoBacking.BackgroundTransparency = 1
	infoTopBorder.BackgroundTransparency = 1
	infoBottomBorder.BackgroundTransparency = 1
	for _, ln in ipairs(infoMainLines) do
		ln.TextTransparency = 1
	end
	for _, ln in ipairs(infoSecondaryLines) do
		ln.TextTransparency = 1
	end
	for _, cf in ipairs(cornerFrames) do
		cf.BackgroundTransparency = 1
	end

	playTween("left_wordmark_in", wordmark, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0})
	task.delay(0.1, function()
		playTween("left_season_in", seasonLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0.35})
		playTween("left_div_in", dividerLine, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.55})
	end)
	task.delay(0.15, function()
		playTween("left_tag_in", tagLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0.18})
		playTween("left_asym_in", asymLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0.55})
	end)
	task.delay(0.2, function()
		playTween("nav_title_in", navTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.5})
		playTween("nav_top_sep_in", navTopSep, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.88})
	end)

	for i, key in ipairs({"findmatch", "howtoplay", "credits"}) do
		local ref = optionRefs[key]
		ref.title.TextTransparency = 1
		ref.subtitle.TextTransparency = 1
		ref.num.TextTransparency = 1
		ref.arrow.TextTransparency = 1
		ref.sep.BackgroundTransparency = 1
		ref.accent.BackgroundTransparency = 1
		ref.fill.BackgroundTransparency = 1
		task.delay(0.25 + (i - 1) * 0.07, function()
			playTween(key .. "_title_in", ref.title, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
			playTween(key .. "_sub_in", ref.subtitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
			playTween(key .. "_num_in", ref.num, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.45})
			playTween(key .. "_arrow_in", ref.arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.65})
			playTween(key .. "_sep_in", ref.sep, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.88})
		end)
	end
	task.delay(0.35, function()
		playTween("center_sep_in", centerSeparator, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.85})
	end)
	task.delay(0.38, function()
		playTween("info_backing_in", infoBacking, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
		playTween("info_top_border_in", infoTopBorder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7})
		playTween("info_bottom_border_in", infoBottomBorder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7})
		playTween("info_panel_lbl_in", infoPanelLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
		playTween("info_panel_div_in", infoDivider, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.82})
		playTween("info_panel_slbl_in", infoSecondaryLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.2})
		playTween("info_panel_sdiv_in", infoSecondaryDivider, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.88})
		for i, ln in ipairs(infoMainLines) do
			playTween("info_panel_mln_in_" .. i, ln, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.05})
		end
		for i, ln in ipairs(infoSecondaryLines) do
			playTween("info_panel_sln_in_" .. i, ln, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.08})
		end
	end)
	task.delay(0.45, function()
		playTween("bottom_line_in", footerLine, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.88})
		playTween("bottom_left_in", footerLeft, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4})
		playTween("bottom_center_in", footerCenter, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4})
		playTween("bottom_right_in", footerRight, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4})
		playTween("bottom_dot_in", onlineDot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.4})
	end)
	task.delay(0.48, function()
		for i, cf in ipairs(cornerFrames) do
			playTween("corner_in_" .. i, cf, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.65})
		end
	end)
	task.delay(0.5, function()
		applyRowStyle("findmatch")
		updateInfoPanel("findmatch")
		task.spawn(function()
			local up = false
			while gui.Enabled and menuScreen.Visible do
				if up then
					local t = TweenService:Create(wordmark, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0.04})
					t:Play()
					t.Completed:Wait()
				else
					local t = TweenService:Create(wordmark, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0})
					t:Play()
					t.Completed:Wait()
				end
				up = not up
			end
		end)
	end)
end

local function transitionSplashToMenu()
	playTween("overlay_in", transitionOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 0,
	})
	task.delay(0.3, function()
		splashScreen.Visible = false
		menuScreen.Visible = true
		playTween("overlay_out", transitionOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		task.delay(0.35, function()
			menuEntrance()
		end)
	end)
end

clickAnywhere.Activated:Connect(function()
	transitionSplashToMenu()
end)

findMatchBtn.Activated:Connect(function()
	applyRowStyle("findmatch")
	updateInfoPanel("findmatch")
	playClickedBindable:Fire()
	playTween("menu_hide", menuScreen, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	playTween("bg_hide", bg, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	TweenService:Create(menuMusic, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Volume = 0}):Play()
	task.delay(0.3, function()
		if gui.Parent then
			gui.Enabled = false
		end
	end)
end)

howToBtn.Activated:Connect(function()
	applyRowStyle("howtoplay")
	updateInfoPanel("howtoplay")
	openOverlay(howOverlay)
end)

creditsBtn.Activated:Connect(function()
	applyRowStyle("credits")
	updateInfoPanel("credits")
	openOverlay(creditsOverlay)
end)

-- Splash entrance
splashContainer.Position = UDim2.new(0.5, 0, 0.5, 30)
logoLabel.TextTransparency = 1
taglineLabel.TextTransparency = 1
lineL.BackgroundTransparency = 1
lineR.BackgroundTransparency = 1
for _, d in ipairs(diamonds) do
	d.BackgroundTransparency = 1
end
playLabel.TextTransparency = 1

task.delay(0.2, function()
	playTween("splash_logo", logoLabel, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0})
	playTween("splash_container", splashContainer, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)})

	task.delay(0.15, function()
		playTween("splash_tag", taglineLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.35})
	end)

	task.delay(0.25, function()
		playTween("orn_l", lineL, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.55})
		playTween("orn_r", lineR, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.55})
		for i, d in ipairs(diamonds) do
			playTween("orn_d_" .. i, d, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.55})
		end
	end)

	task.delay(0.4, function()
		playTween("play_label_default", playLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.2})
	end)

	task.delay(0.82, function()
		task.spawn(function()
			local up = true
			while gui.Enabled and splashScreen.Visible do
				if up then
					local t = TweenService:Create(logoScale, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = 1.008})
					t:Play()
					t.Completed:Wait()
				else
					local t = TweenService:Create(logoScale, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = 1.0})
					t:Play()
					t.Completed:Wait()
				end
				up = not up
			end
		end)

		task.spawn(function()
			local up = false
			while gui.Enabled and splashScreen.Visible do
				if up then
					local t = TweenService:Create(playLabel, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0})
					t:Play()
					t.Completed:Wait()
				else
					local t = TweenService:Create(playLabel, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0.25})
					t:Play()
					t.Completed:Wait()
				end
				up = not up
			end
		end)
	end)
end)

-- Heartbeat: online dot pulse + scan line drift only
RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	onlineDot.BackgroundTransparency = 0.35 + math.sin(t * 3.2) * 0.15

	for _, s in ipairs(scanLines) do
		local p = s.frame.Position
		local ny = p.Y.Scale + s.speed * dt
		if ny > 1 then
			ny = 0
		end
		s.frame.Position = UDim2.new(0, 0, ny, 0)
	end
end)

roleAssignedRemote.OnClientEvent:Connect(function()
	playTween("full_fade_bg", bg, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	playTween("full_fade_splash", splashScreen, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	playTween("full_fade_menu", menuScreen, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	playTween("full_fade_overlay", transitionOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
	TweenService:Create(menuMusic, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Volume = 0}):Play()
	task.delay(0.3, function()
		if gui.Parent then
			gui.Enabled = false
		end
	end)
end)
