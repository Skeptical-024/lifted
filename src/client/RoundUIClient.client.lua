-- RoundUIClient v2

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
	panel = Color3.fromRGB(10, 10, 14),
	white = Color3.fromRGB(245, 245, 245),
	grey = Color3.fromRGB(165, 165, 175),
	teal = Color3.fromRGB(40, 220, 200),
	red = Color3.fromRGB(220, 60, 60),
	gold = Color3.fromRGB(210, 165, 50),
}

local function tweenIn(element, property, targetValue, duration)
	local props = {}
	props[property] = targetValue
	local t = TweenService:Create(element, TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
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
local timerStroke = timerPanel:FindFirstChildOfClass("UIStroke")
if timerStroke then
	timerStroke.Color = COLORS.gold
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

local brazierPanel = makePanel(UDim2.fromOffset(220, 52), UDim2.new(0, 16, 1, -68), gui, 0.2)
local brazierShadow = makeShadow(brazierPanel)
brazierPanel.Visible = false
brazierShadow.Visible = false
local bs = brazierPanel:FindFirstChildOfClass("UIStroke")
if bs then
	bs.Color = COLORS.teal
	bs.Transparency = 0.35
end

local brazierTitle = makeLabel("BRAZIERS", Enum.Font.GothamBold, COLORS.grey, brazierPanel)
brazierTitle.Size = UDim2.new(1, 0, 0, 14)
brazierTitle.TextSize = 12

local brazierIcons = {}
for i = 1, 4 do
	local sq = Instance.new("Frame")
	sq.Size = UDim2.fromOffset(20, 20)
	sq.Position = UDim2.fromOffset(10 + (i - 1) * 28, 24)
	sq.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	sq.Parent = brazierPanel
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = sq
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Transparency = 0.85
	s.Parent = sq
	brazierIcons[i] = {frame = sq, stroke = s}
end

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
barBg.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
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

local resultOverlay = Instance.new("Frame")
resultOverlay.Size = UDim2.fromScale(1, 1)
resultOverlay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
resultOverlay.BackgroundTransparency = 1
resultOverlay.Visible = false
resultOverlay.Parent = gui

local resultPanel = makePanel(UDim2.fromOffset(560, 220), UDim2.new(0.5, -280, 0.5, -110), resultOverlay, 1)
local resultShadow = makeShadow(resultPanel)
resultPanel.Visible = false
resultShadow.Visible = false
local resultStroke = resultPanel:FindFirstChildOfClass("UIStroke")
local resultTop = makeLabel("ROUND OVER", Enum.Font.GothamBold, COLORS.grey, resultPanel)
resultTop.Size = UDim2.new(1, 0, 0, 20)
resultTop.TextSize = 14
local resultMain = makeLabel("", Enum.Font.GothamBlack, COLORS.white, resultPanel)
resultMain.Size = UDim2.new(1, 0, 0, 88)
resultMain.Position = UDim2.fromOffset(0, 50)
resultMain.TextSize = 56
local resultSub = makeLabel("", Enum.Font.GothamBold, COLORS.white, resultPanel)
resultSub.Size = UDim2.new(1, -20, 0, 40)
resultSub.Position = UDim2.fromOffset(10, 132)
resultSub.TextSize = 24
local resultBottom = makeLabel("Next round starting soon...", Enum.Font.Gotham, COLORS.grey, resultPanel)
resultBottom.Size = UDim2.new(1, 0, 0, 22)
resultBottom.Position = UDim2.fromOffset(0, 188)
resultBottom.TextSize = 16

local roundEndTime = 0
local duration = 0
local isRoundActive = false
local sprintState = "Ready"
local sprintStateChangedAt = os.clock()
local thievesRemaining = 0

local feedItems = {}
local function addKillFeedEvent(text)
	local pill = makePanel(UDim2.fromOffset(280, 28), UDim2.fromOffset(20, #feedItems * 34), killFeed, 0.3)
	pill.Position = UDim2.fromOffset(20, #feedItems * 34)
	local lbl = makeLabel(text, Enum.Font.GothamBold, COLORS.white, pill)
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
	else
		brazierPanel.Visible = false
		brazierShadow.Visible = false
		thiefPanel.Visible = false
		thiefShadow.Visible = false
		sprintPanel.Visible = false
		sprintShadow.Visible = false
		crouchPanel.Visible = false
		crouchShadow.Visible = false
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

local function formatTime(secs)
	local m = math.floor(math.max(secs, 0) / 60)
	local s = math.floor(math.max(secs, 0) % 60)
	return string.format("%d:%02d", m, s)
end

roundStartedRemote.OnClientEvent:Connect(function(roundDuration)
	duration = tonumber(roundDuration) or 0
	roundEndTime = os.clock() + duration
	isRoundActive = true
	showCoreHud()
	setRoleUI(localPlayer:GetAttribute("Role"))
end)

roundEndedRemote.OnClientEvent:Connect(function(result, winner)
	isRoundActive = false
	hideCoreHud()
	if type(result) ~= "string" then result = "Round ended" end
	if type(winner) ~= "string" then winner = "Time" end

	resultOverlay.Visible = true
	resultPanel.Visible = true
	resultShadow.Visible = true
	resultOverlay.BackgroundTransparency = 1
	resultPanel.BackgroundTransparency = 1
	resultShadow.BackgroundTransparency = 1

	if winner == "Guardian" then
		resultOverlay.BackgroundColor3 = Color3.fromRGB(60, 10, 10)
		resultMain.Text = "GUARDIAN WINS"
		resultMain.TextColor3 = COLORS.red
		if resultStroke then resultStroke.Color = COLORS.red resultStroke.Transparency = 0.35 end
	elseif winner == "Thieves" then
		resultOverlay.BackgroundColor3 = Color3.fromRGB(10, 40, 50)
		resultMain.Text = "THIEVES WIN"
		resultMain.TextColor3 = COLORS.teal
		if resultStroke then resultStroke.Color = COLORS.teal resultStroke.Transparency = 0.35 end
	else
		resultOverlay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		resultMain.Text = "TIME'S UP"
		resultMain.TextColor3 = COLORS.gold
		if resultStroke then resultStroke.Color = COLORS.gold resultStroke.Transparency = 0.35 end
	end
	resultSub.Text = result

	tweenIn(resultOverlay, "BackgroundTransparency", 0.4, 0.3)
	tweenIn(resultPanel, "BackgroundTransparency", 0.2, 0.3)
	tweenIn(resultShadow, "BackgroundTransparency", 0.6, 0.3)
	task.delay(3.5, function()
		tweenIn(resultOverlay, "BackgroundTransparency", 1, 0.5)
		tweenIn(resultPanel, "BackgroundTransparency", 1, 0.5)
		tweenIn(resultShadow, "BackgroundTransparency", 1, 0.5)
		task.delay(0.52, function()
			resultOverlay.Visible = false
			resultPanel.Visible = false
			resultShadow.Visible = false
		end)
	end)

	if winner == "Thieves" then
		addKillFeedEvent("Thieves extracted loot")
	end
end)

thiefCaughtRemote.OnClientEvent:Connect(function(guardianPlayer, caughtPlayer)
	if typeof(caughtPlayer) == "Instance" and caughtPlayer:IsA("Player") then
		addKillFeedEvent("Guardian caught " .. caughtPlayer.Name)
	end
end)

thiefCountUpdateRemote.OnClientEvent:Connect(function(count)
	thievesRemaining = tonumber(count) or 0
	for i, slot in ipairs(thiefIconFrames) do
		if i <= thievesRemaining then
			slot.frame.BackgroundColor3 = COLORS.red
			slot.label.Text = ""
		else
			slot.frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			slot.label.Text = "X"
			slot.label.TextColor3 = COLORS.grey
		end
	end
end)

brazierProgressUpdateRemote.OnClientEvent:Connect(function(litCount)
	litCount = tonumber(litCount) or 0
	for i, icon in ipairs(brazierIcons) do
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
			icon.frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			icon.stroke.Color = Color3.fromRGB(255, 255, 255)
			icon.stroke.Transparency = 0.85
		end
	end
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
				timerStroke.Color = COLORS.gold
				timerStroke.Transparency = 0.4
			end
		end

		if localPlayer:GetAttribute("Role") == "Guardian" and sprintPanel.Visible then
			local elapsed = os.clock() - sprintStateChangedAt
			if sprintState == "Sprinting" then
				local ratio = math.clamp(1 - (elapsed / 6), 0, 1)
				barFill.Size = UDim2.fromScale(ratio, 1)
				barFill.BackgroundColor3 = COLORS.white
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
				barFill.BackgroundColor3 = COLORS.white
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
