-- MainMenuClient v5

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local C = {
	bg = Color3.fromRGB(5, 7, 14),
	bgDeep = Color3.fromRGB(3, 4, 8),
	panel = Color3.fromRGB(9, 13, 22),
	panelLight = Color3.fromRGB(14, 20, 34),
	card = Color3.fromRGB(11, 16, 28),
	cardLight = Color3.fromRGB(16, 22, 36),
	blue = Color3.fromRGB(50, 130, 220),
	blueDim = Color3.fromRGB(30, 80, 150),
	blueGlow = Color3.fromRGB(80, 160, 255),
	gold = Color3.fromRGB(200, 160, 50),
	goldBright = Color3.fromRGB(225, 185, 75),
	goldDim = Color3.fromRGB(130, 100, 30),
	silver = Color3.fromRGB(220, 225, 235),
	silverDim = Color3.fromRGB(160, 168, 182),
	grey = Color3.fromRGB(110, 118, 135),
	greyDark = Color3.fromRGB(60, 68, 82),
	black = Color3.fromRGB(3, 4, 8),
	white = Color3.fromRGB(240, 242, 248),
}

local function makeFrame(size, pos, color, alpha, parent)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color
	f.BackgroundTransparency = alpha
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function makeCorner(r, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	return c
end

local function makeStroke(color, alpha, thickness, parent)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Transparency = alpha
	s.Thickness = thickness
	s.Parent = parent
	return s
end

local function makePadding(t, b, l, r, parent)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t)
	p.PaddingBottom = UDim.new(0, b)
	p.PaddingLeft = UDim.new(0, l)
	p.PaddingRight = UDim.new(0, r)
	p.Parent = parent
	return p
end

local function makeLabel(text, font, size, color, parent)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = font
	l.TextSize = size
	l.TextColor3 = color
	l.BorderSizePixel = 0
	l.Parent = parent
	return l
end

local function makeButton(size, pos, bg, bgAlpha, textColor, text, font, textSize, parent)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bg
	b.BackgroundTransparency = bgAlpha
	b.TextColor3 = textColor
	b.Text = text
	b.Font = font
	b.TextSize = textSize
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Parent = parent
	return b
end

local function tween(obj, dur, props, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local roleAssignedRemote = ReplicatedStorage:WaitForChild("RoleAssigned")

local playClickedBindable = ReplicatedStorage:FindFirstChild("PlayClicked")
if not playClickedBindable then
	playClickedBindable = Instance.new("BindableEvent")
	playClickedBindable.Name = "PlayClicked"
	playClickedBindable.Parent = ReplicatedStorage
end

local gui = Instance.new("ScreenGui")
gui.Name = "MainMenuUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local bg = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 0, gui)
bg.ZIndex = 1

local floor = makeFrame(UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 0, 0.5, 0), C.bgDeep, 0, gui)
floor.ZIndex = 2
local floorGrad = Instance.new("UIGradient")
floorGrad.Color = ColorSequence.new(Color3.fromRGB(8, 12, 20), C.bg)
floorGrad.Rotation = 90
floorGrad.Parent = floor

local ceiling = makeFrame(UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0, 0), C.bgDeep, 0, gui)
ceiling.ZIndex = 2
local ceilGrad = Instance.new("UIGradient")
ceilGrad.Color = ColorSequence.new(C.bgDeep, C.bg)
ceilGrad.Rotation = 90
ceilGrad.Parent = ceiling

local starsTable = {}
for i = 1, 60 do
	local bright = i <= 5
	local sz = bright and 3 or math.random(1, 3)
	local starColor = (i % 2 == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 210, 255)
	local baseA = bright and 0.2 or (math.random(30, 70) / 100)
	local star = makeFrame(UDim2.fromOffset(sz, sz), UDim2.new(math.random(), 0, math.random(), 0), starColor, baseA, gui)
	star.ZIndex = 3
	makeCorner(bright and 2 or 1, star)
	table.insert(starsTable, {
		frame = star,
		phase = math.random() * math.pi * 2,
		freq = bright and 0.4 or (math.random(3, 12) / 10),
		baseA = baseA,
	})
end

local function makePillar(xScale, width, color, alpha)
	local p = makeFrame(UDim2.fromOffset(width, 2200), UDim2.new(xScale, 0, 0.5, 0), color, alpha, gui)
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.ZIndex = 3
	makeStroke(Color3.fromRGB(30, 50, 90), 0.7, 1, p)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 24, 40)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 18, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 24, 40)),
	})
	g.Parent = p
	return p
end
makePillar(0.09, 65, Color3.fromRGB(12, 18, 30), 0.2)
makePillar(0.91, 65, Color3.fromRGB(12, 18, 30), 0.2)
local centerArch = makeFrame(UDim2.fromOffset(50, 2200), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(8, 12, 20), 0.5, gui)
centerArch.AnchorPoint = Vector2.new(0.5, 0.5)
centerArch.ZIndex = 3

local torchParts = {}
local function makeTorch(xScale)
	local root = makeFrame(UDim2.fromOffset(1, 1), UDim2.new(xScale, 0, 0.30, 0), C.blue, 1, gui)
	root.ZIndex = 4

	local mount = makeFrame(UDim2.fromOffset(6, 16), UDim2.new(0.5, -3, 0.5, -8), Color3.fromRGB(40, 55, 80), 0.3, root)
	mount.ZIndex = 4
	makeCorner(3, mount)
	local outer = makeFrame(UDim2.fromOffset(60, 80), UDim2.new(0.5, -30, 0.5, -40), Color3.fromRGB(30, 80, 180), 0.88, root)
	outer.ZIndex = 4
	makeCorner(40, outer)
	local mid = makeFrame(UDim2.fromOffset(36, 54), UDim2.new(0.5, -18, 0.5, -27), Color3.fromRGB(50, 120, 220), 0.72, root)
	mid.ZIndex = 5
	makeCorner(27, mid)
	local body = makeFrame(UDim2.fromOffset(18, 32), UDim2.new(0.5, -9, 0.5, -16), Color3.fromRGB(100, 160, 255), 0.35, root)
	body.ZIndex = 6
	makeCorner(14, body)
	local tip = makeFrame(UDim2.fromOffset(10, 18), UDim2.new(0.5, -5, 0.5, -9), Color3.fromRGB(180, 210, 255), 0.15, root)
	tip.ZIndex = 7
	makeCorner(8, tip)
	local core = makeFrame(UDim2.fromOffset(4, 4), UDim2.new(0.5, -2, 0.5, -2), Color3.fromRGB(220, 235, 255), 0, root)
	core.ZIndex = 8
	makeCorner(2, core)

	table.insert(torchParts, {
		phase = math.random() * math.pi * 2,
		outer = {frame = outer, w = 60, h = 80, baseA = 0.88},
		mid = {frame = mid, w = 36, h = 54, baseA = 0.72},
		body = {frame = body, w = 18, h = 32, baseA = 0.35},
		tip = {frame = tip, w = 10, h = 18, baseA = 0.15},
	})

	local pool1 = makeFrame(UDim2.fromOffset(160, 40), UDim2.new(xScale, -80, 1, -100), Color3.fromRGB(30, 70, 160), 0.91, gui)
	pool1.ZIndex = 3
	makeCorner(20, pool1)
	local pool2 = makeFrame(UDim2.fromOffset(100, 28), UDim2.new(xScale, -50, 1, -94), Color3.fromRGB(30, 70, 160), 0.94, gui)
	pool2.ZIndex = 3
	makeCorner(14, pool2)
end
makeTorch(0.095)
makeTorch(0.905)

local idolRoot = makeFrame(UDim2.fromOffset(1, 1), UDim2.new(0.5, 0, 0.5, 0), C.goldDim, 1, gui)
idolRoot.ZIndex = 4
local function idolPart(size, pos, color, alpha, z)
	local p = makeFrame(size, pos, color, alpha, idolRoot)
	p.ZIndex = z
	return p
end
idolPart(UDim2.fromOffset(60, 12), UDim2.new(0.5, -30, 0.72, 0), Color3.fromRGB(60, 45, 15), 0.68, 4)
idolPart(UDim2.fromOffset(28, 48), UDim2.new(0.5, -14, 0.52, 0), Color3.fromRGB(70, 52, 18), 0.65, 4)
idolPart(UDim2.fromOffset(42, 16), UDim2.new(0.5, -21, 0.445, 0), Color3.fromRGB(65, 50, 16), 0.68, 4)
idolPart(UDim2.fromOffset(24, 24), UDim2.new(0.5, -12, 0.365, 0), Color3.fromRGB(68, 52, 17), 0.65, 4)
idolPart(UDim2.fromOffset(18, 32), UDim2.new(0.5, -9, 0.27, 0), Color3.fromRGB(72, 55, 18), 0.62, 4)
local gem = idolPart(UDim2.fromOffset(8, 8), UDim2.new(0.5, -4, 0.225, 0), C.gold, 0.35, 5)
makeCorner(4, gem)

local idolGlowParts = {}
local function makeGlow(w, h, color, alpha, radius)
	local g = idolPart(UDim2.fromOffset(w, h), UDim2.new(0.5, -w / 2, 0.45, -h / 2), color, alpha, 3)
	makeCorner(radius, g)
	return g
end
idolGlowParts[1] = {frame = makeGlow(110, 180, Color3.fromRGB(160, 120, 20), 0.93, 55), w = 110, h = 180, baseA = 0.93}
idolGlowParts[2] = {frame = makeGlow(72, 124, Color3.fromRGB(180, 138, 25), 0.89, 36), w = 72, h = 124, baseA = 0.89}
idolGlowParts[3] = {frame = makeGlow(44, 80, Color3.fromRGB(200, 155, 30), 0.84, 22), w = 44, h = 80, baseA = 0.84}

local particles = {}
for _ = 1, 25 do
	local sz = math.random(2, 5)
	local mix = math.random()
	local col = Color3.new(
		(200 + (225 - 200) * mix) / 255,
		(160 + (185 - 160) * mix) / 255,
		(50 + (75 - 50) * mix) / 255
	)
	local p = makeFrame(UDim2.fromOffset(sz, sz), UDim2.new(math.random(), 0, math.random(), 0), col, math.random(50, 80) / 100, gui)
	p.ZIndex = 4
	makeCorner(sz, p)
	table.insert(particles, {
		frame = p,
		speed = math.random(6, 18),
		xDrift = (math.random(0, 1) == 1 and 1 or -1) * (math.random(3, 8) / 10),
		phase = math.random() * math.pi * 2,
		baseA = p.BackgroundTransparency,
	})
end

local stripes = {}
for i = 1, 8 do
	local x = (i - 1) * (1.15 / 7)
	local s = makeFrame(UDim2.fromOffset(140, 2000), UDim2.new(x, 0, 0.5, 0), C.white, 0.984, gui)
	s.AnchorPoint = Vector2.new(0.5, 0.5)
	s.Rotation = 110
	s.ZIndex = 8
	table.insert(stripes, s)
end

local laserLines = {}
for i = 1, 6 do
	local y = (i - 1) / 5
	local h = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, y, 0), C.blue, 0.94, gui)
	h.ZIndex = 9
	table.insert(laserLines, {frame = h, phase = i * 0.4, vertical = false})
end
for i = 1, 5 do
	local x = (i - 1) / 4
	local v = makeFrame(UDim2.new(0, 1, 1, 0), UDim2.new(x, 0, 0, 0), C.blue, 0.94, gui)
	v.ZIndex = 9
	table.insert(laserLines, {frame = v, phase = i * 0.5, vertical = true})
end

local scanLine = makeFrame(UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 0), C.blueGlow, 0.96, gui)
scanLine.ZIndex = 9
local scanProgress = 0

local function makeVignette(size, pos, rot)
	local v = makeFrame(size, pos, C.black, 0, gui)
	v.ZIndex = 10
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	g.Rotation = rot
	g.Parent = v
end
makeVignette(UDim2.new(1, 0, 0, 240), UDim2.new(0, 0, 0, 0), 90)
makeVignette(UDim2.new(1, 0, 0, 240), UDim2.new(0, 0, 1, -240), 270)
makeVignette(UDim2.new(0, 240, 1, 0), UDim2.new(0, 0, 0, 0), 0)
makeVignette(UDim2.new(0, 240, 1, 0), UDim2.new(1, -240, 0, 0), 180)

local overlay = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.fromRGB(4, 6, 12), 1, gui)
overlay.ZIndex = 11

local leftShown = UDim2.new(0.5, -500, 0.5, -300)
local leftHidden = UDim2.new(0.5, -760, 0.5, -300)
local rightShown = UDim2.new(0.5, 18, 0.5, -300)
local rightHidden = UDim2.new(0.5, 258, 0.5, -300)

local leftPanel = makeFrame(UDim2.fromOffset(460, 600), leftHidden, C.panel, 0.04, gui)
leftPanel.ZIndex = 20
makeCorner(16, leftPanel)
local leftStroke = makeStroke(C.gold, 0.6, 1, leftPanel)
makePadding(30, 30, 30, 30, leftPanel)

local rightPanel = makeFrame(UDim2.fromOffset(400, 600), rightHidden, C.panel, 0.04, gui)
rightPanel.ZIndex = 20
makeCorner(16, rightPanel)
makeStroke(C.silver, 0.88, 1, rightPanel)
makePadding(26, 26, 26, 26, rightPanel)

local eyebrowDot = makeFrame(UDim2.fromOffset(5, 5), UDim2.new(0, 0, 0, 4), C.blue, 0, leftPanel)
eyebrowDot.ZIndex = 22
makeCorner(3, eyebrowDot)
local eyebrow = makeLabel("EARLY ACCESS", Enum.Font.GothamBold, 10, C.blue, leftPanel)
eyebrow.Size = UDim2.new(1, -10, 0, 14)
eyebrow.Position = UDim2.new(0, 10, 0, 0)
eyebrow.TextXAlignment = Enum.TextXAlignment.Left
eyebrow.ZIndex = 22

local logoShadow = makeLabel("LIFTED", Enum.Font.GothamBlack, 64, Color3.fromRGB(50, 35, 5), leftPanel)
logoShadow.Size = UDim2.new(1, 0, 0, 80)
logoShadow.Position = UDim2.new(0, 2, 0, 19)
logoShadow.TextXAlignment = Enum.TextXAlignment.Left
logoShadow.TextTransparency = 0.6
logoShadow.ZIndex = 21

local logo = makeLabel("LIFTED", Enum.Font.GothamBlack, 64, C.gold, leftPanel)
logo.Size = UDim2.new(1, 0, 0, 80)
logo.Position = UDim2.new(0, 0, 0, 16)
logo.TextXAlignment = Enum.TextXAlignment.Left
logo.ZIndex = 22

local divider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 100), C.gold, 0, leftPanel)
divider.ZIndex = 22

local taglineFull = "Steal the idol. Don't get caught."
local tagline = makeLabel("", Enum.Font.Gotham, 15, C.silverDim, leftPanel)
tagline.Size = UDim2.new(1, 0, 0, 22)
tagline.Position = UDim2.new(0, 0, 0, 110)
tagline.TextXAlignment = Enum.TextXAlignment.Left
tagline.ZIndex = 22

local decoY = 136
makeFrame(UDim2.fromOffset(44, 1), UDim2.new(0.5, -70, 0, decoY + 2), C.gold, 0, leftPanel).ZIndex = 22
makeFrame(UDim2.fromOffset(44, 1), UDim2.new(0.5, 26, 0, decoY + 2), C.gold, 0, leftPanel).ZIndex = 22
local d1 = makeFrame(UDim2.fromOffset(4, 4), UDim2.new(0.5, -14, 0, decoY), C.gold, 0, leftPanel)
d1.Rotation = 45
d1.ZIndex = 22
local d2 = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0.5, -3, 0, decoY - 1), C.blue, 0, leftPanel)
d2.Rotation = 45
d2.ZIndex = 22
local d3 = makeFrame(UDim2.fromOffset(4, 4), UDim2.new(0.5, 10, 0, decoY), C.gold, 0, leftPanel)
d3.Rotation = 45
d3.ZIndex = 22

local menuLabel = makeLabel("MENU", Enum.Font.GothamBold, 11, C.greyDark, leftPanel)
menuLabel.Size = UDim2.new(1, 0, 0, 16)
menuLabel.Position = UDim2.new(0, 0, 0, 158)
menuLabel.TextXAlignment = Enum.TextXAlignment.Left
menuLabel.ZIndex = 22

local navDefs = {
	{state = "play", text = "PLAY", accent = C.gold, icon = C.gold},
	{state = "how", text = "HOW TO PLAY", accent = C.blue, icon = C.blue},
	{state = "credits", text = "CREDITS", accent = C.grey, icon = C.greyDark},
}
local navButtons = {}
local selectedState = "play"
local selectedArrow

local function styleButton(entry, mode)
	if mode == "selected" then
		entry.btn.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
		entry.btn.BackgroundTransparency = 0.05
		entry.stroke.Color = C.gold
		entry.stroke.Transparency = 0.25
		entry.label.TextColor3 = C.gold
	elseif mode == "hover" then
		entry.btn.BackgroundTransparency = 0.15
		entry.stroke.Color = C.blue
		entry.stroke.Transparency = 0.45
		entry.label.TextColor3 = C.silver
		entry.shine.BackgroundTransparency = 0.7
	else
		entry.btn.BackgroundColor3 = C.panelLight
		entry.btn.BackgroundTransparency = 0.25
		entry.stroke.Color = C.silver
		entry.stroke.Transparency = 0.88
		entry.label.TextColor3 = C.silver
		entry.shine.BackgroundTransparency = 0.9
	end
end

for i, def in ipairs(navDefs) do
	local y = 176 + (i - 1) * 64
	local btn = makeButton(UDim2.new(1, 0, 0, 52), UDim2.new(0, -10, 0, y), C.panelLight, 0.25, C.silver, "", Enum.Font.GothamBold, 17, leftPanel)
	btn.ZIndex = 22
	makeCorner(8, btn)
	local stroke = makeStroke(C.silver, 0.88, 1, btn)
	local accent = makeFrame(UDim2.fromOffset(4, 52), UDim2.new(0, 0, 0, 0), def.accent, 0, btn)
	accent.ZIndex = 23
	local icon = makeFrame(UDim2.fromOffset(28, 28), UDim2.new(0, 12, 0.5, -14), def.icon, 0, btn)
	icon.ZIndex = 23
	makeCorner(6, icon)
	local text = makeLabel(def.text, Enum.Font.GothamBold, 17, C.silver, btn)
	text.Size = UDim2.new(1, -90, 1, 0)
	text.Position = UDim2.new(0, 50, 0, 0)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.ZIndex = 23
	local arrow = makeLabel("›", Enum.Font.GothamBold, 16, C.silverDim, btn)
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(1, -26, 0, 0)
	arrow.ZIndex = 23
	local shine = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.white, 0.9, btn)
	shine.ZIndex = 24

	local entry = {state = def.state, btn = btn, stroke = stroke, label = text, arrow = arrow, shine = shine}
	table.insert(navButtons, entry)

	btn.MouseEnter:Connect(function()
		if selectedState ~= def.state then styleButton(entry, "hover") end
	end)
	btn.MouseLeave:Connect(function()
		if selectedState ~= def.state then styleButton(entry, "default") end
	end)
	btn.MouseButton1Down:Connect(function() tween(btn, 0.08, {Size = UDim2.new(1, 0, 0, 50)}) end)
	btn.MouseButton1Up:Connect(function() tween(btn, 0.08, {Size = UDim2.new(1, 0, 0, 52)}) end)
end

local playersCard = makeFrame(UDim2.new(1, 0, 0, 52), UDim2.new(0, -10, 0, 382), C.cardLight, 0.1, leftPanel)
playersCard.ZIndex = 22
makeCorner(8, playersCard)
makeStroke(C.gold, 0.8, 1, playersCard)
local onlineDot = makeFrame(UDim2.fromOffset(8, 8), UDim2.new(0, 12, 0.5, -4), C.blue, 0, playersCard)
onlineDot.ZIndex = 23
makeCorner(4, onlineDot)
local onlineText = makeLabel("0 PLAYERS ONLINE", Enum.Font.GothamBold, 13, C.silver, playersCard)
onlineText.Size = UDim2.new(1, -24, 1, 0)
onlineText.Position = UDim2.new(0, 24, 0, 0)
onlineText.TextXAlignment = Enum.TextXAlignment.Left
onlineText.ZIndex = 23

local bDiv = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -84), Color3.fromRGB(30, 45, 75), 0, leftPanel)
bDiv.ZIndex = 22
local b1 = makeLabel("v0.1.0  •  Early Access", Enum.Font.Gotham, 12, C.grey, leftPanel)
b1.Size = UDim2.new(1, 0, 0, 16)
b1.Position = UDim2.new(0, 0, 1, -68)
b1.TextXAlignment = Enum.TextXAlignment.Left
b1.ZIndex = 22
local b2 = makeLabel("© 2026 Lifted", Enum.Font.Gotham, 11, C.greyDark, leftPanel)
b2.Size = UDim2.new(1, 0, 0, 16)
b2.Position = UDim2.new(0, 0, 1, -48)
b2.TextXAlignment = Enum.TextXAlignment.Left
b2.ZIndex = 22

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.goldDim
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 22
scroll.Parent = rightPanel

local content = makeFrame(UDim2.new(1, -4, 0, 0), UDim2.new(0, 0, 0, 0), C.panel, 1, scroll)
content.AutomaticSize = Enum.AutomaticSize.Y
content.ZIndex = 22
local ll = Instance.new("UIListLayout")
ll.Padding = UDim.new(0, 12)
ll.SortOrder = Enum.SortOrder.LayoutOrder
ll.Parent = content

local statusDot
local modeArrow
local tipLabel
local searching = false
local menuHidden = false
local tipTimer = 0
local tipIndex = 1
local shineLine
local shineTimer = 0
local tips = {
	"Stealth wins rounds before speed does.",
	"Guardians should deny puzzle progress first.",
	"Split pressure creates extraction windows.",
	"Cooldown timing decides chase outcomes.",
	"Force rotations before committing to extract.",
	"Control the map, then control the objective.",
}

local function clearContent()
	statusDot = nil
	modeArrow = nil
	tipLabel = nil
	shineLine = nil
	searching = false
	for _, c in ipairs(content:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
end

local function addHeader(title)
	local row = makeFrame(UDim2.new(1, 0, 0, 34), UDim2.new(), C.panel, 1, content)
	row.ZIndex = 23
	local h = makeLabel(title, Enum.Font.GothamBlack, 26, C.silver, row)
	h.Size = UDim2.new(1, -80, 1, 0)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.ZIndex = 24
	local pill = makeFrame(UDim2.fromOffset(68, 22), UDim2.new(1, -68, 0.5, -11), C.panelLight, 0, row)
	pill.ZIndex = 24
	makeCorner(11, pill)
	makeStroke(C.blue, 0.4, 1, pill)
	local p = makeLabel("PUBLIC", Enum.Font.GothamBold, 11, C.blue, pill)
	p.Size = UDim2.fromScale(1, 1)
	p.ZIndex = 25
end

local function makeStaggerIn()
	for i, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") then
			child.Position = child.Position + UDim2.fromOffset(0, 6)
			child.BackgroundTransparency = math.min(1, child.BackgroundTransparency + 0.4)
			task.delay((i - 1) * 0.03, function()
				if child.Parent then
					tween(child, 0.15, {Position = child.Position - UDim2.fromOffset(0, 6), BackgroundTransparency = math.max(0, child.BackgroundTransparency - 0.4)})
				end
			end)
		end
	end
end

local function addPlay()
	addHeader("FIND A MATCH")
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.gold, 0, content)

	local status = makeFrame(UDim2.new(1, 0, 0, 56), UDim2.new(), Color3.fromRGB(11, 18, 32), 0, content)
	status.ZIndex = 23
	makeCorner(8, status)
	makeStroke(C.blue, 0.55, 1, status)
	statusDot = makeFrame(UDim2.fromOffset(10, 10), UDim2.new(0, 12, 0.5, -5), C.blueGlow, 0, status)
	statusDot.ZIndex = 24
	makeCorner(5, statusDot)
	local s1 = makeLabel("SERVERS ONLINE", Enum.Font.GothamBold, 14, C.silver, status)
	s1.Size = UDim2.new(1, -28, 0, 20)
	s1.Position = UDim2.new(0, 24, 0, 8)
	s1.TextXAlignment = Enum.TextXAlignment.Left
	s1.ZIndex = 24
	local s2 = makeLabel("Matchmaking available", Enum.Font.Gotham, 12, C.grey, status)
	s2.Size = UDim2.new(1, -28, 0, 18)
	s2.Position = UDim2.new(0, 24, 0, 30)
	s2.TextXAlignment = Enum.TextXAlignment.Left
	s2.ZIndex = 24

	local mode = makeFrame(UDim2.new(1, 0, 0, 80), UDim2.new(), Color3.fromRGB(12, 18, 30), 0, content)
	mode.ZIndex = 23
	makeCorner(8, mode)
	makeStroke(C.gold, 0.55, 1, mode)
	local n = makeLabel("4", Enum.Font.GothamBlack, 52, C.gold, mode)
	n.Size = UDim2.new(0, 72, 1, 0)
	n.Position = UDim2.new(0, 8, 0, -6)
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.ZIndex = 24
	makeFrame(UDim2.fromOffset(1, 52), UDim2.new(0, 88, 0.5, -26), C.gold, 0.2, mode).ZIndex = 24
	modeArrow = makeLabel("→", Enum.Font.GothamBold, 18, C.goldBright, mode)
	modeArrow.Size = UDim2.new(0, 20, 0, 20)
	modeArrow.Position = UDim2.new(0, 96, 0.5, -10)
	modeArrow.ZIndex = 24
	local vs = makeLabel("VS 1", Enum.Font.GothamBlack, 28, C.silver, mode)
	vs.Size = UDim2.new(1, -120, 0, 34)
	vs.Position = UDim2.new(0, 116, 0, 10)
	vs.TextXAlignment = Enum.TextXAlignment.Left
	vs.ZIndex = 24
	local mt = makeLabel("Asymmetric Heist", Enum.Font.Gotham, 13, C.grey, mode)
	mt.Size = UDim2.new(1, -116, 0, 20)
	mt.Position = UDim2.new(0, 116, 0, 44)
	mt.TextXAlignment = Enum.TextXAlignment.Left
	mt.ZIndex = 24

	local season = makeFrame(UDim2.new(1, 0, 0, 48), UDim2.new(), Color3.fromRGB(10, 15, 26), 0, content)
	season.ZIndex = 23
	makeCorner(8, season)
	makeStroke(C.gold, 0.82, 1, season)
	local sd = makeFrame(UDim2.fromOffset(8, 8), UDim2.new(0, 12, 0.5, -4), C.gold, 0, season)
	sd.Rotation = 45
	sd.ZIndex = 24
	local st1 = makeLabel("SEASON 1  —  The Cursed Temple", Enum.Font.GothamBold, 13, C.gold, season)
	st1.Size = UDim2.new(1, -28, 0, 18)
	st1.Position = UDim2.new(0, 24, 0, 7)
	st1.TextXAlignment = Enum.TextXAlignment.Left
	st1.ZIndex = 24
	local st2 = makeLabel("Map 1 of many", Enum.Font.Gotham, 11, C.greyDark, season)
	st2.Size = UDim2.new(1, -28, 0, 16)
	st2.Position = UDim2.new(0, 24, 0, 25)
	st2.TextXAlignment = Enum.TextXAlignment.Left
	st2.ZIndex = 24

	local timerCard = makeFrame(UDim2.new(1, 0, 0, 52), UDim2.new(), Color3.fromRGB(10, 15, 26), 0, content)
	timerCard.ZIndex = 23
	makeCorner(8, timerCard)
	makeStroke(C.blue, 0.75, 1, timerCard)
	local clockOuter = makeFrame(UDim2.fromOffset(8, 8), UDim2.new(0, 12, 0.5, -4), C.silver, 0.1, timerCard)
	clockOuter.ZIndex = 24
	makeCorner(4, clockOuter)
	local clockInner = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0, 13, 0.5, -3), C.blue, 0.3, timerCard)
	clockInner.ZIndex = 25
	makeCorner(3, clockInner)
	local ttxt = makeLabel("Round starting soon...", Enum.Font.Gotham, 13, C.silver, timerCard)
	ttxt.Size = UDim2.new(1, -26, 1, 0)
	ttxt.Position = UDim2.new(0, 24, 0, 0)
	ttxt.TextXAlignment = Enum.TextXAlignment.Left
	ttxt.ZIndex = 24

	local tipsCard = makeFrame(UDim2.new(1, 0, 0, 60), UDim2.new(), Color3.fromRGB(9, 14, 24), 0, content)
	tipsCard.ZIndex = 23
	makeCorner(8, tipsCard)
	makeFrame(UDim2.fromOffset(3, 60), UDim2.new(0, 0, 0, 0), C.blue, 0, tipsCard).ZIndex = 24
	tipLabel = makeLabel(tips[tipIndex], Enum.Font.Gotham, 13, C.silverDim, tipsCard)
	tipLabel.Size = UDim2.new(1, -10, 1, 0)
	tipLabel.Position = UDim2.new(0, 8, 0, 0)
	tipLabel.TextWrapped = true
	tipLabel.TextXAlignment = Enum.TextXAlignment.Left
	tipLabel.TextYAlignment = Enum.TextYAlignment.Center
	tipLabel.ZIndex = 24

	local find = makeButton(UDim2.new(1, 0, 0, 58), UDim2.new(), C.blue, 0, C.white, "FIND MATCH", Enum.Font.GothamBlack, 22, content)
	find.ZIndex = 23
	find.ClipsDescendants = true
	makeCorner(10, find)
	shineLine = makeFrame(UDim2.fromOffset(4, 120), UDim2.new(0, -30, 0.5, -60), C.white, 0.88, find)
	shineLine.ZIndex = 24
	shineLine.Rotation = 30
	shineLine.Visible = false

	find.MouseEnter:Connect(function() if not searching then tween(find, 0.1, {BackgroundColor3 = Color3.fromRGB(70, 150, 240)}) end end)
	find.MouseLeave:Connect(function() if not searching then tween(find, 0.1, {BackgroundColor3 = C.blue}) end end)
	find.MouseButton1Down:Connect(function() if not searching then tween(find, 0.08, {Size = UDim2.new(0.96, 0, 0, 56)}) end end)
	find.MouseButton1Up:Connect(function() if not searching then tween(find, 0.08, {Size = UDim2.new(1, 0, 0, 58)}) end end)
	find.Activated:Connect(function()
		if searching then return end
		playClickedBindable:Fire()
		searching = true
		find.Text = "Searching"
		task.spawn(function()
			local dots = 0
			while searching and find.Parent do
				dots = (dots % 3) + 1
				find.Text = "Searching" .. string.rep(".", dots)
				task.wait(0.35)
			end
		end)
		task.delay(0.6, function()
			if menuHidden then return end
			menuHidden = true
			tween(leftPanel, 0.3, {Position = leftHidden}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.04, function() tween(rightPanel, 0.3, {Position = rightHidden}, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end)
			tween(overlay, 0.35, {BackgroundTransparency = 1})
			task.delay(0.37, function() gui.Enabled = false end)
		end)
	end)
end

local function infoCard(idx, title, body, accent)
	local c = makeFrame(UDim2.new(1, 0, 0, 114), UDim2.new(), C.card, 0, content)
	c.ZIndex = 23
	makeCorner(10, c)
	makePadding(14, 14, 14, 14, c)
	makeFrame(UDim2.fromOffset(4, 114), UDim2.new(0, 0, 0, 0), accent, 0, c).ZIndex = 24
	local badge = makeLabel(string.format("%02d", idx), Enum.Font.GothamBlack, 11, C.greyDark, c)
	badge.Size = UDim2.new(0, 24, 0, 16)
	badge.Position = UDim2.new(1, -30, 0, 0)
	badge.TextXAlignment = Enum.TextXAlignment.Right
	badge.ZIndex = 24
	local t = makeLabel(title, Enum.Font.GothamBold, 15, C.silver, c)
	t.Size = UDim2.new(1, -16, 0, 22)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 24
	local b = makeLabel(body, Enum.Font.Gotham, 13, C.grey, c)
	b.Size = UDim2.new(1, -16, 0, 76)
	b.Position = UDim2.new(0, 0, 0, 24)
	b.TextWrapped = true
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextYAlignment = Enum.TextYAlignment.Top
	b.ZIndex = 24
end

local function addHow()
	local h = makeLabel("HOW TO PLAY", Enum.Font.GothamBlack, 26, C.silver, content)
	h.Size = UDim2.new(1, 0, 0, 34)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.ZIndex = 23
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.gold, 0, content)
	local intro = makeLabel("Master the heist. Outsmart the guardian.", Enum.Font.Gotham, 14, C.grey, content)
	intro.Size = UDim2.new(1, 0, 0, 22)
	intro.TextXAlignment = Enum.TextXAlignment.Left
	intro.ZIndex = 23

	infoCard(1, "THE OBJECTIVE", "4 thieves must infiltrate the cursed temple, solve the brazier puzzle, steal the golden idol from the vault, and extract alive before the 8 minute timer expires.", C.gold)
	infoCard(2, "THE BRAZIER PUZZLE", "Press F near a brazier to light it. Light all 4 in the correct sequence to unlock the idol. Wrong order flashes red and wastes time. The guardian can extinguish your progress.", C.blue)
	infoCard(3, "THE GUARDIAN", "Hunt the thieves as the guardian. Press E near a thief to catch them. Press F near lit braziers to extinguish them. Use Shift to sprint — it has a 10 second cooldown.", C.silverDim)
	infoCard(4, "CONTROLS", "Move: WASD  |  Sprint / Crouch: Shift  |  Interact / Catch: E  |  Brazier: F  |  Camera: Mouse", C.greyDark)

	local roles = makeFrame(UDim2.new(1, 0, 0, 52), UDim2.new(), C.panel, 1, content)
	roles.ZIndex = 23
	local thiefCard = makeFrame(UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(10, 15, 26), 0, roles)
	thiefCard.ZIndex = 24
	makeCorner(8, thiefCard)
	makeStroke(C.gold, 0.6, 1, thiefCard)
	local t1 = makeLabel("THIEF", Enum.Font.GothamBlack, 16, C.gold, thiefCard)
	t1.Size = UDim2.new(1, 0, 0, 22)
	t1.Position = UDim2.new(0, 0, 0, 4)
	t1.ZIndex = 25
	local t2 = makeLabel("Steal the idol", Enum.Font.Gotham, 11, C.grey, thiefCard)
	t2.Size = UDim2.new(1, 0, 0, 18)
	t2.Position = UDim2.new(0, 0, 0, 28)
	t2.ZIndex = 25
	local guardCard = makeFrame(UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0), Color3.fromRGB(10, 15, 26), 0, roles)
	guardCard.ZIndex = 24
	makeCorner(8, guardCard)
	makeStroke(C.blue, 0.6, 1, guardCard)
	local g1 = makeLabel("GUARDIAN", Enum.Font.GothamBlack, 16, C.blue, guardCard)
	g1.Size = UDim2.new(1, 0, 0, 22)
	g1.Position = UDim2.new(0, 0, 0, 4)
	g1.ZIndex = 25
	local g2 = makeLabel("Hunt them down", Enum.Font.Gotham, 11, C.grey, guardCard)
	g2.Size = UDim2.new(1, 0, 0, 18)
	g2.Position = UDim2.new(0, 0, 0, 28)
	g2.ZIndex = 25

	local note = makeFrame(UDim2.new(1, 0, 0, 48), UDim2.new(), C.panel, 0.1, content)
	note.ZIndex = 23
	makeCorner(8, note)
	makeStroke(C.gold, 0.82, 1, note)
	local nt = makeLabel("Rounds last 8 minutes. More maps and modes coming soon.", Enum.Font.Gotham, 12, C.grey, note)
	nt.Size = UDim2.new(1, -10, 1, 0)
	nt.Position = UDim2.new(0, 5, 0, 0)
	nt.TextWrapped = true
	nt.TextXAlignment = Enum.TextXAlignment.Left
	nt.TextYAlignment = Enum.TextYAlignment.Center
	nt.ZIndex = 24
end

local function creditCard(name, role, detail, note, isBlue)
	local c = makeFrame(UDim2.new(1, 0, 0, 110), UDim2.new(), C.card, 0, content)
	c.ZIndex = 23
	makeCorner(10, c)
	makeStroke(C.gold, 0.55, 1, c)
	makePadding(16, 16, 16, 16, c)
	makeFrame(UDim2.fromOffset(4, 110), UDim2.new(0, 0, 0, 0), C.gold, 0, c).ZIndex = 24
	local avatar = makeFrame(UDim2.fromOffset(14, 14), UDim2.new(1, -20, 0, 2), isBlue and C.blue or C.gold, 0.2, c)
	avatar.ZIndex = 24
	makeCorner(7, avatar)
	local n1 = makeLabel(name, Enum.Font.GothamBlack, 20, C.silver, c)
	n1.Size = UDim2.new(1, -20, 0, 24)
	n1.TextXAlignment = Enum.TextXAlignment.Left
	n1.ZIndex = 24
	local n2 = makeLabel(role, Enum.Font.GothamBold, 14, isBlue and C.blue or C.gold, c)
	n2.Size = UDim2.new(1, -20, 0, 20)
	n2.Position = UDim2.new(0, 0, 0, 26)
	n2.TextXAlignment = Enum.TextXAlignment.Left
	n2.ZIndex = 24
	local n3 = makeLabel(detail, Enum.Font.Gotham, 12, C.grey, c)
	n3.Size = UDim2.new(1, -20, 0, 18)
	n3.Position = UDim2.new(0, 0, 0, 48)
	n3.TextXAlignment = Enum.TextXAlignment.Left
	n3.ZIndex = 24
	if note then
		local n4 = makeLabel(note, Enum.Font.Gotham, 11, C.greyDark, c)
		n4.Size = UDim2.new(1, -20, 0, 16)
		n4.Position = UDim2.new(0, 0, 0, 70)
		n4.TextXAlignment = Enum.TextXAlignment.Left
		n4.ZIndex = 24
	end
end

local function thanksItem(text)
	local r = makeFrame(UDim2.new(1, 0, 0, 36), UDim2.new(), Color3.fromRGB(10, 14, 22), 0, content)
	r.ZIndex = 23
	makeCorner(6, r)
	local d = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0, 10, 0.5, -3), C.blue, 0, r)
	d.ZIndex = 24
	makeCorner(3, d)
	local l = makeLabel(text, Enum.Font.Gotham, 13, C.grey, r)
	l.Size = UDim2.new(1, -20, 1, 0)
	l.Position = UDim2.new(0, 20, 0, 0)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 24
end

local function addCredits()
	local h = makeLabel("CREDITS", Enum.Font.GothamBlack, 26, C.silver, content)
	h.Size = UDim2.new(1, 0, 0, 34)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.ZIndex = 23
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.gold, 0, content)
	local sub = makeLabel("An independent game by two developers.", Enum.Font.Gotham, 14, C.grey, content)
	sub.Size = UDim2.new(1, 0, 0, 22)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.ZIndex = 23

	creditCard("CHARLIE MARTIN", "Lead Developer & Game Designer", "Core systems · Networking · Game logic · UI", "16 y/o indie developer", false)
	creditCard("MARTIN JARSKY", "World Builder & Visual Designer", "Map design · Lighting · Asset pipeline", nil, true)

	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), Color3.fromRGB(30, 45, 75), 0.4, content)

	local stats = makeFrame(UDim2.new(1, 0, 0, 80), UDim2.new(), Color3.fromRGB(10, 15, 26), 0, content)
	stats.ZIndex = 23
	makeCorner(10, stats)
	makeStroke(C.blue, 0.7, 1, stats)
	local st = makeLabel("GAME STATS", Enum.Font.GothamBold, 13, C.blue, stats)
	st.Size = UDim2.new(1, -10, 0, 18)
	st.Position = UDim2.new(0, 8, 0, 6)
	st.TextXAlignment = Enum.TextXAlignment.Left
	st.ZIndex = 24
	local s1 = makeLabel("MAPS: 1", Enum.Font.GothamBold, 13, C.gold, stats)
	s1.Size = UDim2.new(0.33, 0, 0, 18)
	s1.Position = UDim2.new(0, 8, 0, 28)
	s1.ZIndex = 24
	local s2 = makeLabel("MODES: 1", Enum.Font.GothamBold, 13, C.gold, stats)
	s2.Size = UDim2.new(0.33, 0, 0, 18)
	s2.Position = UDim2.new(0.33, 0, 0, 28)
	s2.ZIndex = 24
	local s3 = makeLabel("SEASON: 1", Enum.Font.GothamBold, 13, C.gold, stats)
	s3.Size = UDim2.new(0.33, 0, 0, 18)
	s3.Position = UDim2.new(0.66, -8, 0, 28)
	s3.ZIndex = 24
	local ss = makeLabel("More content coming with each season", Enum.Font.Gotham, 11, C.greyDark, stats)
	ss.Size = UDim2.new(1, -10, 0, 14)
	ss.Position = UDim2.new(0, 8, 0, 54)
	ss.TextXAlignment = Enum.TextXAlignment.Left
	ss.ZIndex = 24

	local thanks = makeLabel("SPECIAL THANKS", Enum.Font.GothamBold, 12, C.greyDark, content)
	thanks.Size = UDim2.new(1, 0, 0, 18)
	thanks.TextXAlignment = Enum.TextXAlignment.Left
	thanks.ZIndex = 23

	thanksItem("The Roblox developer community")
	thanksItem("Dead by Daylight — for the asymmetric inspiration")
	thanksItem("You, for playing during early access")

	local b = makeLabel("Lifted  •  2026  •  Early Access", Enum.Font.Gotham, 11, C.greyDark, content)
	b.Size = UDim2.new(1, 0, 0, 16)
	b.TextXAlignment = Enum.TextXAlignment.Center
	b.ZIndex = 23
end

local function fadeSlideContentOut(d)
	for _, obj in ipairs(content:GetChildren()) do
		if obj:IsA("Frame") then
			tween(obj, d, {BackgroundTransparency = math.min(1, obj.BackgroundTransparency + 0.35), Position = obj.Position + UDim2.fromOffset(0, 6)})
		end
		for _, sub in ipairs(obj:GetDescendants()) do
			if sub:IsA("TextLabel") or sub:IsA("TextButton") then
				tween(sub, d, {TextTransparency = 1})
			end
		end
	end
end

local function fadeSlideContentIn()
	for i, obj in ipairs(content:GetChildren()) do
		if obj:IsA("Frame") then
			local basePos = obj.Position
			obj.Position = basePos + UDim2.fromOffset(0, 6)
			obj.BackgroundTransparency = math.min(1, obj.BackgroundTransparency + 0.35)
			task.delay((i - 1) * 0.03, function()
				if obj.Parent then
					tween(obj, 0.15, {Position = basePos, BackgroundTransparency = math.max(0, obj.BackgroundTransparency - 0.35)})
				end
			end)
		end
		for _, sub in ipairs(obj:GetDescendants()) do
			if sub:IsA("TextLabel") or sub:IsA("TextButton") then
				sub.TextTransparency = 1
				task.delay((i - 1) * 0.03, function()
					if sub.Parent then tween(sub, 0.15, {TextTransparency = 0}) end
				end)
			end
		end
	end
end

local function buildState(state)
	clearContent()
	if state == "play" then addPlay()
	elseif state == "how" then addHow()
	else addCredits() end
	content.Size = UDim2.new(1, -4, 0, ll.AbsoluteContentSize.Y)
	scroll.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 8)
	makeStaggerIn()
end

local function styleNav(state)
	selectedState = state
	selectedArrow = nil
	for _, e in ipairs(navButtons) do
		if e.state == state then
			styleButton(e, "selected")
			selectedArrow = e.arrow
		else
			styleButton(e, "default")
		end
	end
end

local function selectNav(state)
	styleNav(state)
	fadeSlideContentOut(0.12)
	task.delay(0.12, function()
		if menuHidden then return end
		buildState(state)
		fadeSlideContentIn()
	end)
end

for _, e in ipairs(navButtons) do
	e.btn.TextTransparency = 1
	e.btn.Position = e.btn.Position + UDim2.fromOffset(-10, 0)
	e.btn.Activated:Connect(function()
		if not menuHidden then
			selectNav(e.state)
		end
	end)
end

local function hideMenu()
	if menuHidden then return end
	menuHidden = true
	tween(leftPanel, 0.3, {Position = leftHidden}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.04, function()
		tween(rightPanel, 0.3, {Position = rightHidden}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
	tween(overlay, 0.35, {BackgroundTransparency = 1})
	task.delay(0.37, function()
		gui.Enabled = false
	end)
end

roleAssignedRemote.OnClientEvent:Connect(hideMenu)

local function runTypewriter()
	tagline.Text = ""
	task.spawn(function()
		for i = 1, #taglineFull do
			if menuHidden then return end
			tagline.Text = string.sub(taglineFull, 1, i)
			task.wait(0.04)
		end
	end)
end

local function showMenu()
	menuHidden = false
	overlay.BackgroundTransparency = 1
	leftPanel.Position = leftHidden
	rightPanel.Position = rightHidden

	tween(overlay, 0.6, {BackgroundTransparency = 0.35}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	tween(leftPanel, 0.55, {Position = leftShown}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(0.1, function()
		tween(rightPanel, 0.55, {Position = rightShown}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)

	task.delay(0.3, runTypewriter)
	task.delay(0.4, function()
		for i, e in ipairs(navButtons) do
			task.delay((i - 1) * 0.08, function()
				if e.btn.Parent then
					tween(e.btn, 0.2, {TextTransparency = 0, Position = e.btn.Position + UDim2.fromOffset(10, 0)})
				end
			end)
		end
	end)
end

styleNav("play")
buildState("play")
showMenu()

local tipElapsed = 0
RunService.Heartbeat:Connect(function(dt)
	if not gui.Enabled then return end
	local t = os.clock()

	for _, s in ipairs(stripes) do
		s.Position = s.Position + UDim2.fromOffset(4 * dt, 0)
		if s.Position.X.Offset > 220 then
			s.Position = s.Position - UDim2.fromOffset(220, 0)
		end
	end

	for _, torch in ipairs(torchParts) do
		local p = torch.phase
		local o = math.sin(t * 2.8 + p)
		local m = math.sin(t * 3.5 + p)
		local b = math.sin(t * 4.8 + p)
		local tp = math.sin(t * 6.2 + p)
		torch.outer.frame.Size = UDim2.fromOffset(torch.outer.w + o * 6, torch.outer.h + o * 6)
		torch.outer.frame.BackgroundTransparency = math.clamp(torch.outer.baseA + o * 0.06, 0.72, 0.96)
		torch.mid.frame.Size = UDim2.fromOffset(torch.mid.w + m * 4, torch.mid.h + m * 4)
		torch.mid.frame.BackgroundTransparency = math.clamp(torch.mid.baseA + m * 0.05, 0.58, 0.9)
		torch.body.frame.Size = UDim2.fromOffset(torch.body.w + b * 3, torch.body.h + b * 3)
		torch.body.frame.BackgroundTransparency = math.clamp(torch.body.baseA + b * 0.04, 0.22, 0.5)
		torch.tip.frame.Size = UDim2.fromOffset(torch.tip.w + tp * 2, torch.tip.h + tp * 2)
		torch.tip.frame.BackgroundTransparency = math.clamp(torch.tip.baseA + tp * 0.035, 0.07, 0.3)
	end

	local g1 = math.sin(t * 1.2)
	local g2 = math.sin(t * 1.8 + 0.9)
	local g3 = math.sin(t * 2.4 + 1.5)
	idolGlowParts[1].frame.Size = UDim2.fromOffset(idolGlowParts[1].w + g1 * 8, idolGlowParts[1].h + g1 * 8)
	idolGlowParts[1].frame.BackgroundTransparency = math.clamp(idolGlowParts[1].baseA + g1 * 0.03, 0.88, 0.98)
	idolGlowParts[2].frame.Size = UDim2.fromOffset(idolGlowParts[2].w + g2 * 5, idolGlowParts[2].h + g2 * 5)
	idolGlowParts[2].frame.BackgroundTransparency = math.clamp(idolGlowParts[2].baseA + g2 * 0.03, 0.84, 0.96)
	idolGlowParts[3].frame.Size = UDim2.fromOffset(idolGlowParts[3].w + g3 * 3, idolGlowParts[3].h + g3 * 3)
	idolGlowParts[3].frame.BackgroundTransparency = math.clamp(idolGlowParts[3].baseA + g3 * 0.03, 0.79, 0.92)
	gem.BackgroundTransparency = 0.35 + (math.sin(t * 2.5) + 1) * 0.1

	for _, p in ipairs(particles) do
		local f = p.frame
		local pos = f.Position
		local ny = pos.Y.Scale - (p.speed / math.max(gui.AbsoluteSize.Y, 1)) * dt
		local nx = pos.X.Scale + math.sin(t * 0.8 + p.phase) * p.xDrift * dt
		if ny <= -0.05 then
			ny = 1.05
			nx = math.random()
		end
		f.Position = UDim2.new(nx, 0, ny, 0)
		f.BackgroundTransparency = math.clamp(p.baseA + math.sin(t * 1.3 + p.phase) * 0.1, 0.35, 0.9)
	end

	for _, star in ipairs(starsTable) do
		star.frame.BackgroundTransparency = math.clamp(star.baseA + math.sin(t * star.freq + star.phase) * 0.12, 0.1, 0.95)
	end

	for _, l in ipairs(laserLines) do
		local freq = l.vertical and 0.8 or 0.6
		l.frame.BackgroundTransparency = 0.93 + math.sin(t * freq + l.phase) * 0.03
	end

	scanProgress = (scanProgress + dt / 8) % 1
	scanLine.Position = UDim2.new(0, 0, scanProgress, 0)

	logo.TextColor3 = C.gold:Lerp(C.goldBright, (math.sin(t * 0.7) + 1) * 0.5)
	local eyebrowScale = 1 + math.sin(t * (math.pi * 2 / 1.2)) * 0.2
	eyebrowDot.Size = UDim2.fromOffset(5 * eyebrowScale, 5 * eyebrowScale)

	leftStroke.Transparency = 0.625 + math.sin(t * 0.5) * 0.075

	if selectedArrow and selectedArrow.Parent then
		selectedArrow.TextSize = 17 + math.sin(t * (math.pi * 2 / 0.8))
	end

	if statusDot and statusDot.Parent then
		local s = 1 + math.sin(t * 4) * 0.1
		statusDot.Size = UDim2.fromOffset(10 * s, 10 * s)
	end

	if onlineDot and onlineDot.Parent then
		local s2 = 1 + math.sin(t * 3.5) * 0.1
		onlineDot.Size = UDim2.fromOffset(8 * s2, 8 * s2)
	end

	if modeArrow and modeArrow.Parent then
		modeArrow.TextTransparency = 0.2 + (math.sin(t * 3) + 1) * 0.25
	end

	shineTimer += dt
	if shineLine and shineLine.Parent then
		if shineTimer >= 3 then
			shineTimer = 0
			shineLine.Visible = true
			shineLine.Position = UDim2.new(0, -30, 0.5, -60)
			tween(shineLine, 0.8, {Position = UDim2.new(1, 30, 0.5, -60)})
			task.delay(0.82, function()
				if shineLine then shineLine.Visible = false end
			end)
		end
	end

	tipElapsed += dt
	if tipElapsed >= 5 then
		tipElapsed = 0
		if tipLabel and tipLabel.Parent and selectedState == "play" then
			tipIndex = (tipIndex % #tips) + 1
			tween(tipLabel, 0.15, {TextTransparency = 1})
			task.delay(0.15, function()
				if tipLabel and tipLabel.Parent and selectedState == "play" then
					tipLabel.Text = tips[tipIndex]
					tipLabel.TextTransparency = 1
					tween(tipLabel, 0.15, {TextTransparency = 0})
				end
			end)
		end
	end
end)
