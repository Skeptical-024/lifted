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

local playButton = Instance.new("TextButton")
playButton.AutoButtonColor = false
playButton.BackgroundTransparency = 1
playButton.BorderSizePixel = 0
playButton.Size = UDim2.fromOffset(200, 44)
playButton.Text = ""
playButton.ZIndex = 12
playButton.LayoutOrder = 4
playButton.Parent = splashContainer
makeCorner(4, playButton)

local playStroke = Instance.new("UIStroke")
playStroke.Color = C.gold
playStroke.Thickness = 1
playStroke.Transparency = 1
playStroke.Parent = playButton

local playLabel = makeLabel("PRESS TO PLAY", Enum.Font.GothamBold, 12, C.gold, 1, Enum.TextXAlignment.Center, 13, playButton)
playLabel.Size = UDim2.new(1, 0, 1, 0)
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

local identityZone = makeFrame(UDim2.fromOffset(800, 120), UDim2.new(0.5, 0, 0, 40), C.bg, 1, 11, menuScreen)
identityZone.AnchorPoint = Vector2.new(0.5, 0)
local identityLayout = Instance.new("UIListLayout")
identityLayout.FillDirection = Enum.FillDirection.Vertical
identityLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
identityLayout.SortOrder = Enum.SortOrder.LayoutOrder
identityLayout.Padding = UDim.new(0, 8)
identityLayout.Parent = identityZone

local wordmark = makeLabel("LIFTED", Enum.Font.GothamBlack, 72, C.titleColor, 0, Enum.TextXAlignment.Center, 12, identityZone)
wordmark.Size = UDim2.new(1, 0, 0, 80)
wordmark.LayoutOrder = 1

local dividerLine = makeFrame(UDim2.fromOffset(120, 1), UDim2.fromOffset(0, 0), C.gold, 0.6, 12, identityZone)
dividerLine.LayoutOrder = 2

local seasonLabel = makeLabel("SEASON 1 — THE CURSED TEMPLE", Enum.Font.GothamBold, 11, C.gold, 0.45, Enum.TextXAlignment.Center, 12, identityZone)
seasonLabel.Size = UDim2.new(1, 0, 0, 16)
seasonLabel.LayoutOrder = 3

local navZone = makeFrame(UDim2.fromOffset(420, 0), UDim2.new(0.5, 0, 1, -48), C.bg, 1, 11, menuScreen)
navZone.AnchorPoint = Vector2.new(0.5, 1)
navZone.AutomaticSize = Enum.AutomaticSize.Y
local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Vertical
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Padding = UDim.new(0, 0)
navLayout.Parent = navZone

local optionRefs = {}

local function makeOption(order, num, title, subtitle, key)
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Size = UDim2.fromOffset(420, 64)
	btn.Text = ""
	btn.ZIndex = 12
	btn.LayoutOrder = order
	btn.Position = UDim2.new(0, 0, 0, 0)

	local sepTop = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.92, 13, btn)

	local content = makeFrame(UDim2.new(1, 0, 0, 63), UDim2.new(0, 0, 0, 1), C.bg, 1, 13, btn)
	local numLabel = makeLabel(num, Enum.Font.GothamBlack, 11, C.gold, 0.4, Enum.TextXAlignment.Left, 14, content)
	numLabel.Size = UDim2.fromOffset(26, 16)
	numLabel.Position = UDim2.fromOffset(16, 24)

	local titleLabel = makeLabel(title, Enum.Font.GothamBlack, 20, C.titleColor, 0, Enum.TextXAlignment.Center, 14, content)
	titleLabel.Size = UDim2.new(1, -80, 0, 30)
	titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	titleLabel.Position = UDim2.new(0.5, 0, 0.5, 0)

	local subtitleLabel = makeLabel(subtitle, Enum.Font.Gotham, 1, C.textMuted, 1, Enum.TextXAlignment.Left, 14, content)
	subtitleLabel.Visible = false

	local arrowLabel = makeLabel("›", Enum.Font.GothamBold, 18, C.gold, 0.5, Enum.TextXAlignment.Center, 14, content)
	arrowLabel.Size = UDim2.fromOffset(20, 20)
	arrowLabel.AnchorPoint = Vector2.new(1, 0.5)
	arrowLabel.Position = UDim2.new(1, -16, 0.5, 0)

	btn.MouseEnter:Connect(function()
		playTween(key .. "_slide_in", btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 6, 0, 0)})
		playTween(key .. "_t_in", titleLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = C.gold})
		playTween(key .. "_r_in", arrowLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0, TextColor3 = C.gold})
		playTween(key .. "_n_in", numLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.1})
	end)

	btn.MouseLeave:Connect(function()
		playTween(key .. "_slide_out", btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
		playTween(key .. "_t_out", titleLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = C.titleColor})
		playTween(key .. "_r_out", arrowLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.5, TextColor3 = C.gold})
		playTween(key .. "_n_out", numLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4})
	end)

	btn.MouseButton1Down:Connect(function()
		playTween(key .. "_press", btn, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 4, 0, 0)})
	end)
	btn.MouseButton1Up:Connect(function()
		playTween(key .. "_rel", btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 8, 0, 0)})
	end)

	btn.Parent = navZone
	optionRefs[key] = {button = btn, sep = sepTop, title = titleLabel, subtitle = subtitleLabel, arrow = arrowLabel, num = numLabel}
	return btn
end

local findMatchBtn = makeOption(1, "01", "FIND MATCH", "Join a public match", "find")
local howToBtn = makeOption(2, "02", "HOW TO PLAY", "Rules and mechanics", "how")
local creditsBtn = makeOption(3, "03", "CREDITS", "The team behind Lifted", "credits")
local navBottomLine = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.fromOffset(0, 0), C.gold, 0.92, 13, navZone)
navBottomLine.LayoutOrder = 4

local bottomBar = makeFrame(UDim2.fromOffset(500, 20), UDim2.new(0.5, 0, 1, -12), C.bg, 1, 12, menuScreen)
bottomBar.AnchorPoint = Vector2.new(0.5, 1)
local onlineDot = makeFrame(UDim2.fromOffset(5, 5), UDim2.new(0, 0, 0.5, 0), C.blue, 0, 13, bottomBar)
onlineDot.AnchorPoint = Vector2.new(0, 0.5)
makeCorner(99, onlineDot)
local onlineLabel = makeLabel("0 PLAYERS ONLINE", Enum.Font.Gotham, 11, Color3.fromRGB(150, 150, 170), 0, Enum.TextXAlignment.Left, 13, bottomBar)
onlineLabel.Size = UDim2.new(0, 180, 1, 0)
onlineLabel.Position = UDim2.fromOffset(10, 0)
local versionLabel = makeLabel("v0.1.0 · Early Access", Enum.Font.Gotham, 11, Color3.fromRGB(100, 100, 120), 0, Enum.TextXAlignment.Right, 13, bottomBar)
versionLabel.Size = UDim2.new(0, 220, 1, 0)
versionLabel.Position = UDim2.new(1, -220, 0, 0)

-- Overlays
local function makeOverlay(name, titleText)
	local overlay = makeFrame(UDim2.fromScale(1, 1), UDim2.new(1, 0, 0, 0), C.bg, 0, 20, gui)
	overlay.Visible = false
	overlay.Name = name

	local backBtn = Instance.new("TextButton")
	backBtn.AutoButtonColor = false
	backBtn.BackgroundColor3 = Color3.fromRGB(10, 11, 18)
	backBtn.BackgroundTransparency = 0.3
	backBtn.BorderSizePixel = 0
	backBtn.Size = UDim2.fromOffset(120, 36)
	backBtn.Position = UDim2.new(0, 32, 0, 48)
	backBtn.Text = ""
	backBtn.ZIndex = 25
	makeCorner(6, backBtn)

	local backLabel = makeLabel("← BACK", Enum.Font.GothamBold, 13, C.gold, 0, Enum.TextXAlignment.Left, 22, backBtn)
	backLabel.Size = UDim2.new(1, 0, 1, 0)
	backLabel.TextTransparency = 0

	backBtn.Parent = overlay

	local title = makeLabel(titleText, Enum.Font.GothamBlack, 32, C.white, 0, Enum.TextXAlignment.Center, 21, overlay)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Size = UDim2.fromOffset(700, 40)
	title.Position = UDim2.new(0.5, 0, 0, 50)

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

local function makeRuleCard(parent, order, num, title, body)
	local card = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.cardMuted, 0, 22, parent)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.LayoutOrder = order
	makeCorner(10, card)
	local accent = makeFrame(UDim2.new(0, 3, 1, 0), UDim2.new(0, 0, 0, 0), C.gold, 0, 23, card)
	makeCorner(4, accent)

	local inner = makeFrame(UDim2.new(1, -18, 0, 0), UDim2.new(0, 18, 0, 0), C.bg, 1, 23, card)
	inner.AutomaticSize = Enum.AutomaticSize.Y

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 16)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.Parent = inner

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = inner

	local n = makeLabel(num, Enum.Font.GothamBlack, 28, C.gold, 0.25, Enum.TextXAlignment.Left, 23, inner)
	n.LayoutOrder = 1
	n.Size = UDim2.new(1, 0, 0, 32)

	local t = makeLabel(title, Enum.Font.GothamBold, 14, C.white, 0, Enum.TextXAlignment.Left, 23, inner)
	t.LayoutOrder = 2
	t.Size = UDim2.new(1, 0, 0, 20)

	local b = makeLabel(body, Enum.Font.Gotham, 12, C.textMuted, 0, Enum.TextXAlignment.Left, 23, inner)
	b.LayoutOrder = 3
	b.Size = UDim2.new(1, 0, 0, 0)
	b.TextWrapped = true
	b.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = parent
end

local howList = Instance.new("UIListLayout")
howList.Padding = UDim.new(0, 20)
howList.SortOrder = Enum.SortOrder.LayoutOrder
howList.Parent = howContent

makeRuleCard(howContent, 1, "01", "THE OBJECTIVE", "4 thieves infiltrate the cursed temple, solve the brazier puzzle, steal the golden idol, and extract before the timer expires.")
makeRuleCard(howContent, 2, "02", "THE BRAZIER PUZZLE", "Press F near a brazier to light it. All 4 must be lit in sequence. Wrong order resets your progress. The guardian can extinguish lit braziers.")
makeRuleCard(howContent, 3, "03", "THE GUARDIAN", "Hunt the thieves. Press E to catch them. Press F to extinguish braziers. Sprint with Shift — 10 second cooldown.")

local creditsList = Instance.new("UIListLayout")
creditsList.Padding = UDim.new(0, 10)
creditsList.SortOrder = Enum.SortOrder.LayoutOrder
creditsList.Parent = creditsContent

local devRow = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.bg, 1, 22, creditsContent)
devRow.LayoutOrder = 1
devRow.AutomaticSize = Enum.AutomaticSize.Y
local devRowList = Instance.new("UIListLayout")
devRowList.FillDirection = Enum.FillDirection.Horizontal
devRowList.Padding = UDim.new(0, 10)
devRowList.Parent = devRow

local function makeDevCard(parent, order, name, role, roleColor, detail, note)
	local card = makeFrame(UDim2.new(0.5, -15, 0, 0), UDim2.fromOffset(0, 0), C.cardMuted, 0, 23, parent)
	card.LayoutOrder = order
	card.AutomaticSize = Enum.AutomaticSize.Y
	makeCorner(10, card)

	local accentBar = makeFrame(UDim2.new(0, 3, 1, 0), UDim2.new(0, 0, 0, 0), C.gold, 0, 13, card)
	makeCorner(4, accentBar)

	local innerContent = makeFrame(UDim2.new(1, -26, 0, 0), UDim2.new(0, 18, 0, 14), C.cardMuted, 1, 13, card)
	innerContent.AutomaticSize = Enum.AutomaticSize.Y
	local innerList = Instance.new("UIListLayout")
	innerList.FillDirection = Enum.FillDirection.Vertical
	innerList.SortOrder = Enum.SortOrder.LayoutOrder
	innerList.Padding = UDim.new(0, 4)
	innerList.Parent = innerContent
	local innerPad = Instance.new("UIPadding")
	innerPad.PaddingBottom = UDim.new(0, 14)
	innerPad.Parent = innerContent

	local n = makeLabel(name, Enum.Font.GothamBlack, 15, C.white, 0, Enum.TextXAlignment.Left, 13, innerContent)
	n.Size = UDim2.new(1, 0, 0, 20)
	n.LayoutOrder = 1
	local r = makeLabel(role, Enum.Font.GothamBold, 12, roleColor, 0, Enum.TextXAlignment.Left, 13, innerContent)
	r.Size = UDim2.new(1, 0, 0, 18)
	r.LayoutOrder = 2
	local d = makeLabel(detail, Enum.Font.Gotham, 11, C.textMuted, 0, Enum.TextXAlignment.Left, 13, innerContent)
	d.Size = UDim2.new(1, 0, 0, 0)
	d.AutomaticSize = Enum.AutomaticSize.Y
	d.TextWrapped = true
	d.LayoutOrder = 3
	if note then
		local nt = makeLabel(note, Enum.Font.Gotham, 11, C.textDim, 0, Enum.TextXAlignment.Left, 13, innerContent)
		nt.Size = UDim2.new(1, 0, 0, 16)
		nt.LayoutOrder = 4
	end
end

makeDevCard(devRow, 1, "IMPLECTE2", "Lead Developer & Game Designer", C.gold, "Core systems · Networking · Game logic · UI", "16 y/o indie developer")
makeDevCard(devRow, 2, "SHOTSON_YOU", "World Builder & Visual Designer", C.blue, "Map design · Lighting · Asset pipeline", nil)

local statsRow = makeFrame(UDim2.new(1, 0, 0, 66), UDim2.fromOffset(0, 0), C.cardMuted, 0, 22, creditsContent)
statsRow.LayoutOrder = 2
makeCorner(10, statsRow)
local statsList = Instance.new("UIListLayout")
statsList.FillDirection = Enum.FillDirection.Horizontal
statsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
statsList.VerticalAlignment = Enum.VerticalAlignment.Center
statsList.Parent = statsRow
for _, text in ipairs({"MAPS: 1", "MODES: 1", "SEASON: 1"}) do
	local col = makeFrame(UDim2.new(1/3, -4, 1, 0), UDim2.fromOffset(0, 0), C.cardMuted, 1, 23, statsRow)
	local lbl = makeLabel(text, Enum.Font.GothamBold, 13, C.gold, 0, Enum.TextXAlignment.Center, 24, col)
	lbl.Size = UDim2.new(1, 0, 1, 0)
end

local function openOverlay(overlay)
	menuScreen.Active = false
	overlay.Visible = true
	overlay.Position = UDim2.new(1, 0, 0, 0)
	playTween("open_" .. overlay.Name, overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	})
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
	dividerLine.BackgroundTransparency = 1
	versionLabel.TextTransparency = 1
	onlineLabel.TextTransparency = 1
	playTween("left_wordmark_in", wordmark, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0})
	task.delay(0.1, function()
		playTween("left_season_in", seasonLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0.45})
		playTween("left_div_in", dividerLine, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.6})
	end)

	for i, key in ipairs({"find", "how", "credits"}) do
		local ref = optionRefs[key]
		ref.title.TextTransparency = 1
		ref.num.TextTransparency = 1
		ref.arrow.TextTransparency = 1
		task.delay(0.15 + (i - 1) * 0.07, function()
			playTween(key .. "_title_in", ref.title, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
			playTween(key .. "_num_in", ref.num, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4})
			playTween(key .. "_arrow_in", ref.arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.5})
		end)
	end
	task.delay(0.35, function()
		playTween("bottom_ver_in", versionLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
		playTween("bottom_online_in", onlineLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
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

playButton.MouseEnter:Connect(function()
	playTween("play_stroke_in", playStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.1})
	playTween("play_label_in", playLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
end)

playButton.MouseLeave:Connect(function()
	playTween("play_stroke_out", playStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.5})
	playTween("play_label_out", playLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.2})
end)

playButton.MouseButton1Down:Connect(function()
	playTween("play_btn_press", playButton, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(194, 42)})
end)
playButton.MouseButton1Up:Connect(function()
	playTween("play_btn_release", playButton, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(200, 44)})
end)

playButton.Activated:Connect(function()
	transitionSplashToMenu()
end)

findMatchBtn.Activated:Connect(function()
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
	openOverlay(howOverlay)
end)

creditsBtn.Activated:Connect(function()
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
playStroke.Transparency = 1
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
		playTween("play_stroke_default", playStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.5})
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
	onlineDot.BackgroundTransparency = 0.15 + (math.sin(t * 3.2) * 0.2 + 0.2)

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
