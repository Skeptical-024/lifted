print("GameManager: script started")
-- Core game loop -- owns round state, role assignment, win conditions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))
local RoleManager = require(script.Parent:WaitForChild("RoleManager"))
local GuardianController = require(script.Parent:WaitForChild("GuardianController"))
local ThiefController = require(script.Parent:WaitForChild("ThiefController"))
local BrazierManager = require(script.Parent:WaitForChild("BrazierManager"))
local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local ObjectiveService = require(script.Parent:WaitForChild("ObjectiveService"))
local IdolService = require(script.Parent:WaitForChild("IdolService"))
local CageService = require(script.Parent:WaitForChild("CageService"))
local GuardianAbilityService = require(script.Parent:WaitForChild("GuardianAbilityService"))
local TestMapService = require(script.Parent:WaitForChild("TestMapService"))
print("GameManager: all modules loaded")

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

local thiefExtractedRemote = getOrCreateRemote("ThiefExtracted")
local catchThiefRemote = getOrCreateRemote("CatchThief")
local setMovementStateRemote = getOrCreateRemote("SetMovementState")
getOrCreateRemote("ThiefCaught")
local roleAssignedRemote = getOrCreateRemote("RoleAssigned")
local brazierInteractRemote = getOrCreateRemote("BrazierInteract")
getOrCreateRemote("GuardianBrazierSequence")
getOrCreateRemote("BrazierStateChanged")
local roundStartedRemote = getOrCreateRemote("RoundStarted")
local roundEndedRemote = getOrCreateRemote("RoundEnded")
local thiefCountUpdateRemote = getOrCreateRemote("ThiefCountUpdate")
local brazierProgressUpdateRemote = getOrCreateRemote("BrazierProgressUpdate")
local lobbyUpdateRemote = getOrCreateRemote("LobbyUpdate")
local requestObjectiveStartRemote = getOrCreateRemote("RequestObjectiveStart")
local requestObjectiveStopRemote = getOrCreateRemote("RequestObjectiveStop")
getOrCreateRemote("ObjectivePromptShown")
getOrCreateRemote("ObjectivePromptHidden")
getOrCreateRemote("ObjectiveInteractionStarted")
getOrCreateRemote("ObjectiveProgress")
getOrCreateRemote("ObjectiveCompleted")
getOrCreateRemote("ObjectiveFailed")
getOrCreateRemote("VaultOpened")

local roundActive = false
local roundId = 0
local rolesByPlayer = {}
local activeThieves = {}
local guardianPlayer = nil
local thievesExtracted = false
local thiefSpawnCursor = 0

local function getTaggedParts(tag)
	local parts = {}
	for _, instance in CollectionService:GetTagged(tag) do
		if instance:IsA("BasePart") and instance:IsDescendantOf(workspace) then
			table.insert(parts, instance)
		end
	end
	return parts
end

local function ensureBasicMap()
	-- Disabled: TestMapService handles all tagged gameplay parts.
end

local function createSpawnPart(name, position, color, tag)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(4, 1, 4)
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.Position = position
	part.Parent = workspace
	CollectionService:AddTag(part, tag)
	return part
end

local function ensureSpawnPoints()
	-- Disabled: TestMapService handles all tagged gameplay parts.
end

local function ensureVaultPart()
	-- Disabled: TestMapService handles all tagged gameplay parts.
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

local function handleCaughtThief(targetPlayer, newState)
	if newState == PlayerStateService.State.Caught then
		freezeThiefCharacter(targetPlayer)
	elseif newState == PlayerStateService.State.Caged then
		freezeThiefCharacter(targetPlayer)
	elseif newState == PlayerStateService.State.Eliminated then
		freezeThiefCharacter(targetPlayer)
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

local function getRemainingThiefCount()
	local remaining = 0
	for thiefPlayer in activeThieves do
		if Players:FindFirstChild(thiefPlayer.Name) then
			remaining += 1
		end
	end
	return remaining
end

local function fireThiefCountToGuardian()
	if guardianPlayer and Players:FindFirstChild(guardianPlayer.Name) then
		thiefCountUpdateRemote:FireClient(guardianPlayer, getRemainingThiefCount())
	end
end

local function fireBrazierProgressToThieves(count)
	for player, role in rolesByPlayer do
		if role == Types.PlayerRole.Thief and Players:FindFirstChild(player.Name) then
			brazierProgressUpdateRemote:FireClient(player, count)
		end
	end
end

local function clearRoundState()
	PlayerStateService.ResetForNewRound(roundId)
	ObjectiveService.StopRound()
	IdolService.StopRound()
	CageService.StopRound()
	GuardianAbilityService.StopRound()

	for player in rolesByPlayer do
		player:SetAttribute("Role", nil)
		resetPlayerMovement(player)
		GuardianController.ResetPlayer(player)
	end

	BrazierManager.Reset()

	roundActive = false
	rolesByPlayer = {}
	activeThieves = {}
	guardianPlayer = nil
	thievesExtracted = false
	thiefSpawnCursor = 0

	for _, tag in ipairs({"ThiefSpawn", "GuardianSpawn"}) do
		for _, part in CollectionService:GetTagged(tag) do
			if part:IsA("BasePart") then
				part.Transparency = 0.5
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	rolesByPlayer[player] = nil
	activeThieves[player] = nil
	GuardianController.ResetPlayer(player)
	if player == guardianPlayer then
		guardianPlayer = nil
	end
	PlayerStateService.UnregisterPlayer(player)
	ObjectiveService.StopAllForPlayer(player)
	IdolService.DropFromPlayer(player, "left")
	CageService.StopAllForPlayer(player)
	GuardianAbilityService.StopAllForPlayer(player)
end)

Players.PlayerAdded:Connect(function(player)
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
			or state == PlayerStateService.State.Caged
			or state == PlayerStateService.State.Eliminated then
			task.defer(function()
				if player.Parent then
					handleCaughtThief(player, state)
				end
			end)
		else
			player:SetAttribute("IsCaught", false)
		end
	end)
end)

setMovementStateRemote.OnServerEvent:Connect(function(player, requestedState, isActive)
	if not roundActive then
		return
	end
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
	elseif role == Types.PlayerRole.Guardian and requestedState == "Sprint" then
		GuardianController.SetSprinting(player, isActive, rolesByPlayer)
	end
end)

-- NOTE: BrazierManager drives placeholder visual feedback only.
-- Objective win state is owned by ObjectiveService.
-- BrazierManager.IsUnlocked() is no longer used as a gate.
brazierInteractRemote.OnServerEvent:Connect(function(player, brazierName)
	if not roundActive then
		return
	end
	if type(brazierName) ~= "string" then
		return
	end

	local role = rolesByPlayer[player]
	if role == Types.PlayerRole.Thief and PlayerStateService.CanInteractObjective(player) then
		local success = BrazierManager.TryLightBrazier(player, brazierName, rolesByPlayer, roundActive)
		if success then
			fireBrazierProgressToThieves(BrazierManager.GetLitCount())
		end
	elseif role == Types.PlayerRole.Guardian then
		local success = BrazierManager.TryExtinguishBrazier(player, brazierName, rolesByPlayer, roundActive)
		if success then
			fireBrazierProgressToThieves(BrazierManager.GetLitCount())
		end
	end
end)

thiefExtractedRemote.OnServerEvent:Connect(function(player)
	-- Old extraction path disabled. IdolService owns extraction.
end)

catchThiefRemote.OnServerEvent:Connect(function(player, targetPlayer)
	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		return
	end
	-- State gate: only alive thieves can be caught
	if not PlayerStateService.CanBeCaught(targetPlayer) then
		return
	end
	if not PlayerStateService.IsGuardian(player) then
		return
	end
	local success = GuardianController.TryCatch(player, targetPlayer, rolesByPlayer, roundActive)
	if success then
		local caught, newState = PlayerStateService.MarkCaught(targetPlayer)
		if caught then
			handleCaughtThief(targetPlayer, newState)
			ObjectiveService.StopAllForPlayer(targetPlayer)
			IdolService.DropFromPlayer(targetPlayer, "caught")
			CageService.CagePlayer(targetPlayer)
			-- Remove from activeThieves regardless of Caught vs Eliminated
			activeThieves[targetPlayer] = nil
			fireThiefCountToGuardian()
		end
	end
end)

local function getRoundPlayers()
	local players = {}
	for _, player in Players:GetPlayers() do
		table.insert(players, player)
	end
	return players
end

TestMapService.Init()
ObjectiveService.Init()
IdolService.Init()
CageService.Init()
GuardianAbilityService.Init()
IdolService.SetRoundEndCallback(function(extractingPlayer)
	thievesExtracted = true
end)
-- ensureBasicMap, ensureVaultPart, ensureSpawnPoints disabled:
-- TestMapService provides all tagged gameplay parts.
print("GameManager: vault ensured")
task.wait(5)

while true do
	print("GameManager: waiting for players")

	while #Players:GetPlayers() < Constants.ROUND_MIN_PLAYERS do
		fireLobbyUpdate("waiting", #Players:GetPlayers(), Constants.ROUND_MIN_PLAYERS, nil)
		print("GameManager: player count = " .. #Players:GetPlayers())
		task.wait(1)
	end

	local countdown = Constants.LOBBY_COUNTDOWN_SECONDS
	local countdownFinished = true
	while countdown > 0 do
		if #Players:GetPlayers() < Constants.ROUND_MIN_PLAYERS then
			countdownFinished = false
			break
		end
		fireLobbyUpdate("countdown", #Players:GetPlayers(), Constants.ROUND_MIN_PLAYERS, countdown)
		task.wait(1)
		countdown -= 1
	end
	if not countdownFinished then
		continue
	end

	local roundPlayers = getRoundPlayers()
	if #roundPlayers < Constants.ROUND_MIN_PLAYERS then
		continue
	end

	clearRoundState()
	roundActive = true
	rolesByPlayer, guardianPlayer = RoleManager.AssignRoles(roundPlayers)
	roundId += 1
	PlayerStateService.ResetForNewRound(roundId)
	for player, role in rolesByPlayer do
		PlayerStateService.RegisterPlayer(player, role, roundId)
	end
	ObjectiveService.ResetForRound(roundId)
	ObjectiveService.AutoRegisterObjectiveParts()
	IdolService.ResetForRound(roundId)
	CageService.ResetForRound(roundId)
	GuardianAbilityService.ResetForRound(roundId)

	task.spawn(function()
		local notified = false
		while roundActive do
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

	for player, role in rolesByPlayer do
		roleAssignedRemote:FireClient(player, role)
	end

	BrazierManager.InitRound(rolesByPlayer)
	fireBrazierProgressToThieves(0)
	fireThiefCountToGuardian()

	for _, player in Players:GetPlayers() do
		roundStartedRemote:FireClient(player, Constants.ROUND_DURATION_SECONDS)
	end

	for _, tag in ipairs({"ThiefSpawn", "GuardianSpawn"}) do
		for _, part in CollectionService:GetTagged(tag) do
			if part:IsA("BasePart") then
				part.Transparency = 1
			end
		end
	end

	local roundEndsAt = os.clock() + Constants.ROUND_DURATION_SECONDS
	local result = "Time expired"
	local winner = "Time"

	while roundActive do
		GuardianController.StepSprintTimers(rolesByPlayer)

		if thievesExtracted then
			result = "Thieves extracted loot"
			winner = "Thieves"
			roundActive = false
			break
		end

		-- PlayerStateService is source of truth for alive thief count
		if PlayerStateService.AreAllThievesOut() then
			result = "Guardian caught all thieves"
			winner = "Guardian"
			roundActive = false
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
			result = "Time expired"
			winner = "Time"
			roundActive = false
			break
		end

		if #Players:GetPlayers() < Constants.ROUND_MIN_PLAYERS then
			result = "Round canceled: not enough players"
			winner = "Time"
			roundActive = false
			break
		end

		RunService.Heartbeat:Wait()
	end

	fireRoundEnded(result, winner)
	print(string.format("[RoundResult] %s", result))
	for _, player in ipairs(Players:GetPlayers()) do
		ObjectiveService.StopAllForPlayer(player)
	end
	clearRoundState()
	task.wait(3)
end
