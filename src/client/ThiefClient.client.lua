local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))

local localPlayer = Players.LocalPlayer
local setMovementStateRemote = ReplicatedStorage:WaitForChild("SetMovementState")
local roundStartedRemote = ReplicatedStorage:WaitForChild("RoundStarted")
local roundEndedRemote = ReplicatedStorage:WaitForChild("RoundEnded")
local requestObjectiveStartRemote = ReplicatedStorage:WaitForChild("RequestObjectiveStart")
local requestObjectiveStopRemote = ReplicatedStorage:WaitForChild("RequestObjectiveStop")
local requestIdolPickupRemote = ReplicatedStorage:WaitForChild("RequestIdolPickup")
local requestExtractRemote = ReplicatedStorage:WaitForChild("RequestExtractWithIdol")
local requestExtractCancelRemote = ReplicatedStorage:WaitForChild("RequestExtractCancel")
local requestCageRescueStartRemote = ReplicatedStorage:WaitForChild("RequestCageRescueStart")
local requestCageRescueStopRemote = ReplicatedStorage:WaitForChild("RequestCageRescueStop")
local requestSkillCheckHitRemote = ReplicatedStorage:WaitForChild("RequestSkillCheckHit")
local RequestObjectiveStart = requestObjectiveStartRemote
local RequestObjectiveStop = requestObjectiveStopRemote
local RequestIdolPickup = requestIdolPickupRemote
local RequestExtractWithIdol = requestExtractRemote
local RequestCageRescueStart = requestCageRescueStartRemote

local crouching = false
local rescuingActive = false
local activeRescueTargetUserId = nil
local activeObjectiveId = nil
local extractionHeld = false

-- Skill check state
local pendingCheckId = nil
local pendingCheckObjectiveId = nil

local footstepSounds = {}
local originalFootstepVolume = {}

local function isThief()
	return localPlayer:GetAttribute("Role") == Types.PlayerRole.Thief
end

local function getRootPart()
	local character = localPlayer.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function refreshFootstepSounds()
	table.clear(footstepSounds)
	table.clear(originalFootstepVolume)
	local character = localPlayer.Character
	if not character then
		return
	end
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Sound") and (descendant.Name == "FootstepSound" or descendant.Name == "Running") then
			table.insert(footstepSounds, descendant)
			originalFootstepVolume[descendant] = descendant.Volume
		end
	end
end

local function applyFootstepVolume()
	for _, sound in footstepSounds do
		if sound.Parent then
			local baseVolume = originalFootstepVolume[sound] or sound.Volume
			if crouching and isThief() then
				sound.Volume = baseVolume * Constants.THIEF_FOOTSTEP_VOLUME_SCALE_CROUCH
			else
				sound.Volume = baseVolume
			end
		end
	end
end

local function getNearestObjectiveStation()
	local rootPart = getRootPart()
	if not rootPart then
		return nil, nil
	end
	local maxDist = Constants.OBJECTIVE_INTERACT_DISTANCE or 12
	local nearest, nearestId, best = nil, nil, maxDist + 0.001
	for _, part in ipairs(CollectionService:GetTagged("ObjectiveStation")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			local objectiveId = part:GetAttribute("ObjectiveId")
			local completed = part:GetAttribute("ObjectiveCompleted")
			if type(objectiveId) == "string" and completed ~= true then
				local d = (part.Position - rootPart.Position).Magnitude
				if d <= maxDist and d < best then
					nearest, nearestId, best = part, objectiveId, d
				end
			end
		end
	end
	return nearest, nearestId
end

local function beginSealInteraction(objectiveId)
	if not isThief() then
		return
	end
	if type(objectiveId) ~= "string" then
		return
	end
	activeObjectiveId = objectiveId
	RequestObjectiveStart:FireServer(objectiveId)
end

local function stopSealInteraction()
	if activeObjectiveId then
		RequestObjectiveStop:FireServer(activeObjectiveId)
		activeObjectiveId = nil
	end
end

local function getNearestIdolPart()
	local root = getRootPart()
	if not root then
		return nil
	end
	local maxDist = Constants.IDOL_INTERACT_DISTANCE or 10
	for _, part in ipairs(CollectionService:GetTagged("Idol")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			local idolState = part:GetAttribute("IdolState")
			if idolState ~= "Locked" and idolState ~= "Carried" then
				if (part.Position - root.Position).Magnitude <= maxDist then
					return part
				end
			end
		end
	end
	return nil
end

local function getNearestExtractPoint()
	local root = getRootPart()
	if not root then
		return nil
	end
	local maxDist = Constants.EXTRACT_INTERACT_DISTANCE or 14
	for _, part in ipairs(CollectionService:GetTagged("ExtractPoint")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			if (part.Position - root.Position).Magnitude <= maxDist then
				return part
			end
		end
	end
	return nil
end

local function getNearestCagedTeammate()
	local char = localPlayer.Character
	if not char then return nil, nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil, nil end
	local maxDist = Constants.CAGE_RESCUE_DISTANCE or 12
	local nearestPlayer = nil
	local nearestUserId = nil
	local nearestDist = maxDist + 0.001
	-- Find nearest caged teammate
	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
		if p ~= localPlayer then
			local isCaged = p:GetAttribute("IsCaged") or
				p:GetAttribute("RoundState") == "Caged"
			if isCaged then
				local pChar = p.Character
				local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
				if pRoot then
					local dist = (pRoot.Position - root.Position).Magnitude
					if dist <= maxDist and dist < nearestDist then
						nearestDist = dist
						nearestPlayer = p
						nearestUserId = p.UserId
					end
				end
			end
		end
	end
	return nearestPlayer, nearestUserId
end

local function isNearRescuePoint()
	local _, targetId = getNearestCagedTeammate()
	return targetId ~= nil
end

local function stopRescue()
	if not rescuingActive then return end
	rescuingActive = false
	requestCageRescueStopRemote:FireServer(activeRescueTargetUserId)
	activeRescueTargetUserId = nil
end

local function clearInteractionState(sendServerStops)
	if sendServerStops then
		stopSealInteraction()
		stopRescue()
		if extractionHeld then
			extractionHeld = false
			requestExtractCancelRemote:FireServer()
		end
	else
		activeObjectiveId = nil
		rescuingActive = false
		activeRescueTargetUserId = nil
		extractionHeld = false
	end
end

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.2)
	refreshFootstepSounds()
	applyFootstepVolume()
end)

localPlayer:GetAttributeChangedSignal("Role"):Connect(function()
	if not isThief() then
		crouching = false
		setMovementStateRemote:FireServer("Crouch", false)
		clearInteractionState(true)
	end
	applyFootstepVolume()
end)

localPlayer:GetAttributeChangedSignal("RoundState"):Connect(function()
	local state = localPlayer:GetAttribute("RoundState")
	if state == "Caught" or state == "Caged" or state == "Eliminated" or state == "Escaped" then
		clearInteractionState(true)
	end
end)

roundStartedRemote.OnClientEvent:Connect(function()
	clearInteractionState(false)
end)

roundEndedRemote.OnClientEvent:Connect(function()
	clearInteractionState(true)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if not isThief() then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		if not crouching then
			crouching = true
			setMovementStateRemote:FireServer("Crouch", true)
			applyFootstepVolume()
		end
	elseif input.KeyCode == Enum.KeyCode.E then
		if not isThief() then return end
		local hasIdol = localPlayer:GetAttribute("HasIdol") == true
		if hasIdol and getNearestExtractPoint() then
			extractionHeld = true
			RequestExtractWithIdol:FireServer()
		elseif not hasIdol and isNearRescuePoint() then
			local _, targetId = getNearestCagedTeammate()
			if targetId then
				rescuingActive = true
				activeRescueTargetUserId = targetId
				RequestCageRescueStart:FireServer(targetId)
			end
		else
			local _, nearObjectiveId = getNearestObjectiveStation()
			if nearObjectiveId then
				task.spawn(beginSealInteraction, nearObjectiveId)
			elseif not hasIdol and getNearestIdolPart() then
				RequestIdolPickup:FireServer()
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Space then
		-- Skill check hit
		if pendingCheckId and pendingCheckObjectiveId then
			requestSkillCheckHitRemote:FireServer(pendingCheckObjectiveId, pendingCheckId)
			pendingCheckId = nil
			pendingCheckObjectiveId = nil
		end
	end
end)

-- Gamepad interact: ButtonX mirrors E for thieves
ContextActionService:BindAction(
	"LIFTED_ThiefInteractGamepad",
	function(actionName, inputState, inputObject)
		if inputState ~= Enum.UserInputState.Begin then return end
		if not isThief() then return end
		-- Mirror E key logic
		local hasIdol = localPlayer:GetAttribute("HasIdol") == true
		if hasIdol and getNearestExtractPoint() then
			extractionHeld = true
			RequestExtractWithIdol:FireServer()
		elseif not hasIdol and isNearRescuePoint() then
			local _, targetId = getNearestCagedTeammate()
			if targetId then
				rescuingActive = true
				activeRescueTargetUserId = targetId
				RequestCageRescueStart:FireServer(targetId)
			end
		else
			local _, nearObjectiveId = getNearestObjectiveStation()
			if nearObjectiveId then
				task.spawn(beginSealInteraction, nearObjectiveId)
			elseif not hasIdol and getNearestIdolPart() then
				RequestIdolPickup:FireServer()
			end
		end
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.KeyCode.ButtonX
)

-- Gamepad skill check: ButtonA
ContextActionService:BindAction(
	"LIFTED_ThiefSkillCheckGamepad",
	function(actionName, inputState, inputObject)
		if inputState ~= Enum.UserInputState.Begin then return end
		if not isThief() then return end
		if pendingCheckId and pendingCheckObjectiveId then
			requestSkillCheckHitRemote:FireServer(pendingCheckObjectiveId, pendingCheckId)
			pendingCheckId = nil
			pendingCheckObjectiveId = nil
		end
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.KeyCode.ButtonA
)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		clearInteractionState(true)
	end
	if input.KeyCode == Enum.KeyCode.LeftShift and crouching then
		crouching = false
		if isThief() then
			setMovementStateRemote:FireServer("Crouch", false)
		end
		applyFootstepVolume()
	end
end)

if localPlayer.Character then
	refreshFootstepSounds()
	applyFootstepVolume()
end

-- Track pending skill checks sent from server
local skillCheckStartedRemote = ReplicatedStorage:FindFirstChild("SkillCheckStarted")
if skillCheckStartedRemote and skillCheckStartedRemote:IsA("RemoteEvent") then
	skillCheckStartedRemote.OnClientEvent:Connect(function(objectiveId, checkId, windowSeconds)
		if not isThief() then return end
		pendingCheckObjectiveId = objectiveId
		pendingCheckId = checkId
		-- Auto-clear if player doesn't press Space in time
		local capturedId = checkId
		task.delay((tonumber(windowSeconds) or 0.75) + 0.2, function()
			if pendingCheckId == capturedId then
				pendingCheckId = nil
				pendingCheckObjectiveId = nil
			end
		end)
	end)
end

local skillCheckExpiredRemote = ReplicatedStorage:FindFirstChild("SkillCheckExpired")
if skillCheckExpiredRemote and skillCheckExpiredRemote:IsA("RemoteEvent") then
	skillCheckExpiredRemote.OnClientEvent:Connect(function(objectiveId, checkId)
		if pendingCheckId == checkId then
			pendingCheckId = nil
			pendingCheckObjectiveId = nil
		end
	end)
end
