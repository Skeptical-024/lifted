-- SkillCheckService
-- Server-authoritative seal skill checks. Fires timed prompts to active thief players.
-- Success adds small progress bonus. No penalty for missing — pure upside mechanic.
-- ObjectiveService polls GetActivePlayersSnapshot; SkillCheckService polls that same API.

local SkillCheckService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local RemoteGuardService = require(script.Parent:WaitForChild("RemoteGuardService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local ENABLED = Constants.SKILL_CHECK_ENABLED ~= false
local MIN_INTERVAL = Constants.SKILL_CHECK_MIN_INTERVAL or 4
local MAX_INTERVAL = Constants.SKILL_CHECK_MAX_INTERVAL or 8
local WINDOW = Constants.SKILL_CHECK_WINDOW_SECONDS or 0.75
local SUCCESS_BONUS = Constants.SKILL_CHECK_SUCCESS_BONUS or 0.035

-- Injected references
local objectiveServiceRef = nil
local scoreCallbacks = nil

-- [checkId] = { player, objectiveId, expiresAt, used }
local activeChecks = {}
local nextCheckId = 0

-- [userId][objectiveId] = next fire time
local nextCheckAt = {}

local roundIsActive = false
local heartbeatConn = nil
local scanAccumulator = 0

local warned = {}
local function warnOnce(key, ...)
	if warned[key] then return end
	warned[key] = true
	warn(...)
end

local function fireOne(player, name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then r:FireClient(player, ...) end
end

local function newCheckId()
	nextCheckId += 1
	return nextCheckId
end

local function playerHasActiveCheck(player)
	for _, check in pairs(activeChecks) do
		if check.player == player and not check.used then
			return true
		end
	end
	return false
end

local function isPlayerWorkingObjective(player, objectiveId, activePlayers)
	local players = activePlayers and activePlayers[objectiveId]
	if type(players) ~= "table" then
		return false
	end
	for _, activePlayer in ipairs(players) do
		if activePlayer == player then
			return true
		end
	end
	return false
end

local function startCheckForPlayer(player, objectiveId)
	if not ENABLED or not roundIsActive then return end
	if not PlayerStateService.IsAliveThief(player) then return end
	if playerHasActiveCheck(player) then return end

	local checkId = newCheckId()
	local expiresAt = os.clock() + WINDOW

	activeChecks[checkId] = {
		player = player,
		objectiveId = objectiveId,
		expiresAt = expiresAt,
		used = false,
	}

	fireOne(player, "SkillCheckStarted", objectiveId, checkId, WINDOW)

	task.delay(WINDOW + 0.15, function()
		local check = activeChecks[checkId]
		if check and not check.used then
			activeChecks[checkId] = nil
			if player.Parent then
				fireOne(player, "SkillCheckExpired", objectiveId, checkId)
			end
		end
	end)
end

local function stopHeartbeat()
	if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
end

local function startHeartbeat()
	stopHeartbeat()
	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		if not roundIsActive or not objectiveServiceRef then return end

		scanAccumulator += dt
		if scanAccumulator < 0.5 then return end
		scanAccumulator = 0

		local now = os.clock()
		local ok, activePlayers = pcall(function()
			return objectiveServiceRef.GetActivePlayersSnapshot()
		end)
		if not ok or type(activePlayers) ~= "table" then return end

		for checkId, check in pairs(activeChecks) do
			if not PlayerStateService.IsAliveThief(check.player)
				or not isPlayerWorkingObjective(check.player, check.objectiveId, activePlayers) then
				check.used = true
				activeChecks[checkId] = nil
				if check.player and check.player.Parent then
					fireOne(check.player, "SkillCheckExpired", check.objectiveId, checkId)
				end
			end
		end

		for objectiveId, players in pairs(activePlayers) do
			for _, player in ipairs(players) do
				if player and player.Parent and PlayerStateService.IsAliveThief(player) then
					local uid = player.UserId
					nextCheckAt[uid] = nextCheckAt[uid] or {}
					local nextTime = nextCheckAt[uid][objectiveId]
					if not nextTime then
						nextCheckAt[uid][objectiveId] = now + MIN_INTERVAL
							+ math.random() * (MAX_INTERVAL - MIN_INTERVAL)
					elseif now >= nextTime then
						nextCheckAt[uid][objectiveId] = now + MIN_INTERVAL
							+ math.random() * (MAX_INTERVAL - MIN_INTERVAL)
						startCheckForPlayer(player, objectiveId)
					end
				end
			end
		end
	end)
end

function SkillCheckService.HandleHit(player, objectiveId, checkId)
	if not ENABLED or not roundIsActive then return end

	if not RemoteGuardService.Allow(player, "RequestSkillCheckHit", 0.3) then return end
	if not PlayerStateService.IsAliveThief(player) then
		fireOne(player, "SkillCheckResult", objectiveId, checkId, false, "not_eligible")
		return
	end

	local check = activeChecks[checkId]
	if not check then
		fireOne(player, "SkillCheckResult", objectiveId, checkId, false, "expired")
		return
	end
	if check.player ~= player or check.objectiveId ~= objectiveId then return end
	if check.used then return end
	local activePlayers = objectiveServiceRef and objectiveServiceRef.GetActivePlayersSnapshot()
	if not isPlayerWorkingObjective(player, objectiveId, activePlayers) then
		check.used = true
		activeChecks[checkId] = nil
		fireOne(player, "SkillCheckResult", objectiveId, checkId, false, "interrupted")
		return
	end

	local now = os.clock()
	if now > check.expiresAt then
		check.used = true
		activeChecks[checkId] = nil
		fireOne(player, "SkillCheckResult", objectiveId, checkId, false, "too_late")
		return
	end

	check.used = true
	activeChecks[checkId] = nil

	if objectiveServiceRef then
		objectiveServiceRef.AddProgressBonus(objectiveId, SUCCESS_BONUS, player)
	end
	if scoreCallbacks and scoreCallbacks.onSkillCheckHit then
		scoreCallbacks.onSkillCheckHit(player, objectiveId)
	end

	fireOne(player, "SkillCheckResult", objectiveId, checkId, true, "success")
end

function SkillCheckService.CancelAllForPlayer(player)
	if not player then return end
	nextCheckAt[player.UserId] = nil
	for checkId, check in pairs(activeChecks) do
		if check.player == player then
			check.used = true
			activeChecks[checkId] = nil
			if player.Parent then
				fireOne(player, "SkillCheckExpired", check.objectiveId, checkId)
			end
		end
	end
end

function SkillCheckService.SetObjectiveService(svc)
	objectiveServiceRef = svc
end

function SkillCheckService.SetScoreCallbacks(callbacks)
	scoreCallbacks = callbacks
end

function SkillCheckService.Init()
	local hitRemote = Remotes.Server(Remotes.Names.RequestSkillCheckHit)
	Remotes.Server(Remotes.Names.SkillCheckStarted)
	Remotes.Server(Remotes.Names.SkillCheckResult)
	Remotes.Server(Remotes.Names.SkillCheckExpired)

	hitRemote.OnServerEvent:Connect(function(player, objectiveId, checkId)
		if type(objectiveId) ~= "string" or type(checkId) ~= "number" then return end
		SkillCheckService.HandleHit(player, objectiveId, checkId)
	end)

	print("[SkillCheckService] Initialized. SKILL_CHECK_ENABLED=" .. tostring(ENABLED))
end

function SkillCheckService.ResetForRound()
	warned = {}
	roundIsActive = true
	activeChecks = {}
	nextCheckAt = {}
	scanAccumulator = 0
	startHeartbeat()
end

function SkillCheckService.StopRound()
	roundIsActive = false
	activeChecks = {}
	nextCheckAt = {}
	stopHeartbeat()
end

return SkillCheckService
