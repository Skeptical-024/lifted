-- MainMenuClient v4

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

local function makeFrame(size, position, color, transparency, z, parent)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.ZIndex = z or 1
	frame.Parent = parent
	return frame
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
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function makeLabel(text, font, size, color, transparency, alignment, z, parent)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.Font = font
	label.TextSize = size
	label.TextColor3 = color
	label.TextTransparency = transparency or 0
	label.TextXAlignment = alignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = z or 12
	label.Parent = parent
	return label
end

local function setTreeTransparency(root, alpha)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			d.TextTransparency = alpha
		elseif d:IsA("Frame") then
			if d.Name ~= "AccentBar" and d.Name ~= "ButtonCore" and d.Name ~= "ButtonHighlight" then
				d.BackgroundTransparency = math.clamp((d:GetAttribute("BaseTransparency") or d.BackgroundTransparency) + alpha, 0, 1)
			end
		end
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "MainMenuUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- LAYER 1: BACKGROUND
local bg = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 0, 1, gui)

local leftEllipse = makeFrame(UDim2.fromOffset(600, 600), UDim2.new(0, -180, 1, 220), Color3.fromRGB(30, 18, 5), 0.75, 1, gui)
leftEllipse.AnchorPoint = Vector2.new(0, 1)
makeCorner(300, leftEllipse)

local centerEllipse = makeFrame(UDim2.fromOffset(800, 400), UDim2.new(0.5, 0, 0.52, 0), Color3.fromRGB(8, 12, 25), 0.8, 1, gui)
centerEllipse.AnchorPoint = Vector2.new(0.5, 0.5)
makeCorner(200, centerEllipse)

local rightEllipse = makeFrame(UDim2.fromOffset(500, 500), UDim2.new(1, 180, 1, 180), Color3.fromRGB(15, 8, 3), 0.78, 1, gui)
rightEllipse.AnchorPoint = Vector2.new(1, 1)
makeCorner(250, rightEllipse)

local stripeContainer = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 1, 1, gui)
for i = 1, 8 do
	local x = (i - 1) / 7
	local stripe = makeFrame(UDim2.new(0, 3, 1.4, 0), UDim2.new(x, -1, -0.2, 0), C.gold, 0.94, 1, stripeContainer)
	stripe.Rotation = 25
	stripe:SetAttribute("BaseTransparency", stripe.BackgroundTransparency)
end

local vignetteBottom = makeFrame(UDim2.new(1, 0, 0, 200), UDim2.new(0, 0, 1, -200), C.bg, 0.1, 1, gui)
local bottomGrad = Instance.new("UIGradient")
bottomGrad.Rotation = 90
bottomGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0.1),
})
bottomGrad.Parent = vignetteBottom

-- LAYER 2: PARTICLES
local particlesLayer = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 1, 2, gui)
local particleCount = 15
local particleRefs = {}

local function randomScaleX()
	return math.random(5, 95) / 100
end

for i = 1, particleCount do
	local p = makeFrame(
		UDim2.fromOffset(3, 3),
		UDim2.new(randomScaleX(), 0, math.random(10, 95) / 100, 0),
		C.gold,
		math.random(60, 90) / 100,
		2,
		particlesLayer
	)
	makeCorner(99, p)
	p:SetAttribute("BaseTransparency", p.BackgroundTransparency)
	table.insert(particleRefs, p)
end

local function animateParticle(particle)
	task.spawn(function()
		task.wait(math.random() * 5)
		while gui.Parent do
			local sx = randomScaleX()
			local startY = 1 + (math.random(0, 25) / 100)
			local endY = startY - (math.random(80, 140) / math.max(gui.AbsoluteSize.Y, 1))
			local dur = math.random(60, 100) / 10
			particle.Position = UDim2.new(sx, 0, startY, 0)
			particle.BackgroundTransparency = 0.9

			local tIn = TweenService:Create(particle, TweenInfo.new(dur * 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.new(sx, 0, (startY + endY) * 0.5, 0),
				BackgroundTransparency = 0.5,
			})
			local tOut = TweenService:Create(particle, TweenInfo.new(dur * 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Position = UDim2.new(sx, 0, endY, 0),
				BackgroundTransparency = 0.9,
			})
			tIn:Play()
			tIn.Completed:Wait()
			tOut:Play()
			tOut.Completed:Wait()
		end
	end)
end

for _, p in ipairs(particleRefs) do
	animateParticle(p)
end

-- LAYER 3: CENTERED CARD
local cardShadow = makeFrame(UDim2.fromOffset(688, 40), UDim2.new(0.5, 0, 0.5, 4), Color3.new(0, 0, 0), 0.5, 9, gui)
cardShadow.AnchorPoint = Vector2.new(0.5, 0.5)
makeCorner(12, cardShadow)

local card = makeFrame(UDim2.fromOffset(680, 40), UDim2.new(0.5, 0, 0.5, 0), C.card, 0, 10, gui)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.AutomaticSize = Enum.AutomaticSize.Y
makeCorner(12, card)
makeStroke(C.gold, 1, 0.7, card)

local cardList = Instance.new("UIListLayout")
cardList.FillDirection = Enum.FillDirection.Vertical
cardList.SortOrder = Enum.SortOrder.LayoutOrder
cardList.Padding = UDim.new(0, 0)
cardList.Parent = card

local maxCardHeightScale = 0.85

local function sectionContainer(order, leftPad, rightPad, topPad, bottomPad)
	local section = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.card, 1, 11, card)
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.LayoutOrder = order
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, leftPad)
	pad.PaddingRight = UDim.new(0, rightPad)
	pad.PaddingTop = UDim.new(0, topPad)
	pad.PaddingBottom = UDim.new(0, bottomPad)
	pad.Parent = section
	return section
end

-- HEADER SECTION
local header = sectionContainer(1, 36, 36, 32, 0)
local earlyAccess = makeLabel("EARLY ACCESS", Enum.Font.GothamBold, 11, C.gold, 0.3, Enum.TextXAlignment.Left, 12, header)
earlyAccess.Size = UDim2.new(1, 0, 0, 16)

local logo = makeLabel("LIFTED", Enum.Font.GothamBlack, 64, C.gold, 0, Enum.TextXAlignment.Left, 12, header)
logo.Size = UDim2.new(1, 0, 0, 72)
logo.Position = UDim2.new(0, 0, 0, 18)

local divider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 102), C.gold, 0.6, 12, header)

local tagline = makeLabel("Steal the idol. Don't get caught.", Enum.Font.Gotham, 15, Color3.fromRGB(200, 200, 210), 0.3, Enum.TextXAlignment.Left, 12, header)
tagline.Size = UDim2.new(1, 0, 0, 20)
tagline.Position = UDim2.new(0, 0, 0, 118)

task.spawn(function()
	local full = "Steal the idol. Don't get caught."
	tagline.Text = ""
	for i = 1, #full do
		if not gui.Parent then
			return
		end
		tagline.Text = string.sub(full, 1, i)
		task.wait(0.03)
	end
end)

local ornamentRow = makeFrame(UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 146), C.card, 1, 12, header)

local lineL = makeFrame(UDim2.fromOffset(80, 1), UDim2.new(0.5, -100, 0.5, 0), C.gold, 0.55, 12, ornamentRow)
lineL.AnchorPoint = Vector2.new(1, 0.5)
local lineR = makeFrame(UDim2.fromOffset(80, 1), UDim2.new(0.5, 100, 0.5, 0), C.gold, 0.55, 12, ornamentRow)
lineR.AnchorPoint = Vector2.new(0, 0.5)
for i = -1, 1 do
	local d = makeFrame(UDim2.fromOffset(6, 6), UDim2.new(0.5, i * 12, 0.5, 0), C.gold, 0.55, 12, ornamentRow)
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Rotation = 45
end
header.Size = UDim2.new(1, 0, 0, 178)

-- NAV SECTION
local nav = sectionContainer(2, 24, 24, 24, 0)
local menuLabel = makeLabel("MENU", Enum.Font.GothamBold, 10, Color3.fromRGB(150, 150, 170), 0.2, Enum.TextXAlignment.Left, 12, nav)
menuLabel.Size = UDim2.new(1, 0, 0, 14)

local navButtonsWrap = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 24), C.card, 1, 12, nav)
navButtonsWrap.AutomaticSize = Enum.AutomaticSize.Y
local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 8)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = navButtonsWrap

local currentTab = "play"
local navDefs = {
	{ key = "play", text = "PLAY" },
	{ key = "howtoplay", text = "HOW TO PLAY" },
	{ key = "credits", text = "CREDITS" },
}

local navRefs = {}

local function styleButton(ref, state)
	local isSelected = (state == "selected")
	local bg = isSelected and Color3.fromRGB(20, 21, 32) or Color3.fromRGB(16, 17, 26)
	local accentT = isSelected and 0.1 or 0.85
	local txt = isSelected and C.gold or C.text
	local arrowT = isSelected and 0 or 0.4
	playTween(ref.key .. "_bg", ref.buttonCore, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = bg,
	})
	playTween(ref.key .. "_accent", ref.accent, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = accentT,
	})
	playTween(ref.key .. "_text", ref.label, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextColor3 = txt,
	})
	playTween(ref.key .. "_arrow", ref.arrow, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextColor3 = isSelected and C.gold or Color3.fromRGB(150, 150, 170),
		TextTransparency = arrowT,
	})
end

for i, def in ipairs(navDefs) do
	local btn = Instance.new("TextButton")
	btn.Name = def.key
	btn.AutoButtonColor = false
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(1, 0, 0, 52)
	btn.LayoutOrder = i
	btn.ZIndex = 12
	btn.Parent = navButtonsWrap

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
		buttonCore = core,
		accent = accent,
		label = label,
		arrow = arrow,
	}
	table.insert(navRefs, ref)

	btn.MouseEnter:Connect(function()
		if currentTab ~= def.key then
			styleButton(ref, "selected")
		end
	end)
	btn.MouseLeave:Connect(function()
		if currentTab ~= def.key then
			styleButton(ref, "default")
		end
	end)

	btn.MouseButton1Down:Connect(function()
		playTween(def.key .. "_press", btn, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 50) })
	end)
	btn.MouseButton1Up:Connect(function()
		playTween(def.key .. "_release", btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 52) })
	end)
end

nav.Size = UDim2.new(1, 0, 0, 214)

-- CONTENT SECTION
local contentSection = sectionContainer(3, 8, 8, 10, 0)
local contentScroller = Instance.new("ScrollingFrame")
contentScroller.BackgroundTransparency = 1
contentScroller.BorderSizePixel = 0
contentScroller.Position = UDim2.fromScale(0, 0)
contentScroller.Size = UDim2.new(1, 0, 0, 420)
contentScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentScroller.ScrollBarThickness = 4
contentScroller.ScrollBarImageColor3 = C.gold
contentScroller.CanvasSize = UDim2.new()
contentScroller.ZIndex = 12
contentScroller.Parent = contentSection

local content = makeFrame(UDim2.new(1, -4, 0, 0), UDim2.fromOffset(0, 0), C.card, 1, 12, contentScroller)
content.AutomaticSize = Enum.AutomaticSize.Y

local contentList = Instance.new("UIListLayout")
contentList.Padding = UDim.new(0, 10)
contentList.SortOrder = Enum.SortOrder.LayoutOrder
contentList.Parent = content

local statusPulseDot
local findMatchButton
local findMatchLabel
local searching = false
local tipLabel

local function cardRow(order)
	local frame = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.cardMuted, 0, 12, content)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.LayoutOrder = order
	makeCorner(10, frame)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.Parent = frame
	return frame
end

local function clearContent()
	for _, child in ipairs(content:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	statusPulseDot = nil
	tipLabel = nil
	findMatchButton = nil
	findMatchLabel = nil
	searching = false
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

local function buildPlayContent()
	local matchCard = cardRow(1)
	local left = makeLabel("4 VS 1", Enum.Font.GothamBlack, 28, C.gold, 0, Enum.TextXAlignment.Left, 13, matchCard)
	left.Size = UDim2.new(0.45, 0, 0, 40)
	local vLine = makeFrame(UDim2.new(0, 1, 0, 36), UDim2.new(0.5, 0, 0, 6), C.gold, 0.8, 13, matchCard)
	local right = makeLabel("Asymmetric Heist", Enum.Font.Gotham, 13, C.textMuted, 0, Enum.TextXAlignment.Right, 13, matchCard)
	right.Size = UDim2.new(0.48, 0, 0, 40)
	right.Position = UDim2.new(0.52, 0, 0, 0)

	local serverCard = cardRow(2)
	statusPulseDot = makeFrame(UDim2.fromOffset(5, 5), UDim2.new(0, 2, 0, 8), C.blue, 0, 13, serverCard)
	makeCorner(99, statusPulseDot)
	local s1 = makeLabel("SERVERS ONLINE", Enum.Font.GothamBold, 12, C.text, 0, Enum.TextXAlignment.Left, 13, serverCard)
	s1.Size = UDim2.new(0.5, -8, 0, 16)
	s1.Position = UDim2.new(0, 14, 0, 0)
	local s2 = makeLabel("Matchmaking available", Enum.Font.Gotham, 12, C.textMuted, 0, Enum.TextXAlignment.Right, 13, serverCard)
	s2.Size = UDim2.new(0.48, 0, 0, 16)
	s2.Position = UDim2.new(0.52, 0, 0, 0)

	local seasonCard = cardRow(3)
	local seasonTitle = makeLabel("✦  SEASON 1 — The Cursed Temple", Enum.Font.GothamBold, 13, C.gold, 0, Enum.TextXAlignment.Left, 13, seasonCard)
	seasonTitle.Size = UDim2.new(1, 0, 0, 18)
	local seasonSub = makeLabel("Map 1 of many", Enum.Font.Gotham, 12, C.textMuted, 0.4, Enum.TextXAlignment.Left, 13, seasonCard)
	seasonSub.Size = UDim2.new(1, 0, 0, 16)
	seasonSub.Position = UDim2.new(0, 0, 0, 20)

	local tipsCard = cardRow(4)
	tipLabel = makeLabel(tips[tipIndex], Enum.Font.Gotham, 12, C.textMuted, 0, Enum.TextXAlignment.Left, 13, tipsCard)
	tipLabel.Size = UDim2.new(1, 0, 0, 34)
	tipLabel.TextWrapped = true
	tipLabel.Font = Enum.Font.Gotham

	local matchBtnWrap = makeFrame(UDim2.new(1, 0, 0, 54), UDim2.fromOffset(0, 0), C.card, 1, 12, content)
	matchBtnWrap.LayoutOrder = 5

	findMatchButton = Instance.new("TextButton")
	findMatchButton.AutoButtonColor = false
	findMatchButton.BackgroundColor3 = C.gold
	findMatchButton.BackgroundTransparency = 0
	findMatchButton.BorderSizePixel = 0
	findMatchButton.Size = UDim2.new(1, 0, 1, 0)
	findMatchButton.Text = ""
	findMatchButton.ZIndex = 13
	findMatchButton.Parent = matchBtnWrap
	makeCorner(10, findMatchButton)

	findMatchLabel = makeLabel("FIND MATCH", Enum.Font.GothamBlack, 15, Color3.fromRGB(8, 8, 12), 0, Enum.TextXAlignment.Center, 14, findMatchButton)
	findMatchLabel.Size = UDim2.new(1, 0, 1, 0)

	findMatchButton.MouseEnter:Connect(function()
		playTween("find_hover", findMatchButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(225, 180, 70) })
	end)
	findMatchButton.MouseLeave:Connect(function()
		playTween("find_leave", findMatchButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = C.gold })
	end)
	findMatchButton.MouseButton1Down:Connect(function()
		playTween("find_press", findMatchButton, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0.97, 0, 0.97, 0), Position = UDim2.new(0.015, 0, 0.015, 0) })
	end)
	findMatchButton.MouseButton1Up:Connect(function()
		playTween("find_release", findMatchButton, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0) })
	end)
	findMatchButton.Activated:Connect(function()
		if searching then
			return
		end
		searching = true
		playClickedBindable:Fire()
		task.spawn(function()
			local dots = 0
			while searching and gui.Enabled do
				dots = (dots % 3) + 1
				findMatchLabel.Text = "SEARCHING" .. string.rep(".", dots)
				task.wait(0.28)
			end
		end)
		task.delay(0.6, function()
			if not gui.Parent then
				return
			end
			local function hide()
				playTween("card_hide", card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 18) })
				playTween("shadow_hide", cardShadow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 22) })
				playTween("gui_fade", tintFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 0 })
				task.delay(0.3, function()
					if gui.Parent then
						gui.Enabled = false
					end
				end)
			end
			hide()
		end)
	end)
end

local function buildHowToPlayContent()
	local headWrap = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.card, 1, 12, content)
	headWrap.AutomaticSize = Enum.AutomaticSize.Y
	headWrap.LayoutOrder = 1
	local h = makeLabel("HOW TO PLAY", Enum.Font.GothamBlack, 20, C.text, 0, Enum.TextXAlignment.Left, 13, headWrap)
	h.Size = UDim2.new(1, 0, 0, 24)
	local hs = makeLabel("Master the heist. Outsmart the guardian.", Enum.Font.Gotham, 13, C.textMuted, 0, Enum.TextXAlignment.Left, 13, headWrap)
	hs.Size = UDim2.new(1, 0, 0, 18)
	hs.Position = UDim2.new(0, 0, 0, 26)
	local hd = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 52), C.gold, 0.65, 13, headWrap)
	headWrap.Size = UDim2.new(1, 0, 0, 62)

	local cards = {
		{"01", "THE OBJECTIVE", "4 thieves infiltrate the cursed temple, solve the brazier puzzle, steal the golden idol, and extract before the timer expires."},
		{"02", "THE BRAZIER PUZZLE", "Press F near a brazier to light it. All 4 must be lit in sequence. Wrong order resets your progress. The guardian can extinguish lit braziers."},
		{"03", "THE GUARDIAN", "Hunt the thieves. Press E to catch them. Press F to extinguish braziers. Sprint with Shift — 10 second cooldown."},
	}

	for i, data in ipairs(cards) do
		local row = cardRow(i + 1)
		local accent = makeFrame(UDim2.new(0, 3, 1, 0), UDim2.fromScale(0, 0), C.gold, 0.15, 13, row)
		accent.Name = "AccentBar"
		local num = makeLabel(data[1], Enum.Font.GothamBlack, 28, C.gold, 0.25, Enum.TextXAlignment.Left, 13, row)
		num.Size = UDim2.new(0, 54, 0, 32)
		local title = makeLabel(data[2], Enum.Font.GothamBold, 14, C.text, 0, Enum.TextXAlignment.Left, 13, row)
		title.Size = UDim2.new(1, -80, 0, 20)
		title.Position = UDim2.new(0, 64, 0, 0)
		local body = makeLabel(data[3], Enum.Font.Gotham, 12, C.textMuted, 0, Enum.TextXAlignment.Left, 13, row)
		body.Size = UDim2.new(1, -80, 0, 0)
		body.Position = UDim2.new(0, 64, 0, 22)
		body.TextWrapped = true
		body.AutomaticSize = Enum.AutomaticSize.Y
	end
end

local function buildCreditsContent()
	local headWrap = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.card, 1, 12, content)
	headWrap.AutomaticSize = Enum.AutomaticSize.Y
	headWrap.LayoutOrder = 1
	local h = makeLabel("CREDITS", Enum.Font.GothamBlack, 20, C.text, 0, Enum.TextXAlignment.Left, 13, headWrap)
	h.Size = UDim2.new(1, 0, 0, 24)
	local hs = makeLabel("An independent game by two developers.", Enum.Font.Gotham, 13, C.textMuted, 0, Enum.TextXAlignment.Left, 13, headWrap)
	hs.Size = UDim2.new(1, 0, 0, 18)
	hs.Position = UDim2.new(0, 0, 0, 26)
	local hd = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 52), C.gold, 0.65, 13, headWrap)
	headWrap.Size = UDim2.new(1, 0, 0, 62)

	local devRow = makeFrame(UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 0), C.card, 1, 12, content)
	devRow.LayoutOrder = 2
	devRow.AutomaticSize = Enum.AutomaticSize.Y
	local horiz = Instance.new("UIListLayout")
	horiz.FillDirection = Enum.FillDirection.Horizontal
	horiz.Padding = UDim.new(0, 10)
	horiz.Parent = devRow

	local function devCard(order, name, role, roleColor, detail, note, dotColor)
		local cardDev = makeFrame(UDim2.new(0.5, -5, 0, 0), UDim2.fromOffset(0, 0), C.cardMuted, 0, 12, devRow)
		cardDev.LayoutOrder = order
		cardDev.AutomaticSize = Enum.AutomaticSize.Y
		makeCorner(10, cardDev)
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, 18)
		p.PaddingRight = UDim.new(0, 18)
		p.PaddingTop = UDim.new(0, 16)
		p.PaddingBottom = UDim.new(0, 16)
		p.Parent = cardDev
		local bar = makeFrame(UDim2.new(0, 3, 1, 0), UDim2.fromScale(0, 0), C.gold, 0.15, 13, cardDev)
		bar.Name = "AccentBar"
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
		return cardDev
	end

	devCard(1, "CHARLIE MARTIN", "Lead Developer & Game Designer", C.gold, "Core systems · Networking · Game logic · UI", "16 y/o indie developer", C.gold)
	devCard(2, "MARTIN JARSKY", "World Builder & Visual Designer", C.blue, "Map design · Lighting · Asset pipeline", nil, C.blue)

	local stats = cardRow(3)
	local cols = makeFrame(UDim2.new(1, 0, 0, 38), UDim2.new(0, 0, 0, 0), C.cardMuted, 1, 13, stats)
	local cl = Instance.new("UIListLayout")
	cl.FillDirection = Enum.FillDirection.Horizontal
	cl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cl.VerticalAlignment = Enum.VerticalAlignment.Center
	cl.Parent = cols
	local function statCol(text)
		local c = makeFrame(UDim2.new(1/3, -4, 1, 0), UDim2.fromOffset(0, 0), C.cardMuted, 1, 13, cols)
		local top = makeLabel(text, Enum.Font.GothamBold, 13, C.gold, 0, Enum.TextXAlignment.Center, 14, c)
		top.Size = UDim2.new(1, 0, 0.6, 0)
		local bot = makeLabel("LABEL", Enum.Font.Gotham, 11, C.textMuted, 0.2, Enum.TextXAlignment.Center, 14, c)
		bot.Size = UDim2.new(1, 0, 0.4, 0)
		bot.Position = UDim2.new(0, 0, 0.6, 0)
	end
	statCol("MAPS: 1")
	statCol("MODES: 1")
	statCol("SEASON: 1")
end

local function fadeContentSwap(builder)
	for _, d in ipairs(content:GetDescendants()) do
		if d:IsA("TextLabel") then
			playTween("fade_out_txt" .. d:GetDebugId(), d, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 })
		elseif d:IsA("Frame") and d ~= content then
			playTween("fade_out_bg" .. d:GetDebugId(), d, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
		end
	end
	task.delay(0.11, function()
		if not gui.Parent then
			return
		end
		clearContent()
		builder()
		for _, d in ipairs(content:GetDescendants()) do
			if d:IsA("TextLabel") then
				d.TextTransparency = 1
				playTween("fade_in_txt" .. d:GetDebugId(), d, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
			elseif d:IsA("Frame") and d ~= content then
				d:SetAttribute("BaseTransparency", d.BackgroundTransparency)
				d.BackgroundTransparency = 1
				playTween("fade_in_bg" .. d:GetDebugId(), d, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = d:GetAttribute("BaseTransparency") or 0 })
			end
		end
	end)
end

local function selectTab(tab)
	currentTab = tab
	for _, ref in ipairs(navRefs) do
		if ref.key == tab then
			styleButton(ref, "selected")
		else
			styleButton(ref, "default")
		end
	end

	if tab == "play" then
		fadeContentSwap(buildPlayContent)
	elseif tab == "howtoplay" then
		fadeContentSwap(buildHowToPlayContent)
	else
		fadeContentSwap(buildCreditsContent)
	end
end

for _, ref in ipairs(navRefs) do
	ref.button.Activated:Connect(function()
		if currentTab ~= ref.key then
			selectTab(ref.key)
		end
	end)
end

-- FOOTER SECTION
local footer = sectionContainer(4, 16, 16, 16, 24)
local footerDivider = makeFrame(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.gold, 0.88, 12, footer)

local versionLabel = makeLabel("v0.1.0 · Early Access", Enum.Font.Gotham, 11, Color3.fromRGB(120, 120, 140), 0, Enum.TextXAlignment.Left, 12, footer)
versionLabel.Size = UDim2.new(0, 220, 0, 18)
versionLabel.Position = UDim2.new(0, 0, 0, 8)

local onlineDot = makeFrame(UDim2.fromOffset(5, 5), UDim2.new(0, 0, 0, 29), C.blue, 0, 12, footer)
makeCorner(99, onlineDot)
local onlineLabel = makeLabel("0 PLAYERS ONLINE", Enum.Font.Gotham, 11, Color3.fromRGB(150, 150, 170), 0, Enum.TextXAlignment.Left, 12, footer)
onlineLabel.Size = UDim2.new(0, 180, 0, 16)
onlineLabel.Position = UDim2.new(0, 10, 0, 24)

local function footerButton(text, xOffset, color)
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0
	btn.BorderSizePixel = 0
	btn.Size = UDim2.fromOffset(110, 34)
	btn.Position = UDim2.new(1, xOffset, 0, 10)
	btn.Text = ""
	btn.ZIndex = 12
	btn.Parent = footer
	makeCorner(8, btn)
	local t = makeLabel(text, Enum.Font.GothamBold, 12, C.white, 0, Enum.TextXAlignment.Center, 13, btn)
	t.Size = UDim2.new(1, 0, 1, 0)
	btn.MouseEnter:Connect(function()
		playTween("footer_h_" .. text, btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.1 })
	end)
	btn.MouseLeave:Connect(function()
		playTween("footer_l_" .. text, btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 })
	end)
	return btn
end

footerButton("Discord", -232, Color3.fromRGB(88, 101, 242))
footerButton("Roblox", -116, C.gold)
footer.Size = UDim2.new(1, 0, 0, 70)

local tintFrame = makeFrame(UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.bg, 0.52, 8, gui)

local function enforceCardMaxHeight()
	local maxHeight = gui.AbsoluteSize.Y * maxCardHeightScale
	local target = math.min(math.max(card.AbsoluteSize.Y, 0), maxHeight)
	card.Size = UDim2.fromOffset(680, target)
	cardShadow.Size = UDim2.fromOffset(688, target + 8)

	local headerH = header.AbsoluteSize.Y
	local navH = nav.AbsoluteSize.Y
	local footerH = footer.AbsoluteSize.Y
	local chrome = headerH + navH + footerH + 18
	local available = math.max(120, target - chrome)
	contentScroller.Size = UDim2.new(1, 0, 0, available)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(enforceCardMaxHeight)
card:GetPropertyChangedSignal("AbsoluteSize"):Connect(enforceCardMaxHeight)

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
	playTween("hide_tint", tintFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 0,
	})
	task.delay(0.34, function()
		if gui.Parent then
			gui.Enabled = false
		end
	end)
end

roleAssignedRemote.OnClientEvent:Connect(hideMenu)

-- Entrance animation
card.Position = UDim2.new(0.5, 0, 0.5, 20)
card.BackgroundTransparency = 1
cardShadow.Position = UDim2.new(0.5, 0, 0.5, 24)
cardShadow.BackgroundTransparency = 1
setTreeTransparency(card, 1)

enforceCardMaxHeight()
selectTab("play")

task.delay(0.1, function()
	playTween("entrance_card", card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0,
	})
	playTween("entrance_shadow", cardShadow, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 4),
		BackgroundTransparency = 0.5,
	})
	playTween("entrance_tint", tintFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.52,
	})

	for _, d in ipairs(header:GetDescendants()) do
		if d:IsA("TextLabel") then
			d.TextTransparency = 1
			playTween("h_text" .. d:GetDebugId(), d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
		end
	end

	task.delay(0.05, function()
		for _, d in ipairs(nav:GetDescendants()) do
			if d:IsA("TextLabel") then
				d.TextTransparency = 1
				playTween("n_text" .. d:GetDebugId(), d, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
			end
		end
	end)

	task.delay(0.1, function()
		for _, d in ipairs(content:GetDescendants()) do
			if d:IsA("TextLabel") then
				d.TextTransparency = 1
				playTween("c_text" .. d:GetDebugId(), d, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
			end
		end
	end)
end)

-- subtle pulses
local pulseT = 0
local tipT = 0
local arrowPulse = 0
local navArrowBase = 18

local run = game:GetService("RunService")
run.Heartbeat:Connect(function(dt)
	pulseT += dt
	tipT += dt
	arrowPulse += dt

	if onlineDot and onlineDot.Parent then
		onlineDot.BackgroundTransparency = 0.2 + (math.sin(pulseT * 3.2) * 0.2 + 0.2)
	end
	if statusPulseDot and statusPulseDot.Parent then
		statusPulseDot.BackgroundTransparency = 0.1 + (math.sin(pulseT * 4) * 0.2 + 0.2)
	end

	for _, ref in ipairs(navRefs) do
		if ref.key == currentTab then
			ref.arrow.TextSize = navArrowBase + math.floor((math.sin(arrowPulse * 4) + 1) * 1)
		end
	end

	if tipLabel and tipLabel.Parent and currentTab == "play" and tipT >= 5 then
		tipT = 0
		tipIndex = (tipIndex % #tips) + 1
		playTween("tip_out", tipLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 })
		task.delay(0.13, function()
			if tipLabel and tipLabel.Parent and currentTab == "play" then
				tipLabel.Text = tips[tipIndex]
				tipLabel.TextTransparency = 1
				playTween("tip_in", tipLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
			end
		end)
	end
end)
