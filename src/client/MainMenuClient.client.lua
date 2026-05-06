-- MainMenuClient v3

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local C = {
	bg = Color3.fromRGB(6, 5, 8),
	panel = Color3.fromRGB(11, 10, 15),
	panelLight = Color3.fromRGB(18, 16, 24),
	card = Color3.fromRGB(16, 14, 22),
	gold = Color3.fromRGB(210, 165, 50),
	goldDim = Color3.fromRGB(140, 108, 32),
	teal = Color3.fromRGB(40, 220, 200),
	red = Color3.fromRGB(220, 60, 60),
	white = Color3.fromRGB(245, 245, 245),
	grey = Color3.fromRGB(155, 150, 165),
	greyDark = Color3.fromRGB(90, 88, 100),
	orange = Color3.fromRGB(255, 130, 40),
	orangeDim = Color3.fromRGB(180, 80, 20),
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

local function makeButton(size, pos, bgColor, textColor, text, font, textSize, parent)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bgColor
	b.TextColor3 = textColor
	b.Text = text
	b.Font = font
	b.TextSize = textSize
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

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local roleAssignedRemote = ReplicatedStorage:WaitForChild("RoleAssigned")

local gui = Instance.new("ScreenGui")
gui.Name = "MainMenuUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local deepBg = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 0, gui)
deepBg.ZIndex = 1

local floor = makeFrame(UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.6, 0), Color3.fromRGB(12, 10, 18), 0, gui)
floor.ZIndex = 2
local floorGrad = Instance.new("UIGradient")
floorGrad.Color = ColorSequence.new(Color3.fromRGB(12, 10, 18), Color3.fromRGB(6, 5, 8))
floorGrad.Rotation = 90
floorGrad.Parent = floor

local ceiling = makeFrame(UDim2.new(1, 0, 0.3, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(6, 5, 8), 0, gui)
ceiling.ZIndex = 2
local ceilGrad = Instance.new("UIGradient")
ceilGrad.Color = ColorSequence.new(Color3.fromRGB(12, 10, 18), Color3.fromRGB(6, 5, 8))
ceilGrad.Rotation = 270
ceilGrad.Parent = ceiling

local function makeColumn(xScale)
	local col = makeFrame(UDim2.fromOffset(80, 2000), UDim2.new(xScale, 0, 0.5, 0), Color3.fromRGB(18, 15, 22), 0.3, gui)
	col.AnchorPoint = Vector2.new(0.5, 0.5)
	col.ZIndex = 3
	makeStroke(Color3.fromRGB(40, 35, 50), 0.7, 1, col)
	return col
end
makeColumn(0.12)
makeColumn(0.5)
makeColumn(0.88)

local torchs = {}
local function makeTorch(xScale)
	local base = makeFrame(UDim2.fromOffset(1, 1), UDim2.new(xScale, 0, 0.35, 0), C.orange, 1, gui)
	base.ZIndex = 4

	local outer = makeFrame(UDim2.fromOffset(40, 60), UDim2.new(0.5, -20, 0.5, -30), C.orange, 0.85, base)
	outer.ZIndex = 4
	makeCorner(20, outer)

	local mid = makeFrame(UDim2.fromOffset(24, 44), UDim2.new(0.5, -12, 0.5, -22), Color3.fromRGB(255, 150, 40), 0.6, base)
	mid.ZIndex = 5
	makeCorner(14, mid)

	local inner = makeFrame(UDim2.fromOffset(14, 28), UDim2.new(0.5, -7, 0.5, -14), Color3.fromRGB(255, 220, 80), 0.2, base)
	inner.ZIndex = 6
	makeCorner(8, inner)

	local ember = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0.5, -3, 0.5, -2), Color3.fromRGB(255, 255, 200), 0, base)
	ember.ZIndex = 7
	makeCorner(3, ember)

	table.insert(torchs, {
		base = base,
		outer = outer,
		mid = mid,
		inner = inner,
		ember = ember,
		offset = math.random() * math.pi * 2,
	})
end
makeTorch(0.14)
makeTorch(0.86)

local leftPool = makeFrame(UDim2.fromOffset(200, 80), UDim2.new(0, 40, 1, -120), Color3.fromRGB(255, 120, 30), 0.88, gui)
leftPool.ZIndex = 3
makeCorner(40, leftPool)
local rightPool = makeFrame(UDim2.fromOffset(200, 80), UDim2.new(1, -240, 1, -120), Color3.fromRGB(255, 120, 30), 0.88, gui)
rightPool.ZIndex = 3
makeCorner(40, rightPool)

local particles = {}
for _ = 1, 20 do
	local sz = math.random(2, 4)
	local p = makeFrame(UDim2.fromOffset(sz, sz), UDim2.new(math.random(), 0, math.random(), 0), Color3.fromRGB(255, 200, 100), math.random(70, 90) / 100, gui)
	p.ZIndex = 4
	makeCorner(sz, p)
	table.insert(particles, {
		frame = p,
		speed = math.random(8, 20),
		horizPhase = math.random() * math.pi * 2,
	})
end

local arch = makeFrame(UDim2.fromOffset(300, 2000), UDim2.new(0.5, -150, 0.5, -1000), Color3.fromRGB(4, 3, 6), 0.4, gui)
arch.ZIndex = 3
local archEdgeL = makeFrame(UDim2.fromOffset(2, 2000), UDim2.new(0, 0, 0, 0), C.gold, 0.9, arch)
archEdgeL.ZIndex = 4
local archEdgeR = makeFrame(UDim2.fromOffset(2, 2000), UDim2.new(1, -2, 0, 0), C.gold, 0.9, arch)
archEdgeR.ZIndex = 4

local function makeVignette(size, pos, rotation)
	local v = makeFrame(size, pos, Color3.new(0, 0, 0), 0, gui)
	v.ZIndex = 5
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	g.Rotation = rotation
	g.Parent = v
	return v
end
makeVignette(UDim2.new(1, 0, 0, 200), UDim2.new(0, 0, 0, 0), 90)
makeVignette(UDim2.new(1, 0, 0, 200), UDim2.new(0, 0, 1, -200), 270)
makeVignette(UDim2.new(0, 200, 1, 0), UDim2.new(0, 0, 0, 0), 0)
makeVignette(UDim2.new(0, 200, 1, 0), UDim2.new(1, -200, 0, 0), 180)

local tintOverlay = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.fromRGB(4, 3, 8), 0.45, gui)
tintOverlay.ZIndex = 6

local stripes = {}
for i = 1, 8 do
	local xScale = (i - 1) * (1.1 / 7)
	local s = makeFrame(UDim2.fromOffset(160, 2000), UDim2.new(xScale, 0, 0.5, 0), C.white, 0.975, gui)
	s.AnchorPoint = Vector2.new(0.5, 0.5)
	s.Rotation = 115
	s.ZIndex = 7
	table.insert(stripes, s)
end

local leftShownPos = UDim2.new(0.5, -496, 0.5, -280)
local leftHiddenPos = UDim2.new(0.5, -720, 0.5, -280)
local rightShownPos = UDim2.new(0.5, 16, 0.5, -280)
local rightHiddenPos = UDim2.new(0.5, 240, 0.5, -280)

local leftPanel = makeFrame(UDim2.fromOffset(460, 560), leftHiddenPos, C.panel, 0.05, gui)
leftPanel.ZIndex = 20
makeCorner(14, leftPanel)
makeStroke(C.gold, 0.65, 1, leftPanel)
makePadding(28, 28, 28, 28, leftPanel)

local rightPanel = makeFrame(UDim2.fromOffset(400, 560), rightHiddenPos, C.panel, 0.05, gui)
rightPanel.ZIndex = 20
makeCorner(14, rightPanel)
makeStroke(C.white, 0.92, 1, rightPanel)
makePadding(24, 24, 24, 24, rightPanel)

local logoShadow = makeLabel("LIFTED", Enum.Font.GothamBlack, 56, Color3.fromRGB(100, 70, 0), leftPanel)
logoShadow.Size = UDim2.new(1, 0, 0, 72)
logoShadow.Position = UDim2.new(0, 2, 0, 2)
logoShadow.TextXAlignment = Enum.TextXAlignment.Left
logoShadow.TextTransparency = 0.5
logoShadow.ZIndex = 21

local logo = makeLabel("LIFTED", Enum.Font.GothamBlack, 56, C.gold, leftPanel)
logo.Size = UDim2.new(1, 0, 0, 72)
logo.Position = UDim2.new(0, 0, 0, 0)
logo.TextXAlignment = Enum.TextXAlignment.Left
logo.ZIndex = 22

local divider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 76), C.gold, 0, leftPanel)
divider.ZIndex = 22

local tagline = makeLabel("Steal the idol. Don't get caught.", Enum.Font.Gotham, 15, C.grey, leftPanel)
tagline.Size = UDim2.new(1, 0, 0, 22)
tagline.Position = UDim2.new(0, 0, 0, 86)
tagline.TextXAlignment = Enum.TextXAlignment.Left
tagline.ZIndex = 22

for i = -1, 1 do
	local d = makeFrame(UDim2.fromOffset(3, 3), UDim2.new(0.5, i * 12 - 1, 0, 116), C.gold, 0, leftPanel)
	d.Rotation = 45
	d.ZIndex = 22
end

local menuHeader = makeLabel("MENU", Enum.Font.GothamBold, 11, C.greyDark, leftPanel)
menuHeader.Size = UDim2.new(1, 0, 0, 16)
menuHeader.Position = UDim2.new(0, 0, 0, 138)
menuHeader.TextXAlignment = Enum.TextXAlignment.Left
menuHeader.ZIndex = 22

local navDefs = {
	{state = "play", text = "PLAY", accent = C.gold, icon = C.gold},
	{state = "howtoplay", text = "HOW TO PLAY", accent = C.teal, icon = C.teal},
	{state = "credits", text = "CREDITS", accent = C.grey, icon = C.greyDark},
}

local navButtons = {}
local selectedState = "play"

local function applyButtonVisual(btn, mode)
	if mode == "selected" then
		btn.button.BackgroundColor3 = Color3.fromRGB(22, 18, 10)
		btn.button.BackgroundTransparency = 0.15
		btn.stroke.Color = C.gold
		btn.stroke.Transparency = 0.2
		btn.label.TextColor3 = C.gold
	elseif mode == "hover" then
		btn.button.BackgroundTransparency = 0.2
		btn.stroke.Color = C.gold
		btn.stroke.Transparency = 0.55
		btn.label.TextColor3 = C.white
	else
		btn.button.BackgroundColor3 = C.panelLight
		btn.button.BackgroundTransparency = 0.3
		btn.stroke.Color = C.white
		btn.stroke.Transparency = 0.9
		btn.label.TextColor3 = C.white
	end
end

for i, def in ipairs(navDefs) do
	local y = 158 + (i - 1) * 62
	local b = makeButton(UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, y), C.panelLight, C.white, "", Enum.Font.GothamBold, 17, leftPanel)
	b.ZIndex = 22
	makeCorner(8, b)
	local stroke = makeStroke(C.white, 0.9, 1, b)

	local accent = makeFrame(UDim2.fromOffset(3, 50), UDim2.new(0, 0, 0, 0), def.accent, 0, b)
	accent.ZIndex = 23
	local icon = makeFrame(UDim2.fromOffset(26, 26), UDim2.new(0, 12, 0.5, -13), def.icon, 0, b)
	icon.ZIndex = 23
	makeCorner(6, icon)
	local text = makeLabel(def.text, Enum.Font.GothamBold, 17, C.white, b)
	text.Size = UDim2.new(1, -50, 1, 0)
	text.Position = UDim2.new(0, 50, 0, 0)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.ZIndex = 23

	local entry = {state = def.state, button = b, stroke = stroke, label = text}
	table.insert(navButtons, entry)

	b.MouseEnter:Connect(function()
		if selectedState ~= def.state then
			applyButtonVisual(entry, "hover")
		end
	end)
	b.MouseLeave:Connect(function()
		if selectedState ~= def.state then
			applyButtonVisual(entry, "default")
		end
	end)
	b.MouseButton1Down:Connect(function()
		tween(b, 0.08, {Size = UDim2.new(1, 0, 0, 49)})
	end)
	b.MouseButton1Up:Connect(function()
		tween(b, 0.08, {Size = UDim2.new(1, 0, 0, 50)})
	end)
end

local bottomDivider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -80), C.white, 0.9, leftPanel)
bottomDivider.ZIndex = 22

local version = makeLabel("v0.1.0  •  Early Access", Enum.Font.Gotham, 12, C.grey, leftPanel)
version.Size = UDim2.new(1, 0, 0, 16)
version.Position = UDim2.new(0, 0, 1, -64)
version.TextXAlignment = Enum.TextXAlignment.Left
version.ZIndex = 22

local copyright = makeLabel("© 2026 Lifted. All rights reserved.", Enum.Font.Gotham, 11, C.greyDark, leftPanel)
copyright.Size = UDim2.new(1, 0, 0, 16)
copyright.Position = UDim2.new(0, 0, 1, -44)
copyright.TextXAlignment = Enum.TextXAlignment.Left
copyright.ZIndex = 22

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.greyDark
scroll.ZIndex = 22
scroll.Parent = rightPanel

local contentRoot = makeFrame(UDim2.new(1, -4, 0, 0), UDim2.new(0, 0, 0, 0), C.panel, 1, scroll)
contentRoot.AutomaticSize = Enum.AutomaticSize.Y
contentRoot.ZIndex = 22

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 12)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentRoot

local pulseDots = {}
local tipLabelRef
local tipTimer = 0
local tips = {
	"Tip: Light braziers in order to unlock the idol",
	"Tip: Crouch to reduce footstep noise",
	"Tip: The guardian can sabotage your sequence",
	"Tip: Spread out to split guardian pressure",
	"Tip: Guardians should patrol braziers first",
	"Tip: Extraction only works when puzzle is complete",
}
local tipIndex = 1
local searching = false
local menuHidden = false
local menuVisible = false

local function clearContent()
	pulseDots = {}
	tipLabelRef = nil
	searching = false
	for _, ch in ipairs(contentRoot:GetChildren()) do
		if not ch:IsA("UIListLayout") then
			ch:Destroy()
		end
	end
end

local function addHeaderWithPill(title)
	local row = makeFrame(UDim2.new(1, 0, 0, 34), UDim2.new(), C.panel, 1, contentRoot)
	row.ZIndex = 23
	local h = makeLabel(title, Enum.Font.GothamBlack, 26, C.white, row)
	h.Size = UDim2.new(1, -84, 1, 0)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.ZIndex = 24

	local pill = makeFrame(UDim2.fromOffset(72, 22), UDim2.new(1, -72, 0.5, -11), C.panelLight, 0, row)
	pill.ZIndex = 24
	makeCorner(11, pill)
	makeStroke(C.teal, 0.4, 1, pill)
	local t = makeLabel("PUBLIC", Enum.Font.GothamBold, 11, C.teal, pill)
	t.Size = UDim2.fromScale(1, 1)
	t.ZIndex = 25
end

local function addPlayState()
	addHeaderWithPill("FIND A MATCH")
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.gold, 0, contentRoot)

	local status = makeFrame(UDim2.new(1, 0, 0, 52), UDim2.new(), Color3.fromRGB(14, 20, 22), 0, contentRoot)
	status.ZIndex = 23
	makeCorner(8, status)
	makeStroke(C.teal, 0.55, 1, status)
	local d = makeFrame(UDim2.fromOffset(10, 10), UDim2.new(0, 12, 0.5, -5), C.teal, 0, status)
	d.ZIndex = 24
	makeCorner(5, d)
	table.insert(pulseDots, d)
	local s1 = makeLabel("SERVERS ONLINE", Enum.Font.GothamBold, 14, C.teal, status)
	s1.Size = UDim2.new(1, -28, 0, 20)
	s1.Position = UDim2.new(0, 24, 0, 6)
	s1.TextXAlignment = Enum.TextXAlignment.Left
	s1.ZIndex = 24
	local s2 = makeLabel("Matchmaking available", Enum.Font.Gotham, 12, C.grey, status)
	s2.Size = UDim2.new(1, -28, 0, 18)
	s2.Position = UDim2.new(0, 24, 0, 27)
	s2.TextXAlignment = Enum.TextXAlignment.Left
	s2.ZIndex = 24

	local mode = makeFrame(UDim2.new(1, 0, 0, 70), UDim2.new(), Color3.fromRGB(20, 16, 10), 0, contentRoot)
	mode.ZIndex = 23
	makeCorner(8, mode)
	makeStroke(C.gold, 0.6, 1, mode)
	local n = makeLabel("4", Enum.Font.GothamBlack, 48, C.gold, mode)
	n.Size = UDim2.new(0, 70, 1, 0)
	n.Position = UDim2.new(0, 8, 0, -6)
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.ZIndex = 24
	local vline = makeFrame(UDim2.fromOffset(1, 46), UDim2.new(0, 86, 0.5, -23), C.gold, 0.3, mode)
	vline.ZIndex = 24
	local vs = makeLabel("VS 1", Enum.Font.GothamBlack, 28, C.white, mode)
	vs.Size = UDim2.new(1, -96, 0, 34)
	vs.Position = UDim2.new(0, 96, 0, 6)
	vs.TextXAlignment = Enum.TextXAlignment.Left
	vs.ZIndex = 24
	local desc = makeLabel("Asymmetric Heist", Enum.Font.Gotham, 13, C.grey, mode)
	desc.Size = UDim2.new(1, -96, 0, 20)
	desc.Position = UDim2.new(0, 96, 0, 40)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.ZIndex = 24

	local active = makeFrame(UDim2.new(1, 0, 0, 44), UDim2.new(), Color3.fromRGB(14, 14, 20), 0, contentRoot)
	active.ZIndex = 23
	makeCorner(8, active)
	makeStroke(C.white, 0.88, 1, active)
	local atext = makeLabel("? PLAYERS ONLINE", Enum.Font.GothamBold, 14, C.white, active)
	atext.Size = UDim2.new(1, -26, 1, 0)
	atext.Position = UDim2.new(0, 10, 0, 0)
	atext.TextXAlignment = Enum.TextXAlignment.Left
	atext.ZIndex = 24
	local ad = makeFrame(UDim2.fromOffset(8, 8), UDim2.new(1, -18, 0.5, -4), C.teal, 0, active)
	ad.ZIndex = 24
	makeCorner(4, ad)
	table.insert(pulseDots, ad)

	local tipsCard = makeFrame(UDim2.new(1, 0, 0, 56), UDim2.new(), Color3.fromRGB(12, 12, 18), 0, contentRoot)
	tipsCard.ZIndex = 23
	makeCorner(8, tipsCard)
	local accent = makeFrame(UDim2.fromOffset(3, 56), UDim2.new(0, 0, 0, 0), C.gold, 0, tipsCard)
	accent.ZIndex = 24
	tipLabelRef = makeLabel(tips[tipIndex], Enum.Font.Gotham, 13, C.grey, tipsCard)
	tipLabelRef.Size = UDim2.new(1, -14, 1, 0)
	tipLabelRef.Position = UDim2.new(0, 10, 0, 0)
	tipLabelRef.TextWrapped = true
	tipLabelRef.TextXAlignment = Enum.TextXAlignment.Left
	tipLabelRef.TextYAlignment = Enum.TextYAlignment.Center
	tipLabelRef.ZIndex = 24

	local findBtn = makeButton(UDim2.new(1, 0, 0, 56), UDim2.new(), C.gold, C.bg, "FIND MATCH", Enum.Font.GothamBlack, 22, contentRoot)
	findBtn.ZIndex = 23
	makeCorner(10, findBtn)

	findBtn.MouseEnter:Connect(function()
		if searching then return end
		tween(findBtn, 0.1, {BackgroundTransparency = 0.08})
	end)
	findBtn.MouseLeave:Connect(function()
		if searching then return end
		tween(findBtn, 0.1, {BackgroundTransparency = 0})
	end)
	findBtn.MouseButton1Down:Connect(function()
		if searching then return end
		tween(findBtn, 0.08, {Size = UDim2.new(0.96, 0, 0, 54)})
	end)
	findBtn.MouseButton1Up:Connect(function()
		if searching then return end
		tween(findBtn, 0.08, {Size = UDim2.new(1, 0, 0, 56)})
	end)
	findBtn.Activated:Connect(function()
		if searching then return end
		searching = true
		findBtn.Text = "Searching"
		task.spawn(function()
			local dots = 0
			while searching and findBtn.Parent do
				dots = (dots % 3) + 1
				findBtn.Text = "Searching" .. string.rep(".", dots)
				task.wait(0.35)
			end
		end)
		task.delay(0.6, function()
			if not menuHidden then
				local function hideMenu()
					if menuHidden then return end
					menuHidden = true
					tween(leftPanel, 0.3, {Position = leftHiddenPos}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					task.delay(0.04, function()
						tween(rightPanel, 0.3, {Position = rightHiddenPos}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					end)
					tween(tintOverlay, 0.35, {BackgroundTransparency = 1})
					task.delay(0.37, function() gui.Enabled = false end)
				end
				hideMenu()
			end
		end)
	end)
end

local function addInstructionCard(title, body, accentColor)
	local cardH = 110
	local card = makeFrame(UDim2.new(1, 0, 0, cardH), UDim2.new(), C.card, 0, contentRoot)
	card.ZIndex = 23
	makeCorner(10, card)
	makePadding(12, 12, 14, 12, card)
	local bar = makeFrame(UDim2.fromOffset(3, cardH), UDim2.new(0, 0, 0, 0), accentColor, 0, card)
	bar.ZIndex = 24
	local t = makeLabel(title, Enum.Font.GothamBold, 15, C.white, card)
	t.Size = UDim2.new(1, -14, 0, 20)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 24
	local b = makeLabel(body, Enum.Font.Gotham, 13, C.grey, card)
	b.Size = UDim2.new(1, -14, 0, 74)
	b.Position = UDim2.new(0, 0, 0, 24)
	b.TextWrapped = true
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextYAlignment = Enum.TextYAlignment.Top
	b.ZIndex = 24
end

local function addHowToState()
	local h = makeLabel("HOW TO PLAY", Enum.Font.GothamBlack, 26, C.white, contentRoot)
	h.Size = UDim2.new(1, 0, 0, 34)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.ZIndex = 23
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.gold, 0, contentRoot)
	local intro = makeLabel("Master both roles to dominate.", Enum.Font.Gotham, 14, C.grey, contentRoot)
	intro.Size = UDim2.new(1, 0, 0, 22)
	intro.TextXAlignment = Enum.TextXAlignment.Left
	intro.ZIndex = 23

	addInstructionCard("THE OBJECTIVE", "4 thieves sneak into the temple, light 4 braziers in the correct sequence, steal the golden idol, and extract before the 8 minute timer expires.", C.gold)
	addInstructionCard("THE BRAZIER PUZZLE", "Stand near a brazier and press F to light it. You must light them in the correct order. Light the wrong one and it flashes red. The guardian can extinguish your progress.", C.teal)
	addInstructionCard("THE GUARDIAN", "One player hunts as the guardian. Press E near a thief to catch them. Press F near a lit brazier to extinguish it. Use Shift to sprint — but it has a cooldown.", C.red)
	addInstructionCard("CONTROLS", "Move: WASD  |  Crouch/Sprint: Shift  |  Catch/Interact: E  |  Brazier: F  |  Camera: Mouse", C.greyDark)

	local note = makeFrame(UDim2.new(1, 0, 0, 54), UDim2.new(), Color3.fromRGB(12, 10, 16), 0, contentRoot)
	note.ZIndex = 23
	makeCorner(8, note)
	makeStroke(C.gold, 0.8, 1, note)
	local n = makeLabel("Rounds last 8 minutes. Thieves win by extracting the idol. Guardian wins by catching all thieves.", Enum.Font.Gotham, 12, C.grey, note)
	n.Size = UDim2.new(1, -12, 1, 0)
	n.Position = UDim2.new(0, 6, 0, 0)
	n.TextWrapped = true
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.TextYAlignment = Enum.TextYAlignment.Center
	n.ZIndex = 24
end

local function addCreditCard(name, role, detail, note)
	local card = makeFrame(UDim2.new(1, 0, 0, 100), UDim2.new(), C.card, 0, contentRoot)
	card.ZIndex = 23
	makeCorner(10, card)
	makeStroke(C.gold, 0.6, 1, card)
	makePadding(16, 16, 16, 16, card)
	local bar = makeFrame(UDim2.fromOffset(3, 100), UDim2.new(0, 0, 0, 0), C.gold, 0, card)
	bar.ZIndex = 24
	local n1 = makeLabel(name, Enum.Font.GothamBlack, 20, C.white, card)
	n1.Size = UDim2.new(1, -10, 0, 24)
	n1.TextXAlignment = Enum.TextXAlignment.Left
	n1.ZIndex = 24
	local n2 = makeLabel(role, Enum.Font.GothamBold, 14, C.teal, card)
	n2.Size = UDim2.new(1, -10, 0, 20)
	n2.Position = UDim2.new(0, 0, 0, 26)
	n2.TextXAlignment = Enum.TextXAlignment.Left
	n2.ZIndex = 24
	local n3 = makeLabel(detail, Enum.Font.Gotham, 12, C.grey, card)
	n3.Size = UDim2.new(1, -10, 0, 18)
	n3.Position = UDim2.new(0, 0, 0, 48)
	n3.TextXAlignment = Enum.TextXAlignment.Left
	n3.ZIndex = 24
	if note then
		local n4 = makeLabel(note, Enum.Font.Gotham, 11, C.greyDark, card)
		n4.Size = UDim2.new(1, -10, 0, 16)
		n4.Position = UDim2.new(0, 0, 0, 70)
		n4.TextXAlignment = Enum.TextXAlignment.Left
		n4.ZIndex = 24
	end
end

local function addThanksItem(text)
	local row = makeFrame(UDim2.new(1, 0, 0, 32), UDim2.new(), C.panel, 0.2, contentRoot)
	row.ZIndex = 23
	makeCorner(8, row)
	local dot = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0, 10, 0.5, -3), C.gold, 0, row)
	dot.ZIndex = 24
	makeCorner(3, dot)
	local lbl = makeLabel(text, Enum.Font.Gotham, 13, C.grey, row)
	lbl.Size = UDim2.new(1, -20, 1, 0)
	lbl.Position = UDim2.new(0, 20, 0, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 24
end

local function addCreditsState()
	local h = makeLabel("CREDITS", Enum.Font.GothamBlack, 26, C.white, contentRoot)
	h.Size = UDim2.new(1, 0, 0, 34)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.ZIndex = 23
	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.gold, 0, contentRoot)
	local sub = makeLabel("Made by two developers.", Enum.Font.Gotham, 14, C.grey, contentRoot)
	sub.Size = UDim2.new(1, 0, 0, 22)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.ZIndex = 23

	addCreditCard("CHARLIE MARTIN", "Lead Developer & Game Designer", "Core systems · Networking · Game logic · UI design", "16 y/o founder of Corvail")
	addCreditCard("MARTIN JARSKY", "World Builder & Visual Designer", "Map design · Lighting · Asset pipeline · Commissions")

	makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(), C.goldDim, 0.5, contentRoot)
	local st = makeLabel("SPECIAL THANKS", Enum.Font.GothamBold, 13, C.greyDark, contentRoot)
	st.Size = UDim2.new(1, 0, 0, 18)
	st.TextXAlignment = Enum.TextXAlignment.Left
	st.ZIndex = 23

	addThanksItem("The Roblox developer community")
	addThanksItem("Dead by Daylight — for the inspiration")
	addThanksItem("You, for playing early access")

	local bottom = makeLabel("Lifted • 2026 • Early Access Build", Enum.Font.Gotham, 11, C.greyDark, contentRoot)
	bottom.Size = UDim2.new(1, 0, 0, 16)
	bottom.TextXAlignment = Enum.TextXAlignment.Center
	bottom.ZIndex = 23
end

local function fadeContent(target, duration)
	for _, d in ipairs(contentRoot:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			tween(d, duration, {TextTransparency = target})
		elseif d:IsA("Frame") and d ~= contentRoot then
			local base = d.BackgroundTransparency
			local goal = target == 1 and math.min(base + 0.5, 1) or math.max(base - 0.5, 0)
			tween(d, duration, {BackgroundTransparency = goal})
		end
	end
end

local function renderState(state)
	clearContent()
	if state == "play" then
		addPlayState()
	elseif state == "howtoplay" then
		addHowToState()
	else
		addCreditsState()
	end
	contentRoot.Size = UDim2.new(1, -4, 0, contentLayout.AbsoluteContentSize.Y)
	scroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 8)
end

local function selectNav(state)
	selectedState = state
	for _, b in ipairs(navButtons) do
		if b.state == state then
			applyButtonVisual(b, "selected")
		else
			applyButtonVisual(b, "default")
		end
	end
	fadeContent(1, 0.12)
	task.delay(0.12, function()
		if menuHidden then return end
		renderState(state)
		for _, d in ipairs(contentRoot:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				d.TextTransparency = 1
			end
		end
		fadeContent(0, 0.15)
	end)
end

local function hideMenu()
	if menuHidden then return end
	menuHidden = true
	tween(leftPanel, 0.3, {Position = leftHiddenPos}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.04, function()
		tween(rightPanel, 0.3, {Position = rightHiddenPos}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
	tween(tintOverlay, 0.35, {BackgroundTransparency = 1})
	task.delay(0.37, function()
		gui.Enabled = false
	end)
end

for _, b in ipairs(navButtons) do
	b.button.Activated:Connect(function()
		if menuHidden then return end
		selectNav(b.state)
	end)
end

roleAssignedRemote.OnClientEvent:Connect(hideMenu)

local function showMenu()
	if menuVisible then return end
	menuVisible = true
	menuHidden = false
	tintOverlay.BackgroundTransparency = 1
	leftPanel.Position = leftHiddenPos
	rightPanel.Position = rightHiddenPos

	tween(tintOverlay, 0.6, {BackgroundTransparency = 0.45}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	tween(leftPanel, 0.55, {Position = leftShownPos}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(0.1, function()
		tween(rightPanel, 0.55, {Position = rightShownPos}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)

	task.delay(0.3, function()
		fadeContent(0, 0.4)
	end)
end

selectNav("play")
showMenu()

RunService.Heartbeat:Connect(function(dt)
	if not gui.Enabled then return end

	for _, s in ipairs(stripes) do
		s.Position = s.Position + UDim2.fromOffset(6 * dt, 0)
		if s.Position.X.Offset > 220 then
			s.Position = s.Position - UDim2.fromOffset(220, 0)
		end
	end

	local t = os.clock()
	for i, torch in ipairs(torchs) do
		local o = torch.offset
		local outerScale = math.sin(t * 3 + o)
		local midScale = math.sin(t * 4.5 + o)
		local innerScale = math.sin(t * 6 + o)
		torch.outer.Size = UDim2.fromOffset(40 + outerScale * 4, 60 + outerScale * 4)
		torch.mid.Size = UDim2.fromOffset(24 + midScale * 3, 44 + midScale * 3)
		torch.inner.Size = UDim2.fromOffset(14 + innerScale * 2, 28 + innerScale * 2)
		torch.outer.BackgroundTransparency = math.clamp(0.85 + math.sin(t * 3 + o) * 0.08, 0.7, 0.95)
		torch.ember.Position = UDim2.new(0.5, -3 + math.sin(t * 8 + i) * 1, 0.5, -2 + math.cos(t * 7 + i) * 1)
	end

	for i, p in ipairs(particles) do
		local f = p.frame
		local ny = f.Position.Y.Offset - p.speed * dt
		local nx = f.Position.X.Offset + math.sin(t + p.horizPhase) * 2 * dt
		if ny < -10 then
			ny = gui.AbsoluteSize.Y + math.random(0, 100)
			nx = math.random(0, math.max(gui.AbsoluteSize.X - 10, 10))
		end
		f.Position = UDim2.new(0, nx, 0, ny)
	end

	for _, d in ipairs(pulseDots) do
		if d and d.Parent then
			local s = 0.9 + (math.sin(t * 4) * 0.1)
			d.Size = UDim2.fromOffset(10 * s, 10 * s)
		end
	end

	tipTimer += dt
	if tipTimer >= 5 then
		tipTimer = 0
		if tipLabelRef and tipLabelRef.Parent and selectedState == "play" then
			tipIndex += 1
			if tipIndex > #tips then tipIndex = 1 end
			tween(tipLabelRef, 0.15, {TextTransparency = 1})
			task.delay(0.15, function()
				if tipLabelRef and tipLabelRef.Parent and selectedState == "play" then
					tipLabelRef.Text = tips[tipIndex]
					tipLabelRef.TextTransparency = 1
					tween(tipLabelRef, 0.15, {TextTransparency = 0})
				end
			end)
		end
	end
end)
