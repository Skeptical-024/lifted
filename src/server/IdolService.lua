-- IdolService
-- Server-authoritative idol pickup, drop, and extraction for LIFTED.
-- Client can only request actions. Server validates everything.
-- Does not require GameManager; uses callback to avoid circular require.

local IdolService = {}

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObjectiveService = require(script.Parent:WaitForChild("ObjectiveService"))
local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local IDOL_DIST = Constants.IDOL_INTERACT_DISTANCE or 10
local EXTRACT_DIST = Constants.EXTRACT_INTERACT_DISTANCE or 14

local idolCarrier = nil
local idolPart = nil
local extractPoints = {}
local idolSpawnCFrame = nil
local roundIsActive = false
local currentRoundId = 0
local roundEndCallback = nil

local function getOrCreateRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then
		return r
	end
	if r then
		r:Destroy()
	end
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = ReplicatedStorage
	return e
end

local function fireAll(name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then
		r:FireAllClients(...)
	end
end

local function fireOne(player, name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then
		r:FireClient(player, ...)
	end
end

local function getRootPart(player)
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function placeIdolAt(position)
	if not idolPart then
		return
	end
	pcall(function()
		idolPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		idolPart.Anchored = true
		idolPart.Transparency = 0.2
		idolPart:SetAttribute("IdolState", "Dropped")
	end)
end

local function resetIdolToSpawn()
	if not idolPart or not idolSpawnCFrame then
		return
	end
	pcall(function()
		idolPart.CFrame = idolSpawnCFrame
		idolPart.Anchored = true
		idolPart.Transparency = 0.2
		idolPart:SetAttribute("IdolState", "Available")
	end)
end

function IdolService.SetRoundEndCallback(callback)
	roundEndCallback = callback
end

function IdolService.Init()
	local requestPickupRemote = getOrCreateRemote("RequestIdolPickup")
	local requestDropRemote = getOrCreateRemote("RequestIdolDrop")
	local requestExtractRemote = getOrCreateRemote("RequestExtractWithIdol")
	getOrCreateRemote("IdolAvailable")
	getOrCreateRemote("IdolPickedUp")
	getOrCreateRemote("IdolDropped")
	getOrCreateRemote("IdolCarrierChanged")
	getOrCreateRemote("IdolExtracted")
	getOrCreateRemote("IdolFailed")

	requestPickupRemote.OnServerEvent:Connect(function(player)
		IdolService.RequestPickup(player)
	end)

	requestDropRemote.OnServerEvent:Connect(function(player)
		IdolService.RequestDrop(player)
	end)

	requestExtractRemote.OnServerEvent:Connect(function(player)
		IdolService.RequestExtract(player)
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

	if not idolPart then
		warn("[IdolService] No Idol-tagged part found.")
	end
	if #extractPoints == 0 then
		warn("[IdolService] No ExtractPoint-tagged parts found.")
	end
end

function IdolService.ResetForRound(roundId)
	currentRoundId = roundId or 0
	roundIsActive = true

	if idolCarrier then
		pcall(function()
			idolCarrier:SetAttribute("HasIdol", false)
		end)
		idolCarrier = nil
	end

	for _, p in ipairs(Players:GetPlayers()) do
		pcall(function()
			p:SetAttribute("HasIdol", false)
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
end

function IdolService.SetRoundActive(isActive)
	roundIsActive = isActive
end

function IdolService.StopRound()
	roundIsActive = false
	if idolCarrier then
		pcall(function()
			idolCarrier:SetAttribute("HasIdol", false)
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
	if not roundIsActive then
		return
	end
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
	if not roundIsActive then
		return
	end
	if not ObjectiveService.IsVaultOpen() then
		fireOne(player, "IdolFailed", "vault_not_open")
		return
	end
	if not PlayerStateService.CanInteractObjective(player) then
		fireOne(player, "IdolFailed", "not_eligible")
		return
	end
	if idolCarrier then
		fireOne(player, "IdolFailed", "already_carried")
		return
	end
	if not idolPart then
		fireOne(player, "IdolFailed", "idol_unbound")
		return
	end
	local root = getRootPart(player)
	if not root then
		fireOne(player, "IdolFailed", "no_character")
		return
	end
	if (root.Position - idolPart.Position).Magnitude > IDOL_DIST then
		fireOne(player, "IdolFailed", "too_far")
		return
	end

	idolCarrier = player
	pcall(function()
		player:SetAttribute("HasIdol", true)
		idolPart:SetAttribute("IdolState", "Carried")
		idolPart.Transparency = 1
		idolPart.Anchored = false
		idolPart.CFrame = root.CFrame * CFrame.new(0, 2, 0)
		idolPart.Anchored = true
	end)

	fireAll("IdolPickedUp", player.UserId, player.Name)
	fireAll("IdolCarrierChanged", player.UserId, player.Name)
	print("[IdolService] Idol picked up by", player.Name)
end

function IdolService.RequestDrop(player)
	if idolCarrier ~= player then
		return
	end
	local root = getRootPart(player)
	local dropPos = root and root.Position or (idolSpawnCFrame and idolSpawnCFrame.Position)
	IdolService.DropFromPlayer(player, "voluntary", dropPos)
end

function IdolService.DropFromPlayer(player, reason, dropPosition)
	if idolCarrier ~= player then
		return
	end
	idolCarrier = nil
	pcall(function()
		player:SetAttribute("HasIdol", false)
	end)

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
	if not roundIsActive then
		return
	end
	if not ObjectiveService.IsVaultOpen() then
		fireOne(player, "IdolFailed", "vault_not_open")
		return
	end
	if idolCarrier ~= player then
		fireOne(player, "IdolFailed", "not_carrier")
		return
	end
	if not PlayerStateService.CanInteractObjective(player) then
		fireOne(player, "IdolFailed", "not_eligible")
		return
	end
	if #extractPoints == 0 then
		fireOne(player, "IdolFailed", "no_extract_points")
		return
	end
	local root = getRootPart(player)
	if not root then
		fireOne(player, "IdolFailed", "no_character")
		return
	end

	local nearEnough = false
	for _, ep in ipairs(extractPoints) do
		if ep and ep.Parent and (root.Position - ep.Position).Magnitude <= EXTRACT_DIST then
			nearEnough = true
			break
		end
	end
	if not nearEnough then
		fireOne(player, "IdolFailed", "too_far_from_extract")
		return
	end

	fireAll("IdolExtracted", player.UserId, player.Name)
	print("[IdolService] Idol extracted by", player.Name, "thieves win")

	if roundEndCallback then
		roundEndCallback(player)
	else
		warn("[IdolService] No round-end callback set cannot end round.")
	end
end

function IdolService.GetCarrier()
	return idolCarrier
end

function IdolService.PlayerHasIdol(player)
	return idolCarrier == player
end

return IdolService
