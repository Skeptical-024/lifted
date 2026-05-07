-- MainMenuClient v5

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
	card = Color3.fromRGB(10, 11, 18),
	cardMuted = Color3.fromRGB(14, 15, 23),
	gold = Color3.fromRGB(210, 165, 50),
	text = Color3.fromRGB(220, 220, 230),
	textMuted = Color3.fromRGB(170, 170, 190),
	textDim = Color3.fromRGB(130, 130, 150),
	blue = Color3.fromRGB(100, 160, 255),
	white = Color3.fromRGB(238, 240, 248),
}

local activeTweens = {}
local function playTween(key, inst, info, props)
	if activeTweens[key] then
		activeTweens[key]:Cancel()
	end
	local tw = TweenService:Create(inst, info, props)
	activeTweens[key] = tw
	tw:Play()
	return tw
end

local function makeCorner(radius, parent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function makeStroke(color, thickness, transparency, parent)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	stroke.Parent = parent
	return stroke
end

local function makeFrame(size, position, color, transparency, z, parent)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.BorderSizePixel = 0
	frame.ZIndex = z
	frame.Parent = parent
	return frame
end

local function makeLabel(text, font, textSize, color, transparency, alignX, z, parent)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.Font = font
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextTransparency = transparency
	label.TextXAlignment = alignX
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = z
	label.Parent = parent
	return label
end

local function makeCardRow(parent, order)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = C.cardMuted
	row.BackgroundTransparency = 0
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.LayoutOrder = order
	row.ZIndex = 12

	makeCorner(10, row)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.Parent = row

	row.Parent = parent
	return row
end

local gui = Instance.new("ScreenGui")
gui.Name = "MainMenuUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- LAYER 1: BACKGROUND
local background = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 0, 1, gui)

local leftEllipse = makeFrame(UDim2.fromOffset(600, 600), UDim2.new(0, -180, 1, 220), Color3.fromRGB(30, 18, 5), 0.75, 1, gui)
leftEllipse.AnchorPoint = Vector2.new(0, 1)
makeCorner(300, leftEllipse)

local centerEllipse = makeFrame(UDim2.fromOffset(800, 400), UDim2.new(0.5, 0, 0.52, 0), Color3.fromRGB(8, 12, 25), 0.8, 1, gui)
centerEllipse.AnchorPoint = Vector2.new(0.5, 0.5)
makeCorner(200, centerEllipse)

local rightEllipse = makeFrame(UDim2.fromOffset(500, 500), UDim2.new(1, 180, 1, 180), Color3.fromRGB(15, 8, 3), 0.78, 1, gui)
rightEllipse.AnchorPoint = Vector2.new(1, 1)
makeCorner(250, rightEllipse)

for i = 1, 8 do
	local x = (i - 1) / 7
	local stripe = makeFrame(UDim2.new(0, 3, 1.4, 0), UDim2.new(x, -1, -0.2, 0), C.gold, 0.94, 1, gui)
	stripe.Rotation = 25
end

local bottomVignette = makeFrame(UDim2.new(1, 0, 0, 200), UDim2.new(0, 0, 1, -200), C.bg, 0.08, 1, gui)
local bottomGrad = Instance.new("UIGradient")
bottomGrad.Rotation = 90
bottomGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0.1),
})
bottomGrad.Parent = bottomVignette

-- LAYER 2: PARTICLES
local particlesLayer = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 1, 2, gui)

local function animateParticle(particle)
	task.spawn(function()
		task.wait(math.random() * 5)
		while gui.Parent do
			local sx = math.random(5, 95) / 100
			local startY = 1 + (math.random(0, 25) / 100)
			local endY = startY - (math.random(80, 140) / math.max(gui.AbsoluteSize.Y, 1))
			local dur = math.random(60, 100) / 10
			particle.Position = UDim2.new(sx, 0, startY, 0)
			particle.BackgroundTransparency = 0.9

			local inTween = TweenService:Create(particle, TweenInfo.new(dur * 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.new(sx, 0, (startY + endY) * 0.5, 0),
				BackgroundTransparency = 0.5,
			})
			local outTween = TweenService:Create(particle, TweenInfo.new(dur * 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Position = UDim2.new(sx, 0, endY, 0),
				BackgroundTransparency = 0.9,
			})

			inTween:Play()
			inTween.Completed:Wait()
			outTween:Play()
			outTween.Completed:Wait()
		end
	end)
end

for _ = 1, 15 do
	local p = makeFrame(
		UDim2.fromOffset(3, 3),
		UDim2.new(math.random(5, 95) / 100, 0, math.random(10, 95) / 100, 0),
		C.gold,
		math.random(60, 90) / 100,
		2,
		particlesLayer
	)
	makeCorner(99, p)
	animateParticle(p)
end

-- LAYER 3: CARD (SCROLLINGFRAME)
local cardShadow = makeFrame(UDim2.fromOffset(688, 40), UDim2.new(0.5, 0, 0.5, 4), Color3.new(0, 0, 0), 0.5, 9, gui)
cardShadow.AnchorPoint = Vector2.new(0.5, 0.5)
makeCorner(12, cardShadow)

local card = Instance.new("ScrollingFrame")
card.Name = "MainCard"
card.Size = UDim2.fromOffset(680, 40)
card.Position = UDim2.new(0.5, 0, 0.5, 20)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.BackgroundColor3 = C.card
card.BackgroundTransparency = 1
card.BorderSizePixel = 0
card.ScrollBarThickness = 0
card.ScrollingEnabled = true
card.AutomaticCanvasSize = Enum.AutomaticSize.Y
card.CanvasSize = UDim2.new()
card.ZIndex = 10
card.Parent = gui

makeCorner(12, card)
makeStroke(C.gold, 1, 0.7, card)

local cardLayout = Instance.new("UIListLayout")
cardLayout.FillDirection = Enum.FillDirection.Vertical
cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
cardLayout.Padding = UDim.new(0, 10)
cardLayout.Parent = card

-- Header section
local header = makeFrame(UDim2.new(1, 0, 0, 180), UDim2.fromOffset(0, 0), C.card, 1, 11, card)
header.LayoutOrder = 1

local headerPad = Instance.new("UIPadding")
headerPad.PaddingLeft = UDim.new(0, 36)
headerPad.PaddingRight = UDim.new(0, 36)
headerPad.PaddingTop = UDim.new(0, 20)
headerPad.PaddingBottom = UDim.new(0, 0)
headerPad.Parent = header

local early = makeLabel("EARLY ACCESS", Enum.Font.GothamBold, 11, C.gold, 0.3, Enum.TextXAlignment.Left, 12, header)
early.Size = UDim2.new(1, 0, 0, 16)

local logo = makeLabel("LIFTED", Enum.Font.GothamBlack, 64, C.gold, 0, Enum.TextXAlignment.Left, 12, header)
logo.Size = UDim2.new(1, 0, 0, 72)
logo.Position = UDim2.new(0, 0, 0, 16)

local divider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 96), C.gold, 0.6, 12, header)

local tagline = makeLabel("Steal the idol. Don't get caught.", Enum.Font.Gotham, 15, Color3.fromRGB(200, 200, 210), 0.3, Enum.TextXAlignment.Left, 12, header)
tagline.Size = UDim2.new(1, 0, 0, 20)
tagline.Position = UDim2.new(0, 0, 0, 110)

local ornament = makeFrame(UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 140), C.card, 1, 12, header)
local lineL = makeFrame(UDim2.fromOffset(80, 1), UDim2.new(0.5, -100, 0.5, 0), C.gold, 0.55, 12, ornament)
lineL.AnchorPoint = Vector2.new(1, 0.5)
local lineR = makeFrame(UDim2.fromOffset(80, 1), UDim2.new(0.5, 100, 0.5, 0), C.gold, 0.55, 12, ornament)
lineR.AnchorPoint = Vector2.new(0, 0.5)
for i = -1, 1 do
	local d = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0.5, i * 12, 0.5, 0), C.gold, 0.55, 12, ornament)
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Rotation = 45
end

-- Nav section
local nav = makeFrame(UDim2.new(1, 0, 0, 210), UDim2.fromOffset(0, 0), C.card, 1, 11, card)
nav.LayoutOrder = 2

local navPad = Instance.new("UIPadding")
navPad.PaddingLeft = UDim.new(0, 24)
navPad.PaddingRight = UDim.new(0, 24)
navPad.PaddingTop = UDim.new(0, 10)
navPad.PaddingBottom = UDim.new(0, 0)
navPad.Parent = nav

local menuLabel = makeLabel("MENU", Enum.Font.GothamBold, 10, Color3.fromRGB(150, 150, 170), 0.2, Enum.TextXAlignment.Left, 12, nav)
menuLabel.Size = UDim2.new(1, 0, 0, 14)

local navButtonsWrap = makeFrame(UDim2.new(1, 0, 0, 164), UDim2.new(0, 0, 0, 24), C.card, 1, 12, nav)
local navList = Instance.new("UIListLayout")
navList.Padding = UDim.new(0, 8)
navList.SortOrder = Enum.SortOrder.LayoutOrder
navList.Parent = navButtonsWrap

-- Content section
local contentFrame = makeFrame(UDim2.new(1, -16, 0, 0), UDim2.new(0, 8, 0, 0), C.card, 1, 11, card)
contentFrame.LayoutOrder = 3
contentFrame.AutomaticSize = Enum.AutomaticSize.Y

local footer = makeFrame(UDim2.new(1, 0, 0, 70), UDim2.fromOffset(0, 0), C.card, 1, 11, card)
footer.LayoutOrder = 4

local footerPad = Instance.new("UIPadding")
footerPad.PaddingLeft = UDim.new(0, 16)
footerPad.PaddingRight = UDim.new(0, 16)
footerPad.PaddingTop = UDim.new(0, 8)
footerPad.PaddingBottom = UDim.new(0, 8)
footerPad.Parent = footer

local footerDivider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.88, 12, footer)

local versionText = makeLabel("v0.1.0 · Early Access", Enum.Font.Gotham, 11, Color3.fromRGB(120, 120, 140), 0, Enum.TextXAlignment.Left, 12, footer)
versionText.Size = UDim2.new(0, 220, 0, 16)
versionText.Position = UDim2.new(0, 0, 0, 10)

local onlineDot = makeFrame(UDim2.fromOffset(5, 5), UDim2.new(0, 0, 0, 30), C.blue, 0, 12, footer)
makeCorner(99, onlineDot)
local onlineText = makeLabel("0 PLAYERS ONLINE", Enum.Font.Gotham, 11, Color3.fromRGB(150, 150, 170), 0, Enum.TextXAlignment.Left, 12, footer)
onlineText.Size = UDim2.new(0, 180, 0, 16)
onlineText.Position = UDim2.new(0, 10, 0, 24)

local function makeFooterBtn(text, xOffset, color)
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0
	btn.BorderSizePixel = 0
	btn.Size = UDim2.fromOffset(110, 34)
	btn.Position = UDim2.new(1, xOffset, 0, 14)
	btn.Text = ""
	btn.ZIndex = 12
	makeCorner(8, btn)
	local lbl = makeLabel(text, Enum.Font.GothamBold, 12, C.white, 0, Enum.TextXAlignment.Center, 13, btn)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	btn.Parent = footer
	return btn
end

makeFooterBtn("Discord", -232, Color3.fromRGB(88, 101, 242))
makeFooterBtn("Roblox", -116, C.gold)

local currentTab = "play"
local navDefs = {
	{key = "play", text = "PLAY"},
	{key = "howtoplay", text = "HOW TO PLAY"},
	{key = "credits", text = "CREDITS"},
}
local navRefs = {}

local function styleNav(ref, selected)
	local bg = selected and Color3.fromRGB(20, 21, 32) or Color3.fromRGB(16, 17, 26)
	local accentT = selected and 0.1 or 0.85
	local txt = selected and C.gold or C.text
	local arrowColor = selected and C.gold or Color3.fromRGB(150, 150, 170)
	local arrowT = selected and 0 or 0.4

	playTween(ref.key .. "_bg", ref.core, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = bg})
	playTween(ref.key .. "_ac", ref.accent, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = accentT})
	playTween(ref.key .. "_tx", ref.label, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = txt})
	playTween(ref.key .. "_ar", ref.arrow, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextColor3 = arrowColor,
		TextTransparency = arrowT,
	})
end

for i, def in ipairs(navDefs) do
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(1, 0, 0, 52)
	btn.LayoutOrder = i
	btn.ZIndex = 12

	local core = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.fromRGB(16, 17, 26), 0, 12, btn)
	core.Name = "ButtonCore"
	makeCorner(8, core)

	local accent = makeFrame(UDim2.new(0, 3, 1, 0), UDim2.fromScale(0, 0), C.gold, 0.85, 13, core)
	accent.Name = "AccentBar"

	local label = makeLabel(def.text, Enum.Font.GothamBold, 14, C.text, 0, Enum.TextXAlignment.Left, 13, core)
	label.Size = UDim2.new(1, -70, 1, 0)
	label.Position = UDim2.new(0, 16, 0, 0)

	local arrow = makeLabel("›", Enum.Font.GothamBold, 18, Color3.fromRGB(150, 150, 170), 0.4, Enum.TextXAlignment.Center, 13, core)
	arrow.Size = UDim2.new(0, 24, 1, 0)
	arrow.Position = UDim2.new(1, -30, 0, 0)

	local ref = {
		key = def.key,
		button = btn,
		core = core,
		accent = accent,
		label = label,
		arrow = arrow,
	}
	table.insert(navRefs, ref)

	btn.MouseEnter:Connect(function()
		if currentTab ~= def.key then
			styleNav(ref, true)
		end
	end)
	btn.MouseLeave:Connect(function()
		if currentTab ~= def.key then
			styleNav(ref, false)
		end
	end)

	btn.Parent = navButtonsWrap
end

local tips = {
	"Thieves must complete the brazier sequence before extracting.",
	"The guardian can reset progress by extinguishing lit braziers.",
	"Split up to force the guardian out of position.",
	"Use crouch to reduce footstep noise near the vault.",
	"Sprint is strongest when used to cut off escape routes.",
	"Extract only when your team is ready.",
}
local tipIndex = 1
local tipLabel
local statusPulseDot
local searching = false

local function ensureContentLayout()
	local layout = contentFrame:FindFirstChild("ContentList")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.Name = "ContentList"
		layout.Padding = UDim.new(0, 10)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = contentFrame
	end
	return layout
end

local function clearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	statusPulseDot = nil
	tipLabel = nil
	searching = false
end

local function buildPlayContent()
	ensureContentLayout()

	local matchCard = makeCardRow(contentFrame, 1)
	local left = makeLabel("4 VS 1", Enum.Font.GothamBlack, 28, C.gold, 0, Enum.TextXAlignment.Left, 13, matchCard)
	left.Size = UDim2.new(0.45, 0, 0, 40)
	local vLine = makeFrame(UDim2.new(0, 1, 0, 36), UDim2.new(0.5, 0, 0, 6), C.gold, 0.8, 13, matchCard)
	local right = makeLabel("Asymmetric Heist", Enum.Font.Gotham, 13, C.textMuted, 0, Enum.TextXAlignment.Right, 13, matchCard)
	right.Size = UDim2.new(0.48, 0, 0, 40)
	right.Position = UDim2.new(0.52, 0, 0, 0)

	local serverCard = makeCardRow(contentFrame, 2)
	statusPulseDot = makeFrame(UDim2.fromOffset(5, 5), UDim2.new(0, 2, 0, 8), C.blue, 0, 13, serverCard)
	makeCorner(99, statusPulseDot)
	local s1 = makeLabel("SERVERS ONLINE", Enum.Font.GothamBold, 12, C.text, 0, Enum.TextXAlignment.Left, 13, serverCard)
	s1.Size = UDim2.new(0.5, -8, 0, 16)
	s1.Position = UDim2.new(0, 14, 0, 0)
	local s2 = makeLabel("Matchmaking available", Enum.Font.Gotham, 12, C.textMuted, 0, Enum.TextXAlignment.Right, 13, serverCard)
	s2.Size = UDim2.new(0.48, 0, 0, 16)
	s2.Position = UDim2.new(0.52, 0, 0, 0)

	local seasonCard = makeCardRow(contentFrame, 3)
	local seasonTitle = makeLabel("✦  SEASON 1 — The Cursed Temple", Enum.Font.GothamBold, 13, C.gold, 0, Enum.TextXAlignment.Left, 13, seasonCard)
	seasonTitle.Size = UDim2.new(1, 0, 0, 18)
	local seasonSub = makeLabel("Map 1 of many", Enum.Font.Gotham, 12, C.textMuted, 0.4, Enum.TextXAlignment.Left, 13, seasonCard)
	seasonSub.Size = UDim2.new(1, 0, 0, 16)
	seasonSub.Position = UDim2.new(0, 0, 0, 20)

	local tipsCard = makeCardRow(contentFrame, 4)
	tipLabel = makeLabel(tips[tipIndex], Enum.Font.Gotham, 12, C.textMuted, 0, Enum.TextXAlignment.Left, 13, tipsCard)
	tipLabel.Size = UDim2.new(1, 0, 0, 36)
	tipLabel.TextWrapped = true

	local findWrap = makeFrame(UDim2.new(1, 0, 0, 54), UDim2.fromOffset(0, 0), C.card, 1, 12, contentFrame)
	findWrap.LayoutOrder = 5

	local findBtn = Instance.new("TextButton")
	findBtn.AutoButtonColor = false
	findBtn.BackgroundColor3 = C.gold
	findBtn.BackgroundTransparency = 0
	findBtn.BorderSizePixel = 0
	findBtn.Size = UDim2.new(1, 0, 1, 0)
	findBtn.Text = ""
	findBtn.ZIndex = 13
	makeCorner(10, findBtn)

	local findLbl = makeLabel("FIND MATCH", Enum.Font.GothamBlack, 15, Color3.fromRGB(8, 8, 12), 0, Enum.TextXAlignment.Center, 14, findBtn)
	findLbl.Size = UDim2.new(1, 0, 1, 0)

	findBtn.MouseEnter:Connect(function()
		playTween("find_hover", findBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(225, 180, 70)})
	end)
	findBtn.MouseLeave:Connect(function()
		playTween("find_leave", findBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = C.gold})
	end)
	findBtn.MouseButton1Down:Connect(function()
		playTween("find_press", findBtn, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.97, 0, 0.97, 0), Position = UDim2.new(0.015, 0, 0.015, 0)})
	end)
	findBtn.MouseButton1Up:Connect(function()
		playTween("find_release", findBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)})
	end)
	findBtn.Activated:Connect(function()
		if searching then
			return
		end
		searching = true
		playClickedBindable:Fire()
		task.spawn(function()
			local dots = 0
			while searching and gui.Enabled do
				dots = (dots % 3) + 1
				findLbl.Text = "SEARCHING" .. string.rep(".", dots)
				task.wait(0.28)
			end
		end)
		task.delay(0.6, function()
			if not gui.Parent then
				return
			end
			playTween("hide_card", card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0.5, 20),
				BackgroundTransparency = 1,
			})
			playTween("hide_shadow", cardShadow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0.5, 24),
				BackgroundTransparency = 1,
			})
			task.delay(0.34, function()
				if gui.Parent then
					gui.Enabled = false
				end
			end)
		end)
	end)

	findBtn.Parent = findWrap
	findWrap.Parent = contentFrame
end

local function buildHowToPlayContent()
	ensureContentLayout()

	local head = makeFrame(UDim2.new(1, 0, 0, 62), UDim2.fromOffset(0, 0), C.card, 1, 12, contentFrame)
	head.LayoutOrder = 1
	local h1 = makeLabel("HOW TO PLAY", Enum.Font.GothamBlack, 20, C.text, 0, Enum.TextXAlignment.Left, 13, head)
	h1.Size = UDim2.new(1, 0, 0, 24)
	local h2 = makeLabel("Master the heist. Outsmart the guardian.", Enum.Font.Gotham, 13, C.textMuted, 0, Enum.TextXAlignment.Left, 13, head)
	h2.Size = UDim2.new(1, 0, 0, 18)
	h2.Position = UDim2.new(0, 0, 0, 26)
	local line = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 52), C.gold, 0.65, 13, head)

	local rules = {
		{"01", "THE OBJECTIVE", "4 thieves infiltrate the cursed temple, solve the brazier puzzle, steal the golden idol, and extract before the timer expires."},
		{"02", "THE BRAZIER PUZZLE", "Press F near a brazier to light it. All 4 must be lit in sequence. Wrong order resets your progress. The guardian can extinguish lit braziers."},
		{"03", "THE GUARDIAN", "Hunt the thieves. Press E to catch them. Press F to extinguish braziers. Sprint with Shift — 10 second cooldown."},
	}

	for i, rule in ipairs(rules) do
		local row = makeCardRow(contentFrame, i + 1)
		local accent = makeFrame(UDim2.new(0, 3, 1, 0), UDim2.new(0, 0, 0, 0), C.gold, 0.15, 13, row)
		local num = makeLabel(rule[1], Enum.Font.GothamBlack, 28, C.gold, 0.25, Enum.TextXAlignment.Left, 13, row)
		num.Size = UDim2.new(0, 54, 0, 32)
		local title = makeLabel(rule[2], Enum.Font.GothamBold, 14, C.text, 0, Enum.TextXAlignment.Left, 13, row)
		title.Size = UDim2.new(1, -80, 0, 20)
		title.Position = UDim2.new(0, 64, 0, 0)
		local body = makeLabel(rule[3], Enum.Font.Gotham, 12, C.textMuted, 0, Enum.TextXAlignment.Left, 13, row)
		body.Size = UDim2.new(1, -80, 0, 0)
		body.Position = UDim2.new(0, 64, 0, 22)
		body.TextWrapped = true
		body.AutomaticSize = Enum.AutomaticSize.Y
	end
end

local function buildCreditsContent()
	ensureContentLayout()

	local head = makeFrame(UDim2.new(1, 0, 0, 62), UDim2.fromOffset(0, 0), C.card, 1, 12, contentFrame)
	head.LayoutOrder = 1
	local h1 = makeLabel("CREDITS", Enum.Font.GothamBlack, 20, C.text, 0, Enum.TextXAlignment.Left, 13, head)
	h1.Size = UDim2.new(1, 0, 0, 24)
	local h2 = makeLabel("An independent game by two developers.", Enum.Font.Gotham, 13, C.textMuted, 0, Enum.TextXAlignment.Left, 13, head)
	h2.Size = UDim2.new(1, 0, 0, 18)
	h2.Position = UDim2.new(0, 0, 0, 26)
	local line = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 52), C.gold, 0.65, 13, head)

	local devRow = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.card, 1, 12, contentFrame)
	devRow.LayoutOrder = 2
	devRow.AutomaticSize = Enum.AutomaticSize.Y
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, 10)
	list.Parent = devRow

	local function devCard(order, name, role, roleColor, detail, note, dotColor)
		local cardDev = makeFrame(UDim2.new(0.5, -5, 0, 0), UDim2.fromOffset(0, 0), C.cardMuted, 0, 12, devRow)
		cardDev.LayoutOrder = order
		cardDev.AutomaticSize = Enum.AutomaticSize.Y
		makeCorner(10, cardDev)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 18)
		pad.PaddingRight = UDim.new(0, 18)
		pad.PaddingTop = UDim.new(0, 16)
		pad.PaddingBottom = UDim.new(0, 16)
		pad.Parent = cardDev
		local accent = makeFrame(UDim2.new(0, 3, 1, 0), UDim2.fromScale(0, 0), C.gold, 0.15, 13, cardDev)
		local dot = makeFrame(UDim2.fromOffset(5, 5), UDim2.new(1, -12, 0, 6), dotColor, 0, 13, cardDev)
		makeCorner(99, dot)
		local n = makeLabel(name, Enum.Font.GothamBlack, 15, C.text, 0, Enum.TextXAlignment.Left, 13, cardDev)
		n.Size = UDim2.new(1, -8, 0, 20)
		local r = makeLabel(role, Enum.Font.GothamBold, 12, roleColor, 0, Enum.TextXAlignment.Left, 13, cardDev)
		r.Size = UDim2.new(1, 0, 0, 18)
		r.Position = UDim2.new(0, 0, 0, 22)
		local d = makeLabel(detail, Enum.Font.Gotham, 11, C.textMuted, 0, Enum.TextXAlignment.Left, 13, cardDev)
		d.Size = UDim2.new(1, 0, 0, 30)
		d.Position = UDim2.new(0, 0, 0, 42)
		d.TextWrapped = true
		if note then
			local nt = makeLabel(note, Enum.Font.Gotham, 11, C.textDim, 0, Enum.TextXAlignment.Left, 13, cardDev)
			nt.Size = UDim2.new(1, 0, 0, 16)
			nt.Position = UDim2.new(0, 0, 0, 74)
		end
	end

	devCard(1, "CHARLIE MARTIN", "Lead Developer & Game Designer", C.gold, "Core systems · Networking · Game logic · UI", "16 y/o indie developer", C.gold)
	devCard(2, "MARTIN JARSKY", "World Builder & Visual Designer", C.blue, "Map design · Lighting · Asset pipeline", nil, C.blue)

	local stats = makeCardRow(contentFrame, 3)
	local cols = makeFrame(UDim2.new(1, 0, 0, 38), UDim2.fromOffset(0, 0), C.cardMuted, 1, 13, stats)
	local colsList = Instance.new("UIListLayout")
	colsList.FillDirection = Enum.FillDirection.Horizontal
	colsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	colsList.VerticalAlignment = Enum.VerticalAlignment.Center
	colsList.Parent = cols
	local function statCol(text)
		local c = makeFrame(UDim2.new(1/3, -4, 1, 0), UDim2.fromOffset(0, 0), C.cardMuted, 1, 13, cols)
		local label = makeLabel(text, Enum.Font.GothamBold, 13, C.gold, 0, Enum.TextXAlignment.Center, 14, c)
		label.Size = UDim2.new(1, 0, 1, 0)
	end
	statCol("MAPS: 1")
	statCol("MODES: 1")
	statCol("SEASON: 1")
end

local function setContentVisualAlpha(alpha)
	for _, d in ipairs(contentFrame:GetDescendants()) do
		if d:IsA("TextLabel") then
			d.TextTransparency = alpha
		elseif d:IsA("Frame") then
			d.BackgroundTransparency = math.clamp((d:GetAttribute("BaseTransparency") or 0) + alpha, 0, 1)
		end
	end
end

local function cacheBaseTransparency(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Frame") then
			d:SetAttribute("BaseTransparency", d.BackgroundTransparency)
		end
	end
end

local function fadeSwap(builder)
	for _, d in ipairs(contentFrame:GetDescendants()) do
		if d:IsA("TextLabel") then
			playTween("fade_out_text_" .. d:GetDebugId(), d, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
		elseif d:IsA("Frame") and d ~= contentFrame then
			playTween("fade_out_bg_" .. d:GetDebugId(), d, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
		end
	end

	task.delay(0.11, function()
		if not gui.Parent then
			return
		end
		clearContent()
		builder()
		cacheBaseTransparency(contentFrame)
		setContentVisualAlpha(1)
		for _, d in ipairs(contentFrame:GetDescendants()) do
			if d:IsA("TextLabel") then
				playTween("fade_in_text_" .. d:GetDebugId(), d, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
			elseif d:IsA("Frame") and d ~= contentFrame then
				local target = d:GetAttribute("BaseTransparency") or 0
				playTween("fade_in_bg_" .. d:GetDebugId(), d, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = target})
			end
		end
	end)
end

local function selectTab(key)
	currentTab = key
	for _, ref in ipairs(navRefs) do
		styleNav(ref, ref.key == key)
	end

	if key == "play" then
		fadeSwap(buildPlayContent)
	elseif key == "howtoplay" then
		fadeSwap(buildHowToPlayContent)
	else
		fadeSwap(buildCreditsContent)
	end
end

for _, ref in ipairs(navRefs) do
	ref.button.Activated:Connect(function()
		if currentTab ~= ref.key then
			selectTab(ref.key)
		end
	end)
end

selectTab("play")

local function clampCardHeight()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local maxH = camera.ViewportSize.Y * 0.85
	local desired = math.min(card.AbsoluteCanvasSize.Y, maxH)
	card.Size = UDim2.fromOffset(680, math.max(220, desired))
	cardShadow.Size = UDim2.fromOffset(688, math.max(228, desired + 8))
end

card:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(clampCardHeight)

local menuHidden = false
local function hideMenu()
	if menuHidden then
		return
	end
	menuHidden = true
	playTween("hide_card", card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.5, 20),
		BackgroundTransparency = 1,
	})
	playTween("hide_shadow", cardShadow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.5, 24),
		BackgroundTransparency = 1,
	})
	task.delay(0.34, function()
		if gui.Parent then
			gui.Enabled = false
		end
	end)
end

roleAssignedRemote.OnClientEvent:Connect(hideMenu)

cacheBaseTransparency(card)
setContentVisualAlpha(1)
clampCardHeight()

-- ENTRANCE ANIMATION
card.Position = UDim2.new(0.5, 0, 0.5, 20)
card.BackgroundTransparency = 1
cardShadow.Position = UDim2.new(0.5, 0, 0.5, 24)
cardShadow.BackgroundTransparency = 1

task.delay(0.1, function()
	if not gui.Parent then
		return
	end
	playTween("enter_card", card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0,
	})
	playTween("enter_shadow", cardShadow, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 4),
		BackgroundTransparency = 0.5,
	})
end)

local pulseT = 0
local tipT = 0
local arrowPulse = 0
local navArrowBase = 18

local run = game:GetService("RunService")
run.Heartbeat:Connect(function(dt)
	pulseT += dt
	tipT += dt
	arrowPulse += dt

	onlineDot.BackgroundTransparency = 0.2 + (math.sin(pulseT * 3.2) * 0.2 + 0.2)
	if statusPulseDot then
		statusPulseDot.BackgroundTransparency = 0.1 + (math.sin(pulseT * 4) * 0.2 + 0.2)
	end

	for _, ref in ipairs(navRefs) do
		if ref.key == currentTab then
			ref.arrow.TextSize = navArrowBase + math.floor((math.sin(arrowPulse * 4) + 1) * 1)
		end
	end

	if tipLabel and currentTab == "play" and tipT >= 5 then
		tipT = 0
		tipIndex = (tipIndex % #tips) + 1
		playTween("tip_out", tipLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
		task.delay(0.13, function()
			if tipLabel and currentTab == "play" then
				tipLabel.Text = tips[tipIndex]
				tipLabel.TextTransparency = 1
				playTween("tip_in", tipLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
			end
		end)
	end
end)
