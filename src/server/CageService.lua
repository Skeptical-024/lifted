-- CageService
-- Server-authoritative cage and rescue system.
-- Physical freeze/teleport to cage is handled by GameManager.freezeThiefCharacter.
-- CageService owns state transitions and rescue progression.

local CageService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local RemoteGuardService = require(script.Parent:WaitForChild("RemoteGuardService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local RESCUE_DIST = Constants.CAGE_RESCUE_DISTANCE or 12
local RESCUE_TIME = Constants.CAGE_RESCUE_SECONDS or 8
local BASE_RATE = 1 / RESCUE_TIME

local MULTIPLIERS = { [1] = 1.0, [2] = 1.5, [3] = 2.0, [4] = 2.25 }

local cagedPlayers = {}
local rescueRecords = {}
local rescuerTargets = {}
local rescuePoint = nil
local cageSpawn = nil
local heartbeatConn = nil
local roundIsActive = false
local rescueCompletedCallback = nil
local scoreCallbacks = nil
local warned = {}

local function warnOnce(key, ...)
	if warned[key] then return end
	warned[key] = true
	warn(...)
end

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

local function getMultiplier(n)
	return MULTIPLIERS[math.clamp(n, 1, 4)] or 1.0
end

local function unfreeze(player)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum.WalkSpeed = Constants.DEFAULT_WALK_SPEED or 16
	if hum.UseJumpPower then
		hum.JumpPower = 50
	else
		hum.JumpHeight = 7.2
	end
	pcall(function() player:SetAttribute("IsCaught", false) end)
end

local function teleportNearCage(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local targetPos
	if rescuePoint then
		targetPos = rescuePoint.Position + Vector3.new(0, 4, 0)
	elseif cageSpawn then
		targetPos = cageSpawn.Position + Vector3.new(8, 4, 0)
	end
	if targetPos then
		pcall(function() root.CFrame = CFrame.new(targetPos) end)
	end
end

local function stopHeartbeat()
	if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
end

local function startHeartbeat()
	stopHeartbeat()
	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		if not roundIsActive then return end

		for cageUserId, rec in pairs(rescueRecords) do
			local caged = cagedPlayers[cageUserId]
			if not caged or not caged.Parent then
				rescueRecords[cageUserId] = nil
				continue
			end

			local valid = {}
			for _, rescuer in ipairs(rec.activeRescuers) do
				if rescuer and rescuer.Parent and PlayerStateService.IsAliveThief(rescuer) then
					local root = getRootPart(rescuer)
					if root and rescuePoint then
						if (root.Position - rescuePoint.Position).Magnitude <= RESCUE_DIST then
							table.insert(valid, rescuer)
						end
					elseif root and cageSpawn then
						if (root.Position - cageSpawn.Position).Magnitude <= RESCUE_DIST then
							table.insert(valid, rescuer)
						end
					end
				else
					if rescuer then
						rescuerTargets[rescuer.UserId] = nil
					end
				end
			end
			local prevCount = #rec.activeRescuers  -- capture before reassigning
			rec.activeRescuers = valid
			local count = #valid
			for _, rescuer in ipairs(valid) do
				rescuerTargets[rescuer.UserId] = cageUserId
			end

			-- If we had rescuers but now have none, the rescue was canceled
			if prevCount > 0 and count == 0 then
				if rec.progress > 0 then
					rec.progress = 0
					fireAll("CageRescueCanceled", cageUserId, "rescuer_left")
				end
				continue
			end

			if count == 0 then continue end

			rec.progress = math.clamp(rec.progress + BASE_RATE * getMultiplier(count) * dt, 0, 1)
			if scoreCallbacks and scoreCallbacks.onRescueProgress then
				local gain = BASE_RATE * getMultiplier(count) * dt
				local share = gain / count
				for _, rescuer in ipairs(valid) do
					scoreCallbacks.onRescueProgress(rescuer, share)
				end
			end
			local now = os.clock()
			if now - (rec.lastProgressEmit or 0) >= 0.12 then
				rec.lastProgressEmit = now
				fireAll("CageRescueProgress", cageUserId, rec.progress, count)
			end

			if rec.progress >= 1 then
				local rescuedPlayer = caged
				CageService.ReleasePlayer(rescuedPlayer, "rescued")
				if scoreCallbacks and scoreCallbacks.onRescueCompleted and #valid > 0 then
					for _, rescuer in ipairs(valid) do
						scoreCallbacks.onRescueCompleted(rescuer, rescuedPlayer)
					end
				end
				-- Fire CageRescueCompleted to all (UI uses this)
				fireAll("CageRescueCompleted", rescuedPlayer.UserId, rescuedPlayer.Name)
				print("[CageService] Rescued:", rescuedPlayer.Name)
			end
		end
	end)
end

function CageService.Init()
	getOrCreateRemote("RequestCageRescueStart")
	getOrCreateRemote("RequestCageRescueStop")
	getOrCreateRemote("PlayerCaged")
	getOrCreateRemote("CageStateChanged")
	getOrCreateRemote("CageRescueStarted")
	getOrCreateRemote("CageRescueProgress")
	getOrCreateRemote("CageRescueCompleted")
	getOrCreateRemote("CageRescueCanceled")
	getOrCreateRemote("CageRescueFailed")

	local startRemote = ReplicatedStorage:WaitForChild("RequestCageRescueStart")
	local stopRemote = ReplicatedStorage:WaitForChild("RequestCageRescueStop")

	startRemote.OnServerEvent:Connect(function(player, targetUserId)
		if not RemoteGuardService.Allow(player, "RequestCageRescueStart", 0.1) then
			return
		end
		CageService.StartRescue(player, targetUserId)
	end)

	stopRemote.OnServerEvent:Connect(function(player, targetUserId)
		if not RemoteGuardService.Allow(player, "RequestCageRescueStop", 0.1) then
			return
		end
		CageService.StopRescue(player, targetUserId)
	end)

	print("[CageService] Initialized.")
end

function CageService.AutoRegisterParts()
	rescuePoint = nil
	cageSpawn = nil

	for _, part in ipairs(CollectionService:GetTagged("CageRescuePoint")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			rescuePoint = part
			break
		end
	end

	for _, part in ipairs(CollectionService:GetTagged("CageSpawn")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			cageSpawn = part
			break
		end
	end

	if not rescuePoint and cageSpawn then
		rescuePoint = cageSpawn
		warnOnce("missing_rescue_point", "[CageService] No CageRescuePoint found, using CageSpawn as fallback.")
	end
	if not cageSpawn then
		warnOnce("missing_cage_spawn", "[CageService] No CageSpawn found - CagePlayer will fail.")
	end
end

function CageService.ResetForRound(roundId)
	roundIsActive = true
	cagedPlayers = {}
	rescueRecords = {}
	rescuerTargets = {}
	CageService.AutoRegisterParts()
	stopHeartbeat()
	startHeartbeat()
end

function CageService.StopRound()
	roundIsActive = false
	stopHeartbeat()
	local snapshot = {}
	for uid, p in pairs(cagedPlayers) do snapshot[uid] = p end
	cagedPlayers = {}
	rescueRecords = {}
	rescuerTargets = {}
	for _, p in pairs(snapshot) do
		if p and p.Parent then
			pcall(function()
				local char = p.Character
				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.WalkSpeed = Constants.DEFAULT_WALK_SPEED or 16
						if hum.UseJumpPower then hum.JumpPower = 50
						else hum.JumpHeight = 7.2 end
					end
				end
				p:SetAttribute("IsCaught", false)
				p:SetAttribute("IsCaged", false)
			end)
		end
	end
end

function CageService.CagePlayer(player)
	if not player or not player.Parent then return end
	if not roundIsActive then return end

	local ok = PlayerStateService.MarkCaged(player)
	if not ok then
		warnOnce("cage_invalid_state_" .. tostring(player.UserId), "[CageService] CagePlayer failed for", player.Name, "- not in Caught state")
		return
	end

	cagedPlayers[player.UserId] = player
	rescueRecords[player.UserId] = {
		player = player,
		progress = 0,
		activeRescuers = {},
		lastProgressEmit = 0,
	}

	fireAll("PlayerCaged", player.UserId, player.Name)
	if scoreCallbacks and scoreCallbacks.onCaged then
		scoreCallbacks.onCaged(player)
	end
	pcall(function() player:SetAttribute("IsCaged", true) end)
	fireAll("CageStateChanged", player.UserId, player.Name, "Caged", "caught")
	print("[CageService] Caged:", player.Name)
end

function CageService.StartRescue(rescuer, targetUserId)
	if not rescuer or not rescuer.Parent then return end
	if not roundIsActive then return end

	if not PlayerStateService.IsAliveThief(rescuer) then
		warnOnce("invalid_rescuer_" .. tostring(rescuer.UserId), "[CageService] Invalid rescuer:", rescuer.Name)
		fireOne(rescuer, "CageRescueFailed", "not_eligible")
		return
	end

	if targetUserId == nil then
		fireOne(rescuer, "CageRescueFailed", "missing_target")
		return
	end
	if targetUserId == rescuer.UserId then
		fireOne(rescuer, "CageRescueFailed", "cannot_rescue_self")
		return
	end
	local targetRec = rescueRecords[targetUserId]
	if cagedPlayers[targetUserId] == nil or targetRec == nil then
		warnOnce("target_not_caged_" .. tostring(targetUserId), "[CageService] Rescue target missing/not caged:", tostring(targetUserId))
		fireOne(rescuer, "CageRescueFailed", "target_not_caged")
		return
	end

	local root = getRootPart(rescuer)
	if not root then
		fireOne(rescuer, "CageRescueFailed", "no_character")
		return
	end
	local refPart = rescuePoint or cageSpawn
	if not refPart then
		fireOne(rescuer, "CageRescueFailed", "no_rescue_point")
		return
	end
	if (root.Position - refPart.Position).Magnitude > RESCUE_DIST then
		warnOnce("rescuer_far_" .. tostring(rescuer.UserId), "[CageService] Rescuer too far:", rescuer.Name)
		fireOne(rescuer, "CageRescueFailed", "too_far")
		return
	end

	local existingTarget = rescuerTargets[rescuer.UserId]
	if existingTarget ~= nil and existingTarget ~= targetUserId then
		fireOne(rescuer, "CageRescueFailed", "already_rescuing_other_target")
		return
	end
	for _, r in ipairs(targetRec.activeRescuers) do
		if r == rescuer then
			return
		end
	end
	table.insert(targetRec.activeRescuers, rescuer)
	rescuerTargets[rescuer.UserId] = targetUserId

	local caged = cagedPlayers[targetUserId]
	local targetName = caged and caged.Name or "teammate"
	fireOne(rescuer, "CageRescueStarted", rescuer.UserId, targetUserId, targetName, RESCUE_TIME)
end

function CageService.StopRescue(rescuer, targetUserId)
	if not rescuer then return end
	rescuerTargets[rescuer.UserId] = nil
	if targetUserId and rescueRecords[targetUserId] then
		local rec = rescueRecords[targetUserId]
		local removed = false
		for i, r in ipairs(rec.activeRescuers) do
			if r == rescuer then
				table.remove(rec.activeRescuers, i)
				removed = true
				break
			end
		end
		if removed and #rec.activeRescuers == 0 and rec.progress > 0 then
			rec.progress = 0
			fireAll("CageRescueCanceled", targetUserId, "rescuer_left")
		end
		return
	end
	for uid, rec in pairs(rescueRecords) do
		local removed = false
		for i, r in ipairs(rec.activeRescuers) do
			if r == rescuer then
				table.remove(rec.activeRescuers, i)
				removed = true
				break
			end
		end
		if removed and #rec.activeRescuers == 0 and rec.progress > 0 then
			rec.progress = 0
			fireAll("CageRescueCanceled", uid, "rescuer_left")
		end
	end
end

function CageService.StopAllForPlayer(player)
	if player and cagedPlayers[player.UserId] then
		fireAll("CageRescueCanceled", player.UserId, "target_left")
		cagedPlayers[player.UserId] = nil
		rescueRecords[player.UserId] = nil
	end
	if player then
		rescuerTargets[player.UserId] = nil
	end
	CageService.StopRescue(player)
end

function CageService.ReleasePlayer(player, reason)
	if not player or not player.Parent then return end
	cagedPlayers[player.UserId] = nil
	rescueRecords[player.UserId] = nil
	for rescuerUserId, targetUserId in pairs(rescuerTargets) do
		if targetUserId == player.UserId then
			rescuerTargets[rescuerUserId] = nil
		end
	end
	local ok = PlayerStateService.MarkRescued(player)
	if not ok then
		local currentState = PlayerStateService.GetState(player)
		warn("[CageService] ReleasePlayer MarkRescued failed for", player.Name, "state:", tostring(currentState))
	end
	-- Unfreeze
	if player.Parent then
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = Constants.DEFAULT_WALK_SPEED or 16
				if hum.UseJumpPower then
					hum.JumpPower = 50
				else
					hum.JumpHeight = 7.2
				end
			end
		end
		-- Teleport near cage exit
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local exitPos
			if rescuePoint then
				exitPos = rescuePoint.Position + Vector3.new(0, 4, 0)
			elseif cageSpawn then
				exitPos = cageSpawn.Position + Vector3.new(8, 4, 0)
			end
			if exitPos then
				pcall(function() root.CFrame = CFrame.new(exitPos) end)
			end
		end
	end
	pcall(function()
		player:SetAttribute("IsCaged", false)
		player:SetAttribute("IsCaught", false)
	end)
	fireAll("CageStateChanged", player.UserId, player.Name, "Alive", reason or "rescued")
	if rescueCompletedCallback then
		rescueCompletedCallback(player, reason or "rescued")
	end
	print("[CageService] Released:", player.Name, "reason:", reason or "rescued")
end

function CageService.SetRescueCompletedCallback(callback)
	rescueCompletedCallback = callback
end

function CageService.SetScoreCallbacks(callbacks)
	scoreCallbacks = callbacks
end

function CageService.IsCaged(player)
	return cagedPlayers[player and player.UserId] ~= nil
end

function CageService.GetCagedPlayersSnapshot()
	local snap = {}
	for uid, p in pairs(cagedPlayers) do
		snap[uid] = { userId = uid, name = p.Name }
	end
	return snap
end

function CageService.CancelRescueForTarget(targetUserId, reason)
	if not targetUserId or not rescueRecords[targetUserId] then
		return
	end
	local rec = rescueRecords[targetUserId]
	for _, rescuer in ipairs(rec.activeRescuers) do
		if rescuer then
			rescuerTargets[rescuer.UserId] = nil
		end
	end
	rec.activeRescuers = {}
	rec.progress = 0
	fireAll("CageRescueCanceled", targetUserId, reason or "canceled")
end

function CageService.GetSnapshot()
	local rescues = {}
	for targetUserId, rec in pairs(rescueRecords) do
		rescues[targetUserId] = {
			targetUserId = targetUserId,
			progress = rec.progress,
			rescuerCount = #rec.activeRescuers,
		}
	end
	return {
		cagedPlayers = CageService.GetCagedPlayersSnapshot(),
		rescues = rescues,
	}
end

return CageService
