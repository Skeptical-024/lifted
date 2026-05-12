-- RoundUIClient v3

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local roundStartedRemote = ReplicatedStorage:WaitForChild("RoundStarted")
local roundEndedRemote = ReplicatedStorage:WaitForChild("RoundEnded")
local thiefCountUpdateRemote = ReplicatedStorage:WaitForChild("ThiefCountUpdate")
local brazierProgressUpdateRemote = ReplicatedStorage:WaitForChild("BrazierProgressUpdate")
local setMovementStateRemote = ReplicatedStorage:WaitForChild("SetMovementState")
local thiefCaughtRemote = ReplicatedStorage:WaitForChild("ThiefCaught")

local COLORS = {
	bg = Color3.fromRGB(8, 10, 16),
	panel = Color3.fromRGB(12, 16, 24),
	panelSoft = Color3.fromRGB(18, 24, 34),
	white = Color3.fromRGB(245, 248, 255),
	grey = Color3.fromRGB(150, 165, 185),
	teal = Color3.fromRGB(120, 220, 255),
	tealDeep = Color3.fromRGB(40, 150, 220),
	red = Color3.fromRGB(230, 65, 75),
	warning = Color3.fromRGB(255, 150, 80),
	gold = Color3.fromRGB(220, 175, 55),
}

local function tweenIn(element, property, targetValue, duration, style, direction)
	local props = {}
	props[property] = targetValue
	local t = TweenService:Create(element, TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
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
gui.Name = "RoundUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local timerPanel = makePanel(UDim2.fromOffset(160, 56), UDim2.new(0.5, -80, 0, -20), gui, 0.2)
local timerShadow = makeShadow(timerPanel)
timerPanel.Visible = false
timerShadow.Visible = false

local objectiveDirectiveLabel = Instance.new("TextLabel")
objectiveDirectiveLabel.Parent = gui
objectiveDirectiveLabel.Size = UDim2.fromOffset(280, 20)
objectiveDirectiveLabel.Position = UDim2.new(0.5, -140, 0, 80)
objectiveDirectiveLabel.BackgroundTransparency = 1
objectiveDirectiveLabel.Font = Enum.Font.GothamBold
objectiveDirectiveLabel.TextSize = 13
objectiveDirectiveLabel.TextColor3 = COLORS.grey
objectiveDirectiveLabel.TextXAlignment = Enum.TextXAlignment.Center
objectiveDirectiveLabel.Text = ""
objectiveDirectiveLabel.Visible = false
objectiveDirectiveLabel.ZIndex = 5

local timerStroke = timerPanel:FindFirstChildOfClass("UIStroke")
if timerStroke then
	timerStroke.Color = COLORS.teal
	timerStroke.Transparency = 0.4
end

local timerTitle = makeLabel("TIME REMAINING", Enum.Font.GothamBold, COLORS.grey, timerPanel)
timerTitle.Size = UDim2.new(1, 0, 0, 14)
timerTitle.TextSize = 11
timerTitle.Position = UDim2.fromOffset(0, 2)

local timerText = makeLabel("8:00", Enum.Font.GothamBlack, COLORS.white, timerPanel)
timerText.Size = UDim2.new(1, 0, 1, -8)
timerText.Position = UDim2.fromOffset(0, 8)
timerText.TextSize = 30

local roleBadge = makePanel(UDim2.fromOffset(140, 36), UDim2.new(0, -180, 0, 16), gui, 0.2)
local roleShadow = makeShadow(roleBadge)
roleBadge.Visible = false
roleShadow.Visible = false
local roleDot = Instance.new("Frame")
roleDot.Size = UDim2.fromOffset(10, 10)
roleDot.Position = UDim2.fromOffset(12, 13)
roleDot.BorderSizePixel = 0
roleDot.Parent = roleBadge
local roleDotCorner = Instance.new("UICorner")
roleDotCorner.CornerRadius = UDim.new(1, 0)
roleDotCorner.Parent = roleDot
local roleText = makeLabel("ROLE", Enum.Font.GothamBold, COLORS.white, roleBadge)
roleText.Size = UDim2.new(1, -28, 1, 0)
roleText.Position = UDim2.fromOffset(24, 0)
roleText.TextSize = 18
roleText.TextXAlignment = Enum.TextXAlignment.Left

local brazierPanel = makePanel(UDim2.fromOffset(220, 88), UDim2.new(0, 16, 1, -96), gui, 0.2)
local brazierShadow = makeShadow(brazierPanel)
brazierShadow.Size = brazierPanel.Size
brazierShadow.Position = brazierPanel.Position + UDim2.fromOffset(2, 2)
brazierPanel.Visible = false
brazierShadow.Visible = false
local bs = brazierPanel:FindFirstChildOfClass("UIStroke")
if bs then
	bs.Color = COLORS.teal
	bs.Transparency = 0.35
end

local brazierTitle = makeLabel("SEALS", Enum.Font.GothamBold, COLORS.grey, brazierPanel)
brazierTitle.Size = UDim2.new(1, 0, 0, 14)
brazierTitle.Position = UDim2.fromOffset(0, 2)
brazierTitle.TextSize = 12

local brazierIcons = {}
local sealNames = {
	[1] = "FLAME",
	[2] = "MOON",
	[3] = "SIGIL",
}
for i = 1, 3 do
	local sq = Instance.new("Frame")
	sq.Size = UDim2.fromOffset(20, 20)
	sq.Position = UDim2.fromOffset(10 + (i - 1) * 28, 26)
	sq.BackgroundColor3 = COLORS.panelSoft
	sq.Parent = brazierPanel
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = sq
	local s = Instance.new("UIStroke")
	s.Color = COLORS.white
	s.Transparency = 0.85
	s.Parent = sq
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromOffset(20, 10)
	nameLabel.Position = UDim2.fromOffset(10 + (i - 1) * 28, 49)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = sealNames[i] or ""
	nameLabel.TextSize = 8
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = COLORS.teal
	nameLabel.TextTransparency = 0.5
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Parent = brazierPanel
	brazierIcons[i] = {frame = sq, stroke = s, label = nameLabel}
end

local vaultStatusLabel = makeLabel("VAULT SEALED", Enum.Font.GothamBold, COLORS.grey, brazierPanel)
vaultStatusLabel.Name = "VaultStatusLabel"
vaultStatusLabel.Position = UDim2.fromOffset(0, 66)
vaultStatusLabel.Size = UDim2.new(1, 0, 0, 14)
vaultStatusLabel.TextSize = 11
vaultStatusLabel.BackgroundTransparency = 1

local guardianStatusPanel = makePanel(
	UDim2.fromOffset(240, 124),
	UDim2.new(0, 16, 1, -192),
	gui, 0.2
)
local guardianStatusShadow = makeShadow(guardianStatusPanel)
guardianStatusPanel.Visible = false
guardianStatusShadow.Visible = false

local gspStroke = guardianStatusPanel:FindFirstChildOfClass("UIStroke")
if gspStroke then
	gspStroke.Color = COLORS.red
	gspStroke.Transparency = 0.35
end

local guardianTitleLabel = makeLabel("GUARDIAN", Enum.Font.GothamBold, COLORS.red, guardianStatusPanel)
guardianTitleLabel.Size = UDim2.new(1, 0, 0, 13)
guardianTitleLabel.TextSize = 11

local guardianDirectiveLabel = makeLabel("STOP THE THIEVES", Enum.Font.GothamBold, COLORS.white, guardianStatusPanel)
guardianDirectiveLabel.Size = UDim2.new(1, 0, 0, 18)
guardianDirectiveLabel.Position = UDim2.fromOffset(0, 14)
guardianDirectiveLabel.TextSize = 15

local guardianCatchPromptLabel = makeLabel("", Enum.Font.GothamBold, COLORS.teal, guardianStatusPanel)
guardianCatchPromptLabel.Size = UDim2.new(1, 0, 0, 14)
guardianCatchPromptLabel.Position = UDim2.fromOffset(0, 34)
guardianCatchPromptLabel.TextSize = 12

local guardianSprintLabel = makeLabel("SPRINT READY", Enum.Font.GothamBold, COLORS.grey, guardianStatusPanel)
guardianSprintLabel.Size = UDim2.new(1, 0, 0, 13)
guardianSprintLabel.Position = UDim2.fromOffset(0, 50)
guardianSprintLabel.TextSize = 11

local guardianCarrierLabel = makeLabel("", Enum.Font.Gotham, COLORS.red, guardianStatusPanel)
guardianCarrierLabel.Size = UDim2.new(1, 0, 0, 14)
guardianCarrierLabel.Position = UDim2.fromOffset(0, 65)
guardianCarrierLabel.TextSize = 12

local guardianAlertLabel = makeLabel("", Enum.Font.GothamBold, COLORS.red, guardianStatusPanel)
guardianAlertLabel.Size = UDim2.new(1, 0, 0, 14)
guardianAlertLabel.Position = UDim2.fromOffset(0, 82)
guardianAlertLabel.TextSize = 11

local thiefPanel = makePanel(UDim2.fromOffset(220, 52), UDim2.new(1, -236, 1, -68), gui, 0.2)
local thiefShadow = makeShadow(thiefPanel)
thiefPanel.Visible = false
thiefShadow.Visible = false
local ts = thiefPanel:FindFirstChildOfClass("UIStroke")
if ts then
	ts.Color = COLORS.red
	ts.Transparency = 0.35
end
local thiefTitle = makeLabel("THIEVES", Enum.Font.GothamBold, COLORS.grey, thiefPanel)
thiefTitle.Size = UDim2.new(1, 0, 0, 14)
thiefTitle.TextSize = 12
local thiefIconFrames = {}
for i = 1, 4 do
	local sq = Instance.new("Frame")
	sq.Size = UDim2.fromOffset(20, 20)
	sq.Position = UDim2.fromOffset(10 + (i - 1) * 28, 24)
	sq.BackgroundColor3 = COLORS.red
	sq.Visible = false
	sq.Parent = thiefPanel
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = sq
	local t = makeLabel("", Enum.Font.GothamBold, COLORS.white, sq)
	t.Size = UDim2.fromScale(1, 1)
	t.TextSize = 16
	thiefIconFrames[i] = {frame = sq, label = t}
end

local sprintPanel = makePanel(UDim2.fromOffset(220, 36), UDim2.new(1, -236, 1, -112), gui, 0.2)
local sprintShadow = makeShadow(sprintPanel)
sprintPanel.Visible = false
sprintShadow.Visible = false
local sprintLabel = makeLabel("SPRINT", Enum.Font.GothamBold, COLORS.white, sprintPanel)
sprintLabel.Size = UDim2.fromOffset(64, 20)
sprintLabel.Position = UDim2.fromOffset(8, 8)
sprintLabel.TextSize = 14
local barBg = Instance.new("Frame")
barBg.Size = UDim2.fromOffset(136, 12)
barBg.Position = UDim2.fromOffset(74, 12)
barBg.BackgroundColor3 = COLORS.panelSoft
barBg.BorderSizePixel = 0
barBg.Parent = sprintPanel
local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(0, 6)
barBgCorner.Parent = barBg
local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(1, 1)
barFill.BackgroundColor3 = COLORS.white
barFill.BorderSizePixel = 0
barFill.Parent = barBg
local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(0, 6)
barFillCorner.Parent = barFill

local crouchPanel = makePanel(UDim2.fromOffset(140, 32), UDim2.new(1, -156, 1, -68), gui, 0.2)
local crouchShadow = makeShadow(crouchPanel)
crouchPanel.Visible = false
crouchShadow.Visible = false
local crouchText = makeLabel("CROUCHING", Enum.Font.GothamBold, COLORS.teal, crouchPanel)
crouchText.Size = UDim2.fromScale(1, 1)
crouchText.TextSize = 14

local idolStatusPanel = makePanel(
	UDim2.fromOffset(220, 80),
	UDim2.new(0.5, -110, 1, -148),
	gui, 0.2
)
local idolStatusShadow = makeShadow(idolStatusPanel)
idolStatusPanel.Visible = false
idolStatusShadow.Visible = false

local objectiveInteractionPanel = makePanel(
	UDim2.fromOffset(220, 92),
	UDim2.new(0.5, -110, 1, -244),
	gui, 0.2
)
local objectiveInteractionShadow = makeShadow(objectiveInteractionPanel)
objectiveInteractionPanel.Visible = false
objectiveInteractionShadow.Visible = false

local oipStroke = objectiveInteractionPanel:FindFirstChildOfClass("UIStroke")
if oipStroke then
	oipStroke.Color = COLORS.teal
	oipStroke.Transparency = 0.35
end

local objectiveNameLabel = makeLabel("", Enum.Font.GothamBold, COLORS.grey, objectiveInteractionPanel)
objectiveNameLabel.Size = UDim2.new(1, 0, 0, 13)
objectiveNameLabel.TextSize = 11

local objectivePromptLabel = makeLabel("", Enum.Font.Gotham, COLORS.white, objectiveInteractionPanel)
objectivePromptLabel.Size = UDim2.new(1, 0, 0, 16)
objectivePromptLabel.Position = UDim2.fromOffset(0, 14)
objectivePromptLabel.TextSize = 13

local objectiveProgressBack = Instance.new("Frame")
objectiveProgressBack.Size = UDim2.new(1, -16, 0, 8)
objectiveProgressBack.Position = UDim2.fromOffset(8, 34)
objectiveProgressBack.BackgroundColor3 = COLORS.panelSoft
objectiveProgressBack.BorderSizePixel = 0
objectiveProgressBack.Parent = objectiveInteractionPanel
local opbCorner = Instance.new("UICorner")
opbCorner.CornerRadius = UDim.new(0, 4)
opbCorner.Parent = objectiveProgressBack

local objectiveProgressFill = Instance.new("Frame")
objectiveProgressFill.Size = UDim2.fromScale(0, 1)
objectiveProgressFill.BackgroundColor3 = COLORS.teal
objectiveProgressFill.BorderSizePixel = 0
objectiveProgressFill.Parent = objectiveProgressBack
local opfCorner = Instance.new("UICorner")
opfCorner.CornerRadius = UDim.new(0, 4)
opfCorner.Parent = objectiveProgressFill

local objectiveProgressLabel = makeLabel("", Enum.Font.GothamBold, COLORS.teal, objectiveInteractionPanel)
objectiveProgressLabel.Size = UDim2.new(1, 0, 0, 12)
objectiveProgressLabel.Position = UDim2.fromOffset(0, 46)
objectiveProgressLabel.TextSize = 10

local objectiveDangerLabel = makeLabel("", Enum.Font.GothamBold, COLORS.red, objectiveInteractionPanel)
objectiveDangerLabel.Size = UDim2.new(1, 0, 0, 14)
objectiveDangerLabel.Position = UDim2.fromOffset(0, 62)
objectiveDangerLabel.TextSize = 11

local skillCheckPanel = makePanel(
	UDim2.fromOffset(280, 64),
	UDim2.new(0.5, -140, 0.5, 80),
	gui, 0.15
)
local skillCheckShadow = makeShadow(skillCheckPanel)
skillCheckPanel.Visible = false
skillCheckShadow.Visible = false

local scpStroke = skillCheckPanel:FindFirstChildOfClass("UIStroke")
if scpStroke then
	scpStroke.Color = COLORS.teal
	scpStroke.Transparency = 0.3
end

local skillCheckLabel = makeLabel("TIMING CHECK", Enum.Font.GothamBold, COLORS.grey, skillCheckPanel)
skillCheckLabel.Size = UDim2.new(1, 0, 0, 13)
skillCheckLabel.TextSize = 11

local skillCheckBack = Instance.new("Frame")
skillCheckBack.Size = UDim2.new(1, -16, 0, 20)
skillCheckBack.Position = UDim2.fromOffset(8, 20)
skillCheckBack.BackgroundColor3 = COLORS.panelSoft
skillCheckBack.BorderSizePixel = 0
skillCheckBack.Parent = skillCheckPanel
local scbCorner = Instance.new("UICorner")
scbCorner.CornerRadius = UDim.new(0, 4)
scbCorner.Parent = skillCheckBack

local skillCheckTargetZone = Instance.new("Frame")
skillCheckTargetZone.Size = UDim2.fromScale(0.2, 1)
skillCheckTargetZone.Position = UDim2.fromScale(0.4, 0)
skillCheckTargetZone.BackgroundColor3 = COLORS.teal
skillCheckTargetZone.BackgroundTransparency = 0.5
skillCheckTargetZone.BorderSizePixel = 0
skillCheckTargetZone.Parent = skillCheckBack
local sctzCorner = Instance.new("UICorner")
sctzCorner.CornerRadius = UDim.new(0, 3)
sctzCorner.Parent = skillCheckTargetZone

local skillCheckNeedle = Instance.new("Frame")
skillCheckNeedle.Size = UDim2.new(0, 3, 1, 0)
skillCheckNeedle.Position = UDim2.fromScale(0, 0)
skillCheckNeedle.BackgroundColor3 = COLORS.white
skillCheckNeedle.BorderSizePixel = 0
skillCheckNeedle.Parent = skillCheckBack

local idolPanelStroke = idolStatusPanel:FindFirstChildOfClass("UIStroke")
if idolPanelStroke then
	idolPanelStroke.Color = COLORS.teal
	idolPanelStroke.Transparency = 0.35
end

local idolTitleLabel = makeLabel("IDOL", Enum.Font.GothamBold, COLORS.grey, idolStatusPanel)
idolTitleLabel.Size = UDim2.new(1, 0, 0, 14)
idolTitleLabel.TextSize = 11

local idolStatusLabel = makeLabel("VAULT LOCKED", Enum.Font.GothamBold, COLORS.white, idolStatusPanel)
idolStatusLabel.Size = UDim2.new(1, 0, 0, 18)
idolStatusLabel.Position = UDim2.fromOffset(0, 14)
idolStatusLabel.TextSize = 14

local carrierLabel = makeLabel("", Enum.Font.Gotham, COLORS.grey, idolStatusPanel)
carrierLabel.Size = UDim2.new(1, 0, 0, 14)
carrierLabel.Position = UDim2.fromOffset(0, 32)
carrierLabel.TextSize = 12

local extractProgressBack = Instance.new("Frame")
extractProgressBack.Size = UDim2.new(1, -16, 0, 8)
extractProgressBack.Position = UDim2.fromOffset(8, 50)
extractProgressBack.BackgroundColor3 = COLORS.panelSoft
extractProgressBack.BorderSizePixel = 0
extractProgressBack.Visible = false
extractProgressBack.Parent = idolStatusPanel
local epbCorner = Instance.new("UICorner")
epbCorner.CornerRadius = UDim.new(0, 4)
epbCorner.Parent = extractProgressBack

local extractProgressFill = Instance.new("Frame")
extractProgressFill.Size = UDim2.fromScale(0, 1)
extractProgressFill.BackgroundColor3 = COLORS.teal
extractProgressFill.BorderSizePixel = 0
extractProgressFill.Parent = extractProgressBack
local epfCorner = Instance.new("UICorner")
epfCorner.CornerRadius = UDim.new(0, 4)
epfCorner.Parent = extractProgressFill

local extractProgressLabel = makeLabel("", Enum.Font.GothamBold, COLORS.teal, idolStatusPanel)
extractProgressLabel.Size = UDim2.new(1, 0, 0, 12)
extractProgressLabel.Position = UDim2.fromOffset(0, 62)
extractProgressLabel.TextSize = 10

local killFeed = Instance.new("Frame")
killFeed.Size = UDim2.fromOffset(280, 160)
killFeed.Position = UDim2.new(1, -296, 0, 16)
killFeed.BackgroundTransparency = 1
killFeed.Parent = gui

local proximity = Instance.new("Frame")
proximity.Size = UDim2.fromOffset(60, 60)
proximity.AnchorPoint = Vector2.new(0.5, 0.5)
proximity.BackgroundColor3 = COLORS.red
proximity.BackgroundTransparency = 0.4
proximity.Visible = false
proximity.Parent = gui
local proxCorner = Instance.new("UICorner")
proxCorner.CornerRadius = UDim.new(1, 0)
proxCorner.Parent = proximity

-- Full-screen dimmer
local roundResultsOverlay = Instance.new("Frame")
roundResultsOverlay.Name = "RoundResultsOverlay"
roundResultsOverlay.Size = UDim2.fromScale(1, 1)
roundResultsOverlay.BackgroundColor3 = COLORS.bg
roundResultsOverlay.BackgroundTransparency = 1
roundResultsOverlay.Visible = false
roundResultsOverlay.ZIndex = 10
roundResultsOverlay.Parent = gui

-- Center modal
local resultPanel = makePanel(
	UDim2.fromOffset(560, 320),
	UDim2.new(0.5, -280, 0.5, -160),
	roundResultsOverlay, 0.1
)
local resultPanelShadow = makeShadow(resultPanel)
resultPanel.Visible = false
resultPanelShadow.Visible = false
resultPanel.ZIndex = 11

local resultStroke = resultPanel:FindFirstChildOfClass("UIStroke")

-- "ROUND OVER" eyebrow
local resultTop = makeLabel("ROUND OVER", Enum.Font.GothamBold, COLORS.grey, resultPanel)
resultTop.Size = UDim2.new(1, 0, 0, 16)
resultTop.TextSize = 12
resultTop.ZIndex = 12

-- Big title: "THIEVES ESCAPED" / "GUARDIAN WON" etc
local resultTitleLabel = makeLabel("", Enum.Font.GothamBlack, COLORS.white, resultPanel)
resultTitleLabel.Size = UDim2.new(1, 0, 0, 72)
resultTitleLabel.Position = UDim2.fromOffset(0, 20)
resultTitleLabel.TextSize = 52
resultTitleLabel.ZIndex = 12

-- Accent line under title
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.fromOffset(0, 2)
accentLine.Position = UDim2.new(0.5, 0, 0, 96)
accentLine.AnchorPoint = Vector2.new(0.5, 0)
accentLine.BorderSizePixel = 0
accentLine.BackgroundColor3 = COLORS.teal
accentLine.ZIndex = 12
accentLine.Parent = resultPanel

-- Reason subtitle: "The idol was lifted." etc
local resultSubtitleLabel = makeLabel("", Enum.Font.GothamBold, COLORS.white, resultPanel)
resultSubtitleLabel.Size = UDim2.new(1, -20, 0, 24)
resultSubtitleLabel.Position = UDim2.fromOffset(10, 106)
resultSubtitleLabel.TextSize = 18
resultSubtitleLabel.ZIndex = 12

-- Role note: "You escaped the temple." etc
local resultRoleNote = makeLabel("", Enum.Font.Gotham, COLORS.grey, resultPanel)
resultRoleNote.Size = UDim2.new(1, -20, 0, 18)
resultRoleNote.Position = UDim2.fromOffset(10, 130)
resultRoleNote.TextSize = 14
resultRoleNote.ZIndex = 12

-- Stats row
local resultStatsFrame = Instance.new("Frame")
resultStatsFrame.Size = UDim2.new(1, -20, 0, 56)
resultStatsFrame.Position = UDim2.fromOffset(10, 158)
resultStatsFrame.BackgroundTransparency = 1
resultStatsFrame.ZIndex = 12
resultStatsFrame.Parent = resultPanel

local statSealLabel, statCaughtLabel, statTimeLabel, statXPLabel
do
	local cols = {
		{name = "SEALS BROKEN", x = 0},
		{name = "THIEVES CAUGHT", x = 130},
		{name = "TIME LEFT", x = 270},
		{name = "XP EARNED", x = 390},
	}
	local vals = {}
	for i, col in ipairs(cols) do
		local h = makeLabel(col.name, Enum.Font.GothamBold, COLORS.grey, resultStatsFrame)
		h.Size = UDim2.fromOffset(120, 14)
		h.Position = UDim2.fromOffset(col.x, 0)
		h.TextSize = 10
		h.TextXAlignment = Enum.TextXAlignment.Left
		h.ZIndex = 12

		local v = makeLabel("0", Enum.Font.GothamBold, COLORS.white, resultStatsFrame)
		v.Size = UDim2.fromOffset(120, 26)
		v.Position = UDim2.fromOffset(col.x, 16)
		v.TextSize = 20
		v.TextXAlignment = Enum.TextXAlignment.Left
		v.ZIndex = 12
		vals[i] = v
	end
	statSealLabel = vals[1]
	statCaughtLabel = vals[2]
	statTimeLabel = vals[3]
	statXPLabel = vals[4]
end

-- Reward label
local resultRewardLabel = makeLabel("", Enum.Font.GothamBold, COLORS.teal, resultPanel)
resultRewardLabel.Size = UDim2.new(1, -20, 0, 18)
resultRewardLabel.Position = UDim2.fromOffset(10, 224)
resultRewardLabel.TextSize = 14
resultRewardLabel.ZIndex = 12

-- Next round label
local resultNextLabel = makeLabel("Next round starting soon", Enum.Font.Gotham, COLORS.grey, resultPanel)
resultNextLabel.Size = UDim2.new(1, -20, 0, 18)
resultNextLabel.Position = UDim2.fromOffset(10, 248)
resultNextLabel.TextSize = 13
resultNextLabel.ZIndex = 12

-- Divider above next round label
local resultDivider = Instance.new("Frame")
resultDivider.Size = UDim2.new(1, -20, 0, 1)
resultDivider.Position = UDim2.fromOffset(10, 242)
resultDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
resultDivider.BackgroundTransparency = 0.88
resultDivider.BorderSizePixel = 0
resultDivider.ZIndex = 12
resultDivider.Parent = resultPanel

local roundEndTime = 0
local duration = 0
local isRoundActive = false
local sprintState = "Ready"
local sprintStateChangedAt = os.clock()
local thievesRemaining = 0
local thievesCaughtByGuardian = 0
local totalThiefIcons = 0
local lastSealLitCount = 0
local sealsBroken = 0
local idolTaken = false
local vaultOpen = false
local idolCarrierUserId = nil
local extractProgress = 0
local lastReportedSealCount = 0
local currentObjectiveId = nil
local currentObjectiveName = nil
local objectiveInteractionActive = false
local objectiveProgress = 0
local skillCheckActive = false
local lastObjectiveAlertTime = 0
local guardianSprintReady = true
local guardianCanCatch = false
local guardianTargetName = nil
local guardianCurrentAlert = nil
local guardianCarrierName = nil
local guardianCarrierUserId = nil
local roundResultVisible = false
local lastCageRescueFeedAt = 0
local lastCageRescuePercent = -1

local function onIdolTaken()
	idolTaken = true
	local role = localPlayer:GetAttribute("Role")
	if objectiveDirectiveLabel then
		if role == "Thief" then
			objectiveDirectiveLabel.Text = "ESCAPE WITH THE IDOL"
		elseif role == "Guardian" then
			objectiveDirectiveLabel.Text = "CATCH THE IDOL CARRIER"
		end
	end
end
-- TODO: connect onIdolTaken() to IdolPickedUp remote when it exists

local feedItems = {}
local function addKillFeedEvent(text)
	local pill = makePanel(UDim2.fromOffset(280, 28), UDim2.fromOffset(20, #feedItems * 34), killFeed, 0.3)
	local msg = string.lower(text or "")
	local eventColor = COLORS.white
	if string.find(msg, "caught") then
		eventColor = COLORS.red
	elseif string.find(msg, "seal") or string.find(msg, "vault") then
		eventColor = COLORS.teal
	elseif string.find(msg, "idol") then
		eventColor = COLORS.gold
	end
	local lbl = makeLabel(text, Enum.Font.GothamBold, eventColor, pill)
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	pill.Position = UDim2.fromOffset(40, #feedItems * 34)
	tweenIn(pill, "Position", UDim2.fromOffset(0, #feedItems * 34), 0.2)
	table.insert(feedItems, 1, pill)
	for i, item in ipairs(feedItems) do
		tweenIn(item, "Position", UDim2.fromOffset(0, (i - 1) * 34), 0.15)
	end
	while #feedItems > 4 do
		local old = table.remove(feedItems)
		old:Destroy()
	end
	task.delay(5, function()
		if pill.Parent then
			tweenIn(pill, "BackgroundTransparency", 1, 0.2)
			task.delay(0.22, function()
				for i, item in ipairs(feedItems) do
					if item == pill then
						table.remove(feedItems, i)
						break
					end
				end
				pill:Destroy()
			end)
		end
	end)
end

local function updateThiefIconCount(total)
	totalThiefIcons = math.clamp(total or 0, 0, 4)
	for i, slot in ipairs(thiefIconFrames) do
		slot.frame.Visible = i <= totalThiefIcons
		if i <= totalThiefIcons then
			slot.frame.BackgroundColor3 = COLORS.red
			slot.label.Text = ""
		end
	end
end

local function inferThiefCount()
	local count = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("Role") == "Thief" then
			count += 1
		end
	end
	return count
end

local function setRoleUI(role)
	if role == "Guardian" then
		roleText.Text = "GUARDIAN"
		roleText.TextColor3 = COLORS.red
		roleDot.BackgroundColor3 = COLORS.red
		local st = roleBadge:FindFirstChildOfClass("UIStroke")
		if st then st.Color = COLORS.red st.Transparency = 0.35 end
		brazierPanel.Visible = false
		brazierShadow.Visible = false
		thiefPanel.Visible = true
		thiefShadow.Visible = true
		sprintPanel.Visible = true
		sprintShadow.Visible = true
		crouchPanel.Visible = false
		crouchShadow.Visible = false
		guardianStatusPanel.Visible = true
		guardianStatusShadow.Visible = true
		guardianDirectiveLabel.Text = "STOP THE THIEVES"
	elseif role == "Thief" then
		roleText.Text = "THIEF"
		roleText.TextColor3 = COLORS.teal
		roleDot.BackgroundColor3 = COLORS.teal
		local st = roleBadge:FindFirstChildOfClass("UIStroke")
		if st then st.Color = COLORS.teal st.Transparency = 0.35 end
		brazierPanel.Visible = true
		brazierShadow.Visible = true
		thiefPanel.Visible = false
		thiefShadow.Visible = false
		sprintPanel.Visible = false
		sprintShadow.Visible = false
		crouchPanel.Visible = false
		crouchShadow.Visible = false
		guardianStatusPanel.Visible = false
		guardianStatusShadow.Visible = false
	else
		brazierPanel.Visible = false
		brazierShadow.Visible = false
		thiefPanel.Visible = false
		thiefShadow.Visible = false
		sprintPanel.Visible = false
		sprintShadow.Visible = false
		crouchPanel.Visible = false
		crouchShadow.Visible = false
		guardianStatusPanel.Visible = false
		guardianStatusShadow.Visible = false
	end
end

local function showCoreHud()
	roleBadge.Visible = true
	roleShadow.Visible = true
	roleBadge.Position = UDim2.new(0, -180, 0, 16)
	tweenIn(roleBadge, "Position", UDim2.new(0, 16, 0, 16), 0.25)

	timerPanel.Visible = true
	timerShadow.Visible = true
	timerPanel.Position = UDim2.new(0.5, -80, 0, -20)
	tweenIn(timerPanel, "Position", UDim2.new(0.5, -80, 0, 16), 0.25)
end

local function hideCoreHud()
	roleBadge.Visible = false
	roleShadow.Visible = false
	timerPanel.Visible = false
	timerShadow.Visible = false
	brazierPanel.Visible = false
	brazierShadow.Visible = false
	thiefPanel.Visible = false
	thiefShadow.Visible = false
	sprintPanel.Visible = false
	sprintShadow.Visible = false
	crouchPanel.Visible = false
	crouchShadow.Visible = false
	proximity.Visible = false
end

local function isGuardianRole()
	return localPlayer:GetAttribute("Role") == "Guardian"
end

local function resetGuardianHUD()
	guardianSprintReady = true
	guardianCanCatch = false
	guardianTargetName = nil
	guardianCurrentAlert = nil
	guardianCarrierName = nil
	guardianCarrierUserId = nil
	guardianDirectiveLabel.Text = "STOP THE THIEVES"
	guardianCatchPromptLabel.Text = ""
	guardianSprintLabel.Text = "SPRINT READY"
	guardianAlertLabel.Text = ""
	guardianCarrierLabel.Text = ""
	guardianStatusPanel.Visible = false
	guardianStatusShadow.Visible = false
end

local function setGuardianPanelVisible(visible)
	if visible and not isGuardianRole() then return end
	guardianStatusPanel.Visible = visible
	guardianStatusShadow.Visible = visible
end

local function setGuardianDirective(text)
	if not isGuardianRole() then return end
	if type(text) == "string" and #text > 0 then
		guardianDirectiveLabel.Text = text
	end
end

local function setGuardianAlert(text, duration)
	if not isGuardianRole() then return end
	if type(text) ~= "string" or #text == 0 then return end
	guardianAlertLabel.Text = text
	guardianCurrentAlert = text
	lastObjectiveAlertTime = os.clock()
	if type(duration) == "number" and duration > 0 then
		local captured = text
		task.delay(duration, function()
			if guardianAlertLabel.Parent and guardianAlertLabel.Text == captured then
				guardianAlertLabel.Text = ""
			end
		end)
	end
end

local function setGuardianCatchPrompt(canCatch, targetName)
	if not isGuardianRole() then return end
	guardianCanCatch = canCatch == true
	if guardianCanCatch then
		local name = (type(targetName) == "string" and #targetName > 0) and targetName or "thief"
		guardianTargetName = name
		guardianCatchPromptLabel.Text = "Press E to catch " .. name
	else
		guardianCatchPromptLabel.Text = ""
		guardianTargetName = nil
	end
end

local function setGuardianSprintState(ready, cooldownRemaining, cooldownTotal)
	if not isGuardianRole() then return end
	-- Updates text label only. Visual bar is owned by existing sprintPanel.
	guardianSprintReady = ready == true
	if guardianSprintReady then
		guardianSprintLabel.Text = "SPRINT READY"
	else
		local remaining = math.clamp(tonumber(cooldownRemaining) or 0, 0, 999)
		local total = math.clamp(tonumber(cooldownTotal) or 0, 0, 999)
		local _ = total
		local __ = remaining
		guardianSprintLabel.Text = "SPRINT COOLDOWN"
	end
end

local function setGuardianCarrier(carrierUserId, carrierName)
	if not isGuardianRole() then return end
	guardianCarrierUserId = carrierUserId
	guardianCarrierName = carrierName
	local displayName = (type(carrierName) == "string" and #carrierName > 0) and carrierName or "Unknown"
	guardianCarrierLabel.Text = "Carrier: " .. displayName
	setGuardianDirective("CATCH THE IDOL CARRIER")
	setGuardianAlert("The idol has been taken", 4)
end

local function clearGuardianCarrier()
	if not isGuardianRole() then return end
	guardianCarrierUserId = nil
	guardianCarrierName = nil
	guardianCarrierLabel.Text = ""
end

local function isThiefRole()
	return localPlayer:GetAttribute("Role") == "Thief"
end

local function resetObjectiveInteractionUI()
	currentObjectiveId = nil
	currentObjectiveName = nil
	objectiveInteractionActive = false
	objectiveProgress = 0
	skillCheckActive = false
	objectiveInteractionPanel.Visible = false
	objectiveInteractionShadow.Visible = false
	objectiveNameLabel.Text = ""
	objectivePromptLabel.Text = ""
	objectiveDangerLabel.Text = ""
	objectiveProgressFill.Size = UDim2.fromScale(0, 1)
	objectiveProgressLabel.Text = ""
	skillCheckPanel.Visible = false
	skillCheckShadow.Visible = false
end

local function showObjectivePrompt(objectiveId, objectiveName)
	if not isThiefRole() then return end
	currentObjectiveId = objectiveId
	currentObjectiveName = objectiveName
	objectiveInteractionPanel.Visible = true
	objectiveInteractionShadow.Visible = true
	objectiveNameLabel.Text = (type(objectiveName) == "string" and #objectiveName > 0)
		and objectiveName or "SEAL OBJECTIVE"
	objectivePromptLabel.Text = "Hold E to break seal"
	objectiveDangerLabel.Text = ""
end

local function hideObjectivePrompt()
	if objectiveInteractionActive then return end
	objectiveInteractionPanel.Visible = false
	objectiveInteractionShadow.Visible = false
	objectivePromptLabel.Text = ""
end

local function startObjectiveInteraction(objectiveId, objectiveName)
	if not isThiefRole() then return end
	objectiveInteractionActive = true
	currentObjectiveId = objectiveId
	currentObjectiveName = objectiveName
	objectiveInteractionPanel.Visible = true
	objectiveInteractionShadow.Visible = true
	objectiveNameLabel.Text = (type(objectiveName) == "string" and #objectiveName > 0)
		and objectiveName or "SEAL OBJECTIVE"
	objectivePromptLabel.Text = "Breaking seal..."
	objectiveDangerLabel.Text = ""
end

local function hideSkillCheck()
	skillCheckActive = false
	skillCheckPanel.Visible = false
	skillCheckShadow.Visible = false
end

local function updateObjectiveProgress(progress)
	progress = math.clamp(tonumber(progress) or 0, 0, 1)
	objectiveProgress = progress
	objectiveProgressFill.Size = UDim2.fromScale(progress, 1)
	objectiveProgressLabel.Text = math.floor(progress * 100) .. "%"
	-- DO NOT call completeObjectiveInteraction() here.
	-- Server drives completion via ObjectiveCompleted remote only.
	-- Client must never self-complete an objective.
end

local function completeObjectiveInteraction()
	objectiveInteractionActive = false
	objectivePromptLabel.Text = "Seal broken"
	objectiveDangerLabel.Text = ""
	hideSkillCheck()
	if currentObjectiveId ~= nil then
		addKillFeedEvent("A seal has been broken")
	end
	task.delay(1.5, function()
		if not objectiveInteractionActive then
			if objectiveInteractionPanel.Parent then
				objectiveInteractionPanel.Visible = false
			end
			if objectiveInteractionShadow.Parent then
				objectiveInteractionShadow.Visible = false
			end
		end
	end)
end

local function failObjectiveInteraction(reason)
	local msg = (type(reason) == "string" and #reason > 0) and reason or "Noise made"
	objectiveDangerLabel.Text = msg
	objectiveDangerLabel.TextColor3 = COLORS.red
	hideSkillCheck()
	task.delay(2, function()
		if objectiveDangerLabel.Parent then
			objectiveDangerLabel.Text = ""
		end
	end)
end

local function showSkillCheck(targetStart, targetEnd, needlePosition)
	if not isThiefRole() then return end
	targetStart = math.clamp(tonumber(targetStart) or 0.35, 0, 1)
	targetEnd = math.clamp(tonumber(targetEnd) or 0.65, 0, 1)
	needlePosition = math.clamp(tonumber(needlePosition) or 0, 0, 1)
	skillCheckActive = true
	skillCheckPanel.Visible = true
	skillCheckShadow.Visible = true
	local zoneWidth = math.max(targetEnd - targetStart, 0)
	skillCheckTargetZone.Position = UDim2.fromScale(targetStart, 0)
	skillCheckTargetZone.Size = UDim2.fromScale(zoneWidth, 1)
	skillCheckNeedle.Position = UDim2.fromScale(needlePosition, 0)
end

local function updateSkillCheckNeedle(needlePosition)
	needlePosition = math.clamp(tonumber(needlePosition) or 0, 0, 1)
	skillCheckNeedle.Position = UDim2.fromScale(needlePosition, 0)
end

local function setIdolPanelVisible(visible)
	idolStatusPanel.Visible = visible
	idolStatusShadow.Visible = visible
end

local function resetIdolExtractUI()
	vaultOpen = false
	idolTaken = false
	idolCarrierUserId = nil
	extractProgress = 0
	lastReportedSealCount = 0
	idolStatusLabel.Text = "VAULT LOCKED"
	carrierLabel.Text = ""
	extractProgressLabel.Text = ""
	extractProgressFill.Size = UDim2.fromScale(0, 1)
	extractProgressBack.Visible = false
	setIdolPanelVisible(false)
end

local function setVaultOpenUI()
	vaultOpen = true
	idolStatusLabel.Text = "VAULT OPEN"
	carrierLabel.Text = "Find the idol"
	setIdolPanelVisible(true)
	addKillFeedEvent("The vault is open")
	local role = localPlayer:GetAttribute("Role")
	if objectiveDirectiveLabel then
		if role == "Thief" then
			objectiveDirectiveLabel.Text = "VAULT OPEN: FIND THE IDOL"
		elseif role == "Guardian" then
			objectiveDirectiveLabel.Text = "STOP THE ESCAPE"
		end
	end
end

local function setIdolAvailableUI()
	setIdolPanelVisible(true)
	idolStatusLabel.Text = "IDOL AVAILABLE"
	carrierLabel.Text = "Take the idol"
end

local function setIdolCarrierUI(carrierUserId, carrierName)
	idolTaken = true
	idolCarrierUserId = carrierUserId
	local displayName = (type(carrierName) == "string" and #carrierName > 0) and carrierName or "Unknown"
	setIdolPanelVisible(true)
	idolStatusLabel.Text = "IDOL TAKEN"
	carrierLabel.Text = "Carrier: " .. displayName
	addKillFeedEvent("The idol has been taken")
	local role = localPlayer:GetAttribute("Role")
	if objectiveDirectiveLabel then
		if carrierUserId == localPlayer.UserId then
			objectiveDirectiveLabel.Text = "ESCAPE WITH THE IDOL"
		elseif role == "Guardian" then
			objectiveDirectiveLabel.Text = "CATCH THE IDOL CARRIER"
		elseif role == "Thief" then
			objectiveDirectiveLabel.Text = "PROTECT THE CARRIER"
		end
	end
end

local function setIdolDroppedUI()
	idolTaken = false
	idolCarrierUserId = nil
	setIdolPanelVisible(true)
	idolStatusLabel.Text = "IDOL DROPPED"
	carrierLabel.Text = "Recover the idol"
	extractProgress = 0
	extractProgressFill.Size = UDim2.fromScale(0, 1)
	extractProgressBack.Visible = false
	extractProgressLabel.Text = ""
end

local function setExtractProgressUI(progress)
	progress = math.clamp(tonumber(progress) or 0, 0, 1)
	extractProgress = progress
	setIdolPanelVisible(true)
	extractProgressBack.Visible = true
	extractProgressFill.Size = UDim2.fromScale(progress, 1)
	if progress > 0 then
		extractProgressLabel.Text = "EXTRACTING " .. math.floor(progress * 100) .. "%"
	else
		extractProgressLabel.Text = ""
	end
end

local function formatTime(secs)
	local m = math.floor(math.max(secs, 0) / 60)
	local s = math.floor(math.max(secs, 0) % 60)
	return string.format("%d:%02d", m, s)
end

local function normalizeRoundResult(...)
	local args = {...}
	if type(args[1]) == "table" then
		return args[1]
	end
	local resultStr = type(args[1]) == "string" and args[1] or ""
	local winnerStr = type(args[2]) == "string" and args[2] or ""
	local reason = "Unknown"
	if resultStr:lower():find("extract") then
		reason = "IdolExtracted"
	elseif resultStr:lower():find("caught") then
		reason = "AllThievesCaught"
	elseif resultStr:lower():find("time") then
		reason = "TimerExpired"
	end
	return {
		winningTeam = (winnerStr ~= "" and winnerStr or nil),
		reason = reason,
		role = localPlayer:GetAttribute("Role"),
		xpEarned = 0,
		sealsBroken = (lastReportedSealCount or 0),
		thievesCaught = (thievesCaughtByGuardian or 0),
		timeRemaining = 0,
	}
end

local function formatRoundReason(winningTeam, reason)
	if winningTeam == "Thieves" then
		if reason == "IdolExtracted" then return "The idol was lifted." end
		return "The thieves won."
	elseif winningTeam == "Guardian" then
		if reason == "AllThievesCaught" then return "All thieves were caught." end
		if reason == "TimerExpired" then return "The temple held." end
		return "The guardian stopped the heist."
	elseif winningTeam == "Draw" then
		return "No winner."
	end
	return "Returning to lobby."
end

local function getLocalResultNote(winningTeam)
	local role = localPlayer:GetAttribute("Role")
	if role == "Thief" then
		if winningTeam == "Thieves" then return "You escaped the temple." end
		return "The heist failed."
	elseif role == "Guardian" then
		if winningTeam == "Guardian" then return "You protected the idol." end
		return "The idol was stolen."
	end
	return "Round complete."
end

local function hideRoundResults()
	roundResultVisible = false
	roundResultsOverlay.Visible = false
	resultPanel.Visible = false
	resultPanelShadow.Visible = false
end

local function resetRoundResultsUI()
	hideRoundResults()
	resultTitleLabel.Text = ""
	resultSubtitleLabel.Text = ""
	resultRoleNote.Text = ""
	resultRewardLabel.Text = ""
	statSealLabel.Text = "0"
	statCaughtLabel.Text = "0"
	statTimeLabel.Text = "0s"
	statXPLabel.Text = "+0"
	accentLine.Size = UDim2.fromOffset(0, 2)
end

local function showRoundResults(...)
	if roundResultVisible then return end
	roundResultVisible = true

	local data = normalizeRoundResult(...)
	local winningTeam = data.winningTeam or ""

	local accentColor = COLORS.white
	if winningTeam == "Thieves" then
		accentColor = COLORS.teal
		roundResultsOverlay.BackgroundColor3 = Color3.fromRGB(8, 32, 40)
	elseif winningTeam == "Guardian" then
		accentColor = COLORS.red
		roundResultsOverlay.BackgroundColor3 = Color3.fromRGB(40, 8, 8)
	else
		roundResultsOverlay.BackgroundColor3 = COLORS.bg
	end

	if winningTeam == "Thieves" then
		resultTitleLabel.Text = "THIEVES ESCAPED"
		resultTitleLabel.TextColor3 = COLORS.teal
	elseif winningTeam == "Guardian" then
		resultTitleLabel.Text = "GUARDIAN WON"
		resultTitleLabel.TextColor3 = COLORS.red
	elseif winningTeam == "Draw" then
		resultTitleLabel.Text = "ROUND ENDED"
		resultTitleLabel.TextColor3 = COLORS.white
	else
		resultTitleLabel.Text = "ROUND OVER"
		resultTitleLabel.TextColor3 = COLORS.white
	end

	resultSubtitleLabel.Text = formatRoundReason(winningTeam, data.reason)
	resultRoleNote.Text = getLocalResultNote(winningTeam)

	statSealLabel.Text = tostring(math.clamp(tonumber(data.sealsBroken) or 0, 0, 3)) .. " / 3"
	statCaughtLabel.Text = tostring(tonumber(data.thievesCaught) or 0)
	statTimeLabel.Text = tostring(math.floor(math.max(tonumber(data.timeRemaining) or 0, 0))) .. "s"
	statXPLabel.Text = "+" .. tostring(tonumber(data.xpEarned) or 0)

	resultRewardLabel.Text = ""

	accentLine.BackgroundColor3 = accentColor
	if resultStroke then
		resultStroke.Color = accentColor
		resultStroke.Transparency = 0.35
	end

	roundResultsOverlay.Visible = true
	resultPanel.Visible = true
	resultPanelShadow.Visible = true
	roundResultsOverlay.BackgroundTransparency = 1
	resultPanel.BackgroundTransparency = 0.1
	resultPanelShadow.BackgroundTransparency = 1
	resultPanel.Position = UDim2.new(0.5, -280, 0.5, -200)
	accentLine.Size = UDim2.fromOffset(0, 2)

	tweenIn(roundResultsOverlay, "BackgroundTransparency", 0.45, 0.35)
	tweenIn(resultPanel, "Position", UDim2.new(0.5, -280, 0.5, -160), 0.4,
		Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(0.4, function()
		if accentLine.Parent then
			tweenIn(accentLine, "Size", UDim2.fromOffset(400, 2), 0.5)
		end
	end)
end

roundStartedRemote.OnClientEvent:Connect(function(roundDuration, totalThieves)
	duration = tonumber(roundDuration) or 0
	roundEndTime = os.clock() + duration
	isRoundActive = true
	thievesCaughtByGuardian = 0
	showCoreHud()
	addKillFeedEvent("Break 3 seals to open the vault")
	setRoleUI(localPlayer:GetAttribute("Role"))
	if localPlayer:GetAttribute("Role") == "Guardian" then
		updateThiefIconCount(tonumber(totalThieves) or inferThiefCount())
	end
	sealsBroken = 0
	idolTaken = false
	objectiveDirectiveLabel.Visible = true
	local role = localPlayer:GetAttribute("Role")
	if role == "Thief" then
		objectiveDirectiveLabel.Text = "BREAK 3 SEALS"
	elseif role == "Guardian" then
		objectiveDirectiveLabel.Text = "STOP THE THIEVES"
	else
		objectiveDirectiveLabel.Text = ""
	end
	resetIdolExtractUI()
	resetObjectiveInteractionUI()
	resetGuardianHUD()
	if isGuardianRole() then
		guardianStatusPanel.Visible = true
		guardianStatusShadow.Visible = true
	end
	resetRoundResultsUI()
end)

roundEndedRemote.OnClientEvent:Connect(function(result, winner)
	isRoundActive = false
	hideCoreHud()
	if type(result) ~= "string" then result = "Round ended" end
	if type(winner) ~= "string" then winner = "Time" end
	if winner == "Thieves" then
		addKillFeedEvent("Thieves extracted loot")
	end
	local resultPanels = {
		objectiveInteractionPanel,
		skillCheckPanel,
		guardianStatusPanel,
		idolStatusPanel,
	}
	for _, panel in ipairs(resultPanels) do
		if typeof(panel) == "Instance" and panel.Parent then
			panel.Visible = false
		end
	end
	addKillFeedEvent("Round over")
	showRoundResults(result, winner)
	objectiveDirectiveLabel.Visible = false
	objectiveDirectiveLabel.Text = ""
	sealsBroken = 0
	idolTaken = false
	resetIdolExtractUI()
	resetObjectiveInteractionUI()
	resetGuardianHUD()
end)

thiefCaughtRemote.OnClientEvent:Connect(function(_, caughtPlayer)
	if typeof(caughtPlayer) == "Instance" and caughtPlayer:IsA("Player") then
		addKillFeedEvent("Guardian caught " .. caughtPlayer.Name)
	end
	if localPlayer:GetAttribute("Role") == "Guardian" then
		thievesCaughtByGuardian += 1
	end
end)

thiefCountUpdateRemote.OnClientEvent:Connect(function(count)
	thievesRemaining = tonumber(count) or 0
	for i, slot in ipairs(thiefIconFrames) do
		if i <= totalThiefIcons and slot.frame.Visible then
			if i <= thievesRemaining then
				slot.frame.BackgroundColor3 = COLORS.red
				slot.label.Text = ""
			else
				slot.frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				slot.label.Text = "X"
				slot.label.TextColor3 = COLORS.grey
			end
		end
	end
end)

brazierProgressUpdateRemote.OnClientEvent:Connect(function(litCount)
	litCount = math.clamp(tonumber(litCount) or 0, 0, 3)
	for i, icon in ipairs(brazierIcons) do
		if i > #brazierIcons then
			break
		end
		if i <= litCount then
			icon.frame.BackgroundColor3 = COLORS.teal
			icon.stroke.Color = COLORS.teal
			icon.stroke.Transparency = 0.15
			icon.frame.Size = UDim2.fromOffset(20, 20)
			tweenIn(icon.frame, "Size", UDim2.fromOffset(24, 24), 0.1)
			task.delay(0.1, function()
				if icon.frame.Parent then
					tweenIn(icon.frame, "Size", UDim2.fromOffset(20, 20), 0.1)
				end
			end)
		else
			icon.frame.BackgroundColor3 = COLORS.panelSoft
			icon.stroke.Color = COLORS.white
			icon.stroke.Transparency = 0.85
		end
	end
	lastSealLitCount = litCount
end)

setMovementStateRemote.OnClientEvent:Connect(function(state, active)
	local role = localPlayer:GetAttribute("Role")
	if role == "Guardian" and state == "Sprint" then
		if active then
			sprintState = "Sprinting"
			sprintStateChangedAt = os.clock()
		else
			sprintState = "Cooldown"
			sprintStateChangedAt = os.clock()
		end
	elseif role == "Thief" and state == "Crouch" then
		if active then
			crouchPanel.Visible = true
			crouchShadow.Visible = true
			crouchPanel.BackgroundColor3 = Color3.fromRGB(10, 40, 50)
			crouchPanel.BackgroundTransparency = 0.2
		else
			crouchPanel.Visible = false
			crouchShadow.Visible = false
		end
	end
end)

localPlayer:GetAttributeChangedSignal("Role"):Connect(function()
	setRoleUI(localPlayer:GetAttribute("Role"))
end)

RunService.Heartbeat:Connect(function()
	if isRoundActive then
		local remain = math.max(0, roundEndTime - os.clock())
		timerText.Text = formatTime(remain)

		if remain <= 30 then
			if math.floor(os.clock() * 2) % 2 == 0 then
				timerText.TextColor3 = COLORS.red
			else
				timerText.TextColor3 = COLORS.white
			end
			if timerStroke then timerStroke.Color = COLORS.red end
		elseif remain <= 60 then
			timerText.TextColor3 = COLORS.red
			if timerStroke then
				timerStroke.Color = COLORS.red
				timerStroke.Transparency = 0.2 + ((math.sin(os.clock() * 6) + 1) * 0.15)
			end
			else
				timerText.TextColor3 = COLORS.white
				if timerStroke then
					timerStroke.Color = COLORS.teal
					timerStroke.Transparency = 0.4
				end
			end

		if localPlayer:GetAttribute("Role") == "Guardian" and sprintPanel.Visible then
			local elapsed = os.clock() - sprintStateChangedAt
				if sprintState == "Sprinting" then
					local ratio = math.clamp(1 - (elapsed / 6), 0, 1)
					barFill.Size = UDim2.fromScale(ratio, 1)
					barFill.BackgroundColor3 = COLORS.teal
				if ratio <= 0 then
					sprintState = "Cooldown"
					sprintStateChangedAt = os.clock()
				end
			elseif sprintState == "Cooldown" then
				local ratio = math.clamp(elapsed / 10, 0, 1)
				barFill.Size = UDim2.fromScale(ratio, 1)
				barFill.BackgroundColor3 = COLORS.red
				if ratio >= 1 then
					sprintState = "Ready"
					sprintStateChangedAt = os.clock()
				end
				else
					barFill.Size = UDim2.fromScale(1, 1)
					barFill.BackgroundColor3 = COLORS.teal
				end
		end

		if localPlayer:GetAttribute("Role") == "Thief" then
			local myChar = localPlayer.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			local guardian
			for _, p in ipairs(Players:GetPlayers()) do
				if p:GetAttribute("Role") == "Guardian" then
					guardian = p
					break
				end
			end
			local gRoot = guardian and guardian.Character and guardian.Character:FindFirstChild("HumanoidRootPart")
			if myRoot and gRoot then
				local vec = gRoot.Position - myRoot.Position
				local dist = vec.Magnitude
				if dist <= 40 then
					local cam = workspace.CurrentCamera
					if cam then
						local look = cam.CFrame.LookVector
						local right = cam.CFrame.RightVector
						local f = look:Dot(vec.Unit)
						local r = right:Dot(vec.Unit)
						local sx = math.clamp(0.5 + r * 0.45, 0.08, 0.92)
						local sy = math.clamp(0.5 - f * 0.45, 0.08, 0.92)
						proximity.Position = UDim2.new(sx, 0, sy, 0)
						proximity.Visible = true
						local pulse = 0.9 + ((math.sin(os.clock() * math.pi * 2) + 1) * 0.05)
						proximity.Size = UDim2.fromOffset(60 * pulse, 60 * pulse)
					end
				else
					proximity.Visible = false
				end
			else
				proximity.Visible = false
			end
		else
			proximity.Visible = false
		end
	end
end)

-- Optional future remote hooks - safe if remotes do not exist yet
local function connectOptional(name, handler)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		remote.OnClientEvent:Connect(handler)
	end
end

connectOptional("VaultOpened", function()
	if not vaultOpen then
		setVaultOpenUI()
	end
	setGuardianDirective("STOP THE ESCAPE")
	setGuardianAlert("The vault is open", 4)
end)

connectOptional("IdolAvailable", function()
	setIdolAvailableUI()
end)

connectOptional("IdolPickedUp", function(carrierUserId, carrierName)
	setIdolCarrierUI(carrierUserId, carrierName)
	setGuardianCarrier(carrierUserId, carrierName)
end)

connectOptional("IdolCarrierChanged", function(carrierUserId, carrierName)
	setIdolCarrierUI(carrierUserId, carrierName)
	setGuardianCarrier(carrierUserId, carrierName)
end)

connectOptional("IdolDropped", function()
	setIdolDroppedUI()
	clearGuardianCarrier()
	setGuardianDirective("RECOVER CONTROL")
	setGuardianAlert("The idol was dropped", 3)
end)

connectOptional("ExtractStarted", function()
	setExtractProgressUI(0)
end)

connectOptional("ExtractProgress", function(progress)
	setExtractProgressUI(progress)
end)

connectOptional("ExtractCanceled", function()
	setExtractProgressUI(0)
end)

connectOptional("ExtractCompleted", function()
	setExtractProgressUI(1)
	idolStatusLabel.Text = "EXTRACTED"
	carrierLabel.Text = "Escape complete"
end)

connectOptional("ObjectivePromptShown", function(objectiveId, objectiveName)
	showObjectivePrompt(objectiveId, objectiveName)
end)

connectOptional("ObjectivePromptHidden", function(objectiveId)
	if currentObjectiveId == nil or currentObjectiveId == objectiveId then
		hideObjectivePrompt()
	end
end)

connectOptional("ObjectiveInteractionStarted", function(objectiveId, objectiveName)
	startObjectiveInteraction(objectiveId, objectiveName)
end)

connectOptional("ObjectiveProgress", function(objectiveId, progress)
	if currentObjectiveId == nil or currentObjectiveId == objectiveId then
		updateObjectiveProgress(progress)
	end
end)

connectOptional("ObjectiveCompleted", function(objectiveId)
	local indexByObjectiveId = {
		FlameSeal = 1,
		MoonLock = 2,
		StoneSigil = 3,
	}
	local idx = indexByObjectiveId[objectiveId]
	if idx and brazierIcons[idx] then
		local icon = brazierIcons[idx]
		icon.frame.BackgroundColor3 = COLORS.teal
		icon.stroke.Color = COLORS.teal
		icon.stroke.Transparency = 0.15
		icon.frame.Size = UDim2.fromOffset(20, 20)
		tweenIn(icon.frame, "Size", UDim2.fromOffset(24, 24), 0.1)
		task.delay(0.1, function()
			if icon.frame.Parent then
				tweenIn(icon.frame, "Size", UDim2.fromOffset(20, 20), 0.1)
			end
		end)
		sealsBroken = math.clamp(sealsBroken + 1, 0, 3)
		local status = brazierPanel:FindFirstChild("VaultStatusLabel")
		if status and status:IsA("TextLabel") then
			status.Text = "VAULT SEALED"
			status.TextColor3 = COLORS.grey
		end
	end
	completeObjectiveInteraction()
end)

connectOptional("ObjectiveFailed", function(objectiveId, reason)
	failObjectiveInteraction(reason)
end)

connectOptional("ObjectiveSkillCheckShown", function(targetStart, targetEnd, needlePosition)
	showSkillCheck(targetStart, targetEnd, needlePosition)
end)

connectOptional("ObjectiveSkillCheckNeedle", function(needlePosition)
	updateSkillCheckNeedle(needlePosition)
end)

connectOptional("ObjectiveSkillCheckHidden", function()
	hideSkillCheck()
end)

connectOptional("GuardianCatchPrompt", function(canCatch, targetName)
	setGuardianCatchPrompt(canCatch, targetName)
end)

connectOptional("GuardianSprintState", function(ready, cooldownRemaining, cooldownTotal)
	setGuardianSprintState(ready, cooldownRemaining, cooldownTotal)
end)

connectOptional("GuardianAlert", function(text, duration)
	setGuardianAlert(text, duration)
end)

connectOptional("ObjectiveStarted", function(objectiveId, objectiveName)
	setGuardianAlert("A seal is being broken", 3)
end)

connectOptional("RoundResults", function(resultData)
	showRoundResults(resultData)
end)

connectOptional("PlayerCaged", function(userId, playerName)
	local name = type(playerName) == "string" and playerName or "A thief"
	addKillFeedEvent(name .. " was caged")
end)

connectOptional("CageRescueProgress", function(userId, progress, rescuerCount)
	progress = math.clamp(tonumber(progress) or 0, 0, 1)
	local now = os.clock()
	local percent = math.floor(progress * 100)
	local percentStep = math.floor(percent / 10)
	local lastStep = math.floor(math.max(lastCageRescuePercent, 0) / 10)
	if (now - lastCageRescueFeedAt) >= 1.5 and percentStep > lastStep then
		lastCageRescueFeedAt = now
		lastCageRescuePercent = percent
		addKillFeedEvent("Rescue in progress: " .. percent .. "%")
	end
end)

connectOptional("CageRescueCompleted", function(userId, playerName)
	local name = type(playerName) == "string" and playerName or "A thief"
	lastCageRescueFeedAt = 0
	lastCageRescuePercent = -1
	addKillFeedEvent(name .. " was rescued")
end)
