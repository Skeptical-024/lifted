local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))

local localPlayer = Players.LocalPlayer
local brazierInteractRemote = ReplicatedStorage:WaitForChild("BrazierInteract")
local guardianBrazierSequenceRemote = ReplicatedStorage:WaitForChild("GuardianBrazierSequence")
local brazierStateChangedRemote = ReplicatedStorage:WaitForChild("BrazierStateChanged")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrazierGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "InteractHint"
hintLabel.Size = UDim2.new(0, 220, 0, 36)
hintLabel.Position = UDim2.new(0.5, -110, 1, -140)
hintLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
hintLabel.BackgroundTransparency = 0.25
hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hintLabel.Text = "Press F to interact"
hintLabel.TextScaled = true
hintLabel.Font = Enum.Font.GothamBold
hintLabel.Visible = false
hintLabel.Parent = screenGui

local sequencePanel = Instance.new("Frame")
sequencePanel.Name = "SequencePanel"
sequencePanel.Size = UDim2.new(0, 420, 0, 48)
sequencePanel.Position = UDim2.new(1, -440, 0, 20)
sequencePanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
sequencePanel.BackgroundTransparency = 0.2
sequencePanel.Visible = false
sequencePanel.Parent = screenGui

local sequenceLabel = Instance.new("TextLabel")
sequenceLabel.Size = UDim2.fromScale(1, 1)
sequenceLabel.BackgroundTransparency = 1
sequenceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sequenceLabel.TextXAlignment = Enum.TextXAlignment.Left
sequenceLabel.Font = Enum.Font.GothamBold
sequenceLabel.TextScaled = true
sequenceLabel.Text = ""
sequenceLabel.Parent = sequencePanel

local litSet = {}

local function isGuardian()
	return localPlayer:GetAttribute("Role") == Types.PlayerRole.Guardian
end

local function getRootPart()
	local character = localPlayer.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function findBrazier(name)
	local instance = workspace:FindFirstChild(name, true)
	if instance and instance:IsA("BasePart") then
		return instance
	end
	return nil
end

local function getFillPart(name)
	local suffix = string.match(name, "Brazier(%d+)")
	if suffix then
		local fill = workspace:FindFirstChild("BrazierFill" .. suffix, true)
		if fill and fill:IsA("BasePart") then
			return fill
		end
	end
	return findBrazier(name)
end

local function applyVisual(name, lit)
	local fill = getFillPart(name)
	if not fill then
		return
	end

	if lit then
		fill.Color = Color3.fromRGB(255, 140, 30)
		fill.Material = Enum.Material.Neon
		local light = fill:FindFirstChild("BrazierLight")
		if not light then
			light = Instance.new("PointLight")
			light.Name = "BrazierLight"
			light.Brightness = 5
			light.Range = 15
			light.Color = Color3.fromRGB(255, 160, 60)
			light.Parent = fill
		end
	else
		fill.Color = Color3.fromRGB(40, 35, 30)
		fill.Material = Enum.Material.Cobblestone
		local light = fill:FindFirstChild("BrazierLight")
		if light then
			light:Destroy()
		end
	end
end

local function updateAllBraziers()
	for i = 1, 8 do
		local name = "Brazier" .. i
		applyVisual(name, litSet[name] == true)
	end
end

local function getNearestBrazierName()
	local root = getRootPart()
	if not root then
		return nil
	end

	local nearestName = nil
	local nearestDist = math.huge
	for i = 1, 8 do
		local name = "Brazier" .. i
		local brazier = findBrazier(name)
		if brazier then
			local dist = (root.Position - brazier.Position).Magnitude
			if dist <= Constants.BRAZIER_INTERACT_DISTANCE and dist < nearestDist then
				nearestDist = dist
				nearestName = name
			end
		end
	end
	return nearestName
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode ~= Enum.KeyCode.F then
		return
	end
	local name = getNearestBrazierName()
	if name then
		brazierInteractRemote:FireServer(name)
	end
end)

brazierStateChangedRemote.OnClientEvent:Connect(function(litNames)
	litSet = {}
	if type(litNames) == "table" then
		for _, name in ipairs(litNames) do
			if type(name) == "string" then
				litSet[name] = true
			end
		end
	end
	updateAllBraziers()
end)

guardianBrazierSequenceRemote.OnClientEvent:Connect(function(sequence)
	if not isGuardian() then
		return
	end
	if type(sequence) ~= "table" then
		return
	end
	sequencePanel.Visible = true
	sequenceLabel.Text = "Sequence: " .. table.concat(sequence, " → ")
end)

local heartbeatAccum = 0
RunService.Heartbeat:Connect(function(dt)
	heartbeatAccum += dt
	if heartbeatAccum < 0.1 then
		return
	end
	heartbeatAccum = 0

	hintLabel.Visible = getNearestBrazierName() ~= nil
	if not isGuardian() then
		sequencePanel.Visible = false
	end
end)
