local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))

local localPlayer = Players.LocalPlayer
local thiefExtractedRemote = ReplicatedStorage:WaitForChild("ThiefExtracted")
local setMovementStateRemote = ReplicatedStorage:WaitForChild("SetMovementState")

local crouching = false
local extracting = false
local extractToken = 0

local footstepSounds = {}
local originalFootstepVolume = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThiefExtractGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local barContainer = Instance.new("Frame")
barContainer.Name = "ExtractBarContainer"
barContainer.Size = UDim2.new(0, 400, 0, 24)
barContainer.Position = UDim2.new(0.5, -200, 1, -80)
barContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
barContainer.BorderSizePixel = 0
barContainer.Visible = false
barContainer.Parent = screenGui

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 6)
barCorner.Parent = barContainer

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.Position = UDim2.fromScale(0, 0)
fill.BackgroundColor3 = Color3.fromRGB(35, 220, 200)
fill.BorderSizePixel = 0
fill.Parent = barContainer

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = fill

local label = Instance.new("TextLabel")
label.Name = "ExtractLabel"
label.BackgroundTransparency = 1
label.Size = UDim2.new(0, 400, 0, 28)
label.Position = UDim2.new(0.5, -200, 1, -112)
label.Font = Enum.Font.GothamBold
label.Text = "EXTRACTING..."
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.TextStrokeTransparency = 0.5
label.Visible = false
label.Parent = screenGui

local function setExtractProgress(visible, progress)
	barContainer.Visible = visible
	label.Visible = visible
	fill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
end

local function isThief()
	return localPlayer:GetAttribute("Role") == Types.PlayerRole.Thief
end

local function getRootPart()
	local character = localPlayer.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function refreshFootstepSounds()
	table.clear(footstepSounds)
	table.clear(originalFootstepVolume)
	local character = localPlayer.Character
	if not character then
		return
	end
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Sound") and (descendant.Name == "FootstepSound" or descendant.Name == "Running") then
			table.insert(footstepSounds, descendant)
			originalFootstepVolume[descendant] = descendant.Volume
		end
	end
end

local function applyFootstepVolume()
	for _, sound in footstepSounds do
		if sound.Parent then
			local baseVolume = originalFootstepVolume[sound] or sound.Volume
			if crouching and isThief() then
				sound.Volume = baseVolume * Constants.THIEF_FOOTSTEP_VOLUME_SCALE_CROUCH
			else
				sound.Volume = baseVolume
			end
		end
	end
end

local function isNearVault()
	local rootPart = getRootPart()
	if not rootPart then
		return false
	end
	for _, vault in CollectionService:GetTagged("Vault") do
		if vault:IsA("BasePart") and vault:IsDescendantOf(workspace) then
			if (vault.Position - rootPart.Position).Magnitude <= Constants.THIEF_EXTRACT_DISTANCE then
				return true
			end
		end
	end
	return false
end

local function beginExtract()
	if extracting or not isThief() then
		return
	end
	if not isNearVault() then
		return
	end

	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	extracting = true
	extractToken += 1
	local token = extractToken
	local startPos = rootPart.Position
	local startTime = os.clock()
	local deadline = startTime + Constants.THIEF_EXTRACT_HOLD_SECONDS

	setExtractProgress(true, 0)

	while os.clock() < deadline do
		if token ~= extractToken then
			setExtractProgress(false, 0)
			return
		end
		if not isThief() then
			extracting = false
			setExtractProgress(false, 0)
			return
		end
		local currentRoot = getRootPart()
		if not currentRoot then
			extracting = false
			setExtractProgress(false, 0)
			return
		end
		if (currentRoot.Position - startPos).Magnitude > Constants.THIEF_EXTRACT_MOVE_CANCEL_DISTANCE then
			extracting = false
			setExtractProgress(false, 0)
			return
		end

		local elapsed = os.clock() - startTime
		local progress = elapsed / Constants.THIEF_EXTRACT_HOLD_SECONDS
		setExtractProgress(true, progress)
		task.wait()
	end

	if token == extractToken and extracting and isThief() then
		setExtractProgress(true, 1)
		extracting = false
		thiefExtractedRemote:FireServer()
		task.wait(0.05)
		setExtractProgress(false, 0)
	end
end

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.2)
	refreshFootstepSounds()
	applyFootstepVolume()
end)

localPlayer:GetAttributeChangedSignal("Role"):Connect(function()
	if not isThief() then
		crouching = false
		extracting = false
		extractToken += 1
		setMovementStateRemote:FireServer("Crouch", false)
		setExtractProgress(false, 0)
	end
	applyFootstepVolume()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if not isThief() then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		if not crouching then
			crouching = true
			setMovementStateRemote:FireServer("Crouch", true)
			applyFootstepVolume()
		end
	elseif input.KeyCode == Enum.KeyCode.E then
		task.spawn(beginExtract)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift and crouching then
		crouching = false
		if isThief() then
			setMovementStateRemote:FireServer("Crouch", false)
		end
		applyFootstepVolume()
	end
end)

if localPlayer.Character then
	refreshFootstepSounds()
	applyFootstepVolume()
end
