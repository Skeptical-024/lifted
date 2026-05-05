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

local roundActive = false
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
	if workspace:FindFirstChild("TempleFloor") then
		return
	end

	local mapColor = Color3.fromRGB(60, 60, 60)

	local floor = Instance.new("Part")
	floor.Name = "TempleFloor"
	floor.Size = Vector3.new(200, 1, 200)
	floor.Anchored = true
	floor.Position = Vector3.new(0, 0, 0)
	floor.Color = mapColor
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = workspace

	local function createWall(name, size, position)
		local wall = Instance.new("Part")
		wall.Name = name
		wall.Size = size
		wall.Anchored = true
		wall.Position = position
		wall.Color = mapColor
		wall.Material = Enum.Material.SmoothPlastic
		wall.Parent = workspace
	end

	createWall("TempleWallNorth", Vector3.new(200, 20, 2), Vector3.new(0, 10, -100))
	createWall("TempleWallSouth", Vector3.new(200, 20, 2), Vector3.new(0, 10, 100))
	createWall("TempleWallEast", Vector3.new(2, 20, 200), Vector3.new(100, 10, 0))
	createWall("TempleWallWest", Vector3.new(2, 20, 200), Vector3.new(-100, 10, 0))
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
	local thiefSpawns = getTaggedParts("ThiefSpawn")
	for index = #thiefSpawns + 1, #Constants.THIEF_SPAWN_POSITIONS do
		createSpawnPart(
			string.format("ThiefSpawn%d", index),
			Constants.THIEF_SPAWN_POSITIONS[index],
			Color3.fromRGB(0, 255, 0),
			"ThiefSpawn"
		)
	end

	local guardianSpawns = getTaggedParts("GuardianSpawn")
	if #guardianSpawns == 0 then
		createSpawnPart(
			"GuardianSpawn",
			Constants.GUARDIAN_SPAWN_POSITION,
			Color3.fromRGB(255, 0, 0),
			"GuardianSpawn"
		)
	end
end

local function ensureVaultPart()
	local existingVaults = CollectionService:GetTagged("Vault")
	for _, vault in existingVaults do
		if vault:IsA("BasePart") and vault:IsDescendantOf(workspace) then
			return
		end
	end

	local vault = Instance.new("Part")
	vault.Name = "Vault"
	vault.Size = Vector3.new(6, 6, 6)
	vault.Anchored = true
	vault.Position = Vector3.new(0, 3, 0)
	vault.Color = Color3.fromRGB(255, 221, 89)
	vault.Material = Enum.Material.Metal
	vault.Parent = workspace
	CollectionService:AddTag(vault, "Vault")
end

local function resetPlayerMovement(player)
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Constants.DEFAULT_WALK_SPEED
		end
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

local function clearRoundState()
	for player in rolesByPlayer do
		player:SetAttribute("Role", nil)
		resetPlayerMovement(player)
		GuardianController.ResetPlayer(player)
	end

	roundActive = false
	rolesByPlayer = {}
	activeThieves = {}
	guardianPlayer = nil
	thievesExtracted = false
	thiefSpawnCursor = 0
end

Players.PlayerRemoving:Connect(function(player)
	rolesByPlayer[player] = nil
	activeThieves[player] = nil
	GuardianController.ResetPlayer(player)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.WalkSpeed = Constants.DEFAULT_WALK_SPEED
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
				humanoid.WalkSpeed = isActive and Constants.THIEF_CROUCH_SPEED or Constants.DEFAULT_WALK_SPEED
			end
		end
	elseif role == Types.PlayerRole.Guardian and requestedState == "Sprint" then
		GuardianController.SetSprinting(player, isActive, rolesByPlayer)
	end
end)

thiefExtractedRemote.OnServerEvent:Connect(function(player)
	local valid = ThiefController.ValidateExtract(player, rolesByPlayer, roundActive)
	if not valid then
		return
	end
	thievesExtracted = true
end)

catchThiefRemote.OnServerEvent:Connect(function(player, targetPlayer)
	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		return
	end
	local success = GuardianController.TryCatch(player, targetPlayer, rolesByPlayer, roundActive)
	if success then
		activeThieves[targetPlayer] = nil
	end
end)

local function getRoundPlayers()
	local players = {}
	for _, player in Players:GetPlayers() do
		table.insert(players, player)
	end
	return players
end

ensureBasicMap()
ensureVaultPart()
ensureSpawnPoints()
print("GameManager: vault ensured")
task.wait(5)

while true do
	print("GameManager: waiting for players")
	while #Players:GetPlayers() < Constants.ROUND_MIN_PLAYERS do
		print("GameManager: player count = " .. #Players:GetPlayers())
		task.wait(1)
	end

	local roundPlayers = getRoundPlayers()
	if #roundPlayers < Constants.ROUND_MIN_PLAYERS then
		continue
	end

	clearRoundState()
	roundActive = true
	rolesByPlayer, guardianPlayer = RoleManager.AssignRoles(roundPlayers)

	for player, role in rolesByPlayer do
		applyBaseMovementForRole(player, role)
		if role == Types.PlayerRole.Thief then
			activeThieves[player] = true
		end
	end

	for player, role in rolesByPlayer do
		roleAssignedRemote:FireClient(player, role)
	end

	local roundEndsAt = os.clock() + Constants.ROUND_DURATION_SECONDS
	local result = "Time expired"

	while roundActive do
		GuardianController.StepSprintTimers(rolesByPlayer)

		if thievesExtracted then
			result = "Thieves extracted loot"
			roundActive = false
			break
		end

		local remainingThieves = 0
		local staleThieves = {}
		for thiefPlayer in activeThieves do
			if Players:FindFirstChild(thiefPlayer.Name) then
				remainingThieves += 1
			else
				table.insert(staleThieves, thiefPlayer)
			end
		end
		for _, stalePlayer in staleThieves do
			activeThieves[stalePlayer] = nil
		end
		if remainingThieves == 0 then
			result = "Guardian caught all thieves"
			roundActive = false
			break
		end

		if os.clock() >= roundEndsAt then
			result = "Time expired"
			roundActive = false
			break
		end

		if #Players:GetPlayers() < Constants.ROUND_MIN_PLAYERS then
			result = "Round canceled: not enough players"
			roundActive = false
			break
		end

		RunService.Heartbeat:Wait()
	end

	print(string.format("[RoundResult] %s", result))
	clearRoundState()
	task.wait(3)
end
