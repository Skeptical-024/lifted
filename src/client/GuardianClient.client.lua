local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))

local localPlayer = Players.LocalPlayer
local catchThiefRemote = ReplicatedStorage:WaitForChild("CatchThief")
local requestRushRemote = ReplicatedStorage:WaitForChild("RequestGuardianRush")
local requestRevealRemote = ReplicatedStorage:WaitForChild("RequestGuardianReveal")
local requestRoarRemote = ReplicatedStorage:WaitForChild("RequestGuardianRoar")
local guardianRevealRemote = ReplicatedStorage:WaitForChild("GuardianRevealStarted")
local guardianCarrierPingRemote = ReplicatedStorage:WaitForChild("GuardianCarrierPing")

local function isGuardian()
	return localPlayer:GetAttribute("Role") == Types.PlayerRole.Guardian
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local revealMarkers = {}
local carrierMarker = nil

local function clearRevealMarkers()
	for _, marker in ipairs(revealMarkers) do
		if marker and marker.Parent then
			marker:Destroy()
		end
	end
	revealMarkers = {}
end

local function clearCarrierMarker()
	if carrierMarker and carrierMarker.Parent then
		carrierMarker:Destroy()
	end
	carrierMarker = nil
end

local function updateCarrierMarker(name, position, duration)
	clearCarrierMarker()
	local _ = name
	local part = Instance.new("Part")
	part.Name = "CarrierPingMarker"
	part.Size = Vector3.new(2, 2, 2)
	part.Shape = Enum.PartType.Ball
	part.CanCollide = false
	part.Anchored = true
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 200, 0)
	part.Transparency = 0.2
	if typeof(position) == "Vector3" then
		part.Position = position + Vector3.new(0, 5, 0)
	end
	part.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(60, 20)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "IDOL"
	lbl.TextColor3 = Color3.fromRGB(255, 220, 80)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.Parent = bb
	carrierMarker = part
	-- Auto-clear after duration (refreshed on next ping before expiry)
	task.delay(type(duration) == "number" and duration + 0.2 or 2, function()
		if carrierMarker == part then
			clearCarrierMarker()
		end
	end)
end

local function getRevealAdorneeForUserId(userId)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == userId then
			local character = player.Character
			if not character then return nil end
			return character:FindFirstChild("Head")
				or character:FindFirstChild("HumanoidRootPart")
		end
	end
	return nil
end

local function tryCatchNearestThief()
	if not isGuardian() then
		return
	end
	local guardianRoot = getRootPart(localPlayer)
	if not guardianRoot then
		return
	end

	local closestTarget = nil
	local closestDistance = math.huge
	for _, player in Players:GetPlayers() do
		if player ~= localPlayer and player:GetAttribute("Role") == Types.PlayerRole.Thief then
			local thiefRoot = getRootPart(player)
			if thiefRoot then
				local distance = (guardianRoot.Position - thiefRoot.Position).Magnitude
				if distance <= Constants.GUARDIAN_CATCH_DISTANCE and distance < closestDistance then
					closestDistance = distance
					closestTarget = player
				end
			end
		end
	end

	if closestTarget then
		catchThiefRemote:FireServer(closestTarget)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if not isGuardian() then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		if isGuardian() then
			requestRushRemote:FireServer()
		end
	elseif input.KeyCode == Enum.KeyCode.E then
		tryCatchNearestThief()
	elseif input.KeyCode == Enum.KeyCode.Q then
		if isGuardian() then
			requestRevealRemote:FireServer()
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		if isGuardian() then
			requestRoarRemote:FireServer()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		-- Rush is server-managed. No client-side release action needed.
	end
end)

localPlayer:GetAttributeChangedSignal("Role"):Connect(function()
	if not isGuardian() then
		clearRevealMarkers()
		clearCarrierMarker()
	end
end)

guardianRevealRemote.OnClientEvent:Connect(function(revealed, duration)
	clearRevealMarkers()
	if type(revealed) ~= "table" then
		return
	end
	for _, data in ipairs(revealed) do
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(80, 24)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		bb.Name = "RevealMarker_" .. tostring(data.userId)
		local adornee = getRevealAdorneeForUserId(tonumber(data.userId))
		if adornee then
			bb.Adornee = adornee
		end
		bb.Parent = workspace

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Text = type(data.name) == "string" and data.name or "Thief"
		lbl.TextColor3 = Color3.fromRGB(255, 200, 200)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.Parent = bb

		if not adornee and typeof(data.position) == "Vector3" then
			local fallbackPart = Instance.new("Part")
			fallbackPart.Name = "RevealMarkerPart_" .. tostring(data.userId)
			fallbackPart.Size = Vector3.new(1, 1, 1)
			fallbackPart.CanCollide = false
			fallbackPart.Anchored = true
			fallbackPart.Transparency = 1
			fallbackPart.Position = data.position + Vector3.new(0, 4, 0)
			fallbackPart.Parent = workspace
			bb.Adornee = fallbackPart
			table.insert(revealMarkers, fallbackPart)
		end

		table.insert(revealMarkers, bb)
	end
	task.delay(type(duration) == "number" and duration or 4, clearRevealMarkers)
end)

guardianCarrierPingRemote.OnClientEvent:Connect(function(carrierUserId, carrierName, position, duration)
	local _ = carrierUserId
	if not isGuardian() then
		clearCarrierMarker()
		return
	end
	updateCarrierMarker(
		type(carrierName) == "string" and carrierName or "Carrier",
		typeof(position) == "Vector3" and position or nil,
		duration
	)
end)
