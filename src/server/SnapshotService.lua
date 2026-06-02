-- SnapshotService
-- Server-owned state recovery for clients that load late or miss events.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteGuardService = require(script.Parent:WaitForChild("RemoteGuardService"))

local SnapshotService = {}

local deps = {}

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

local function buildSnapshot(player)
	local round = deps.GetRoundSnapshot and deps.GetRoundSnapshot() or {}
	local playerStateService = deps.PlayerStateService
	local objectiveService = deps.ObjectiveService
	local idolService = deps.IdolService
	local cageService = deps.CageService
	local guardianAbilityService = deps.GuardianAbilityService
	local roundScoreService = deps.RoundScoreService

	local playerRole = playerStateService and playerStateService.GetRole(player) or player:GetAttribute("Role")
	local playerState = playerStateService and playerStateService.GetState(player) or player:GetAttribute("RoundState")

	return {
		roundState = round.roundState or "Lobby",
		timeRemaining = round.timeRemaining or 0,
		playerRole = playerRole,
		playerState = playerState,
		aliveThiefCount = playerStateService and playerStateService.CountAliveThieves() or 0,
		totalThiefCount = round.totalThiefCount or 0,
		objectives = objectiveService and objectiveService.GetSnapshot and objectiveService.GetSnapshot()
			or objectiveService and objectiveService.GetObjectivesSnapshot and objectiveService.GetObjectivesSnapshot()
			or {},
		vaultOpen = objectiveService and objectiveService.IsVaultOpen and objectiveService.IsVaultOpen() or false,
		idol = idolService and idolService.GetSnapshot and idolService.GetSnapshot() or {},
		cage = cageService and cageService.GetSnapshot and cageService.GetSnapshot() or {},
		guardianAbilities = guardianAbilityService and guardianAbilityService.GetCooldownSnapshot
			and guardianAbilityService.GetCooldownSnapshot(player)
			or {},
		scoreSummary = roundScoreService and roundScoreService.GetSnapshot and roundScoreService.GetSnapshot() or nil,
	}
end

function SnapshotService.Configure(newDeps)
	deps = newDeps or {}
end

function SnapshotService.Init()
	local requestRemote = getOrCreateRemote("RequestGameSnapshot")
	getOrCreateRemote("GameSnapshot")

	requestRemote.OnServerEvent:Connect(function(player)
		if not RemoteGuardService.Allow(player, "RequestGameSnapshot", 0.5) then
			return
		end
		SnapshotService.SendSnapshot(player)
	end)
end

function SnapshotService.SendSnapshot(player)
	if not player or not player.Parent then
		return
	end
	local remote = ReplicatedStorage:FindFirstChild("GameSnapshot")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireClient(player, buildSnapshot(player))
	end
end

function SnapshotService.BuildSnapshot(player)
	return buildSnapshot(player)
end

function SnapshotService.PrintSnapshot(player)
	local snapshot = buildSnapshot(player)
	local idol = snapshot.idol or {}
	local cage = snapshot.cage or {}
	local score = snapshot.scoreSummary or {}
	local mvp = type(score.mvp) == "table" and score.mvp or nil

	print(string.format("[Snapshot] player=%s roundState=%s timeRemaining=%.1f role=%s state=%s",
		player and player.Name or "server",
		tostring(snapshot.roundState),
		tonumber(snapshot.timeRemaining) or 0,
		tostring(snapshot.playerRole),
		tostring(snapshot.playerState)
	))
	print(string.format("[Snapshot] activeThieves=%s/%s vaultOpen=%s",
		tostring(snapshot.aliveThiefCount),
		tostring(snapshot.totalThiefCount),
		tostring(snapshot.vaultOpen)
	))
	for objectiveId, obj in pairs(snapshot.objectives or {}) do
		print(string.format("[Snapshot][Objective] %s progress=%.2f completed=%s active=%s",
			tostring(objectiveId),
			tonumber(obj.progress) or 0,
			tostring(obj.completed),
			tostring(obj.activeCount)
		))
	end
	print(string.format("[Snapshot][Idol] state=%s carrier=%s extracting=%s progress=%.2f",
		tostring(idol.state),
		tostring(idol.carrierName or idol.carrierUserId or "none"),
		tostring(idol.isExtracting),
		tonumber(idol.extractProgress) or 0
	))
	local cagedCount = 0
	for _, row in pairs(cage.cagedPlayers or {}) do
		cagedCount += 1
		print(string.format("[Snapshot][Cage] caged=%s(%s)", tostring(row.name), tostring(row.userId)))
	end
	if cagedCount == 0 then
		print("[Snapshot][Cage] caged=none")
	end
	for targetUserId, rec in pairs(cage.rescues or {}) do
		print(string.format("[Snapshot][Rescue] target=%s progress=%.2f rescuers=%s",
			tostring(targetUserId),
			tonumber(rec.progress) or 0,
			tostring(rec.rescuerCount)
		))
	end
	for abilityName, seconds in pairs(snapshot.guardianAbilities or {}) do
		print(string.format("[Snapshot][Cooldown] %s=%.1f", tostring(abilityName), tonumber(seconds) or 0))
	end
	if mvp then
		print(string.format("[Snapshot][Score] MVP=%s score=%s", tostring(mvp.name), tostring(mvp.totalScore)))
	end
	return snapshot
end

return SnapshotService
