-- ObjectiveService
-- Server-authoritative 3-seal objective system for LIFTED.
-- Clients cannot set progress or mark completion.
-- Requires PlayerStateService as sibling module.

local ObjectiveService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))

-- Config
local INTERACT_DISTANCE = 12
local SOLO_COMPLETION_TIME = 18
local PROGRESS_PER_SECOND = 1 / SOLO_COMPLETION_TIME

local MULTIPLIERS = { [1] = 1.0, [2] = 1.45, [3] = 1.8, [4] = 2.0 }

local OBJECTIVE_DEFS = {
	{ id = "FlameSeal", displayName = "FLAME SEAL" },
	{ id = "MoonLock", displayName = "MOON LOCK" },
	{ id = "StoneSigil", displayName = "STONE SIGIL" },
}

-- Runtime state
local objectives = {}
local vaultOpen = false
local currentRoundId = 0
local heartbeatConn = nil

-- Remote helpers

local function fireAll(remoteName, ...)
	local r = ReplicatedStorage:FindFirstChild(remoteName)
	if r and r:IsA("RemoteEvent") then
		r:FireAllClients(...)
	end
end

local function fireOne(player, remoteName, ...)
	local r = ReplicatedStorage:FindFirstChild(remoteName)
	if r and r:IsA("RemoteEvent") then
		r:FireClient(player, ...)
	end
end

-- Internal helpers

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
		lastProgressAt = 0,
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

-- Progress heartbeat

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

			-- Re-validate active players each tick
			local valid = {}
			for _, p in ipairs(obj.activePlayers) do
				if p and p.Parent and PlayerStateService.CanInteractObjective(p) then
					local root = getRootPart(p)
					if root and obj.part then
						if (root.Position - obj.part.Position).Magnitude <= INTERACT_DISTANCE then
							table.insert(valid, p)
						end
					elseif not obj.part then
						-- No part bound yet - allow without distance check (prototype)
						table.insert(valid, p)
					end
				end
			end
			obj.activePlayers = valid

			local count = #valid
			if count == 0 then
				continue
			end

			local gain = PROGRESS_PER_SECOND * getMultiplier(count) * dt
			obj.progress = math.clamp(obj.progress + gain, 0, 1)
			obj.lastProgressAt = os.clock()
			updatePartAttribs(obj)

			fireAll("ObjectiveProgress", obj.id, obj.progress)

			if obj.progress >= 1 then
				obj.progress = 1
				obj.completed = true
				obj.activePlayers = {}
				updatePartAttribs(obj)

				local completedCount = ObjectiveService.GetCompletedCount()
				fireAll("ObjectiveCompleted", obj.id, obj.displayName, completedCount)

				if completedCount >= 3 and not vaultOpen then
					vaultOpen = true
					fireAll("VaultOpened")
				end
			end
		end
	end)
end

-- Public API

function ObjectiveService.ResetForRound(roundId)
	currentRoundId = roundId or 0
	vaultOpen = false
	objectives = {}
	for _, def in ipairs(OBJECTIVE_DEFS) do
		objectives[def.id] = newObjectiveRecord(def)
	end
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
		part:SetAttribute("ObjectiveProgress", 0)
		part:SetAttribute("ObjectiveCompleted", false)
		CollectionService:AddTag(part, "ObjectiveStation")
	end)
end

function ObjectiveService.AutoRegisterObjectiveParts()
	-- Pass 1: tagged parts with ObjectiveId attribute
	for _, part in ipairs(CollectionService:GetTagged("ObjectiveStation")) do
		if not part:IsA("BasePart") or not part:IsDescendantOf(workspace) then
			continue
		end
		local id = part:GetAttribute("ObjectiveId")
		if id and objectives[id] and not objectives[id].part then
			ObjectiveService.RegisterObjectivePart(id, part)
		end
	end

	-- Pass 2: prototype fallback - map brazier parts to seal ids in order
	local unmapped = {}
	for _, def in ipairs(OBJECTIVE_DEFS) do
		if not objectives[def.id].part then
			table.insert(unmapped, def.id)
		end
	end

	if #unmapped > 0 then
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
				warn("[ObjectiveService] No part found for", id, "- distance check disabled")
			end
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
	if obj.part then
		local root = getRootPart(player)
		if not root then
			return false, "no_character"
		end
		if (root.Position - obj.part.Position).Magnitude > INTERACT_DISTANCE then
			return false, "too_far"
		end
	end
	return true, "ok"
end

function ObjectiveService.StartInteraction(player, objectiveId)
	local ok, reason = ObjectiveService.CanPlayerInteract(player, objectiveId)
	if not ok then
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
	fireAll("ObjectiveProgress", objectiveId, obj.progress)
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
			fireOne(player, "ObjectivePromptHidden", objectiveId)
			break
		end
	end
end

function ObjectiveService.StopAllInteractionsForPlayer(player)
	for _, obj in pairs(objectives) do
		for i, p in ipairs(obj.activePlayers) do
			if p == player then
				table.remove(obj.activePlayers, i)
				break
			end
		end
	end
end

function ObjectiveService.GetObjective(objectiveId)
	local obj = objectives[objectiveId]
	if not obj then
		return nil
	end
	return {
		id = obj.id,
		displayName = obj.displayName,
		progress = obj.progress,
		completed = obj.completed,
		activeCount = #obj.activePlayers,
	}
end

function ObjectiveService.GetObjectivesSnapshot()
	local snap = {}
	for id in pairs(objectives) do
		snap[id] = ObjectiveService.GetObjective(id)
	end
	return snap
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

-- Debug only - never expose to client
function ObjectiveService.ForceCompleteObjective(objectiveId)
	local obj = objectives[objectiveId]
	if not obj then
		return
	end
	obj.progress = 1
	obj.completed = true
	obj.activePlayers = {}
	updatePartAttribs(obj)
	local n = ObjectiveService.GetCompletedCount()
	fireAll("ObjectiveCompleted", obj.id, obj.displayName, n)
	if n >= 3 and not vaultOpen then
		vaultOpen = true
		fireAll("VaultOpened")
	end
end

return ObjectiveService
