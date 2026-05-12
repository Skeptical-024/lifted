-- ObjectiveService
-- Server-authoritative 3-seal objective system for LIFTED.
-- Clients can only request start/stop interactions.

local ObjectiveService = {}

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local INTERACT_DISTANCE = Constants.OBJECTIVE_INTERACTION_DISTANCE or 12
local SOLO_COMPLETION_TIME = Constants.OBJECTIVE_SOLO_SECONDS or 18
local PROGRESS_PER_SECOND = 1 / SOLO_COMPLETION_TIME

local MULTIPLIERS = {
	[1] = 1.0,
	[2] = 1.45,
	[3] = 1.8,
	[4] = 2.0,
}

local OBJECTIVE_DEFS = {
	{ id = "FlameSeal", displayName = "FLAME SEAL" },
	{ id = "MoonLock", displayName = "MOON LOCK" },
	{ id = "StoneSigil", displayName = "STONE SIGIL" },
}

local objectives = {}
local vaultOpen = false
local currentRoundId = 0
local heartbeatConn = nil
local initialized = false
local remotes = {}

local function getOrCreateRemote(name)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	if remote then
		remote:Destroy()
	end
	local created = Instance.new("RemoteEvent")
	created.Name = name
	created.Parent = ReplicatedStorage
	return created
end

local function fireAll(remoteName, ...)
	local r = remotes[remoteName] or ReplicatedStorage:FindFirstChild(remoteName)
	if r and r:IsA("RemoteEvent") then
		r:FireAllClients(...)
	end
end

local function fireOne(player, remoteName, ...)
	local r = remotes[remoteName] or ReplicatedStorage:FindFirstChild(remoteName)
	if r and r:IsA("RemoteEvent") then
		r:FireClient(player, ...)
	end
end

local function getRootPart(player)
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getMultiplier(count)
	return MULTIPLIERS[math.clamp(count, 1, 4)] or 1.0
end

local function newObjectiveRecord(def)
	return {
		id = def.id,
		displayName = def.displayName,
		part = nil,
		progress = 0,
		completed = false,
		activePlayers = {},
		lastProgressEmitAt = 0,
	}
end

local function updatePartAttribs(obj)
	if not obj.part then
		return
	end
	pcall(function()
		obj.part:SetAttribute("ObjectiveProgress", obj.progress)
		obj.part:SetAttribute("ObjectiveCompleted", obj.completed)
	end)
end

local function setVaultPartsOpen(open)
	for _, part in ipairs(CollectionService:GetTagged("Vault")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			pcall(function()
				part:SetAttribute("VaultOpen", open)
				if open then
					part.CanCollide = false
					part.Transparency = 0.75
				else
					part.CanCollide = true
					part.Transparency = 0
				end
			end)
		end
	end

	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "Vault" then
			pcall(function()
				part:SetAttribute("VaultOpen", open)
				if open then
					part.CanCollide = false
					part.Transparency = 0.75
				else
					part.CanCollide = true
					part.Transparency = 0
				end
			end)
		end
	end
end

local function stopHeartbeat()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
end

local function startHeartbeat()
	stopHeartbeat()
	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		for _, obj in pairs(objectives) do
			if obj.completed then
				continue
			end

			if not obj.part then
				obj.activePlayers = {}
				continue
			end

			local valid = {}
			for _, p in ipairs(obj.activePlayers) do
				if p and p.Parent and PlayerStateService.CanInteractObjective(p) then
					local root = getRootPart(p)
					if root then
						if (root.Position - obj.part.Position).Magnitude <= INTERACT_DISTANCE then
							table.insert(valid, p)
						end
					end
				end
			end
			obj.activePlayers = valid

			local activeCount = #valid
			if activeCount == 0 then
				continue
			end

			local gain = PROGRESS_PER_SECOND * getMultiplier(activeCount) * dt
			obj.progress = math.clamp(obj.progress + gain, 0, 1)
			updatePartAttribs(obj)

			local now = os.clock()
			if obj.progress >= 1 or (now - obj.lastProgressEmitAt) >= 0.1 then
				fireAll("ObjectiveProgress", obj.id, obj.progress)
				obj.lastProgressEmitAt = now
			end

			if obj.progress >= 1 then
				obj.progress = 1
				obj.completed = true
				obj.activePlayers = {}
				updatePartAttribs(obj)

				local completedCount = ObjectiveService.GetCompletedCount()
				fireAll("ObjectiveCompleted", obj.id, obj.displayName, completedCount)

				if completedCount >= 3 and not vaultOpen then
					vaultOpen = true
					setVaultPartsOpen(true)
					fireAll("VaultOpened")
				end
			end
		end
	end)
end

function ObjectiveService.Init()
	if initialized then
		return
	end
	initialized = true

	remotes.RequestObjectiveStart = getOrCreateRemote("RequestObjectiveStart")
	remotes.RequestObjectiveStop = getOrCreateRemote("RequestObjectiveStop")
	remotes.ObjectiveInteractionStarted = getOrCreateRemote("ObjectiveInteractionStarted")
	remotes.ObjectiveProgress = getOrCreateRemote("ObjectiveProgress")
	remotes.ObjectiveCompleted = getOrCreateRemote("ObjectiveCompleted")
	remotes.ObjectiveFailed = getOrCreateRemote("ObjectiveFailed")
	remotes.VaultOpened = getOrCreateRemote("VaultOpened")

	ObjectiveService.ResetForRound(0)
	ObjectiveService.AutoRegisterObjectiveParts()

	remotes.RequestObjectiveStart.OnServerEvent:Connect(function(player, objectiveId)
		if type(objectiveId) ~= "string" then
			return
		end
		ObjectiveService.StartInteraction(player, objectiveId)
	end)

	remotes.RequestObjectiveStop.OnServerEvent:Connect(function(player, objectiveId)
		if type(objectiveId) ~= "string" then
			return
		end
		ObjectiveService.StopInteraction(player, objectiveId)
	end)
end

function ObjectiveService.ResetForRound(roundId)
	currentRoundId = roundId or currentRoundId or 0
	vaultOpen = false
	objectives = {}
	for _, def in ipairs(OBJECTIVE_DEFS) do
		objectives[def.id] = newObjectiveRecord(def)
	end
	setVaultPartsOpen(false)
	stopHeartbeat()
	startHeartbeat()
end

function ObjectiveService.StopRound()
	stopHeartbeat()
	for _, obj in pairs(objectives) do
		obj.activePlayers = {}
	end
end

function ObjectiveService.RegisterObjectivePart(objectiveId, part)
	local obj = objectives[objectiveId]
	if not obj then
		warn("[ObjectiveService] Unknown id:", objectiveId)
		return
	end
	obj.part = part
	pcall(function()
		part:SetAttribute("ObjectiveId", objectiveId)
		part:SetAttribute("ObjectiveName", obj.displayName)
		part:SetAttribute("ObjectiveProgress", obj.progress)
		part:SetAttribute("ObjectiveCompleted", obj.completed)
		CollectionService:AddTag(part, "ObjectiveStation")
	end)
end

function ObjectiveService.AutoRegisterObjectiveParts()
	for _, part in ipairs(CollectionService:GetTagged("ObjectiveStation")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			local id = part:GetAttribute("ObjectiveId")
			if id and objectives[id] and not objectives[id].part then
				ObjectiveService.RegisterObjectivePart(id, part)
			end
		end
	end

	local unmapped = {}
	for _, def in ipairs(OBJECTIVE_DEFS) do
		if not objectives[def.id].part then
			table.insert(unmapped, def.id)
		end
	end

	if #unmapped == 0 then
		return
	end

	local candidates = {}
	for _, p in ipairs(CollectionService:GetTagged("Brazier")) do
		if p:IsA("BasePart") and p:IsDescendantOf(workspace) then
			table.insert(candidates, p)
		end
	end

	if #candidates == 0 then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name:lower():find("brazier") then
				table.insert(candidates, obj)
				if #candidates >= 3 then
					break
				end
			end
		end
	end

	for i, id in ipairs(unmapped) do
		if candidates[i] then
			ObjectiveService.RegisterObjectivePart(id, candidates[i])
		else
			warn("[ObjectiveService] No part found for", id, "objective is non-interactable")
		end
	end
end

function ObjectiveService.CanPlayerInteract(player, objectiveId)
	if not player or not player.Parent then
		return false, "player_missing"
	end
	if not PlayerStateService.CanInteractObjective(player) then
		return false, "not_eligible"
	end

	local obj = objectives[objectiveId]
	if not obj then
		return false, "invalid_objective"
	end
	if obj.completed then
		return false, "already_completed"
	end
	if vaultOpen then
		return false, "vault_open"
	end

	if not obj.part then
		return false, "objective_unbound"
	end

	local root = getRootPart(player)
	if not root then
		return false, "no_character"
	end
	if (root.Position - obj.part.Position).Magnitude > INTERACT_DISTANCE then
		return false, "too_far"
	end

	return true, "ok"
end

function ObjectiveService.StartInteraction(player, objectiveId)
	local ok, reason = ObjectiveService.CanPlayerInteract(player, objectiveId)
	if not ok then
		fireOne(player, "ObjectiveFailed", objectiveId, reason)
		return false, reason
	end

	local obj = objectives[objectiveId]
	for _, p in ipairs(obj.activePlayers) do
		if p == player then
			return true, "already_active"
		end
	end

	table.insert(obj.activePlayers, player)
	fireOne(player, "ObjectiveInteractionStarted", objectiveId, obj.displayName)
	fireOne(player, "ObjectiveProgress", objectiveId, obj.progress)
	return true, "ok"
end

function ObjectiveService.StopInteraction(player, objectiveId)
	local obj = objectives[objectiveId]
	if not obj then
		return
	end
	for i, p in ipairs(obj.activePlayers) do
		if p == player then
			table.remove(obj.activePlayers, i)
			break
		end
	end
end

function ObjectiveService.StopAllForPlayer(player)
	for _, obj in pairs(objectives) do
		for i, p in ipairs(obj.activePlayers) do
			if p == player then
				table.remove(obj.activePlayers, i)
				break
			end
		end
	end
end

function ObjectiveService.GetCompletedCount()
	local n = 0
	for _, obj in pairs(objectives) do
		if obj.completed then
			n += 1
		end
	end
	return n
end

function ObjectiveService.IsVaultOpen()
	return vaultOpen
end

function ObjectiveService.GetObjectivesSnapshot()
	local snap = {}
	for id, obj in pairs(objectives) do
		snap[id] = {
			id = obj.id,
			displayName = obj.displayName,
			progress = obj.progress,
			completed = obj.completed,
			activeCount = #obj.activePlayers,
		}
	end
	return snap
end

return ObjectiveService
