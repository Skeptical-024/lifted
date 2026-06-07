-- RuntimeAuditService
-- Studio/debug QA checks for impossible gameplay states. Warns only.

local RuntimeAuditService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local deps = {}
local running = false
local lastReport = nil
local loopToken = 0

local REQUIRED_REMOTES = {
	"RoundStarted", "RoundEnded", "RoundResults", "RoleAssigned", "GameSnapshot", "RequestGameSnapshot",
	"RequestObjectiveStart", "RequestObjectiveStop", "ObjectiveInteractionStarted", "ObjectiveProgress",
	"ObjectiveCompleted", "ObjectiveFailed", "VaultOpened",
	"RequestIdolPickup", "RequestIdolDrop", "RequestExtractWithIdol", "RequestExtractCancel",
	"IdolAvailable", "IdolPickedUp", "IdolDropped", "IdolCarrierChanged", "IdolExtracted", "IdolFailed",
	"ExtractProgress", "ExtractCompleted", "ExtractCanceled", "ExtractFailed", "GuardianCarrierPing",
	"RequestCageRescueStart", "RequestCageRescueStop", "PlayerCaged", "CageRescueStarted",
	"CageRescueProgress", "CageRescueCompleted", "CageRescueFailed", "CageRescueCanceled",
	"RequestGuardianRush", "RequestGuardianReveal", "RequestGuardianRoar", "GuardianRushStarted",
	"GuardianRushFailed", "GuardianRevealStarted", "GuardianRevealFailed", "GuardianRoarActivated",
	"GuardianRoarFailed", "GuardianAbilityCooldown", "GuardianCatchFailed",
}

local REQUIRED_TAGS = {
	ObjectiveStation = 3,
	Vault = 1,
	Idol = 1,
	ExtractPoint = 1,
	ThiefSpawn = 1,
	GuardianSpawn = 1,
	CageSpawn = 1,
	CageRescuePoint = 1,
}

local REMOTES_FOLDER_NAME = "Remote" .. "s"

local function add(list, message)
	table.insert(list, message)
end

local function countTagged(tag)
	local count = 0
	for _, inst in ipairs(CollectionService:GetTagged(tag)) do
		if inst:IsA("BasePart") and inst:IsDescendantOf(workspace) then
			count += 1
		end
	end
	return count
end

local function hasRemotesFolder()
	local folder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	return folder ~= nil
end

local function getHumanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function isEffected(player)
	return player:GetAttribute("IdolCarrierSpeed") ~= nil
		or player:GetAttribute("IsCrouching") == true
		or player:GetAttribute("IsCaught") == true
		or player:GetAttribute("IsCaged") == true
end

function RuntimeAuditService.Init(newDeps)
	deps = newDeps or {}
end

function RuntimeAuditService.RunOnce()
	local warnings = {}
	local errors = {}
	local constants = deps.Constants or {}
	local playerStateService = deps.PlayerStateService
	local objectiveService = deps.ObjectiveService
	local idolService = deps.IdolService
	local cageService = deps.CageService
	local roundScoreService = deps.RoundScoreService
	local round = deps.GetRoundSnapshot and deps.GetRoundSnapshot() or {}
	local active = round.roundState == "Active"

	if hasRemotesFolder() then
		add(errors, "ReplicatedStorage has a Remotes folder. Remotes must stay flat.")
	end
	for _, remoteName in ipairs(REQUIRED_REMOTES) do
		local remote = ReplicatedStorage:FindFirstChild(remoteName)
		if not (remote and remote:IsA("RemoteEvent")) then
			add(errors, "Missing RemoteEvent: " .. remoteName)
		end
	end

	if active then
		local guardians = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if playerStateService and playerStateService.IsGuardian(player) then
				table.insert(guardians, player)
			end
		end
		if #guardians == 0 then
			add(errors, "Active round has zero guardians.")
		elseif #guardians > 1 then
			add(errors, "Active round has more than one guardian: " .. tostring(#guardians))
		end

		for tag, minCount in pairs(REQUIRED_TAGS) do
			local count = countTagged(tag)
			if count < minCount then
				add(warnings, string.format("Tag %s has %d parts; expected >= %d.", tag, count, minCount))
			end
		end
	end

	local idol = idolService and idolService.GetSnapshot and idolService.GetSnapshot() or {}
	local carrier = idolService and idolService.GetCarrier and idolService.GetCarrier() or nil
	for _, player in ipairs(Players:GetPlayers()) do
		local role = player:GetAttribute("Role")
		local state = player:GetAttribute("RoundState")
		local serviceRole = playerStateService and playerStateService.GetRole(player) or nil
		local serviceState = playerStateService and playerStateService.GetState(player) or nil

		if role ~= nil and serviceRole ~= nil and tostring(role) ~= tostring(serviceRole) and active then
			add(warnings, string.format("Role mismatch for %s attr=%s service=%s", player.Name, tostring(role), tostring(serviceRole)))
		end
		if state ~= nil and serviceState ~= nil and tostring(state) ~= tostring(serviceState) and active then
			add(warnings, string.format("State mismatch for %s attr=%s service=%s", player.Name, tostring(state), tostring(serviceState)))
		end

		if player:GetAttribute("HasIdol") == true and carrier ~= player then
			add(errors, string.format("%s has HasIdol=true but is not IdolService carrier.", player.Name))
		end
		if carrier == player and player:GetAttribute("HasIdol") ~= true then
			add(errors, string.format("%s is IdolService carrier but HasIdol is false.", player.Name))
		end
		if (player:GetAttribute("IsCaged") == true or state == "Caged") and player:GetAttribute("HasIdol") == true then
			add(errors, string.format("%s is caged and still has idol.", player.Name))
		end

		local hum = getHumanoid(player)
		if active and hum and not isEffected(player) then
			local maxExpected = (constants.DEFAULT_WALK_SPEED or 16) * (constants.GUARDIAN_RUSH_SPEED_MULTIPLIER or 1.45) + 1
			if hum.WalkSpeed < 1 then
				add(warnings, string.format("%s WalkSpeed below 1 without active lock/effect: %.2f", player.Name, hum.WalkSpeed))
			elseif hum.WalkSpeed > maxExpected then
				add(warnings, string.format("%s WalkSpeed above expected max: %.2f", player.Name, hum.WalkSpeed))
			end
		end

		local root = getRoot(player)
		if active and root and root.Position.Y <= (constants.FALL_RESET_Y or -100) then
			add(warnings, string.format("%s is below FALL_RESET_Y: %.1f", player.Name, root.Position.Y))
		end
	end

	if carrier and carrier:GetAttribute("HasIdol") ~= true then
		add(errors, "Idol carrier exists but carrier HasIdol attribute is false.")
	end
	if idol.carrierUserId and not carrier then
		add(errors, "Idol snapshot has carrierUserId but GetCarrier returned nil.")
	end

	if objectiveService then
		local completed = objectiveService.GetCompletedCount and objectiveService.GetCompletedCount() or 0
		local vaultOpen = objectiveService.IsVaultOpen and objectiveService.IsVaultOpen() or false
		if vaultOpen and completed < 3 then
			add(errors, "VaultOpen=true before all 3 objectives completed.")
		elseif (not vaultOpen) and completed >= 3 and active then
			add(errors, "VaultOpen=false after all 3 objectives completed.")
		end

		local activePlayers = objectiveService.GetActivePlayersSnapshot and objectiveService.GetActivePlayersSnapshot() or {}
		for objectiveId, players in pairs(activePlayers) do
			for _, player in ipairs(players) do
				if not playerStateService or not playerStateService.CanInteractObjective(player) then
					add(errors, string.format("Invalid objective active player: %s on %s", player and player.Name or "nil", tostring(objectiveId)))
				end
			end
		end
	end

	if round.resultsFired == true and round.roundState == "Active" then
		add(errors, "RoundResults already fired while roundState is Active.")
	end
	if active and (not round.timeRemaining or round.timeRemaining <= 0) then
		add(warnings, "RoundState Active but timeRemaining is missing or <= 0.")
	end

	if roundScoreService and roundScoreService.GetSnapshot then
		local score = roundScoreService.GetSnapshot()
		if active and type(score.players) == "table" and #score.players == 0 and #Players:GetPlayers() > 0 then
			add(warnings, "Score payload has no players during active round.")
		end
	end

	lastReport = {
		ok = #errors == 0,
		errors = errors,
		warnings = warnings,
		checkedAt = os.clock(),
	}

	RuntimeAuditService.PrintReport(lastReport)
	return lastReport
end

function RuntimeAuditService.PrintReport(report)
	report = report or lastReport
	if not report then
		print("[RuntimeAudit] No report yet.")
		return
	end
	if report.ok then
		print(string.format("[RuntimeAudit] PASS warnings=%d", #report.warnings))
	else
		warn(string.format("[RuntimeAudit] FAIL errors=%d warnings=%d", #report.errors, #report.warnings))
	end
	for _, message in ipairs(report.errors) do
		warn("[RuntimeAudit][ERROR] " .. message)
	end
	for _, message in ipairs(report.warnings) do
		warn("[RuntimeAudit][WARN] " .. message)
	end
end

function RuntimeAuditService.Start()
	local constants = deps.Constants or {}
	if not (RunService:IsStudio() or constants.RUNTIME_AUDIT_ENABLED == true) then
		return
	end
	if running then
		return
	end
	running = true
	loopToken += 1
	local token = loopToken
	task.spawn(function()
		while running and token == loopToken do
			RuntimeAuditService.RunOnce()
			task.wait(constants.RUNTIME_AUDIT_INTERVAL or 5)
		end
	end)
end

function RuntimeAuditService.Stop()
	running = false
	loopToken += 1
end

function RuntimeAuditService.GetLastReport()
	return lastReport
end

return RuntimeAuditService
