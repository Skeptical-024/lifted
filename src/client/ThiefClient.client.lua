local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local localPlayer = Players.LocalPlayer
local setMovementStateRemote = Remotes.Client(Remotes.Names.SetMovementState)
local roundStartedRemote = Remotes.Client(Remotes.Names.RoundStarted)
local roundEndedRemote = Remotes.Client(Remotes.Names.RoundEnded)
local requestObjectiveStartRemote = Remotes.Client(Remotes.Names.RequestObjectiveStart)
local requestObjectiveStopRemote = Remotes.Client(Remotes.Names.RequestObjectiveStop)
local requestIdolPickupRemote = Remotes.Client(Remotes.Names.RequestIdolPickup)
local requestExtractRemote = Remotes.Client(Remotes.Names.RequestExtractWithIdol)
local requestExtractCancelRemote = Remotes.Client(Remotes.Names.RequestExtractCancel)
local requestCageRescueStartRemote = Remotes.Client(Remotes.Names.RequestCageRescueStart)
local requestCageRescueStopRemote = Remotes.Client(Remotes.Names.RequestCageRescueStop)
local requestSkillCheckHitRemote = Remotes.Client(Remotes.Names.RequestSkillCheckHit)
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
local updateTouchButtons = function() end

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
			task.defer(updateTouchButtons)
		end
	end
end)

-- Gamepad interact: ButtonX mirrors E for thieves
ContextActionService:BindAction(
	"LIFTED_ThiefInteractGamepad",
	function(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			clearInteractionState(true)
			return Enum.ContextActionResult.Sink
		end
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
	true,
	Enum.KeyCode.ButtonX
)
ContextActionService:SetTitle("LIFTED_ThiefInteractGamepad", "Interact")
ContextActionService:SetPosition("LIFTED_ThiefInteractGamepad", UDim2.new(1, -150, 1, -190))

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
			task.defer(updateTouchButtons)
		end
		return Enum.ContextActionResult.Sink
	end,
	true,
	Enum.KeyCode.ButtonA
)
ContextActionService:SetTitle("LIFTED_ThiefSkillCheckGamepad", "Hit")
ContextActionService:SetPosition("LIFTED_ThiefSkillCheckGamepad", UDim2.new(1, -260, 1, -190))

ContextActionService:BindAction(
	"LIFTED_ThiefCrouch",
	function(_, inputState, _)
		if not isThief() then return end
		if inputState == Enum.UserInputState.Begin then
			crouching = true
			setMovementStateRemote:FireServer("Crouch", true)
			applyFootstepVolume()
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			crouching = false
			setMovementStateRemote:FireServer("Crouch", false)
			applyFootstepVolume()
		end
		return Enum.ContextActionResult.Sink
	end,
	true,
	Enum.KeyCode.ButtonL1
)
ContextActionService:SetTitle("LIFTED_ThiefCrouch", "Crouch")
ContextActionService:SetPosition("LIFTED_ThiefCrouch", UDim2.new(1, -370, 1, -290))

updateTouchButtons = function()
	local active = isThief() and localPlayer:GetAttribute("RoundState") == "Alive"
	local interactButton = ContextActionService:GetButton("LIFTED_ThiefInteractGamepad")
	local hitButton = ContextActionService:GetButton("LIFTED_ThiefSkillCheckGamepad")
	local crouchButton = ContextActionService:GetButton("LIFTED_ThiefCrouch")
	if interactButton then interactButton.Visible = active end
	if hitButton then hitButton.Visible = active and pendingCheckId ~= nil end
	if crouchButton then crouchButton.Visible = active end
end

localPlayer:GetAttributeChangedSignal("Role"):Connect(updateTouchButtons)
localPlayer:GetAttributeChangedSignal("RoundState"):Connect(updateTouchButtons)
task.defer(updateTouchButtons)

local skillCheckResultRemote = Remotes.Find(Remotes.Names.SkillCheckResult)
if skillCheckResultRemote then
	skillCheckResultRemote.OnClientEvent:Connect(function(_, checkId)
		if pendingCheckId == checkId then
			pendingCheckId = nil
			pendingCheckObjectiveId = nil
			updateTouchButtons()
		end
	end)
end

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
local skillCheckStartedRemote = Remotes.Find(Remotes.Names.SkillCheckStarted)
if skillCheckStartedRemote then
	skillCheckStartedRemote.OnClientEvent:Connect(function(objectiveId, checkId, windowSeconds)
		if not isThief() then return end
		pendingCheckObjectiveId = objectiveId
		pendingCheckId = checkId
		updateTouchButtons()
		-- Auto-clear if player doesn't press Space in time
		local capturedId = checkId
		task.delay((tonumber(windowSeconds) or 0.75) + 0.2, function()
			if pendingCheckId == capturedId then
				pendingCheckId = nil
				pendingCheckObjectiveId = nil
				updateTouchButtons()
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
			updateTouchButtons()
		end
	end)
end
