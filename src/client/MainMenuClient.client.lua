-- MainMenuClient v6

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
	cardLight = Color3.fromRGB(16, 22, 38),
	blue = Color3.fromRGB(50, 130, 220),
	blueDim = Color3.fromRGB(30, 80, 150),
	blueGlow = Color3.fromRGB(80, 160, 255),
	gold = Color3.fromRGB(182, 148, 40),
	goldBright = Color3.fromRGB(205, 170, 60),
	goldDim = Color3.fromRGB(110, 88, 24),
	silver = Color3.fromRGB(215, 220, 232),
	silverDim = Color3.fromRGB(150, 158, 175),
	grey = Color3.fromRGB(100, 110, 128),
	greyDark = Color3.fromRGB(55, 63, 78),
	black = Color3.fromRGB(3, 4, 8),
	white = Color3.fromRGB(238, 240, 248),
}

local function makeFrame(size, pos, color, alpha, parent)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color
	f.BackgroundTransparency = alpha
	f.BorderSizePixel = 0
	f.ClipsDescendants = false
	f.Parent = parent
	return f
end

local function makeCorner(radius, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
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

local function makeLabel(text, font, textSize, color, parent)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = font
	l.TextSize = textSize
	l.TextColor3 = color
	l.BorderSizePixel = 0
	l.Parent = parent
	return l
end

local function makeButton(text, font, textSize, bg, bgAlpha, textColor, parent)
	local b = Instance.new("TextButton")
	b.Text = text
	b.Font = font
	b.TextSize = textSize
	b.TextColor3 = textColor
	b.BackgroundColor3 = bg
	b.BackgroundTransparency = bgAlpha
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Parent = parent
	return b
end

local function tween(obj, duration, props, style, direction)
	local t = TweenService:Create(obj, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function makeCard(parent)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = C.card
	f.BackgroundTransparency = 0
	f.BorderSizePixel = 0
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.Size = UDim2.new(1, 0, 0, 0)
	f.Parent = parent
	makeCorner(10, f)
	makePadding(14, 14, 14, 14, f)
	return f
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

local base = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 0, gui)
base.ZIndex = 1

local floor = makeFrame(UDim2.new(1, 0, 0.48, 0), UDim2.new(0, 0, 0.52, 0), C.bgDeep, 0, gui)
floor.ZIndex = 2
local floorGrad = Instance.new("UIGradient")
floorGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 14, 24)),
	ColorSequenceKeypoint.new(1, C.bg),
})
floorGrad.Rotation = 90
floorGrad.Parent = floor

local ceil = makeFrame(UDim2.new(1, 0, 0.30, 0), UDim2.new(0, 0, 0, 0), C.bgDeep, 0, gui)
ceil.ZIndex = 2
local ceilGrad = Instance.new("UIGradient")
ceilGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 4, 9)),
	ColorSequenceKeypoint.new(1, C.bg),
})
ceilGrad.Rotation = 90
ceilGrad.Parent = ceil

local starsTable = {}
for i = 1, 55 do
	local sz = math.random(1, 3)
	local col = math.random() > 0.35 and Color3.fromRGB(195, 215, 255) or Color3.fromRGB(255, 255, 255)
	local baseA = math.random(38, 68) / 100
	local star = makeFrame(UDim2.fromOffset(sz, sz), UDim2.new(math.random() * 0.94 + 0.02, 0, math.random() * 0.88 + 0.02, 0), col, baseA, gui)
	star.ZIndex = 3
	makeCorner(sz, star)
	table.insert(starsTable, {frame = star, phase = math.random() * math.pi * 2, freq = math.random(2, 9) / 10, baseA = baseA})
end
for _ = 1, 5 do
	local star = makeFrame(UDim2.fromOffset(3, 3), UDim2.new(math.random() * 0.90 + 0.05, 0, math.random() * 0.80 + 0.05, 0), Color3.fromRGB(240, 248, 255), 0.18, gui)
	star.ZIndex = 3
	makeCorner(3, star)
	table.insert(starsTable, {frame = star, phase = math.random() * math.pi * 2, freq = 0.35, baseA = 0.18})
end

local function makePillar(xScale)
	local p = makeFrame(UDim2.fromOffset(62, 2200), UDim2.new(xScale, 0, 0.5, 0), Color3.fromRGB(13, 19, 31), 0.12, gui)
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.ZIndex = 3
	makeStroke(Color3.fromRGB(32, 50, 90), 0.62, 1, p)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 26, 42)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(13, 19, 31)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 26, 42)),
	})
	grad.Rotation = 90
	grad.Parent = p
end
makePillar(0.09)
makePillar(0.91)
local centerArch = makeFrame(UDim2.fromOffset(46, 2200), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(7, 10, 18), 0.42, gui)
centerArch.AnchorPoint = Vector2.new(0.5, 0.5)
centerArch.ZIndex = 3

local torchParts = {}
local function makeTorch(xScale)
	local root = makeFrame(UDim2.fromOffset(1, 1), UDim2.new(xScale, 0, 0.28, 0), C.bg, 1, gui)
	root.ZIndex = 4
	local function tc(size, color, alpha, cornerR, z)
		local f = makeFrame(size, UDim2.new(0.5, 0, 0.5, 0), color, alpha, root)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.ZIndex = z
		if cornerR > 0 then makeCorner(cornerR, f) end
		return f
	end
	tc(UDim2.fromOffset(8, 16), Color3.fromRGB(38, 52, 80), 0.18, 3, 4)
	local outerHalo = tc(UDim2.fromOffset(72, 96), Color3.fromRGB(18, 56, 158), 0.72, 48, 4)
	local midGlow = tc(UDim2.fromOffset(42, 62), Color3.fromRGB(38, 108, 208), 0.52, 31, 5)
	local flameBody = tc(UDim2.fromOffset(20, 36), Color3.fromRGB(88, 148, 248), 0.18, 14, 6)
	local flameTip = tc(UDim2.fromOffset(11, 20), Color3.fromRGB(168, 202, 255), 0.05, 8, 7)
	tc(UDim2.fromOffset(5, 5), Color3.fromRGB(228, 238, 255), 0, 3, 8)

	local pool = makeFrame(UDim2.fromOffset(165, 42), UDim2.new(xScale, -82, 0.95, 0), Color3.fromRGB(22, 60, 152), 0.80, gui)
	pool.ZIndex = 3
	makeCorner(21, pool)

	table.insert(torchParts, {
		phase = math.random() * math.pi * 2,
		outerHalo = {frame = outerHalo, bw = 72, bh = 96, bA = 0.72},
		midGlow = {frame = midGlow, bw = 42, bh = 62, bA = 0.52},
		flameBody = {frame = flameBody, bw = 20, bh = 36, bA = 0.18},
		flameTip = {frame = flameTip, bw = 11, bh = 20, bA = 0.05},
	})
end
makeTorch(0.09)
makeTorch(0.91)

local idolRoot = makeFrame(UDim2.fromOffset(1, 1), UDim2.new(0.5, 0, 0.5, 0), C.bg, 1, gui)
idolRoot.ZIndex = 3
local function idolPart(w, h, yScale, color, alpha, z)
	local f = makeFrame(UDim2.fromOffset(w, h), UDim2.new(0.5, -w / 2, yScale, -h / 2), color, alpha, idolRoot)
	f.ZIndex = z
	return f
end
local idolGlowParts = {}
local outerRing = idolPart(145, 225, 0.42, Color3.fromRGB(135, 104, 20), 0.84, 3)
makeCorner(72, outerRing)
local midRing = idolPart(92, 155, 0.42, Color3.fromRGB(158, 122, 24), 0.78, 3)
makeCorner(46, midRing)
local innerRing = idolPart(58, 102, 0.42, Color3.fromRGB(182, 148, 40), 0.70, 4)
makeCorner(29, innerRing)
idolGlowParts = {
	{frame = outerRing, bw = 145, bh = 225, bA = 0.84},
	{frame = midRing, bw = 92, bh = 155, bA = 0.78},
	{frame = innerRing, bw = 58, bh = 102, bA = 0.70},
}
idolPart(66, 13, 0.735, Color3.fromRGB(52, 40, 11), 0.50, 4)
idolPart(30, 52, 0.525, Color3.fromRGB(62, 47, 12), 0.50, 4)
idolPart(46, 17, 0.448, Color3.fromRGB(58, 44, 12), 0.52, 4)
idolPart(26, 26, 0.362, Color3.fromRGB(60, 46, 12), 0.50, 4)
idolPart(20, 34, 0.268, Color3.fromRGB(64, 49, 13), 0.48, 4)
local gem = idolPart(9, 9, 0.222, C.gold, 0.18, 5)
makeCorner(5, gem)

local particlesTable = {}
for _ = 1, 28 do
	local sz = math.random(2, 5)
	local mix = math.random()
	local col = Color3.new((182 + (205 - 182) * mix) / 255, (148 + (170 - 148) * mix) / 255, (40 + (60 - 40) * mix) / 255)
	local bA = math.random(42, 70) / 100
	local pf = makeFrame(UDim2.fromOffset(sz, sz), UDim2.new(math.random(), 0, math.random(), 0), col, bA, gui)
	pf.ZIndex = 4
	makeCorner(sz, pf)
	table.insert(particlesTable, {frame = pf, speed = math.random(6, 18), xDrift = (math.random(0, 1) == 1 and 1 or -1) * (math.random(2, 7) / 10), phase = math.random() * math.pi * 2, bA = bA})
end

local stripesTable = {}
for i = 1, 10 do
	local x = (i - 1) * (1.18 / 9)
	local s = makeFrame(UDim2.fromOffset(140, 2000), UDim2.new(x, 0, 0.5, 0), C.white, 0.983, gui)
	s.AnchorPoint = Vector2.new(0.5, 0.5)
	s.Rotation = 110
	s.ZIndex = 8
	table.insert(stripesTable, s)
end

local laserLines = {}
for i = 1, 7 do
	local y = (i - 1) / 6
	local lf = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, y, 0), C.blue, 0.93, gui)
	lf.ZIndex = 9
	table.insert(laserLines, {frame = lf, phase = i * 0.38, isV = false})
end
for i = 1, 6 do
	local x = (i - 1) / 5
	local lf = makeFrame(UDim2.new(0, 1, 1, 0), UDim2.new(x, 0, 0, 0), C.blue, 0.93, gui)
	lf.ZIndex = 9
	table.insert(laserLines, {frame = lf, phase = i * 0.44, isV = true})
end

local scanLine = makeFrame(UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 0), C.blueGlow, 0.94, gui)
scanLine.ZIndex = 9
local scanT = 0

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

local tint = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.fromRGB(4, 6, 12), 0.30, gui)
tint.ZIndex = 11

local leftShown = UDim2.new(0.5, -502, 0.5, -304)
local leftHidden = UDim2.new(0.5, -780, 0.5, -304)
local rightShown = UDim2.new(0.5, 18, 0.5, -304)
local rightHidden = UDim2.new(0.5, 260, 0.5, -304)

local leftPanel = makeFrame(UDim2.fromOffset(462, 608), leftHidden, C.panel, 0.04, gui)
leftPanel.ZIndex = 20
makeCorner(16, leftPanel)
local leftPanelStroke = makeStroke(C.gold, 0.58, 1, leftPanel)
makePadding(30, 28, 28, 28, leftPanel)

local rightPanel = makeFrame(UDim2.fromOffset(402, 608), rightHidden, C.panel, 0.04, gui)
rightPanel.ZIndex = 20
makeCorner(16, rightPanel)
makeStroke(C.silver, 0.86, 1, rightPanel)
makePadding(24, 24, 24, 24, rightPanel)

local eyebrowDot = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0, 0, 0, 4), C.blue, 0, leftPanel)
eyebrowDot.ZIndex = 22
makeCorner(3, eyebrowDot)
local eyebrowLabel = makeLabel("EARLY ACCESS", Enum.Font.GothamBold, 10, C.blue, leftPanel)
eyebrowLabel.Size = UDim2.new(1, -10, 0, 16)
eyebrowLabel.Position = UDim2.new(0, 10, 0, 0)
eyebrowLabel.TextXAlignment = Enum.TextXAlignment.Left
eyebrowLabel.ZIndex = 22

local logoShadow = makeLabel("LIFTED", Enum.Font.GothamBlack, 66, Color3.fromRGB(45, 32, 4), leftPanel)
logoShadow.Size = UDim2.new(1, 0, 0, 82)
logoShadow.Position = UDim2.new(0, 2, 0, 23)
logoShadow.TextXAlignment = Enum.TextXAlignment.Left
logoShadow.TextTransparency = 0.62
logoShadow.ZIndex = 21

local logoLabel = makeLabel("LIFTED", Enum.Font.GothamBlack, 66, C.gold, leftPanel)
logoLabel.Size = UDim2.new(1, 0, 0, 82)
logoLabel.Position = UDim2.new(0, 0, 0, 20)
logoLabel.TextXAlignment = Enum.TextXAlignment.Left
logoLabel.ZIndex = 22

local divider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 106), C.gold, 0, leftPanel)
divider.ZIndex = 22

local fullTagline = "Steal the idol. Don't get caught."
local taglineLabel = makeLabel("", Enum.Font.Gotham, 15, C.silverDim, leftPanel)
taglineLabel.Size = UDim2.new(1, 0, 0, 22)
taglineLabel.Position = UDim2.new(0, 0, 0, 116)
taglineLabel.TextXAlignment = Enum.TextXAlignment.Left
taglineLabel.ZIndex = 22

local decoY = 146
makeFrame(UDim2.fromOffset(44, 1), UDim2.new(0.5, -72, 0, decoY + 2), C.gold, 0, leftPanel).ZIndex = 22
local d1 = makeFrame(UDim2.fromOffset(4, 4), UDim2.new(0.5, -22, 0, decoY), C.gold, 0, leftPanel)
d1.Rotation = 45
d1.ZIndex = 22
local d2 = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0.5, -3, 0, decoY - 1), C.blue, 0, leftPanel)
d2.Rotation = 45
d2.ZIndex = 22
local d3 = makeFrame(UDim2.fromOffset(4, 4), UDim2.new(0.5, 16, 0, decoY), C.gold, 0, leftPanel)
d3.Rotation = 45
d3.ZIndex = 22
makeFrame(UDim2.fromOffset(44, 1), UDim2.new(0.5, 30, 0, decoY + 2), C.gold, 0, leftPanel).ZIndex = 22

local menuLabel = makeLabel("MENU", Enum.Font.GothamBold, 11, C.greyDark, leftPanel)
menuLabel.Size = UDim2.new(1, 0, 0, 16)
menuLabel.Position = UDim2.new(0, 0, 0, 168)
menuLabel.TextXAlignment = Enum.TextXAlignment.Left
menuLabel.ZIndex = 22

local navButtons = {}
local selectedState = "play"
local selectedArrow
local navDefs = {
	{state = "play", text = "PLAY", accent = C.gold, icon = C.gold},
	{state = "how", text = "HOW TO PLAY", accent = C.blue, icon = C.blue},
	{state = "credits", text = "CREDITS", accent = C.grey, icon = C.greyDark},
}

local function styleButton(entry, mode)
	if mode == "selected" then
		entry.btn.BackgroundColor3 = Color3.fromRGB(12, 18, 32)
		entry.btn.BackgroundTransparency = 0.06
		entry.stroke.Color = C.gold
		entry.stroke.Transparency = 0.22
		entry.label.TextColor3 = C.gold
	elseif mode == "hover" then
		entry.btn.BackgroundTransparency = 0.12
		entry.stroke.Color = C.gold
		entry.stroke.Transparency = 0.45
		entry.label.TextColor3 = C.silver
	else
		entry.btn.BackgroundColor3 = C.panelLight
		entry.btn.BackgroundTransparency = 0.22
		entry.stroke.Color = C.silver
		entry.stroke.Transparency = 0.88
		entry.label.TextColor3 = C.silver
	end
end

for i, def in ipairs(navDefs) do
	local y = 186 + (i - 1) * 64
	local btn = makeButton("", Enum.Font.GothamBold, 17, C.panelLight, 0.22, C.silver, leftPanel)
	btn.Size = UDim2.new(1, 0, 0, 52)
	btn.Position = UDim2.new(0, -10, 0, y)
	btn.ZIndex = 22
	btn.ClipsDescendants = true
	makeCorner(8, btn)
	local stroke = makeStroke(C.silver, 0.88, 1, btn)
	local accentBar = makeFrame(UDim2.fromOffset(4, 52), UDim2.new(0, 0, 0, 0), def.accent, 0, btn)
	accentBar.ZIndex = 23
	local icon = makeFrame(UDim2.fromOffset(28, 28), UDim2.new(0, 12, 0.5, -14), def.icon, 0, btn)
	icon.ZIndex = 23
	makeCorner(6, icon)
	local label = makeLabel(def.text, Enum.Font.GothamBold, 17, C.silver, btn)
	label.Size = UDim2.new(1, -90, 1, 0)
	label.Position = UDim2.new(0, 52, 0, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 23
	local arrow = makeLabel("›", Enum.Font.GothamBold, 16, C.silverDim, btn)
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(1, -26, 0, 0)
	arrow.ZIndex = 23
	local shine = makeFrame(UDim2.fromOffset(3, 70), UDim2.fromOffset(-20, -9), C.white, 0.92, btn)
	shine.Rotation = 25
	shine.ZIndex = 24

	local entry = {state = def.state, btn = btn, stroke = stroke, label = label, arrow = arrow, shine = shine}
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

local playerCountCard = makeFrame(UDim2.new(1, 0, 0, 50), UDim2.new(0, -10, 0, 358), C.card, 0, leftPanel)
playerCountCard.ZIndex = 22
makeCorner(8, playerCountCard)
makeStroke(C.gold, 0.80, 1, playerCountCard)
local playerDot = makeFrame(UDim2.fromOffset(8, 8), UDim2.new(0, 12, 0.5, -4), C.blue, 0, playerCountCard)
playerDot.ZIndex = 23
makeCorner(4, playerDot)
local playerCountLabel = makeLabel("0 PLAYERS ONLINE", Enum.Font.GothamBold, 13, C.silver, playerCountCard)
playerCountLabel.Size = UDim2.new(1, -26, 1, 0)
playerCountLabel.Position = UDim2.new(0, 28, 0, 0)
playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
playerCountLabel.ZIndex = 23

local socialRow = makeFrame(UDim2.new(1, 0, 0, 36), UDim2.new(0, -10, 0, 418), C.panel, 1, leftPanel)
socialRow.ZIndex = 22
local discord = makeButton("Discord", Enum.Font.Gotham, 12, C.blue, 0.15, C.silver, socialRow)
discord.Size = UDim2.new(0.48, 0, 1, 0)
discord.Position = UDim2.new(0, 0, 0, 0)
discord.ZIndex = 23
makeCorner(8, discord)
makeStroke(C.blue, 0.5, 1, discord)
local roblox = makeButton("Roblox", Enum.Font.Gotham, 12, C.gold, 0.15, C.silver, socialRow)
roblox.Size = UDim2.new(0.48, 0, 1, 0)
roblox.Position = UDim2.new(0.52, 0, 0, 0)
roblox.ZIndex = 23
makeCorner(8, roblox)
makeStroke(C.gold, 0.5, 1, roblox)

makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -86), Color3.fromRGB(28, 40, 68), 0, leftPanel).ZIndex = 22
local b1 = makeLabel("v0.1.0  •  Early Access", Enum.Font.Gotham, 12, C.grey, leftPanel)
b1.Size = UDim2.new(1, 0, 0, 16)
b1.Position = UDim2.new(0, 0, 1, -70)
b1.TextXAlignment = Enum.TextXAlignment.Left
b1.ZIndex = 22
local b2 = makeLabel("© 2026 Lifted", Enum.Font.Gotham, 11, C.greyDark, leftPanel)
b2.Size = UDim2.new(1, 0, 0, 16)
b2.Position = UDim2.new(0, 0, 1, -50)
b2.TextXAlignment = Enum.TextXAlignment.Left
b2.ZIndex = 22

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.goldDim
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ZIndex = 21
scroll.Parent = rightPanel

local content = makeFrame(UDim2.new(1, -4, 0, 0), UDim2.new(0, 0, 0, 0), C.panel, 1, scroll)
content.AutomaticSize = Enum.AutomaticSize.Y
content.ZIndex = 21
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local statusDot
local tipLabel
local findMatchButton
local findMatchShine
local modeArrow
local tips = {
	"Thieves must complete the brazier sequence before extracting.",
	"The guardian can reset your progress by extinguishing lit braziers.",
	"Split up to force the guardian out of position.",
	"Sprint has a cooldown. Use it when it counts.",
	"Crouch near braziers to reduce the chance of being heard.",
	"Extract only when your whole team is ready.",
}
local tipElapsed = 0
local tipIndex = 1
local searching = false
local menuHidden = false
local menuShown = false

local function clearContent()
	statusDot = nil
	tipLabel = nil
	findMatchButton = nil
	findMatchShine = nil
	modeArrow = nil
	searching = false
	for _, ch in ipairs(content:GetChildren()) do
		if not ch:IsA("UIListLayout") then ch:Destroy() end
	end
end

local function addPlay()
	local row = makeFrame(UDim2.new(1, 0, 0, 36), UDim2.new(), C.panel, 1, content)
	row.ZIndex = 22
	local h = makeLabel("FIND A MATCH", Enum.Font.GothamBlack, 24, C.silver, row)
	h.Size = UDim2.new(1, -80, 1, 0)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.ZIndex = 23
	local pill = makeFrame(UDim2.fromOffset(66, 20), UDim2.new(1, -66, 0.5, -10), C.panelLight, 0, row)
	pill.ZIndex = 23
	makeCorner(10, pill)
	makeStroke(C.blue, 0.4, 1, pill)
	local pt = makeLabel("PUBLIC", Enum.Font.GothamBold, 10, C.blue, pill)
	pt.Size = UDim2.fromScale(1, 1)
	pt.ZIndex = 24

	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.gold, 0, content).ZIndex = 22

	local status = makeCard(content)
	status.ZIndex = 22
	status.Size = UDim2.new(1, 0, 0, 56)
	makeStroke(C.blue, 0.55, 1, status)
	statusDot = makeFrame(UDim2.fromOffset(10, 10), UDim2.new(0, 12, 0.5, -5), C.blue, 0, status)
	statusDot.ZIndex = 23
	makeCorner(5, statusDot)
	local s1 = makeLabel("SERVERS ONLINE", Enum.Font.GothamBold, 14, C.silver, status)
	s1.Size = UDim2.new(1, -26, 0, 20)
	s1.Position = UDim2.new(0, 24, 0, 8)
	s1.TextXAlignment = Enum.TextXAlignment.Left
	s1.ZIndex = 23
	local s2 = makeLabel("Matchmaking available", Enum.Font.Gotham, 12, C.grey, status)
	s2.Size = UDim2.new(1, -26, 0, 18)
	s2.Position = UDim2.new(0, 24, 0, 30)
	s2.TextXAlignment = Enum.TextXAlignment.Left
	s2.ZIndex = 23

	local mode = makeCard(content)
	mode.ZIndex = 22
	mode.Size = UDim2.new(1, 0, 0, 80)
	makeStroke(C.gold, 0.55, 1, mode)
	local four = makeLabel("4", Enum.Font.GothamBlack, 50, C.gold, mode)
	four.Size = UDim2.new(0, 64, 1, 0)
	four.Position = UDim2.new(0, 8, 0, -4)
	four.TextXAlignment = Enum.TextXAlignment.Left
	four.ZIndex = 23
	makeFrame(UDim2.fromOffset(1, 52), UDim2.new(0, 82, 0.5, -26), C.gold, 0.2, mode).ZIndex = 23
	modeArrow = makeLabel("→", Enum.Font.GothamBold, 18, C.goldBright, mode)
	modeArrow.Size = UDim2.new(0, 18, 0, 20)
	modeArrow.Position = UDim2.new(0, 88, 0.5, -10)
	modeArrow.ZIndex = 23
	local vs = makeLabel("VS 1", Enum.Font.GothamBlack, 26, C.silver, mode)
	vs.Size = UDim2.new(1, -110, 0, 34)
	vs.Position = UDim2.new(0, 108, 0, 10)
	vs.TextXAlignment = Enum.TextXAlignment.Left
	vs.ZIndex = 23
	local vsub = makeLabel("Asymmetric Heist", Enum.Font.Gotham, 13, C.grey, mode)
	vsub.Size = UDim2.new(1, -110, 0, 20)
	vsub.Position = UDim2.new(0, 108, 0, 44)
	vsub.TextXAlignment = Enum.TextXAlignment.Left
	vsub.ZIndex = 23

	local season = makeCard(content)
	season.ZIndex = 22
	season.Size = UDim2.new(1, 0, 0, 48)
	makeStroke(C.gold, 0.82, 1, season)
	local d = makeFrame(UDim2.fromOffset(8, 8), UDim2.new(0, 12, 0.5, -4), C.gold, 0, season)
	d.Rotation = 45
	d.ZIndex = 23
	local sH = makeLabel("SEASON 1  —  The Cursed Temple", Enum.Font.GothamBold, 13, C.gold, season)
	sH.Size = UDim2.new(1, -28, 0, 18)
	sH.Position = UDim2.new(0, 24, 0, 7)
	sH.TextXAlignment = Enum.TextXAlignment.Left
	sH.ZIndex = 23
	local sSub = makeLabel("Map 1 of many", Enum.Font.Gotham, 11, C.greyDark, season)
	sSub.Size = UDim2.new(1, -28, 0, 16)
	sSub.Position = UDim2.new(0, 24, 0, 25)
	sSub.TextXAlignment = Enum.TextXAlignment.Left
	sSub.ZIndex = 23

	local history = makeCard(content)
	history.ZIndex = 22
	history.Size = UDim2.new(1, 0, 0, 50)
	makeStroke(C.silverDim, 0.78, 1, history)
	local lh = makeLabel("LAST MATCH", Enum.Font.GothamBold, 12, C.silverDim, history)
	lh.Size = UDim2.new(1, 0, 0, 16)
	lh.TextXAlignment = Enum.TextXAlignment.Left
	lh.ZIndex = 23
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 18), C.greyDark, 0.4, history).ZIndex = 23
	local lm = makeLabel("No recent matches.", Enum.Font.Gotham, 13, C.grey, history)
	lm.Size = UDim2.new(1, 0, 0, 20)
	lm.Position = UDim2.new(0, 0, 0, 24)
	lm.TextXAlignment = Enum.TextXAlignment.Left
	lm.ZIndex = 23

	local patch = makeCard(content)
	patch.ZIndex = 22
	patch.Size = UDim2.new(1, 0, 0, 58)
	makeStroke(C.blue, 0.78, 1, patch)
	local ph = makeLabel("LATEST UPDATE", Enum.Font.GothamBold, 12, C.blue, patch)
	ph.Size = UDim2.new(1, 0, 0, 16)
	ph.TextXAlignment = Enum.TextXAlignment.Left
	ph.ZIndex = 23
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 18), C.blue, 0.5, patch).ZIndex = 23
	local pb = makeLabel("v0.1.0 — Full UI overhaul, main menu, lobby, minimap, brazier HUD.", Enum.Font.Gotham, 12, C.grey, patch)
	pb.Size = UDim2.new(1, 0, 0, 34)
	pb.Position = UDim2.new(0, 0, 0, 22)
	pb.TextWrapped = true
	pb.TextXAlignment = Enum.TextXAlignment.Left
	pb.TextYAlignment = Enum.TextYAlignment.Top
	pb.ZIndex = 23

	local tipsCard = makeCard(content)
	tipsCard.ZIndex = 22
	tipsCard.Size = UDim2.new(1, 0, 0, 60)
	makeFrame(UDim2.fromOffset(3, 60), UDim2.new(0, 0, 0, 0), C.blue, 0, tipsCard).ZIndex = 23
	tipLabel = makeLabel(tips[tipIndex], Enum.Font.Gotham, 13, C.silverDim, tipsCard)
	tipLabel.Size = UDim2.new(1, -10, 1, 0)
	tipLabel.Position = UDim2.new(0, 8, 0, 0)
	tipLabel.TextWrapped = true
	tipLabel.TextXAlignment = Enum.TextXAlignment.Left
	tipLabel.TextYAlignment = Enum.TextYAlignment.Center
	tipLabel.ZIndex = 23

	findMatchButton = makeButton("FIND MATCH", Enum.Font.GothamBlack, 22, C.blue, 0, C.white, content)
	findMatchButton.Size = UDim2.new(1, 0, 0, 56)
	findMatchButton.ZIndex = 22
	findMatchButton.ClipsDescendants = true
	makeCorner(10, findMatchButton)
	findMatchShine = makeFrame(UDim2.fromOffset(4, 80), UDim2.fromOffset(-30, -12), C.white, 0.88, findMatchButton)
	findMatchShine.Rotation = 28
	findMatchShine.ZIndex = 23

	findMatchButton.MouseEnter:Connect(function() if not searching then tween(findMatchButton, 0.1, {BackgroundColor3 = Color3.fromRGB(65, 145, 235)}) end end)
	findMatchButton.MouseLeave:Connect(function() if not searching then tween(findMatchButton, 0.1, {BackgroundColor3 = C.blue}) end end)
	findMatchButton.MouseButton1Down:Connect(function() if not searching then tween(findMatchButton, 0.08, {Size = UDim2.new(0.97, 0, 0, 54)}) end end)
	findMatchButton.MouseButton1Up:Connect(function() if not searching then tween(findMatchButton, 0.08, {Size = UDim2.new(1, 0, 0, 56)}) end end)
	findMatchButton.Activated:Connect(function()
		if searching then return end
		searching = true
		playClickedBindable:Fire()
		findMatchButton.Text = "Searching"
		task.spawn(function()
			local dots = 0
			while searching and findMatchButton.Parent do
				dots = (dots % 3) + 1
				findMatchButton.Text = "Searching" .. string.rep(".", dots)
				task.wait(0.35)
			end
		end)
		task.delay(0.6, function()
			hideMenu()
		end)
	end)

	task.spawn(function()
		while gui.Enabled and findMatchButton and findMatchButton.Parent and not menuHidden do
			task.wait(4)
			if not gui.Enabled or not findMatchButton.Parent then break end
			findMatchShine.Position = UDim2.fromOffset(-30, -10)
			tween(findMatchShine, 0.5, {Position = UDim2.fromOffset(findMatchButton.AbsoluteSize.X + 30, -10)})
			task.wait(0.52)
			if findMatchShine.Parent then
				findMatchShine.Position = UDim2.fromOffset(-30, -10)
			end
		end
	end)
end

local function infoCard(idx, title, body, accent)
	local c = makeCard(content)
	c.ZIndex = 22
	c.Size = UDim2.new(1, 0, 0, 114)
	makeFrame(UDim2.fromOffset(4, 114), UDim2.new(0, 0, 0, 0), accent, 0, c).ZIndex = 23
	local badge = makeLabel(string.format("%02d", idx), Enum.Font.GothamBlack, 11, C.greyDark, c)
	badge.Size = UDim2.new(0, 24, 0, 16)
	badge.Position = UDim2.new(1, -30, 0, 0)
	badge.TextXAlignment = Enum.TextXAlignment.Right
	badge.ZIndex = 23
	local t = makeLabel(title, Enum.Font.GothamBold, 15, C.silver, c)
	t.Size = UDim2.new(1, -20, 0, 22)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 23
	local b = makeLabel(body, Enum.Font.Gotham, 13, C.grey, c)
	b.Size = UDim2.new(1, -20, 0, 76)
	b.Position = UDim2.new(0, 0, 0, 24)
	b.TextWrapped = true
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextYAlignment = Enum.TextYAlignment.Top
	b.ZIndex = 23
end

local function addHow()
	local h = makeLabel("HOW TO PLAY", Enum.Font.GothamBlack, 24, C.silver, content)
	h.Size = UDim2.new(1, 0, 0, 34)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.ZIndex = 22
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.gold, 0, content).ZIndex = 22
	local intro = makeLabel("Master the heist. Outsmart the guardian.", Enum.Font.Gotham, 14, C.grey, content)
	intro.Size = UDim2.new(1, 0, 0, 22)
	intro.TextXAlignment = Enum.TextXAlignment.Left
	intro.ZIndex = 22

	infoCard(1, "THE OBJECTIVE", "4 thieves must infiltrate the cursed temple, solve the brazier puzzle, steal the golden idol from the vault, and extract alive before the 8 minute timer expires.", C.gold)
	infoCard(2, "THE BRAZIER PUZZLE", "Press F near a brazier to light it. Light all 4 in the correct sequence to unlock the idol. Wrong order flashes red and wastes time. The guardian can extinguish your progress.", C.blue)
	infoCard(3, "THE GUARDIAN", "Hunt the thieves as the guardian. Press E near a thief to catch them. Press F near lit braziers to extinguish them. Use Shift to sprint — it has a 10 second cooldown.", C.silverDim)
	infoCard(4, "CONTROLS", "Move: WASD  |  Sprint / Crouch: Shift  |  Catch / Interact: E  |  Brazier: F  |  Camera: Mouse", C.greyDark)

	local roleRow = makeFrame(UDim2.new(1, 0, 0, 52), UDim2.new(), C.panel, 1, content)
	roleRow.ZIndex = 22
	local thief = makeCard(roleRow)
	thief.ZIndex = 23
	thief.Size = UDim2.new(0.48, 0, 1, 0)
	thief.Position = UDim2.new(0, 0, 0, 0)
	makeStroke(C.gold, 0.55, 1, thief)
	local t1 = makeLabel("THIEF", Enum.Font.GothamBlack, 18, C.gold, thief)
	t1.Size = UDim2.new(1, 0, 0, 22)
	t1.TextXAlignment = Enum.TextXAlignment.Left
	t1.ZIndex = 24
	local t2 = makeLabel("Steal the idol", Enum.Font.Gotham, 12, C.grey, thief)
	t2.Size = UDim2.new(1, 0, 0, 18)
	t2.Position = UDim2.new(0, 0, 0, 24)
	t2.ZIndex = 24
	local guardian = makeCard(roleRow)
	guardian.ZIndex = 23
	guardian.Size = UDim2.new(0.48, 0, 1, 0)
	guardian.Position = UDim2.new(0.52, 0, 0, 0)
	makeStroke(C.blue, 0.55, 1, guardian)
	local g1 = makeLabel("GUARDIAN", Enum.Font.GothamBlack, 18, C.blue, guardian)
	g1.Size = UDim2.new(1, 0, 0, 22)
	g1.TextXAlignment = Enum.TextXAlignment.Left
	g1.ZIndex = 24
	local g2 = makeLabel("Hunt them down", Enum.Font.Gotham, 12, C.grey, guardian)
	g2.Size = UDim2.new(1, 0, 0, 18)
	g2.Position = UDim2.new(0, 0, 0, 24)
	g2.ZIndex = 24

	local note = makeCard(content)
	note.ZIndex = 22
	note.Size = UDim2.new(1, 0, 0, 48)
	makeStroke(C.gold, 0.82, 1, note)
	local nt = makeLabel("Rounds last 8 minutes. More maps and game modes coming with each season.", Enum.Font.Gotham, 12, C.grey, note)
	nt.Size = UDim2.new(1, 0, 1, 0)
	nt.TextWrapped = true
	nt.TextXAlignment = Enum.TextXAlignment.Left
	nt.TextYAlignment = Enum.TextYAlignment.Center
	nt.ZIndex = 23
end

local function creditCard(name, role, detail, note, avatarColor)
	local c = makeCard(content)
	c.ZIndex = 22
	c.Size = UDim2.new(1, 0, 0, 110)
	makeStroke(C.gold, 0.55, 1, c)
	makeFrame(UDim2.fromOffset(4, 110), UDim2.new(0, 0, 0, 0), C.gold, 0, c).ZIndex = 23
	local av = makeFrame(UDim2.fromOffset(14, 14), UDim2.new(1, -20, 0, 2), avatarColor, 0.2, c)
	av.ZIndex = 23
	makeCorner(7, av)
	local n1 = makeLabel(name, Enum.Font.GothamBlack, 20, C.silver, c)
	n1.Size = UDim2.new(1, -20, 0, 24)
	n1.TextXAlignment = Enum.TextXAlignment.Left
	n1.ZIndex = 23
	local n2 = makeLabel(role, Enum.Font.GothamBold, 14, avatarColor, c)
	n2.Size = UDim2.new(1, -20, 0, 20)
	n2.Position = UDim2.new(0, 0, 0, 26)
	n2.TextXAlignment = Enum.TextXAlignment.Left
	n2.ZIndex = 23
	local n3 = makeLabel(detail, Enum.Font.Gotham, 12, C.grey, c)
	n3.Size = UDim2.new(1, -20, 0, 18)
	n3.Position = UDim2.new(0, 0, 0, 48)
	n3.TextXAlignment = Enum.TextXAlignment.Left
	n3.ZIndex = 23
	if note then
		local n4 = makeLabel(note, Enum.Font.Gotham, 11, C.greyDark, c)
		n4.Size = UDim2.new(1, -20, 0, 16)
		n4.Position = UDim2.new(0, 0, 0, 70)
		n4.TextXAlignment = Enum.TextXAlignment.Left
		n4.ZIndex = 23
	end
end

local function thanksItem(text)
	local row = makeCard(content)
	row.ZIndex = 22
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
	local d = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0, 10, 0.5, -3), C.blue, 0, row)
	d.ZIndex = 23
	makeCorner(3, d)
	local t = makeLabel(text, Enum.Font.Gotham, 13, C.grey, row)
	t.Size = UDim2.new(1, -20, 1, 0)
	t.Position = UDim2.new(0, 20, 0, 0)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 23
end

local function addCredits()
	local h = makeLabel("CREDITS", Enum.Font.GothamBlack, 24, C.silver, content)
	h.Size = UDim2.new(1, 0, 0, 34)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.ZIndex = 22
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.gold, 0, content).ZIndex = 22
	local sub = makeLabel("An independent game by two developers.", Enum.Font.Gotham, 14, C.grey, content)
	sub.Size = UDim2.new(1, 0, 0, 22)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.ZIndex = 22

	creditCard("CHARLIE MARTIN", "Lead Developer & Game Designer", "Core systems · Networking · Game logic · UI", "16 y/o indie developer", C.gold)
	creditCard("MARTIN JARSKY", "World Builder & Visual Designer", "Map design · Lighting · Asset pipeline", nil, C.blue)

	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), Color3.fromRGB(28, 40, 68), 0.4, content).ZIndex = 22

	local stats = makeCard(content)
	stats.ZIndex = 22
	stats.Size = UDim2.new(1, 0, 0, 80)
	makeStroke(C.blue, 0.70, 1, stats)
	local sh = makeLabel("GAME STATS", Enum.Font.GothamBold, 13, C.blue, stats)
	sh.Size = UDim2.new(1, 0, 0, 16)
	sh.TextXAlignment = Enum.TextXAlignment.Left
	sh.ZIndex = 23
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 18), C.blue, 0.5, stats).ZIndex = 23
	local sRow = makeFrame(UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 26), C.panel, 1, stats)
	sRow.ZIndex = 23
	local s1 = makeLabel("MAPS: 1", Enum.Font.GothamBold, 13, C.gold, sRow)
	s1.Size = UDim2.new(0.33, 0, 1, 0)
	s1.TextXAlignment = Enum.TextXAlignment.Center
	s1.ZIndex = 24
	local s2 = makeLabel("MODES: 1", Enum.Font.GothamBold, 13, C.gold, sRow)
	s2.Size = UDim2.new(0.33, 0, 1, 0)
	s2.Position = UDim2.new(0.33, 0, 0, 0)
	s2.TextXAlignment = Enum.TextXAlignment.Center
	s2.ZIndex = 24
	local s3 = makeLabel("SEASON: 1", Enum.Font.GothamBold, 13, C.gold, sRow)
	s3.Size = UDim2.new(0.33, 0, 1, 0)
	s3.Position = UDim2.new(0.66, 0, 0, 0)
	s3.TextXAlignment = Enum.TextXAlignment.Center
	s3.ZIndex = 24
	local ss = makeLabel("More content coming with each season", Enum.Font.Gotham, 11, C.greyDark, stats)
	ss.Size = UDim2.new(1, 0, 0, 14)
	ss.Position = UDim2.new(0, 0, 0, 50)
	ss.TextXAlignment = Enum.TextXAlignment.Left
	ss.ZIndex = 23

	local thanksHeader = makeLabel("SPECIAL THANKS", Enum.Font.GothamBold, 12, C.greyDark, content)
	thanksHeader.Size = UDim2.new(1, 0, 0, 18)
	thanksHeader.TextXAlignment = Enum.TextXAlignment.Left
	thanksHeader.ZIndex = 22

	thanksItem("The Roblox developer community")
	thanksItem("Dead by Daylight — for the asymmetric inspiration")
	thanksItem("You, for playing during early access")

	local bottom = makeLabel("Lifted  •  2026  •  Early Access", Enum.Font.Gotham, 11, C.greyDark, content)
	bottom.Size = UDim2.new(1, 0, 0, 16)
	bottom.TextXAlignment = Enum.TextXAlignment.Center
	bottom.ZIndex = 22
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

local function fadeOutContent()
	for _, obj in ipairs(content:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			tween(obj, 0.10, {TextTransparency = 1})
		end
	end
end

local function staggerInContent()
	local items = content:GetChildren()
	for i, child in ipairs(items) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			local basePos = child.Position
			child.Position = basePos + UDim2.fromOffset(0, 6)
			tween(child, 0.14, {Position = basePos})
			for _, obj in ipairs(child:GetDescendants()) do
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					obj.TextTransparency = 1
					task.delay((i - 1) * 0.03, function()
						if obj.Parent then tween(obj, 0.14, {TextTransparency = 0}) end
					end)
				end
			end
		end
	end
end

local function buildState(state)
	clearContent()
	if state == "play" then
		addPlay()
	elseif state == "how" then
		addHow()
	else
		addCredits()
	end
	content.Size = UDim2.new(1, -4, 0, layout.AbsoluteContentSize.Y)
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
end

local function selectNav(state)
	styleNav(state)
	fadeOutContent()
	task.delay(0.10, function()
		if menuHidden then return end
		buildState(state)
		staggerInContent()
	end)
end

for _, e in ipairs(navButtons) do
	e.label.TextTransparency = 1
	e.btn.Activated:Connect(function()
		if menuHidden then return end
		selectNav(e.state)
	end)
end

local function hideMenu()
	if menuHidden then return end
	menuHidden = true
	tween(leftPanel, 0.28, {Position = leftHidden}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.04, function()
		tween(rightPanel, 0.28, {Position = rightHidden}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
	tween(tint, 0.32, {BackgroundTransparency = 0})
	task.delay(0.34, function()
		gui.Enabled = false
	end)
end

local function showMenu()
	menuShown = true
	menuHidden = false
	tint.BackgroundTransparency = 0.30
	leftPanel.Position = leftHidden
	rightPanel.Position = rightHidden
	tween(leftPanel, 0.55, {Position = leftShown}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(0.10, function()
		tween(rightPanel, 0.55, {Position = rightShown}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)

	task.delay(0.40, function()
		taglineLabel.Text = ""
		task.spawn(function()
			for i = 1, #fullTagline do
				if menuHidden then break end
				taglineLabel.Text = string.sub(fullTagline, 1, i)
				task.wait(0.038)
			end
		end)
	end)

	task.delay(0.35, function()
		for i, e in ipairs(navButtons) do
			task.delay((i - 1) * 0.08, function()
				if menuHidden then return end
				tween(e.label, 0.18, {TextTransparency = 0})
			end)
		end
	end)
end

roleAssignedRemote.OnClientEvent:Connect(hideMenu)

styleNav("play")
buildState("play")
showMenu()

RunService.Heartbeat:Connect(function(dt)
	if not gui.Enabled then return end
	local t = os.clock()

	for _, s in ipairs(stripesTable) do
		s.Position = s.Position + UDim2.fromOffset(5 * dt, 0)
		if s.Position.X.Offset > 230 then
			s.Position = s.Position - UDim2.fromOffset(230, 0)
		end
	end

	for _, torch in ipairs(torchParts) do
		local p = torch.phase
		local slow = math.sin(t * 1.8 + p)
		local mid = math.sin(t * 2.6 + p + 0.8)
		local fast = math.sin(t * 3.4 + p + 1.6)
		local vfast = math.sin(t * 4.2 + p + 2.4)

		local oh = torch.outerHalo
		oh.frame.Size = UDim2.fromOffset(oh.bw + slow * 7, oh.bh + slow * 7)
		oh.frame.BackgroundTransparency = math.clamp(oh.bA + slow * 0.05, oh.bA - 0.06, oh.bA + 0.06)

		local mg = torch.midGlow
		mg.frame.Size = UDim2.fromOffset(mg.bw + mid * 4, mg.bh + mid * 4)
		mg.frame.BackgroundTransparency = math.clamp(mg.bA + mid * 0.04, mg.bA - 0.05, mg.bA + 0.05)

		local fb = torch.flameBody
		fb.frame.Size = UDim2.fromOffset(fb.bw + fast * 3, fb.bh + fast * 3)
		fb.frame.BackgroundTransparency = math.clamp(fb.bA + fast * 0.03, fb.bA - 0.04, fb.bA + 0.04)

		local ft = torch.flameTip
		ft.frame.Size = UDim2.fromOffset(ft.bw + vfast * 2, ft.bh + vfast * 2)
		ft.frame.BackgroundTransparency = math.clamp(ft.bA + vfast * 0.02, ft.bA - 0.03, ft.bA + 0.03)
	end

	local heartbeat = math.sin(t * (math.pi * 2 / 3.0))
	idolGlowParts[1].frame.Size = UDim2.fromOffset(idolGlowParts[1].bw + heartbeat * 10, idolGlowParts[1].bh + heartbeat * 10)
	idolGlowParts[1].frame.BackgroundTransparency = math.clamp(idolGlowParts[1].bA - heartbeat * 0.04, 0.76, 0.92)
	idolGlowParts[2].frame.Size = UDim2.fromOffset(idolGlowParts[2].bw + heartbeat * 6, idolGlowParts[2].bh + heartbeat * 6)
	idolGlowParts[2].frame.BackgroundTransparency = math.clamp(idolGlowParts[2].bA - heartbeat * 0.04, 0.70, 0.86)
	idolGlowParts[3].frame.Size = UDim2.fromOffset(idolGlowParts[3].bw + heartbeat * 4, idolGlowParts[3].bh + heartbeat * 4)
	idolGlowParts[3].frame.BackgroundTransparency = math.clamp(idolGlowParts[3].bA - heartbeat * 0.05, 0.60, 0.78)
	gem.BackgroundTransparency = 0.21 + math.sin(t * (math.pi * 2 / 2.5)) * 0.07

	for _, p in ipairs(particlesTable) do
		local f = p.frame
		local pos = f.Position
		local ny = pos.Y.Scale - (p.speed / math.max(gui.AbsoluteSize.Y, 1)) * dt
		local nx = pos.X.Scale + math.sin(t * 0.6 + p.phase) * p.xDrift * dt
		if ny < -0.04 then
			ny = 1.04
			nx = math.random()
		end
		f.Position = UDim2.new(math.clamp(nx, 0, 1), 0, ny, 0)
		f.BackgroundTransparency = math.clamp(p.bA + math.sin(t * 0.9 + p.phase) * 0.08, 0.35, 0.82)
	end

	for _, star in ipairs(starsTable) do
		star.frame.BackgroundTransparency = math.clamp(star.baseA + math.sin(t * star.freq + star.phase) * 0.12, 0.22, 0.85)
	end

	scanT = scanT + dt / 8.0
	if scanT > 1 then scanT = 0 end
	scanLine.Position = UDim2.new(0, 0, scanT, 0)

	for _, line in ipairs(laserLines) do
		line.frame.BackgroundTransparency = 0.91 + math.sin(t * 0.5 + line.phase) * 0.03
	end

	logoLabel.TextColor3 = C.gold:Lerp(C.goldBright, ((math.sin(t * (math.pi * 2 / 4.0)) + 1) / 2) * 0.35)
	eyebrowDot.BackgroundTransparency = math.clamp(0.88 + math.sin(t * (math.pi * 2 / 1.4)) * 0.12, 0.65, 1)
	leftPanelStroke.Transparency = 0.52 + math.sin(t * (math.pi * 2 / 5.0)) * 0.10

	if playerDot and playerDot.Parent then
		playerDot.BackgroundTransparency = math.clamp(0.05 + math.sin(t * (math.pi * 2 / 1.2)) * 0.18, 0, 0.35)
	end

	if statusDot and statusDot.Parent then
		statusDot.BackgroundTransparency = math.clamp(0.05 + math.sin(t * (math.pi * 2 / 1.1) + 0.5) * 0.18, 0, 0.35)
	end

	if selectedArrow and selectedArrow.Parent then
		selectedArrow.TextSize = 17 + math.sin(t * (math.pi * 2 / 0.8))
	end

	if modeArrow and modeArrow.Parent then
		modeArrow.TextTransparency = 0.3 + (math.sin(t * (math.pi * 2 / 1.5)) + 1) * 0.3
	end

	tipElapsed = tipElapsed + dt
	if tipElapsed >= 5 then
		tipElapsed = 0
		if tipLabel and tipLabel.Parent and selectedState == "play" then
			tipIndex = (tipIndex % #tips) + 1
			tween(tipLabel, 0.18, {TextTransparency = 1})
			task.delay(0.20, function()
				if tipLabel and tipLabel.Parent and selectedState == "play" then
					tipLabel.Text = tips[tipIndex]
					tipLabel.TextTransparency = 1
					tween(tipLabel, 0.18, {TextTransparency = 0})
				end
			end)
		end
	end
end)
