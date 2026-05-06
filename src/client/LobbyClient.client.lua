-- LobbyClient v3

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local C = {
	bg = Color3.fromRGB(8, 6, 6),
	bgWarm = Color3.fromRGB(12, 8, 7),
	panel = Color3.fromRGB(14, 10, 9),
	panelLight = Color3.fromRGB(22, 15, 13),
	card = Color3.fromRGB(18, 12, 11),
	crimson = Color3.fromRGB(180, 35, 35),
	crimsonDim = Color3.fromRGB(100, 20, 20),
	crimsonGlow = Color3.fromRGB(220, 60, 60),
	gold = Color3.fromRGB(195, 150, 45),
	goldBright = Color3.fromRGB(220, 175, 70),
	goldDim = Color3.fromRGB(130, 95, 28),
	parchment = Color3.fromRGB(235, 225, 210),
	parchmentDim = Color3.fromRGB(175, 165, 150),
	greyWarm = Color3.fromRGB(140, 130, 120),
	greyDark = Color3.fromRGB(80, 72, 65),
	orange = Color3.fromRGB(200, 110, 30),
	orangeDim = Color3.fromRGB(140, 70, 15),
	black = Color3.fromRGB(4, 3, 3),
}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local lobbyUpdateRemote = ReplicatedStorage:WaitForChild("LobbyUpdate")
local roundStartedRemote = ReplicatedStorage:WaitForChild("RoundStarted")
local roleAssignedRemote = ReplicatedStorage:WaitForChild("RoleAssigned")

local playClickedBindable = ReplicatedStorage:FindFirstChild("PlayClicked")
if not playClickedBindable then
	playClickedBindable = Instance.new("BindableEvent")
	playClickedBindable.Name = "PlayClicked"
	playClickedBindable.Parent = ReplicatedStorage
end

local playClicked = false
local function onPlayClicked()
	playClicked = true
end
playClickedBindable.Event:Connect(onPlayClicked)

local startTime = os.clock()
local menuActive = true

local function tween(element, props, duration, style, direction)
	local t = TweenService:Create(element, TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function makePanel(size, position, parent)
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = size
	panel.Position = position
	panel.BackgroundColor3 = C.panel
	panel.BackgroundTransparency = 0.2
	panel.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.85
	stroke.Thickness = 1
	stroke.Parent = panel

	return panel
end

local function makeLabel(text, font, textColor, parent)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = font
	label.TextColor3 = textColor
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.Position = UDim2.fromScale(0, 0)
overlay.BackgroundColor3 = C.bg
overlay.BackgroundTransparency = 0.92
overlay.Visible = false
overlay.Parent = gui

local panelBasePos = UDim2.new(0.5, -240, 0.5, -140)
local panel = makePanel(UDim2.fromOffset(480, 280), panelBasePos + UDim2.fromOffset(0, 20), overlay)
panel.Visible = false

local logo = makeLabel("LIFTED", Enum.Font.GothamBlack, C.gold, panel)
logo.Size = UDim2.fromOffset(420, 64)
logo.Position = UDim2.fromOffset(30, 16)
logo.TextSize = 50
logo.TextXAlignment = Enum.TextXAlignment.Center
logo.TextYAlignment = Enum.TextYAlignment.Center

local divider = Instance.new("Frame")
divider.Size = UDim2.fromOffset(400, 1)
divider.Position = UDim2.fromOffset(40, 84)
divider.BorderSizePixel = 0
divider.BackgroundColor3 = C.crimson
divider.BackgroundTransparency = 0.2
divider.Parent = panel

local statusLabel = makeLabel("WAITING FOR PLAYERS", Enum.Font.GothamBold, C.parchment, panel)
statusLabel.Size = UDim2.fromOffset(420, 40)
statusLabel.Position = UDim2.fromOffset(30, 102)
statusLabel.TextSize = 30
statusLabel.TextXAlignment = Enum.TextXAlignment.Center

local countdownLabel = makeLabel("", Enum.Font.GothamBlack, C.parchment, panel)
countdownLabel.Size = UDim2.fromOffset(420, 92)
countdownLabel.Position = UDim2.fromOffset(30, 136)
countdownLabel.TextSize = 84
countdownLabel.TextXAlignment = Enum.TextXAlignment.Center
countdownLabel.Visible = false

local countPill = Instance.new("Frame")
countPill.Name = "CountPill"
countPill.Size = UDim2.fromOffset(180, 36)
countPill.Position = UDim2.fromOffset(150, 188)
countPill.BackgroundColor3 = C.panelLight
countPill.BackgroundTransparency = 0.1
countPill.Parent = panel

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(0, 18)
pillCorner.Parent = countPill

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = C.crimson
pillStroke.Transparency = 0.45
pillStroke.Thickness = 1
pillStroke.Parent = countPill

local countLabel = makeLabel("1 / 2 PLAYERS", Enum.Font.GothamBold, C.gold, countPill)
countLabel.Size = UDim2.fromScale(1, 1)
countLabel.TextSize = 18
countLabel.TextXAlignment = Enum.TextXAlignment.Center

local subtext = makeLabel("Steal the idol. Don't get caught.", Enum.Font.Gotham, C.greyWarm, panel)
subtext.Size = UDim2.fromOffset(420, 24)
subtext.Position = UDim2.fromOffset(30, 240)
subtext.TextSize = 18
subtext.TextXAlignment = Enum.TextXAlignment.Center

local visible = false
local mode = "waiting"
local baseWaiting = "WAITING FOR PLAYERS"
local dotCount = 0
local pulseConnection

local function startCriticalPulse()
	if pulseConnection then return end
	pulseConnection = RunService.Heartbeat:Connect(function()
		local alpha = (math.sin(os.clock() * 8) + 1) / 2
		local stroke = panel:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = C.crimson
			stroke.Transparency = 0.2 + (0.35 * (1 - alpha))
		end
	end)
end

local function stopCriticalPulse()
	if pulseConnection then
		pulseConnection:Disconnect()
		pulseConnection = nil
	end
	local stroke = panel:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Transparency = 0.85
	end
end

local function showPanel()
	if visible then return end
	visible = true
	overlay.Visible = true
	panel.Visible = true
	overlay.BackgroundTransparency = 1
	panel.BackgroundTransparency = 1
	panel.Position = panelBasePos + UDim2.fromOffset(0, 20)
	tween(overlay, {BackgroundTransparency = 0.92}, 0.3)
	tween(panel, {BackgroundTransparency = 0.2, Position = panelBasePos}, 0.4)
end

local function hidePanel()
	if not visible then return end
	visible = false
	tween(overlay, {BackgroundTransparency = 1}, 0.25)
	tween(panel, {BackgroundTransparency = 1, Position = panelBasePos + UDim2.fromOffset(0, 12)}, 0.25)
	task.delay(0.27, function()
		if not visible then
			overlay.Visible = false
			panel.Visible = false
		end
	end)
end

local function setWaiting(playerCount, required)
	mode = "waiting"
	statusLabel.Text = baseWaiting
	countdownLabel.Visible = false
	countPill.Visible = true
	countLabel.Text = string.format("%d / %d PLAYERS", playerCount, required)
	subtext.Text = "Steal the idol. Don't get caught."
	stopCriticalPulse()
	showPanel()
end

local function pulseCountdown()
	countdownLabel.Size = UDim2.fromOffset(420, 92)
	tween(countdownLabel, {Size = UDim2.fromOffset(468, 108)}, 0.14)
	task.delay(0.14, function()
		if countdownLabel.Parent and mode == "countdown" then
			tween(countdownLabel, {Size = UDim2.fromOffset(420, 92)}, 0.14)
		end
	end)
end

local function setCountdown(seconds)
	mode = "countdown"
	statusLabel.Text = "ROUND STARTING"
	countPill.Visible = false
	countdownLabel.Visible = true
	countdownLabel.Text = tostring(seconds)
	countdownLabel.TextColor3 = seconds <= 3 and C.goldBright or C.parchment
	subtext.Text = "Get ready..."
	showPanel()
	pulseCountdown()
	if seconds <= 3 then startCriticalPulse() else stopCriticalPulse() end
end

local function processLobbyPayload(payload)
	if not menuActive or not playClicked then return end
	if type(payload) ~= "table" then return end
	if payload.status == "waiting" then
		setWaiting(tonumber(payload.playerCount) or 0, tonumber(payload.required) or 0)
	elseif payload.status == "countdown" then
		setCountdown(tonumber(payload.countdown) or 0)
	end
end

lobbyUpdateRemote.OnClientEvent:Connect(function(payload)
	local elapsed = os.clock() - startTime
	if elapsed < 2 then
		task.delay(2 - elapsed, function()
			processLobbyPayload(payload)
		end)
	else
		processLobbyPayload(payload)
	end
end)

roundStartedRemote.OnClientEvent:Connect(function()
	menuActive = false
	stopCriticalPulse()
	hidePanel()
end)

roleAssignedRemote.OnClientEvent:Connect(function()
	menuActive = false
	stopCriticalPulse()
	hidePanel()
end)

task.spawn(function()
	while true do
		if visible and mode == "waiting" then
			dotCount = (dotCount + 1) % 4
			statusLabel.Text = baseWaiting .. string.rep(".", dotCount)
		end
		task.wait(0.5)
	end
end)
