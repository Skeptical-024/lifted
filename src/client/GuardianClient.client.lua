local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local localPlayer = Players.LocalPlayer
local catchThiefRemote = Remotes.Client(Remotes.Names.CatchThief)
local requestRushRemote = Remotes.Client(Remotes.Names.RequestGuardianRush)
local requestRevealRemote = Remotes.Client(Remotes.Names.RequestGuardianReveal)
local requestRoarRemote = Remotes.Client(Remotes.Names.RequestGuardianRoar)
local guardianRevealRemote = Remotes.Client(Remotes.Names.GuardianRevealStarted)
local guardianCarrierPingRemote = Remotes.Client(Remotes.Names.GuardianCarrierPing)

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

	catchThiefRemote:FireServer(closestTarget)
end

-- Guardian actions via ContextActionService for keyboard + gamepad support.
-- All validation is server-side; client just sends request.

local function bindGuardianActions()
	ContextActionService:BindAction(
		"LIFTED_GuardianCatch",
		function(_, inputState, _)
			if inputState ~= Enum.UserInputState.Begin then return end
			if not isGuardian() then return end
			tryCatchNearestThief()
			return Enum.ContextActionResult.Sink
		end,
		true,
		Enum.KeyCode.E, Enum.KeyCode.ButtonX
	)
	ContextActionService:SetTitle("LIFTED_GuardianCatch", "Catch")
	ContextActionService:SetPosition("LIFTED_GuardianCatch", UDim2.new(1, -150, 1, -190))
	ContextActionService:BindAction(
		"LIFTED_GuardianRush",
		function(_, inputState, _)
			if inputState ~= Enum.UserInputState.Begin then return end
			if not isGuardian() then return end
			requestRushRemote:FireServer()
			return Enum.ContextActionResult.Sink
		end,
		true,
		Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL1
	)
	ContextActionService:SetTitle("LIFTED_GuardianRush", "Rush")
	ContextActionService:SetPosition("LIFTED_GuardianRush", UDim2.new(1, -260, 1, -190))
	ContextActionService:BindAction(
		"LIFTED_GuardianReveal",
		function(_, inputState, _)
			if inputState ~= Enum.UserInputState.Begin then return end
			if not isGuardian() then return end
			requestRevealRemote:FireServer()
			return Enum.ContextActionResult.Sink
		end,
		true,
		Enum.KeyCode.Q, Enum.KeyCode.ButtonY
	)
	ContextActionService:SetTitle("LIFTED_GuardianReveal", "Reveal")
	ContextActionService:SetPosition("LIFTED_GuardianReveal", UDim2.new(1, -150, 1, -290))
	ContextActionService:BindAction(
		"LIFTED_GuardianRoar",
		function(_, inputState, _)
			if inputState ~= Enum.UserInputState.Begin then return end
			if not isGuardian() then return end
			requestRoarRemote:FireServer()
			return Enum.ContextActionResult.Sink
		end,
		true,
		Enum.KeyCode.R, Enum.KeyCode.ButtonB
	)
	ContextActionService:SetTitle("LIFTED_GuardianRoar", "Roar")
	ContextActionService:SetPosition("LIFTED_GuardianRoar", UDim2.new(1, -260, 1, -290))
end

local function unbindGuardianActions()
	ContextActionService:UnbindAction("LIFTED_GuardianCatch")
	ContextActionService:UnbindAction("LIFTED_GuardianRush")
	ContextActionService:UnbindAction("LIFTED_GuardianReveal")
	ContextActionService:UnbindAction("LIFTED_GuardianRoar")
end

localPlayer:GetAttributeChangedSignal("Role"):Connect(function()
	if isGuardian() then
		bindGuardianActions()
	else
		unbindGuardianActions()
		clearRevealMarkers()
		clearCarrierMarker()
	end
end)

-- Bind if already guardian on script start
if isGuardian() then
	bindGuardianActions()
end

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
