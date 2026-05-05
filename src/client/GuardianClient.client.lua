local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))

local localPlayer = Players.LocalPlayer
local catchThiefRemote = ReplicatedStorage:WaitForChild("CatchThief")
local setMovementStateRemote = ReplicatedStorage:WaitForChild("SetMovementState")

local sprinting = false
local sprintCooldownUntil = 0
local sprintEndsAt = 0

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

local function canStartSprint(now)
	return now >= sprintCooldownUntil
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
		local now = os.clock()
		if not sprinting and canStartSprint(now) then
			sprinting = true
			sprintEndsAt = now + Constants.GUARDIAN_SPRINT_DURATION_SECONDS
			setMovementStateRemote:FireServer("Sprint", true)
			task.spawn(function()
				local activeUntil = sprintEndsAt
				while sprinting and os.clock() < activeUntil do
					task.wait(0.1)
				end
				if sprinting and sprintEndsAt == activeUntil then
					sprinting = false
					sprintCooldownUntil = os.clock() + Constants.GUARDIAN_SPRINT_COOLDOWN_SECONDS
					setMovementStateRemote:FireServer("Sprint", false)
				end
			end)
		end
	elseif input.KeyCode == Enum.KeyCode.E then
		tryCatchNearestThief()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift and sprinting then
		sprinting = false
		sprintCooldownUntil = os.clock() + Constants.GUARDIAN_SPRINT_COOLDOWN_SECONDS
		if isGuardian() then
			setMovementStateRemote:FireServer("Sprint", false)
		end
	end
end)

localPlayer:GetAttributeChangedSignal("Role"):Connect(function()
	if not isGuardian() and sprinting then
		sprinting = false
		setMovementStateRemote:FireServer("Sprint", false)
	end
end)
