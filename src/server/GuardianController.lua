local GuardianController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local sprintStateByPlayer = {}

local function getHumanoid(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function ensureSprintState(player)
	local state = sprintStateByPlayer[player]
	if state then
		return state
	end

	state = {
		isSprinting = false,
		sprintEndsAt = 0,
		cooldownEndsAt = 0,
	}
	sprintStateByPlayer[player] = state
	return state
end

function GuardianController.ResetPlayer(player)
	sprintStateByPlayer[player] = nil
end

function GuardianController.SetSprinting(player, shouldSprint, rolesByPlayer)
	if rolesByPlayer[player] ~= "Guardian" then
		return
	end

	local humanoid = getHumanoid(player)
	if not humanoid then
		return
	end

	local now = os.clock()
	local state = ensureSprintState(player)

	if state.isSprinting and now >= state.sprintEndsAt then
		state.isSprinting = false
		state.cooldownEndsAt = now + Constants.GUARDIAN_SPRINT_COOLDOWN_SECONDS
	end

	if shouldSprint then
		if state.isSprinting then
			return
		end
		if now < state.cooldownEndsAt then
			return
		end
		state.isSprinting = true
		state.sprintEndsAt = now + Constants.GUARDIAN_SPRINT_DURATION_SECONDS
		humanoid.WalkSpeed = Constants.GUARDIAN_SPRINT_SPEED
	else
		if state.isSprinting then
			state.isSprinting = false
			state.cooldownEndsAt = now + Constants.GUARDIAN_SPRINT_COOLDOWN_SECONDS
		end
		humanoid.WalkSpeed = Constants.DEFAULT_WALK_SPEED
	end
end

function GuardianController.StepSprintTimers(rolesByPlayer)
	local now = os.clock()
	for player, state in sprintStateByPlayer do
		if rolesByPlayer[player] == "Guardian" and state.isSprinting and now >= state.sprintEndsAt then
			state.isSprinting = false
			state.cooldownEndsAt = now + Constants.GUARDIAN_SPRINT_COOLDOWN_SECONDS
			local humanoid = getHumanoid(player)
			if humanoid then
				humanoid.WalkSpeed = Constants.DEFAULT_WALK_SPEED
			end
		end
	end
end

function GuardianController.TryCatch(guardianPlayer, targetPlayer, rolesByPlayer, roundActive)
	if not roundActive then
		return false, "round_inactive"
	end
	if rolesByPlayer[guardianPlayer] ~= "Guardian" then
		return false, "not_guardian"
	end
	if rolesByPlayer[targetPlayer] ~= "Thief" then
		return false, "target_not_thief"
	end
	if not Players:FindFirstChild(guardianPlayer.Name) or not Players:FindFirstChild(targetPlayer.Name) then
		return false, "player_missing"
	end

	local guardianRoot = getRootPart(guardianPlayer)
	local thiefRoot = getRootPart(targetPlayer)
	if not guardianRoot or not thiefRoot then
		return false, "missing_root"
	end

	local distance = (guardianRoot.Position - thiefRoot.Position).Magnitude
	if distance > Constants.GUARDIAN_CATCH_DISTANCE then
		return false, "too_far"
	end

	if targetPlayer.Character then
		targetPlayer.Character:Destroy()
	end
	return true
end

return GuardianController
