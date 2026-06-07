print("GameManager: script started")
-- Core game loop -- owns round state, role assignment, win conditions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local RoleManager = require(script.Parent:WaitForChild("RoleManager"))
local GuardianController = require(script.Parent:WaitForChild("GuardianController"))
local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local ObjectiveService = require(script.Parent:WaitForChild("ObjectiveService"))
local IdolService = require(script.Parent:WaitForChild("IdolService"))
local CageService = require(script.Parent:WaitForChild("CageService"))
local GuardianAbilityService = require(script.Parent:WaitForChild("GuardianAbilityService"))
local TestMapService = require(script.Parent:WaitForChild("TestMapService"))
local RoundScoreService = require(script.Parent:WaitForChild("RoundScoreService"))
local MapValidationService = require(script.Parent:WaitForChild("MapValidationService"))
local DebugCommandService = require(script.Parent:WaitForChild("DebugCommandService"))
local RemoteGuardService = require(script.Parent:WaitForChild("RemoteGuardService"))
local SnapshotService = require(script.Parent:WaitForChild("SnapshotService"))
local RuntimeAuditService = require(script.Parent:WaitForChild("RuntimeAuditService"))
local SkillCheckService = require(script.Parent:WaitForChild("SkillCheckService"))
local SessionAnalyticsService = require(script.Parent:WaitForChild("SessionAnalyticsService"))
local PingService = require(script.Parent:WaitForChild("PingService"))
local ActivityService = require(script.Parent:WaitForChild("ActivityService"))
print("GameManager: all modules loaded")

local thiefExtractedRemote = Remotes.Server(Remotes.Names.ThiefExtracted)
local catchThiefRemote = Remotes.Server(Remotes.Names.CatchThief)
local guardianCatchFailedRemote = Remotes.Server(Remotes.Names.GuardianCatchFailed)
local setMovementStateRemote = Remotes.Server(Remotes.Names.SetMovementState)
local thiefCaughtRemote = Remotes.Server(Remotes.Names.ThiefCaught)
local playerEliminatedRemote = Remotes.Server(Remotes.Names.PlayerEliminated)
local roleAssignedRemote = Remotes.Server(Remotes.Names.RoleAssigned)
local roundStartedRemote = Remotes.Server(Remotes.Names.RoundStarted)
local roundEndedRemote = Remotes.Server(Remotes.Names.RoundEnded)
local thiefCountUpdateRemote = Remotes.Server(Remotes.Names.ThiefCountUpdate)
local lobbyUpdateRemote = Remotes.Server(Remotes.Names.LobbyUpdate)
local requestObjectiveStartRemote = Remotes.Server(Remotes.Names.RequestObjectiveStart)
local requestObjectiveStopRemote = Remotes.Server(Remotes.Names.RequestObjectiveStop)
Remotes.Server(Remotes.Names.ObjectivePromptShown)
Remotes.Server(Remotes.Names.ObjectivePromptHidden)
Remotes.Server(Remotes.Names.ObjectiveInteractionStarted)
Remotes.Server(Remotes.Names.ObjectiveProgress)
Remotes.Server(Remotes.Names.ObjectiveCompleted)
Remotes.Server(Remotes.Names.ObjectiveFailed)
Remotes.Server(Remotes.Names.VaultOpened)

local roundActive = false
local roundId = 0
local rolesByPlayer = {}
local activeThieves = {}
local guardianPlayer = nil
local thiefSpawnCursor = 0
local vaultWatcherToken = 0
local endingRound = false
local forcedWinner = nil
local forcedReason = nil
local resultsFired = false
local lastGuardianUserId = nil
local roundEndsAt = 0
local totalThiefCount = 0
local forceStartRequested = false
local skipCountdownRequested = false

local RoundStates = {
	Lobby = "Lobby",
	Intermission = "Intermission",
	Countdown = "Countdown",
	AssigningRoles = "AssigningRoles",
	Starting = "Starting",
	Active = "Active",
	Ending = "Ending",
	Results = "Results",
	Cleanup = "Cleanup",
}

local roundState = RoundStates.Lobby

local function setRoundState(state, reason)
	if roundState == state then
		if reason then
			print(string.format("[RoundState] duplicate %s ignored (%s)", tostring(state), tostring(reason)))
		end
		return
	end
	local previous = roundState
	roundState = state
	print(string.format(
		"[RoundTransition] %s -> %s roundId=%d reason=%s players=%d winner=%s",
		tostring(previous),
		tostring(state),
		roundId,
		tostring(reason or ""),
		#Players:GetPlayers(),
		tostring(forcedWinner or "")
	))
end

local function getRoundState()
	return roundState
end

local function isRoundActive()
	return roundState == RoundStates.Active and roundActive
end

local function canAcceptGameplayRequest()
	return isRoundActive() and not endingRound
end

local function requestEndRound(winner, reason)
	if endingRound or forcedWinner ~= nil then
		return false
	end
	endingRound = true
	forcedWinner = winner or "Time"
	forcedReason = reason or "Round ended"
	setRoundState(RoundStates.Ending, forcedReason)
	return true
end

local function getTaggedParts(tag)
	local parts = {}
	for _, instance in CollectionService:GetTagged(tag) do
		if instance:IsA("BasePart") and instance:IsDescendantOf(workspace) then
			table.insert(parts, instance)
		end
	end
	return parts
end


local function resetPlayerMovement(player)
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Constants.DEFAULT_WALK_SPEED
			if humanoid.UseJumpPower then
				humanoid.JumpPower = 50
			else
				humanoid.JumpHeight = 7.2
			end
		end
	end
	player:SetAttribute("IsCaught", false)
	player:SetAttribute("IsCaged", false)
	player:SetAttribute("IsCrouching", false)
	player:SetAttribute("IsExtracting", false)
	player:SetAttribute("HasIdol", false)
	player:SetAttribute("IdolCarrierSpeed", nil)
end

local function getOrCreateCaughtHoldingSpawn()
	local tagged = CollectionService:GetTagged("CageSpawn")
	for _, instance in ipairs(tagged) do
		if instance:IsA("BasePart") and instance:IsDescendantOf(workspace) then
			return instance
		end
	end

	local named = workspace:FindFirstChild("CageSpawn", true)
	if named and named:IsA("BasePart") then
		return named
	end

	local existing = workspace:FindFirstChild("TemporaryCaughtHoldingSpawn")
	if existing and existing:IsA("BasePart") then
		return existing
	end

	local part = Instance.new("Part")
	part.Name = "TemporaryCaughtHoldingSpawn"
	part.Size = Vector3.new(8, 1, 8)
	part.Anchored = true
	part.CanCollide = true
	part.Position = Vector3.new(0, 5, 130)
	part.Color = Color3.fromRGB(120, 120, 120)
	part.Transparency = 0.35
	part.Parent = workspace
	return part
end

local function freezeThiefCharacter(player)
	local character = player.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid then
		return
	end

	local holdingSpawn = getOrCreateCaughtHoldingSpawn()
	if holdingSpawn then
		rootPart.CFrame = CFrame.new(holdingSpawn.Position + Vector3.new(0, 5, 0))
	end

	humanoid.WalkSpeed = 0
	if humanoid.UseJumpPower then
		humanoid.JumpPower = 0
	else
		humanoid.JumpHeight = 0
	end
	humanoid.PlatformStand = false
	player:SetAttribute("IsCaught", true)
end

local function getOrCreateSpectatorSpawn()
	local tagged = getTaggedParts("SpectatorSpawn")
	if tagged[1] then
		return tagged[1]
	end
	local existing = workspace:FindFirstChild("TemporarySpectatorSpawn")
	if existing and existing:IsA("BasePart") then
		return existing
	end
	local part = Instance.new("Part")
	part.Name = "TemporarySpectatorSpawn"
	part.Size = Vector3.new(24, 1, 24)
	part.Anchored = true
	part.CanCollide = true
	part.Position = Vector3.new(0, 8, 155)
	part.Color = Color3.fromRGB(30, 35, 45)
	part.Transparency = 0.25
	part.Parent = workspace
	return part
end

local function applyEliminatedTreatment(player, announce)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		local spectatorSpawn = getOrCreateSpectatorSpawn()
		if humanoid then
			humanoid.WalkSpeed = Constants.DEFAULT_WALK_SPEED or 16
			if humanoid.UseJumpPower then
				humanoid.JumpPower = 50
			else
				humanoid.JumpHeight = 7.2
			end
		end
		if root and spectatorSpawn then
			root.CFrame = CFrame.new(spectatorSpawn.Position + Vector3.new(0, 4, 0))
		end
	end
	player:SetAttribute("IsCaught", false)
	player:SetAttribute("IsCaged", false)
	if announce ~= false then
		playerEliminatedRemote:FireAllClients(player.UserId, player.Name)
	end
end

local function handleCaughtThief(targetPlayer, newState)
	if newState == PlayerStateService.State.Caught then
		freezeThiefCharacter(targetPlayer)
	elseif newState == PlayerStateService.State.Caged then
		freezeThiefCharacter(targetPlayer)
	elseif newState == PlayerStateService.State.Eliminated then
		applyEliminatedTreatment(targetPlayer)
	end
end

local function teleportToSpawn(player, role)
	local character = player.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if role == Types.PlayerRole.Guardian then
		local guardianSpawns = getTaggedParts("GuardianSpawn")
		local spawnPart = guardianSpawns[1]
		if spawnPart then
			rootPart.CFrame = CFrame.new(spawnPart.Position + Vector3.new(0, 5, 0))
		end
	elseif role == Types.PlayerRole.Thief then
		local thiefSpawns = getTaggedParts("ThiefSpawn")
		if #thiefSpawns > 0 then
			thiefSpawnCursor += 1
			local spawnIndex = ((thiefSpawnCursor - 1) % #thiefSpawns) + 1
			local spawnPart = thiefSpawns[spawnIndex]
			rootPart.CFrame = CFrame.new(spawnPart.Position + Vector3.new(0, 5, 0))
		end
	end
end

local function applyBaseMovementForRole(player, role)
	resetPlayerMovement(player)
	player:SetAttribute("Role", role)
	teleportToSpawn(player, role)
end

local function teleportPlayerForSafety(player)
	if not player or not player.Parent then return end
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local state = PlayerStateService.GetState(player)
	if state == PlayerStateService.State.Caged or state == PlayerStateService.State.Caught then
		local cage = getOrCreateCaughtHoldingSpawn()
		if cage then
			rootPart.CFrame = CFrame.new(cage.Position + Vector3.new(0, 5, 0))
		end
		return
	elseif state == PlayerStateService.State.Eliminated then
		applyEliminatedTreatment(player)
		return
	end

	local role = rolesByPlayer[player]
	if role == Types.PlayerRole.Guardian then
		local guardianSpawns = getTaggedParts("GuardianSpawn")
		local spawnPart = guardianSpawns[1]
		if spawnPart then
			rootPart.CFrame = CFrame.new(spawnPart.Position + Vector3.new(0, 5, 0))
		end
	else
		local thiefSpawns = getTaggedParts("ThiefSpawn")
		local spawnPart = thiefSpawns[1]
		if spawnPart then
			rootPart.CFrame = CFrame.new(spawnPart.Position + Vector3.new(0, 5, 0))
		end
	end
end

local function fireRoundEnded(result, winner)
	for _, player in Players:GetPlayers() do
		roundEndedRemote:FireClient(player, result, winner)
	end
end

local function fireLobbyUpdate(status, playerCount, requiredCount, countdown)
	for _, player in Players:GetPlayers() do
		lobbyUpdateRemote:FireClient(player, {
			status = status,
			playerCount = playerCount,
			required = requiredCount,
			countdown = countdown,
		})
	end
end

local function getRequiredPlayerCount()
	return Constants.MIN_PLAYERS_TO_START or 2
end

local function getEligibleLobbyPlayers()
	return ActivityService.GetEligiblePlayers()
end

local function getRemainingThiefCount()
	return PlayerStateService.CountAliveThieves()
end

local function fireThiefCountToGuardian()
	if guardianPlayer and Players:FindFirstChild(guardianPlayer.Name) then
		thiefCountUpdateRemote:FireClient(guardianPlayer, getRemainingThiefCount())
	end
end

local function clearRoundState()
	setRoundState(RoundStates.Cleanup, "clearRoundState")
	ObjectiveService.StopRound()
	IdolService.StopRound()
	CageService.StopRound()
	GuardianAbilityService.StopRound()
	RoundScoreService.StopRound()
	SkillCheckService.StopRound()
	PingService.StopRound()
	RemoteGuardService.Reset()

	for player in rolesByPlayer do
		player:SetAttribute("Role", nil)
		resetPlayerMovement(player)
		GuardianController.ResetPlayer(player)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerStateService.ClearRoundAttributes(player)
	end
	PlayerStateService.ResetForNewRound(roundId)

	roundActive = false
	endingRound = false
	forcedWinner = nil
	forcedReason = nil
	resultsFired = false
	rolesByPlayer = {}
	activeThieves = {}
	guardianPlayer = nil
	thiefSpawnCursor = 0
	totalThiefCount = 0
	roundEndsAt = 0

	for _, tag in ipairs({"ThiefSpawn", "GuardianSpawn"}) do
		for _, part in CollectionService:GetTagged(tag) do
			if part:IsA("BasePart") then
				part.Transparency = 0.5
			end
		end
	end

	print(string.format("[RoundLifecycle] Cleanup complete roundId=%d", roundId))
end

local function setForcedRoundResult(winner, reason)
	requestEndRound(winner, reason)
end

local function requestForceStart()
	if #Players:GetPlayers() < getRequiredPlayerCount() then
		print("[DebugCommand] forcestart denied: not enough players")
		return
	end
	if roundState ~= RoundStates.Lobby and roundState ~= RoundStates.Countdown then
		print("[DebugCommand] forcestart denied: not in lobby/countdown (state=" .. tostring(roundState) .. ")")
		return
	end
	forceStartRequested = true
	skipCountdownRequested = true
	print("[DebugCommand] Force start requested")
end

local function requestSkipCountdown()
	if roundState ~= RoundStates.Countdown then
		print("[DebugCommand] skiplobby denied: not in countdown (state=" .. tostring(roundState) .. ")")
		return
	end
	skipCountdownRequested = true
	print("[DebugCommand] Skip countdown requested")
end

Players.PlayerRemoving:Connect(function(player)
	local role = rolesByPlayer[player]
	local state = PlayerStateService.GetState(player)
	local hadIdol = IdolService.PlayerHasIdol(player)
	local caged = CageService.IsCaged(player)
	print(string.format(
		"[PlayerLeave] %s role=%s state=%s hadIdol=%s extracting=%s caged=%s",
		player.Name,
		tostring(role),
		tostring(state),
		tostring(hadIdol),
		"unknown",
		tostring(caged)
	))

	ObjectiveService.StopAllForPlayer(player)
	IdolService.DropFromPlayer(player, "left")
	CageService.StopAllForPlayer(player)
	GuardianAbilityService.StopAllForPlayer(player)
	RemoteGuardService.ClearPlayer(player)
	PlayerStateService.UnregisterPlayer(player)
	rolesByPlayer[player] = nil
	activeThieves[player] = nil
	GuardianController.ResetPlayer(player)
	if player == guardianPlayer then
		guardianPlayer = nil
		if roundActive then
			requestEndRound("Thieves", "Guardian left")
		end
	elseif role == Types.PlayerRole.Thief and roundActive and PlayerStateService.CountAliveThieves() <= 0 then
		requestEndRound("Guardian", "All thieves left")
	end
	fireThiefCountToGuardian()
end)

Players.PlayerAdded:Connect(function(player)
	if roundActive then
		player:SetAttribute("Role", nil)
		player:SetAttribute("RoundState", PlayerStateService.State.OutOfRound)
		lobbyUpdateRemote:FireClient(player, {
			status = "in_progress",
			playerCount = #getEligibleLobbyPlayers(),
			required = getRequiredPlayerCount(),
			countdown = nil,
		})
	else
		player:SetAttribute("Role", nil)
		player:SetAttribute("RoundState", PlayerStateService.State.Lobby)
	end
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.WalkSpeed = Constants.DEFAULT_WALK_SPEED
			if humanoid.UseJumpPower then
				humanoid.JumpPower = 50
			else
				humanoid.JumpHeight = 7.2
			end
		end

		local state = PlayerStateService.GetState(player)
		if state == PlayerStateService.State.Caught
			or state == PlayerStateService.State.Caged then
			task.defer(function()
				if player.Parent then
					handleCaughtThief(player, state)
				end
			end)
			elseif state == PlayerStateService.State.Eliminated then
				task.defer(function()
					if player.Parent then
						applyEliminatedTreatment(player, false)
				end
			end)
		else
			player:SetAttribute("IsCaught", false)
		end
	end)
	task.defer(function()
		if player.Parent then
			SnapshotService.SendSnapshot(player)
		end
	end)
end)

setMovementStateRemote.OnServerEvent:Connect(function(player, requestedState, isActive)
	if not canAcceptGameplayRequest() then
		return
	end
	if not RemoteGuardService.Allow(player, "SetMovementState", 0.05) then
		return
	end
	ActivityService.MarkActive(player, "movement")
	if type(requestedState) ~= "string" or type(isActive) ~= "boolean" then
		return
	end

	local role = rolesByPlayer[player]
	if role == Types.PlayerRole.Thief and requestedState == "Crouch" then
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				if isActive then
					humanoid.WalkSpeed = Constants.THIEF_CROUCH_SPEED
				else
					-- Restore to carrier speed if carrying idol, otherwise default
					local carrierSpeed = player:GetAttribute("IdolCarrierSpeed")
					humanoid.WalkSpeed = (carrierSpeed and carrierSpeed > 0) and carrierSpeed or Constants.DEFAULT_WALK_SPEED
				end
				player:SetAttribute("IsCrouching", isActive)
			end
		end
	end
end)

thiefExtractedRemote.OnServerEvent:Connect(function(player)
	-- Legacy extraction remote. IdolService owns extraction. This remote intentionally does nothing.
end)

catchThiefRemote.OnServerEvent:Connect(function(player, targetPlayer)
	if not canAcceptGameplayRequest() then
		guardianCatchFailedRemote:FireClient(player, "round_inactive")
		return
	end
	if not RemoteGuardService.Allow(player, "CatchThief", 0.2) then
		return
	end
	ActivityService.MarkActive(player, "catch")
	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		guardianCatchFailedRemote:FireClient(player, "no_target")
		return
	end
	-- State gate: only alive thieves can be caught
	if not PlayerStateService.CanBeCaught(targetPlayer) then
		guardianCatchFailedRemote:FireClient(player, "not_eligible")
		return
	end
	if not PlayerStateService.IsGuardian(player) then
		guardianCatchFailedRemote:FireClient(player, "not_guardian")
		return
	end
	local success = GuardianController.TryCatch(player, targetPlayer, rolesByPlayer, roundActive)
	if success then
		local wasIdolCarrier = IdolService.PlayerHasIdol(targetPlayer)
		-- Capture drop position BEFORE handleCaughtThief teleports the player to cage.
		-- Without this, idol would drop at cage position instead of catch location.
		local idolDropPosition = nil
		if wasIdolCarrier then
			local chr = targetPlayer.Character
			local root = chr and chr:FindFirstChild("HumanoidRootPart")
			idolDropPosition = root and root.Position
		end
		local caught, newState = PlayerStateService.MarkCaught(targetPlayer)
		if caught then
			-- Fire ThiefCaught after MarkCaught so newState is included
			thiefCaughtRemote:FireAllClients(player, targetPlayer, newState)
			RoundScoreService.RecordCaughtByGuardian(player, targetPlayer, wasIdolCarrier)
			handleCaughtThief(targetPlayer, newState)
			ObjectiveService.StopAllForPlayer(targetPlayer)
			SkillCheckService.CancelAllForPlayer(targetPlayer)
			IdolService.DropFromPlayer(targetPlayer, "caught", idolDropPosition)
			SessionAnalyticsService.RecordCatch()
			if newState == PlayerStateService.State.Caught then
				CageService.CagePlayer(targetPlayer)
				SessionAnalyticsService.RecordCage()
			end
			activeThieves[targetPlayer] = nil
			fireThiefCountToGuardian()
		end
	else
		guardianCatchFailedRemote:FireClient(player, "too_far")
	end
end)

local function getRoundPlayers()
	return getEligibleLobbyPlayers()
end

local function getRoundSnapshot()
	return {
		roundId = roundId,
		roundState = getRoundState(),
		roundActive = roundActive,
		timeRemaining = math.max(0, roundEndsAt - os.clock()),
		totalThiefCount = totalThiefCount,
		activePlayersCount = #Players:GetPlayers(),
		guardianName = guardianPlayer and guardianPlayer.Name or nil,
		winner = forcedWinner,
		reason = forcedReason,
		resultsFired = resultsFired,
	}
end

TestMapService.Init()
local mapReport = MapValidationService.ValidateCurrentMap()
MapValidationService.PrintReport()
if Constants.STRICT_MAP_VALIDATION == true and not mapReport.ok then
	warn("[MapValidation] STRICT_MAP_VALIDATION enabled and map report has errors.")
end
ObjectiveService.Init()
IdolService.Init()
CageService.Init()
GuardianAbilityService.Init()
RoundScoreService.Init()
SnapshotService.Configure({
	PlayerStateService = PlayerStateService,
	ObjectiveService = ObjectiveService,
	IdolService = IdolService,
	CageService = CageService,
	GuardianAbilityService = GuardianAbilityService,
	RoundScoreService = RoundScoreService,
	ActivityService = ActivityService,
	GetRoundSnapshot = getRoundSnapshot,
})
SnapshotService.Init()
RuntimeAuditService.Init({
	Constants = Constants,
	PlayerStateService = PlayerStateService,
	ObjectiveService = ObjectiveService,
	IdolService = IdolService,
	CageService = CageService,
	RoundScoreService = RoundScoreService,
	GetRoundSnapshot = getRoundSnapshot,
})
RuntimeAuditService.Start()
IdolService.SetRoundEndCallback(function(extractingPlayer)
	local name = extractingPlayer and extractingPlayer.Name or "A thief"
	SessionAnalyticsService.RecordExtractionComplete()
	requestEndRound("Thieves", name .. " extracted the idol")
end)
CageService.SetRescueCompletedCallback(function(rescuedPlayer, reason)
	local _ = rescuedPlayer
	local _reason = reason
	SessionAnalyticsService.RecordRescue()
	fireThiefCountToGuardian()
end)

-- Wire SkillCheckService
SkillCheckService.SetObjectiveService(ObjectiveService)
SkillCheckService.SetScoreCallbacks({
	onSkillCheckHit = function(player, objectiveId)
		RoundScoreService.RecordSkillCheckHit(player)
		SessionAnalyticsService.RecordSkillCheckHit()
	end,
})
SkillCheckService.Init()

-- Wire SessionAnalyticsService analytics via ability/idol callbacks
GuardianAbilityService.SetScoreCallbacks({
	onRush = function(player)
		RoundScoreService.RecordGuardianRush(player)
		SessionAnalyticsService.RecordRush()
	end,
	onReveal = function(player, revealedCount)
		RoundScoreService.RecordGuardianReveal(player, revealedCount)
		SessionAnalyticsService.RecordReveal()
	end,
	onRoar = function(player, affectedCount)
		RoundScoreService.RecordGuardianRoar(player, affectedCount)
		SessionAnalyticsService.RecordRoar()
	end,
})
IdolService.SetScoreCallbacks({
	onIdolPickedUp = function(player)
		RoundScoreService.RecordIdolPickedUp(player)
		SessionAnalyticsService.RecordIdolPickup()
	end,
	onIdolExtracted = function(player)
		RoundScoreService.RecordIdolExtracted(player)
		SessionAnalyticsService.RecordExtractionComplete()
	end,
})
ObjectiveService.SetScoreCallbacks({
	onSealProgress = function(player, objectiveId, delta)
		RoundScoreService.RecordSealProgress(player, objectiveId, delta)
	end,
	onSealCompleted = function(player, objectiveId)
		RoundScoreService.RecordSealCompleted(player, objectiveId)
		SessionAnalyticsService.RecordSealCompleted()
		if ObjectiveService.GetCompletedCount() >= 3 then
			SessionAnalyticsService.RecordVaultOpened()
		end
	end,
})
CageService.SetScoreCallbacks({
	onCaged = function(player)
		RoundScoreService.RecordCaged(player)
	end,
	onRescueProgress = function(player, delta)
		RoundScoreService.RecordRescueProgress(player, delta)
	end,
	onRescueCompleted = function(rescuer, rescued)
		RoundScoreService.RecordRescueCompleted(rescuer, rescued)
	end,
})

-- Wire PingService analytics
PingService.SetAnalyticsCallback(function()
	SessionAnalyticsService.RecordPing()
end)
PingService.Init()
ActivityService.Init()
for _, remoteName in ipairs({
	"RequestObjectiveStart", "RequestObjectiveStop",
	"RequestIdolPickup", "RequestIdolDrop", "RequestExtractWithIdol", "RequestExtractCancel",
	"RequestCageRescueStart", "RequestCageRescueStop",
	"RequestGuardianRush", "RequestGuardianReveal", "RequestGuardianRoar",
	"RequestSkillCheckHit", "RequestPing",
}) do
	ActivityService.TrackRemote(remoteName)
end
SessionAnalyticsService.Init()
DebugCommandService.Init({
	Constants = Constants,
	ObjectiveService = ObjectiveService,
	IdolService = IdolService,
	CageService = CageService,
	PlayerStateService = PlayerStateService,
	MapValidationService = MapValidationService,
	SnapshotService = SnapshotService,
	RuntimeAuditService = RuntimeAuditService,
	ActivityService = ActivityService,
	SessionAnalyticsService = SessionAnalyticsService,
	GetRoundSnapshot = getRoundSnapshot,
	SetForcedRoundResult = setForcedRoundResult,
	RequestForceStart = requestForceStart,
	SkipCountdown = requestSkipCountdown,
})
task.wait(5)

while true do
	print("GameManager: waiting for players")
	setRoundState(RoundStates.Lobby, "waiting_for_players")

	while #getEligibleLobbyPlayers() < getRequiredPlayerCount() do
		local eligibleCount = #getEligibleLobbyPlayers()
		if forceStartRequested and #Players:GetPlayers() >= getRequiredPlayerCount() then
			break
		end
		forceStartRequested = false
		fireLobbyUpdate("waiting", eligibleCount, getRequiredPlayerCount(), nil)
		task.wait(1)
	end
	forceStartRequested = false

	setRoundState(RoundStates.Countdown, "min_players_ready")
	local countdown = Constants.LOBBY_COUNTDOWN_SECONDS
	local countdownFinished = true
	while countdown > 0 do
		if skipCountdownRequested then
			countdown = math.min(countdown, 2)
			skipCountdownRequested = false
		end
		local eligibleCount = #getEligibleLobbyPlayers()
		if eligibleCount < getRequiredPlayerCount() then
			countdownFinished = false
			break
		end
		fireLobbyUpdate("countdown", eligibleCount, getRequiredPlayerCount(), countdown)
		task.wait(1)
		countdown -= 1
	end
	skipCountdownRequested = false
	if not countdownFinished then
		setRoundState(RoundStates.Lobby, "countdown_canceled")
		continue
	end

	local roundPlayers = getRoundPlayers()
	if #roundPlayers < getRequiredPlayerCount() then
		continue
	end

	setRoundState(RoundStates.Cleanup, "pre_round_cleanup")
	clearRoundState()
	setRoundState(RoundStates.AssigningRoles, "assign_roles")
	-- Fix stale lastGuardianUserId: only use it if that player still exists
	local validLastGuardian = lastGuardianUserId
	if validLastGuardian then
		local stillHere = false
		for _, p in ipairs(roundPlayers) do
			if p.UserId == validLastGuardian then stillHere = true; break end
		end
		if not stillHere then validLastGuardian = nil end
	end
	rolesByPlayer, guardianPlayer = RoleManager.AssignRoles(roundPlayers, validLastGuardian)
	if guardianPlayer then
		lastGuardianUserId = guardianPlayer.UserId
	end
	roundId += 1
	print(string.format("[RoundLifecycle] Start roundId=%d guardian=%s", roundId, guardianPlayer and guardianPlayer.Name or "?"))
	PlayerStateService.ResetForNewRound(roundId)
	RoundScoreService.ResetForRound(roundId, rolesByPlayer)
	for player, role in rolesByPlayer do
		PlayerStateService.RegisterPlayer(player, role, roundId)
		RoundScoreService.RegisterPlayer(player, role)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if not rolesByPlayer[player] then
			player:SetAttribute("Role", nil)
			player:SetAttribute("RoundState", PlayerStateService.State.OutOfRound)
		end
	end
	ObjectiveService.ResetForRound(roundId)
	ObjectiveService.AutoRegisterObjectiveParts()
	IdolService.ResetForRound(roundId)
	CageService.ResetForRound(roundId)
	GuardianAbilityService.ResetForRound(roundId)
	SkillCheckService.ResetForRound()
	PingService.ResetForRound()
	ActivityService.ResetForRound(roundPlayers)
	SessionAnalyticsService.StartRound(
		roundId,
		#roundPlayers,
		guardianPlayer and guardianPlayer.Name or "?"
	)
	roundActive = true
	endingRound = false
	forcedWinner = nil
	forcedReason = nil
	setRoundState(RoundStates.Starting, "services_ready")

	vaultWatcherToken += 1
	local watcherToken = vaultWatcherToken
	task.spawn(function()
		local notified = false
		while roundActive and watcherToken == vaultWatcherToken do
			if not notified and ObjectiveService.IsVaultOpen() then
				notified = true
				IdolService.OnVaultOpened()
			end
			task.wait(0.2)
		end
	end)

	for player, role in rolesByPlayer do
		applyBaseMovementForRole(player, role)
		if role == Types.PlayerRole.Thief then
			activeThieves[player] = true
		end
	end
	totalThiefCount = PlayerStateService.CountAliveThieves()

	for player, role in rolesByPlayer do
		roleAssignedRemote:FireClient(player, role)
	end

	fireThiefCountToGuardian()

	for _, player in Players:GetPlayers() do
		roundStartedRemote:FireClient(player, Constants.ROUND_DURATION_SECONDS, PlayerStateService.CountAliveThieves())
	end

	for _, tag in ipairs({"ThiefSpawn", "GuardianSpawn"}) do
		for _, part in CollectionService:GetTagged(tag) do
			if part:IsA("BasePart") then
				part.Transparency = 1
			end
		end
	end

	roundEndsAt = os.clock() + Constants.ROUND_DURATION_SECONDS
	local result = "Time expired"
	local winner = "Time"
	local lastFallSafetyAt = 0
	local lastAfkCheckAt = 0
	setRoundState(RoundStates.Active, "round_started")

	while roundActive do
		if forcedWinner ~= nil then
			result = forcedReason or "Round ended by debug command"
			winner = forcedWinner
			roundActive = false
			break
		end
		-- PlayerStateService is source of truth for alive thief count
		if PlayerStateService.AreAllThievesOut() then
			requestEndRound("Guardian", "All thieves captured")
			break
		end
		-- Keep activeThieves pruned for any legacy references
		local staleThieves = {}
		for thiefPlayer in activeThieves do
			if not Players:FindFirstChild(thiefPlayer.Name) then
				table.insert(staleThieves, thiefPlayer)
			end
		end
		for _, stalePlayer in staleThieves do
			activeThieves[stalePlayer] = nil
		end

		if os.clock() >= roundEndsAt then
			requestEndRound("Guardian", "Time expired")
			break
		end

		if #Players:GetPlayers() < getRequiredPlayerCount() then
			requestEndRound("Guardian", "Not enough players")
			break
		end

		local now = os.clock()
		if now - lastAfkCheckAt >= 1 then
			lastAfkCheckAt = now
			for player, role in pairs(rolesByPlayer) do
				local state = PlayerStateService.GetState(player)
				if state == PlayerStateService.State.Alive then
					if ActivityService.ShouldWarn(player) then
						ActivityService.MarkWarned(player)
					end
					if ActivityService.ShouldAction(player) then
						ActivityService.MarkActioned(player)
						if role == Types.PlayerRole.Guardian then
							requestEndRound("Thieves", "Guardian AFK")
							break
						elseif role == Types.PlayerRole.Thief then
							ObjectiveService.StopAllForPlayer(player)
							SkillCheckService.CancelAllForPlayer(player)
							CageService.StopAllForPlayer(player)
							IdolService.DropFromPlayer(player, "afk")
							PlayerStateService.MarkEliminated(player)
							applyEliminatedTreatment(player)
							activeThieves[player] = nil
							fireThiefCountToGuardian()
						end
					end
				end
			end
		end
		if now - lastFallSafetyAt >= 0.5 then
			lastFallSafetyAt = now
			for player in pairs(rolesByPlayer) do
				local character = player.Character
				local rootPart = character and character:FindFirstChild("HumanoidRootPart")
				if rootPart and rootPart.Position.Y <= (Constants.FALL_RESET_Y or -100) then
					teleportPlayerForSafety(player)
				end
			end
		end

		RunService.Heartbeat:Wait()
	end

	if forcedWinner ~= nil then
		result = forcedReason or result
		winner = forcedWinner
	end
	roundActive = false
	setRoundState(RoundStates.Results, result)
	SessionAnalyticsService.EndRound(winner, result)
	fireRoundEnded(result, winner)
	RoundScoreService.FireResults(winner, result)
	resultsFired = true
	print(string.format("[RoundLifecycle] End roundId=%d winner=%s reason=%s", roundId, tostring(winner), tostring(result)))
	for _, player in ipairs(Players:GetPlayers()) do
		ObjectiveService.StopAllForPlayer(player)
		SkillCheckService.CancelAllForPlayer(player)
	end
	clearRoundState()
	setRoundState(RoundStates.Intermission, "results_complete")
	fireLobbyUpdate("intermission", #Players:GetPlayers(), getRequiredPlayerCount(), Constants.INTERMISSION_SECONDS or 10)
	task.wait(Constants.RESULTS_DISPLAY_SECONDS or 8)
end
