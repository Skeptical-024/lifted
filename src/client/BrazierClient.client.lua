-- BrazierClient v2

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local UIStateController = nil
do
	local controllersFolder = script.Parent:FindFirstChild("controllers")
	local stateModule = controllersFolder and controllersFolder:FindFirstChild("UIStateController")
	if stateModule then
		local ok, mod = pcall(require, stateModule)
		if ok then
			UIStateController = mod
		end
	end
end

local brazierInteractRemote = ReplicatedStorage:WaitForChild("BrazierInteract")
local guardianSequenceRemote = ReplicatedStorage:WaitForChild("GuardianBrazierSequence")
local brazierStateChangedRemote = ReplicatedStorage:WaitForChild("BrazierStateChanged")

local INTERACT_DISTANCE = 8
local COLORS = {
	panel = Color3.fromRGB(10, 10, 14),
	white = Color3.fromRGB(245, 245, 245),
	grey = Color3.fromRGB(160, 160, 170),
	teal = Color3.fromRGB(40, 220, 200),
	red = Color3.fromRGB(220, 60, 60),
	gold = Color3.fromRGB(210, 165, 50),
}

local function tweenIn(element, property, targetValue, duration)
	local p = {}
	p[property] = targetValue
	local t = TweenService:Create(element, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
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
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = f
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
gui.Name = "BrazierUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local interactPanel = makePanel(UDim2.fromOffset(200, 32), UDim2.new(0.5, -100, 1, -100), gui, 0.2)
local interactShadow = makeShadow(interactPanel)
interactPanel.Visible = false
interactShadow.Visible = false

local interactText = makeLabel("[F] Interact", Enum.Font.GothamBold, COLORS.white, interactPanel)
interactText.Size = UDim2.fromScale(1, 1)
interactText.TextSize = 18
interactText.RichText = true
interactText.Text = "<font color='rgb(210,165,50)'>[F]</font> Interact"

local sequencePanel = makePanel(UDim2.fromOffset(460, 60), UDim2.new(1, -476, 0, 80), gui, 0.2)
local sequenceShadow = makeShadow(sequencePanel)
sequencePanel.Visible = false
sequenceShadow.Visible = false
local seqStroke = sequencePanel:FindFirstChildOfClass("UIStroke")
if seqStroke then
	seqStroke.Color = COLORS.red
	seqStroke.Transparency = 0.4
end

local seqLabel = makeLabel("SABOTAGE SEQUENCE:", Enum.Font.GothamBold, COLORS.grey, sequencePanel)
seqLabel.Size = UDim2.new(0, 170, 1, 0)
seqLabel.TextSize = 14
seqLabel.TextXAlignment = Enum.TextXAlignment.Left

local seqValue = makeLabel("", Enum.Font.GothamBold, COLORS.red, sequencePanel)
seqValue.Size = UDim2.new(1, -180, 1, 0)
seqValue.Position = UDim2.fromOffset(175, 0)
seqValue.TextSize = 24
seqValue.TextXAlignment = Enum.TextXAlignment.Left

local thiefHints = makePanel(UDim2.fromOffset(180, 44), UDim2.new(0, 16, 1, -120), gui, 0.2)
local thiefHintsShadow = makeShadow(thiefHints)
thiefHints.Visible = false
thiefHintsShadow.Visible = false
local hintIcons = {}
for i = 1, 4 do
	local slot = Instance.new("Frame")
	slot.Size = UDim2.fromOffset(36, 36)
	slot.Position = UDim2.fromOffset((i - 1) * 42 + 6, 4)
	slot.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	slot.Parent = thiefHints
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = slot
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 255, 255)
	st.Transparency = 0.85
	st.Parent = slot
	local t = makeLabel("?", Enum.Font.GothamBold, COLORS.grey, slot)
	t.Size = UDim2.fromScale(1, 1)
	t.TextSize = 20
	t.TextXAlignment = Enum.TextXAlignment.Center
	t.TextYAlignment = Enum.TextYAlignment.Center
	hintIcons[i] = {frame = slot, label = t, stroke = st}
end

local currentNearby
local isHintVisible = false
local knownSequence = {}
local litSet = {}

local function findBrazierByName(name)
	return workspace:FindFirstChild(name, true)
end

local function setFillVisual(brazierName, lit)
	local fill = workspace:FindFirstChild("BrazierFill" .. brazierName:gsub("Brazier", ""), true)
	if not fill or not fill:IsA("BasePart") then
		return
	end
	if lit then
		fill.Color = Color3.fromRGB(255, 140, 30)
		fill.Material = Enum.Material.Neon
		if not fill:FindFirstChild("ClientBrazierGlow") then
			local light = Instance.new("PointLight")
			light.Name = "ClientBrazierGlow"
			light.Brightness = 5
			light.Range = 15
			light.Color = Color3.fromRGB(255, 160, 60)
			light.Parent = fill
		end
	else
		fill.Color = Color3.fromRGB(40, 35, 30)
		fill.Material = Enum.Material.Cobblestone
		local glow = fill:FindFirstChild("ClientBrazierGlow")
		if glow then
			glow:Destroy()
		end
	end
end

local function showInteract()
	if isHintVisible then
		return
	end
	isHintVisible = true
	interactPanel.Visible = true
	interactShadow.Visible = true
	interactPanel.BackgroundTransparency = 1
	interactShadow.BackgroundTransparency = 1
	tweenIn(interactPanel, "BackgroundTransparency", 0.2, 0.2)
	tweenIn(interactShadow, "BackgroundTransparency", 0.6, 0.2)
end

local function hideInteract()
	if not isHintVisible then
		return
	end
	isHintVisible = false
	tweenIn(interactPanel, "BackgroundTransparency", 1, 0.2)
	tweenIn(interactShadow, "BackgroundTransparency", 1, 0.2)
	task.delay(0.21, function()
		if not isHintVisible then
			interactPanel.Visible = false
			interactShadow.Visible = false
		end
	end)
end

local function updateThiefHints()
	local role = localPlayer:GetAttribute("Role")
	if role ~= "Thief" then
		thiefHints.Visible = false
		thiefHintsShadow.Visible = false
		return
	end
	thiefHints.Visible = true
	thiefHintsShadow.Visible = true

	local revealIndex = 1
	for i = 1, #knownSequence do
		if litSet[knownSequence[i]] then
			revealIndex = i + 1
		else
			break
		end
	end

	for i, item in ipairs(hintIcons) do
		local name = knownSequence[i]
		if not name then
			item.label.Text = "?"
			item.frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			item.label.TextColor3 = COLORS.grey
		elseif i <= revealIndex then
			local n = name:gsub("Brazier", "")
			if litSet[name] then
				item.label.Text = "✓"
				item.frame.BackgroundColor3 = Color3.fromRGB(40, 220, 200)
				item.label.TextColor3 = Color3.fromRGB(10, 10, 14)
				item.stroke.Color = COLORS.teal
				item.stroke.Transparency = 0.2
			else
				item.label.Text = n
				item.frame.BackgroundColor3 = Color3.fromRGB(40, 220, 200)
				item.label.TextColor3 = Color3.fromRGB(10, 10, 14)
				item.stroke.Color = COLORS.teal
				item.stroke.Transparency = 0.2
			end
		else
			item.label.Text = "?"
			item.frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			item.label.TextColor3 = COLORS.grey
			item.stroke.Color = Color3.fromRGB(255, 255, 255)
			item.stroke.Transparency = 0.85
		end
	end
end

local function getNearbyBrazier()
	local char = localPlayer.Character
	if not char then
		return nil
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	for i = 1, 8 do
		local name = "Brazier" .. i
		local part = findBrazierByName(name)
		if part and part:IsA("BasePart") and (part.Position - root.Position).Magnitude <= INTERACT_DISTANCE then
			return name
		end
	end
	return nil
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		local nearby = getNearbyBrazier()
		if nearby then
			brazierInteractRemote:FireServer(nearby)
		end
	end
end)

guardianSequenceRemote.OnClientEvent:Connect(function(sequence)
	if type(sequence) ~= "table" then
		return
	end
	knownSequence = sequence
	local role = localPlayer:GetAttribute("Role")
	if role == "Guardian" then
		local pieces = {}
		for _, fullName in ipairs(sequence) do
			table.insert(pieces, "B" .. fullName:gsub("Brazier", ""))
		end
		seqValue.Text = table.concat(pieces, " → ")
		sequencePanel.Visible = true
		sequenceShadow.Visible = true
		sequencePanel.Position = UDim2.new(1, -440, 0, 80)
		tweenIn(sequencePanel, "Position", UDim2.new(1, -476, 0, 80), 0.25)
	end
	updateThiefHints()
end)

brazierStateChangedRemote.OnClientEvent:Connect(function(litBraziers)
	if type(litBraziers) ~= "table" then
		return
	end
	local previousLitSet = litSet
	litSet = {}
	for _, name in ipairs(litBraziers) do
		litSet[name] = true
	end
	for i = 1, 8 do
		local name = "Brazier" .. i
		setFillVisual(name, litSet[name] == true)
	end
	if UIStateController then
		local objectiveMap = {}
		for i = 1, 8 do
			local name = "Brazier" .. i
			objectiveMap[name] = litSet[name] == true
		end
		local objectiveList = {}
		for id, completed in pairs(objectiveMap) do
			table.insert(objectiveList, { id = id, completed = completed })
		end
		table.sort(objectiveList, function(a, b)
			return a.id < b.id
		end)
		UIStateController.Set("objectives", objectiveList)
		for id, isLit in pairs(objectiveMap) do
			local wasLit = previousLitSet[id] == true
			if isLit and not wasLit then
				UIStateController.Set("lastAlert", "brazier_lit")
			elseif (not isLit) and wasLit then
				UIStateController.Set("lastAlert", "brazier_extinguished")
			end
		end
	end
	updateThiefHints()
end)

RunService.RenderStepped:Connect(function(dt)
	currentNearby = getNearbyBrazier()
	if currentNearby then
		showInteract()
		local s = 1 + (math.sin(os.clock() * math.pi * 2) * 0.05)
		interactPanel.Size = UDim2.fromOffset(200 * s, 32 * s)
	else
		hideInteract()
		interactPanel.Size = UDim2.fromOffset(200, 32)
	end
end)

localPlayer:GetAttributeChangedSignal("Role"):Connect(function()
	local role = localPlayer:GetAttribute("Role")
	if role ~= "Guardian" then
		sequencePanel.Visible = false
		sequenceShadow.Visible = false
	end
	updateThiefHints()
end)
