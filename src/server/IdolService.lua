-- IdolService
-- Server-authoritative idol pickup, drop, carrier slow, extraction hold, carrier pings.

local IdolService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObjectiveService = require(script.Parent:WaitForChild("ObjectiveService"))
local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local IDOL_DIST = Constants.IDOL_INTERACT_DISTANCE or 10
local EXTRACT_DIST = Constants.EXTRACT_INTERACT_DISTANCE or 14
local HOLD_SECONDS = Constants.THIEF_EXTRACT_HOLD_SECONDS or 5
local CARRIER_SPEED_MULT = Constants.IDOL_CARRIER_SPEED_MULTIPLIER or 0.75
local CARRIER_PING_INTERVAL = Constants.IDOL_CARRIER_REVEAL_INTERVAL or 1.25
local CARRIER_PING_DUR = Constants.IDOL_CARRIER_REVEAL_DURATION or 1.5
local BASE_SPEED = Constants.DEFAULT_WALK_SPEED or 16
local CARRIER_SPEED = BASE_SPEED * CARRIER_SPEED_MULT

-- State
local idolCarrier = nil
local idolPart = nil
local extractPoints = {}
local idolSpawnCFrame = nil
local roundIsActive = false
local currentRoundId = 0
local roundEndCallback = nil

-- Extraction state
local isExtracting = false
local extractProgress = 0
local extractToken = 0
local extractProgressAt = 0

-- Carrier ping state
local lastPingAt = 0

-- Heartbeat
local heartbeatConn = nil

local function getOrCreateRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then return r end
	if r then r:Destroy() end
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = ReplicatedStorage
	return e
end

local function fireAll(name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then r:FireAllClients(...) end
end

local function fireOne(player, name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then r:FireClient(player, ...) end
end

local function getRootPart(player)
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function applyCarrierSlow(player)
	local hum = getHumanoid(player)
	if hum then hum.WalkSpeed = CARRIER_SPEED end
	pcall(function() player:SetAttribute("IdolCarrierSpeed", CARRIER_SPEED) end)
end

local function restoreCarrierSpeed(player)
	-- Only restore if player is still alive — do not unfreeze caught/caged players
	if not PlayerStateService.IsAlive(player) then return end
	local hum = getHumanoid(player)
	if hum then hum.WalkSpeed = BASE_SPEED end
	pcall(function() player:SetAttribute("IdolCarrierSpeed", nil) end)
end

local function cancelExtraction(reason)
	if not isExtracting then return end
	isExtracting = false
	extractProgress = 0
	extractToken += 1
	fireAll("ExtractCanceled", reason or "canceled")
end

local function placeIdolAt(position)
	if not idolPart then return end
	pcall(function()
		idolPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		idolPart.Anchored = true
		idolPart.Transparency = 0.2
		idolPart:SetAttribute("IdolState", "Dropped")
	end)
end

local function resetIdolToSpawn()
	if not idolPart or not idolSpawnCFrame then return end
	pcall(function()
		idolPart.CFrame = idolSpawnCFrame
		idolPart.Anchored = true
		idolPart.Transparency = 0.2
		idolPart:SetAttribute("IdolState", "Available")
	end)
end

local function stopHeartbeat()
	if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
end

local function startHeartbeat()
	stopHeartbeat()
	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		if not roundIsActive then return end

		-- Carrier ping to guardian
		if idolCarrier and idolCarrier.Parent then
			local now = os.clock()
			if now - lastPingAt >= CARRIER_PING_INTERVAL then
				lastPingAt = now
				local root = getRootPart(idolCarrier)
				if root then
					-- Find guardian and fire ping only to them
					for _, p in ipairs(Players:GetPlayers()) do
						if PlayerStateService.IsGuardian(p) then
							fireOne(p, "GuardianCarrierPing",
								idolCarrier.UserId,
								idolCarrier.Name,
								root.Position,
								CARRIER_PING_DUR)
						end
					end
				end
			end
		end

		-- Extraction progress
		if not isExtracting then return end
		if not idolCarrier then
			cancelExtraction("no_carrier")
			return
		end
		if not PlayerStateService.CanInteractObjective(idolCarrier) then
			cancelExtraction("not_eligible")
			return
		end
		if not ObjectiveService.IsVaultOpen() then
			cancelExtraction("vault_closed")
			return
		end
		local root = getRootPart(idolCarrier)
		if not root then
			cancelExtraction("no_character")
			return
		end
		-- Validate still near any extract point
		local nearExtract = false
		local nearExtractPart = nil
		for _, ep in ipairs(extractPoints) do
			if ep and ep.Parent and (root.Position - ep.Position).Magnitude <= EXTRACT_DIST then
				nearExtract = true
				nearExtractPart = ep
				break
			end
		end
		if not nearExtract then
			cancelExtraction("left_extract")
			return
		end
		local _ = nearExtractPart

		extractProgress = math.clamp(extractProgress + dt / HOLD_SECONDS, 0, 1)

		-- Fire progress throttled to ~0.1s
		local now2 = os.clock()
		if now2 - extractProgressAt >= 0.1 then
			extractProgressAt = now2
			fireAll("ExtractProgress", extractProgress)
		end

		if extractProgress >= 1 then
			isExtracting = false
			extractToken += 1
			local carrier = idolCarrier
			idolCarrier = nil
			pcall(function()
				carrier:SetAttribute("HasIdol", false)
				carrier:SetAttribute("IdolCarrierSpeed", nil)
			end)
			PlayerStateService.MarkEscaped(carrier)
			if idolPart then
				pcall(function()
					idolPart.Transparency = 1
					idolPart:SetAttribute("IdolState", "Extracted")
				end)
			end
			fireAll("ExtractCompleted", carrier.UserId, carrier.Name)
			fireAll("IdolExtracted", carrier.UserId, carrier.Name)
			fireAll("IdolCarrierChanged", nil, nil)
			print("[IdolService] Extraction complete by", carrier.Name)
			if roundEndCallback then
				roundEndCallback(carrier)
			else
				warn("[IdolService] No round-end callback set.")
			end
		end
	end)
end

-- Public API

function IdolService.SetRoundEndCallback(callback)
	roundEndCallback = callback
end

function IdolService.Init()
	local requestPickupRemote = getOrCreateRemote("RequestIdolPickup")
	local requestDropRemote = getOrCreateRemote("RequestIdolDrop")
	local requestExtractRemote = getOrCreateRemote("RequestExtractWithIdol")
	local requestCancelRemote = getOrCreateRemote("RequestExtractCancel")
	getOrCreateRemote("IdolAvailable")
	getOrCreateRemote("IdolPickedUp")
	getOrCreateRemote("IdolDropped")
	getOrCreateRemote("IdolCarrierChanged")
	getOrCreateRemote("IdolExtracted")
	getOrCreateRemote("IdolFailed")
	getOrCreateRemote("ExtractStarted")
	getOrCreateRemote("ExtractProgress")
	getOrCreateRemote("ExtractCanceled")
	getOrCreateRemote("ExtractCompleted")
	getOrCreateRemote("GuardianCarrierPing")

	requestPickupRemote.OnServerEvent:Connect(function(player)
		IdolService.RequestPickup(player)
	end)
	requestDropRemote.OnServerEvent:Connect(function(player)
		IdolService.RequestDrop(player)
	end)
	requestExtractRemote.OnServerEvent:Connect(function(player)
		IdolService.RequestExtract(player)
	end)
	requestCancelRemote.OnServerEvent:Connect(function(player)
		IdolService.RequestExtractCancel(player)
	end)

	print("[IdolService] Initialized.")
end

function IdolService.AutoRegisterParts()
	idolPart = nil
	extractPoints = {}
	for _, part in ipairs(CollectionService:GetTagged("Idol")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			idolPart = part
			idolSpawnCFrame = part.CFrame
			break
		end
	end
	for _, part in ipairs(CollectionService:GetTagged("ExtractPoint")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			table.insert(extractPoints, part)
		end
	end
	if not idolPart then warn("[IdolService] No Idol-tagged part found.") end
	if #extractPoints == 0 then warn("[IdolService] No ExtractPoint parts found.") end
end

function IdolService.ResetForRound(roundId)
	currentRoundId = roundId or 0
	roundIsActive = true
	isExtracting = false
	extractProgress = 0
	extractToken += 1
	lastPingAt = 0
	if idolCarrier then
		pcall(function()
			idolCarrier:SetAttribute("HasIdol", false)
			idolCarrier:SetAttribute("IdolCarrierSpeed", nil)
		end)
		idolCarrier = nil
	end
	for _, p in ipairs(Players:GetPlayers()) do
		pcall(function()
			p:SetAttribute("HasIdol", false)
			p:SetAttribute("IdolCarrierSpeed", nil)
		end)
	end
	IdolService.AutoRegisterParts()
	if idolPart then
		pcall(function()
			idolPart.CFrame = idolSpawnCFrame or idolPart.CFrame
			idolPart.Transparency = 0.6
			idolPart.Anchored = true
			idolPart:SetAttribute("IdolState", "Locked")
		end)
	end
	stopHeartbeat()
	startHeartbeat()
end

function IdolService.SetRoundActive(isActive)
	roundIsActive = isActive
end

function IdolService.StopRound()
	roundIsActive = false
	cancelExtraction("round_ended")
	stopHeartbeat()
	if idolCarrier then
		pcall(function()
			idolCarrier:SetAttribute("HasIdol", false)
			idolCarrier:SetAttribute("IdolCarrierSpeed", nil)
		end)
		idolCarrier = nil
	end
	if idolPart and idolSpawnCFrame then
		pcall(function()
			idolPart.CFrame = idolSpawnCFrame
			idolPart.Transparency = 0.6
			idolPart.Anchored = true
			idolPart:SetAttribute("IdolState", "Locked")
		end)
	end
end

function IdolService.OnVaultOpened()
	if not roundIsActive then return end
	if not idolPart then
		warn("[IdolService] Vault opened but no idol part registered.")
		return
	end
	pcall(function()
		idolPart.Transparency = 0.2
		idolPart:SetAttribute("IdolState", "Available")
	end)
	fireAll("IdolAvailable")
	print("[IdolService] Idol is now available.")
end

function IdolService.RequestPickup(player)
	if not roundIsActive then return end
	if not ObjectiveService.IsVaultOpen() then
		fireOne(player, "IdolFailed", "vault_not_open") return
	end
	if not PlayerStateService.CanInteractObjective(player) then
		fireOne(player, "IdolFailed", "not_eligible") return
	end
	if idolCarrier then
		fireOne(player, "IdolFailed", "already_carried") return
	end
	if not idolPart then
		fireOne(player, "IdolFailed", "idol_unbound") return
	end
	local root = getRootPart(player)
	if not root then
		fireOne(player, "IdolFailed", "no_character") return
	end
	if (root.Position - idolPart.Position).Magnitude > IDOL_DIST then
		fireOne(player, "IdolFailed", "too_far") return
	end

	idolCarrier = player
	pcall(function()
		player:SetAttribute("HasIdol", true)
		idolPart:SetAttribute("IdolState", "Carried")
		idolPart.Transparency = 1
		idolPart.Anchored = true
		idolPart.CFrame = root.CFrame * CFrame.new(0, 2, 0)
	end)
	applyCarrierSlow(player)
	lastPingAt = 0 -- fire first ping immediately next heartbeat

	fireAll("IdolPickedUp", player.UserId, player.Name)
	fireAll("IdolCarrierChanged", player.UserId, player.Name)
	print("[IdolService] Idol picked up by", player.Name)
end

function IdolService.RequestDrop(player)
	if idolCarrier ~= player then return end
	local root = getRootPart(player)
	local dropPos = root and root.Position or (idolSpawnCFrame and idolSpawnCFrame.Position)
	IdolService.DropFromPlayer(player, "voluntary", dropPos)
end

function IdolService.DropFromPlayer(player, reason, dropPosition)
	if idolCarrier ~= player then return end
	cancelExtraction("idol_dropped")
	idolCarrier = nil
	restoreCarrierSpeed(player)
	pcall(function() player:SetAttribute("HasIdol", false) end)
	local pos = dropPosition
	if not pos then
		local root = getRootPart(player)
		pos = root and root.Position
	end
	if pos and idolPart then
		placeIdolAt(pos)
	elseif idolPart then
		resetIdolToSpawn()
	end
	fireAll("IdolDropped", player.UserId, reason or "unknown")
	fireAll("IdolCarrierChanged", nil, nil)
	print("[IdolService] Idol dropped by", player.Name, "reason:", reason or "unknown")
end

function IdolService.RequestExtract(player)
	if not roundIsActive then return end
	if not ObjectiveService.IsVaultOpen() then
		fireOne(player, "IdolFailed", "vault_not_open") return
	end
	if idolCarrier ~= player then
		fireOne(player, "IdolFailed", "not_carrier") return
	end
	if not PlayerStateService.CanInteractObjective(player) then
		fireOne(player, "IdolFailed", "not_eligible") return
	end
	if isExtracting then return end -- already in progress
	if #extractPoints == 0 then
		fireOne(player, "IdolFailed", "no_extract_points") return
	end
	local root = getRootPart(player)
	if not root then
		fireOne(player, "IdolFailed", "no_character") return
	end
	local nearEP = nil
	for _, ep in ipairs(extractPoints) do
		if ep and ep.Parent and (root.Position - ep.Position).Magnitude <= EXTRACT_DIST then
			nearEP = ep
			break
		end
	end
	if not nearEP then
		fireOne(player, "IdolFailed", "too_far_from_extract") return
	end

	isExtracting = true
	extractProgress = 0
	extractProgressAt = 0
	local extractId = nearEP:GetAttribute("ExtractId") or "unknown"
	local extractName = nearEP:GetAttribute("ExtractName") or "EXTRACT"
	fireAll("ExtractStarted", player.UserId, extractId, extractName, HOLD_SECONDS)
end

function IdolService.RequestExtractCancel(player)
	if idolCarrier ~= player then return end
	if not isExtracting then return end
	cancelExtraction("player_canceled")
end

function IdolService.GetCarrier()
	return idolCarrier
end

function IdolService.PlayerHasIdol(player)
	return idolCarrier == player
end

return IdolService
