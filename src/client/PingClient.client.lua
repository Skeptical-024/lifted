-- PingClient
-- Renders world-space ping markers for teammates.
-- Pings auto-expire after server-specified lifetime.
-- G key / Gamepad R1 to ping from current position.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local localPlayer = Players.LocalPlayer
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local pingCreatedRemote = Remotes.Client(Remotes.Names.PingCreated)
local requestPingRemote = Remotes.Client(Remotes.Names.RequestPing)
local roundStartedRemote = Remotes.Client(Remotes.Names.RoundStarted)
local roundEndedRemote   = Remotes.Client(Remotes.Names.RoundEnded)

local TYPE_COLOR = {
	Objective = Color3.fromRGB(40, 220, 200),
	Idol      = Color3.fromRGB(220, 175, 55),
	Extract   = Color3.fromRGB(60, 200, 80),
	Cage      = Color3.fromRGB(200, 60, 200),
	Danger    = Color3.fromRGB(220, 80, 40),
	Generic   = Color3.fromRGB(200, 200, 200),
}
local TYPE_LABEL = {
	Objective = "SEAL", Idol = "IDOL", Extract = "EXTRACT",
	Cage = "RESCUE", Danger = "DANGER", Generic = "PING",
}

local activeMarkers = {}

local function clearMarkers()
	for _, inst in ipairs(activeMarkers) do
		if inst and inst.Parent then inst:Destroy() end
	end
	activeMarkers = {}
end

local function createMarker(pingData, lifetime)
	if typeof(pingData.position) ~= "Vector3" then return end
	local color = TYPE_COLOR[pingData.pingType] or TYPE_COLOR.Generic
	local label = TYPE_LABEL[pingData.pingType] or "PING"

	local part = Instance.new("Part")
	part.Name = "PingMarker"
	part.Size = Vector3.new(1.5, 1.5, 1.5)
	part.Shape = Enum.PartType.Ball
	part.CanCollide = false
	part.Anchored = true
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.15
	part.Position = pingData.position + Vector3.new(0, 2.5, 0)
	part.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(84, 30)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = part
	bb.Parent = workspace

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
	bg.BackgroundTransparency = 0.25
	bg.BorderSizePixel = 0
	bg.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = bg

	local topLabel = Instance.new("TextLabel")
	topLabel.Size = UDim2.new(1, 0, 0.55, 0)
	topLabel.BackgroundTransparency = 1
	topLabel.Text = label
	topLabel.TextColor3 = color
	topLabel.Font = Enum.Font.GothamBold
	topLabel.TextScaled = true
	topLabel.Parent = bg

	local senderLabel = Instance.new("TextLabel")
	senderLabel.Size = UDim2.new(1, 0, 0.45, 0)
	senderLabel.Position = UDim2.fromScale(0, 0.55)
	senderLabel.BackgroundTransparency = 1
	senderLabel.Text = pingData.playerName or "?"
	senderLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
	senderLabel.Font = Enum.Font.Gotham
	senderLabel.TextScaled = true
	senderLabel.Parent = bg

	table.insert(activeMarkers, part)
	table.insert(activeMarkers, bb)

	local lifeTime = type(lifetime) == "number" and math.clamp(lifetime, 1, 15) or 5
	task.delay(lifeTime, function()
		if part.Parent then part:Destroy() end
		if bb.Parent then bb:Destroy() end
	end)
end

-- Context-sensitive ping type based on player's current state
local function getContextPingType()
	if localPlayer:GetAttribute("HasIdol") == true then return "Idol" end
	local state = localPlayer:GetAttribute("RoundState")
	if state == "Caged" then return "Cage" end
	local role = localPlayer:GetAttribute("Role")
	if role == "Guardian" then return "Danger" end
	return "Objective"
end

local function sendPing()
	local role = localPlayer:GetAttribute("Role")
	if not role then return end
	local state = localPlayer:GetAttribute("RoundState")
	if state ~= "Alive" then return end

	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	requestPingRemote:FireServer(getContextPingType(), root.Position)
end

-- Input binding: G key + gamepad R1
ContextActionService:BindAction(
	"LIFTED_Ping",
	function(actionName, inputState, inputObject)
		if inputState ~= Enum.UserInputState.Begin then return end
		sendPing()
		return Enum.ContextActionResult.Sink
	end,
	true,
	Enum.KeyCode.G,
	Enum.KeyCode.ButtonR1
)
ContextActionService:SetTitle("LIFTED_Ping", "Ping")
ContextActionService:SetPosition("LIFTED_Ping", UDim2.new(1, -370, 1, -190))

local function updatePingButton()
	local button = ContextActionService:GetButton("LIFTED_Ping")
	if button then
		button.Visible = localPlayer:GetAttribute("Role") ~= nil
			and localPlayer:GetAttribute("RoundState") == "Alive"
	end
end
localPlayer:GetAttributeChangedSignal("Role"):Connect(updatePingButton)
localPlayer:GetAttributeChangedSignal("RoundState"):Connect(updatePingButton)
task.defer(updatePingButton)

pingCreatedRemote.OnClientEvent:Connect(function(pingData, lifetime)
	if type(pingData) ~= "table" then return end
	createMarker(pingData, lifetime)
end)

roundStartedRemote.OnClientEvent:Connect(clearMarkers)
roundEndedRemote.OnClientEvent:Connect(clearMarkers)
