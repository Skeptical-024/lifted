-- GuardianAbilityService
-- Server-authoritative guardian ability kit: Rush, Reveal, Roar.
-- Client only requests. Server validates, applies, and restores all effects.
-- Rush bypasses GuardianController.SetSprinting to avoid WalkSpeed conflicts.

local GuardianAbilityService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local ObjectiveService = require(script.Parent:WaitForChild("ObjectiveService"))
local CageService = require(script.Parent:WaitForChild("CageService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local RUSH_DURATION = Constants.GUARDIAN_RUSH_DURATION or 2
local RUSH_COOLDOWN = Constants.GUARDIAN_RUSH_COOLDOWN or 10
local RUSH_MULTIPLIER = Constants.GUARDIAN_RUSH_SPEED_MULTIPLIER or 1.45
local REVEAL_DURATION = Constants.GUARDIAN_REVEAL_DURATION or 4
local REVEAL_COOLDOWN = Constants.GUARDIAN_REVEAL_COOLDOWN or 30
local ROAR_RADIUS = Constants.GUARDIAN_ROAR_RADIUS or 22
local ROAR_SLOW_DUR = Constants.GUARDIAN_ROAR_SLOW_DURATION or 2.5
local ROAR_SLOW_MULT = Constants.GUARDIAN_ROAR_SLOW_MULTIPLIER or 0.55
local ROAR_COOLDOWN = Constants.GUARDIAN_ROAR_COOLDOWN or 18
local BASE_SPEED = Constants.DEFAULT_WALK_SPEED or 16

local abilityState = {}
local roundIsActive = false
local slowedThieves = {} -- [userId] = {player, originalWalkSpeed, token}

local function getOrCreateRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then return r end
	if r then r:Destroy() end
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = ReplicatedStorage
	return e
end

local function fireOne(player, name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then r:FireClient(player, ...) end
end

local function fireAll(name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then r:FireAllClients(...) end
end

local function getHumanoid(player)
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(player)
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getOrInitState(player)
	local uid = player.UserId
	if not abilityState[uid] then
		abilityState[uid] = {
			rushCooldownUntil = 0,
			revealCooldownUntil = 0,
			roarCooldownUntil = 0,
			isRushing = false,
		}
	end
	return abilityState[uid]
end

local function validateGuardian(player)
	if not roundIsActive then return false, "round_inactive" end
	if not player or not player.Parent then return false, "player_missing" end
	if not PlayerStateService.IsGuardian(player) then return false, "not_guardian" end
	if not getHumanoid(player) then return false, "no_humanoid" end
	return true, "ok"
end

local function restoreSpeed(player)
	if not player or not player.Parent then return end
	local h = getHumanoid(player)
	if h then h.WalkSpeed = BASE_SPEED end
end

local function restoreThiefSlow(player)
	if not player then return end
	local entry = slowedThieves[player.UserId]
	if not entry then return end
	slowedThieves[player.UserId] = nil
	local h = getHumanoid(player)
	if not h then return end
	local restoreValue = tonumber(entry.originalWalkSpeed)
	if restoreValue == nil then
		local crouchSpeed = Constants.THIEF_CROUCH_SPEED or 8
		local isCrouching = player:GetAttribute("IsCrouching") or false
		restoreValue = isCrouching and crouchSpeed or BASE_SPEED
	end
	h.WalkSpeed = restoreValue
end

function GuardianAbilityService.RequestRush(player)
	local ok, reason = validateGuardian(player)
	if not ok then
		fireOne(player, "GuardianRushFailed", reason)
		return
	end
	local state = getOrInitState(player)
	local now = os.clock()
	if now < state.rushCooldownUntil then
		fireOne(player, "GuardianRushFailed", "on_cooldown")
		fireOne(player, "GuardianAbilityCooldown", "Rush", state.rushCooldownUntil - now)
		return
	end
	if state.isRushing then
		fireOne(player, "GuardianRushFailed", "already_rushing")
		return
	end
	local hum = getHumanoid(player)
	if not hum then
		fireOne(player, "GuardianRushFailed", "no_humanoid")
		return
	end
	state.isRushing = true
	state.rushCooldownUntil = now + RUSH_COOLDOWN
	hum.WalkSpeed = BASE_SPEED * RUSH_MULTIPLIER
	fireOne(player, "GuardianRushStarted", RUSH_DURATION, RUSH_COOLDOWN)
	fireOne(player, "GuardianAbilityCooldown", "Rush", RUSH_COOLDOWN)
	local uid = player.UserId
	task.delay(RUSH_DURATION, function()
		if not abilityState[uid] then return end
		abilityState[uid].isRushing = false
		if player.Parent and PlayerStateService.IsGuardian(player) then
			local h = getHumanoid(player)
			if h then h.WalkSpeed = BASE_SPEED end
		end
	end)
end

function GuardianAbilityService.RequestReveal(player)
	local ok, reason = validateGuardian(player)
	if not ok then
		fireOne(player, "GuardianRevealFailed", reason)
		return
	end
	local state = getOrInitState(player)
	local now = os.clock()
	if now < state.revealCooldownUntil then
		fireOne(player, "GuardianRevealFailed", "on_cooldown")
		fireOne(player, "GuardianAbilityCooldown", "Reveal", state.revealCooldownUntil - now)
		return
	end
	state.revealCooldownUntil = now + REVEAL_COOLDOWN
	local revealed = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player
			and PlayerStateService.IsAlive(p)
			and PlayerStateService.GetRole(p) == PlayerStateService.Role.Thief then
			local root = getRootPart(p)
			if root then
				table.insert(revealed, {
					userId = p.UserId,
					name = p.Name,
					position = root.Position,
				})
			end
		end
	end
	fireOne(player, "GuardianRevealStarted", revealed, REVEAL_DURATION)
	fireOne(player, "GuardianAbilityCooldown", "Reveal", REVEAL_COOLDOWN)
end

function GuardianAbilityService.RequestRoar(player)
	local ok, reason = validateGuardian(player)
	if not ok then
		fireOne(player, "GuardianRoarFailed", reason)
		return
	end
	local state = getOrInitState(player)
	local now = os.clock()
	if now < state.roarCooldownUntil then
		fireOne(player, "GuardianRoarFailed", "on_cooldown")
		fireOne(player, "GuardianAbilityCooldown", "Roar", state.roarCooldownUntil - now)
		return
	end
	local guardianRoot = getRootPart(player)
	if not guardianRoot then
		fireOne(player, "GuardianRoarFailed", "no_character")
		return
	end
	state.roarCooldownUntil = now + ROAR_COOLDOWN
	local affected = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and PlayerStateService.IsAliveThief(p) then
			local root = getRootPart(p)
			if root and (root.Position - guardianRoot.Position).Magnitude <= ROAR_RADIUS then
				table.insert(affected, p)
			end
		end
	end
	for _, thief in ipairs(affected) do
		ObjectiveService.StopAllForPlayer(thief)
		CageService.StopRescue(thief)
		local h = getHumanoid(thief)
		if h then
			local uid = thief.UserId
			local existing = slowedThieves[uid]
			if not existing then
				slowedThieves[uid] = {
					player = thief,
					originalWalkSpeed = h.WalkSpeed,
					token = 1,
				}
			else
				existing.player = thief
				existing.token = (existing.token or 0) + 1
			end
			local token = slowedThieves[uid].token
			h.WalkSpeed = BASE_SPEED * ROAR_SLOW_MULT
			task.delay(ROAR_SLOW_DUR, function()
				local entry = slowedThieves[uid]
				if not entry then return end
				if entry.token ~= token then return end
				if not thief.Parent then return end
				restoreThiefSlow(thief)
			end)
		end
	end
	fireAll("GuardianRoarActivated", guardianRoot.Position, ROAR_RADIUS, #affected)
	fireOne(player, "GuardianAbilityCooldown", "Roar", ROAR_COOLDOWN)
end

function GuardianAbilityService.StopAllForPlayer(player)
	restoreThiefSlow(player)
	restoreSpeed(player)
	if player then abilityState[player.UserId] = nil end
end

function GuardianAbilityService.Init()
	local rushRemote = getOrCreateRemote("RequestGuardianRush")
	local revealRemote = getOrCreateRemote("RequestGuardianReveal")
	local roarRemote = getOrCreateRemote("RequestGuardianRoar")
	getOrCreateRemote("GuardianRushStarted")
	getOrCreateRemote("GuardianRushFailed")
	getOrCreateRemote("GuardianRevealStarted")
	getOrCreateRemote("GuardianRevealFailed")
	getOrCreateRemote("GuardianRoarActivated")
	getOrCreateRemote("GuardianRoarFailed")
	getOrCreateRemote("GuardianAbilityCooldown")
	rushRemote.OnServerEvent:Connect(function(p)
		GuardianAbilityService.RequestRush(p)
	end)
	revealRemote.OnServerEvent:Connect(function(p)
		GuardianAbilityService.RequestReveal(p)
	end)
	roarRemote.OnServerEvent:Connect(function(p)
		GuardianAbilityService.RequestRoar(p)
	end)
end

function GuardianAbilityService.ResetForRound(roundId)
	abilityState = {}
	roundIsActive = true
end

function GuardianAbilityService.StopRound()
	roundIsActive = false
	for _, entry in pairs(slowedThieves) do
		if entry and entry.player then
			restoreThiefSlow(entry.player)
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		restoreSpeed(p)
	end
	slowedThieves = {}
	abilityState = {}
end

function GuardianAbilityService.SetRoundActive(isActive)
	roundIsActive = isActive
end

return GuardianAbilityService
