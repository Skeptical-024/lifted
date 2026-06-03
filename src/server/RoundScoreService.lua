-- RoundScoreService
-- Session-only round contribution tracking and results payload.

local RoundScoreService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local scoresByUserId = {}
local rolesByUserId = {}
local roundId = 0
local roundActive = false
local sealCompletionAwards = {} -- [objectiveId] = { [userId] = true }
local warned = {}

local function warnOnce(key, ...)
	if warned[key] then return end
	warned[key] = true
	warn(...)
end

local WEIGHTS = {
	sealProgress = 100,
	sealCompleted = 150,
	idolPickup = 150,
	idolExtracted = 500,
	rescueProgress = 80,
	rescueCompleted = 200,
	catch = 200,
	cage = 100,
	idolCarrierCatchBonus = 300,
	roarHit = 50,
	revealUse = 75,
	rushUse = 25,
	skillCheckHit = 20,
}

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

local function ensureEntry(player, role)
	if not player then
		return nil
	end
	local uid = player.UserId
	local entry = scoresByUserId[uid]
	if entry then
		if role then
			entry.role = role
			rolesByUserId[uid] = role
		end
		return entry
	end
	if roundActive then
		warnOnce("unregistered_score_" .. tostring(uid), "[RoundScoreService] Recording event for unregistered player:", player.Name)
	end
	entry = {
		userId = uid,
		name = player.Name,
		role = role or rolesByUserId[uid] or "None",
		totalScore = 0,
		stats = {
			sealProgressPoints = 0,
			sealsCompleted = 0,
			idolPickups = 0,
			idolExtracted = 0,
			rescueProgressPoints = 0,
			rescuesCompleted = 0,
			timesCaged = 0,
			catches = 0,
			cages = 0,
			idolCarrierCatches = 0,
			roarHits = 0,
			revealsUsed = 0,
			rushesUsed = 0,
			skillChecksHit = 0,
		},
	}
	scoresByUserId[uid] = entry
	rolesByUserId[uid] = entry.role
	return entry
end

local function addScore(entry, amount)
	if not entry then return end
	entry.totalScore += amount
end

function RoundScoreService.Init()
	getOrCreateRemote("RoundResults")
end

function RoundScoreService.ResetForRound(newRoundId, rolesByPlayer)
	roundId = newRoundId or 0
	roundActive = false
	scoresByUserId = {}
	rolesByUserId = {}
	sealCompletionAwards = {}
	for player, role in pairs(rolesByPlayer or {}) do
		RoundScoreService.RegisterPlayer(player, role)
	end
	roundActive = true
end

function RoundScoreService.StopRound()
	roundActive = false
end

function RoundScoreService.RegisterPlayer(player, role)
	ensureEntry(player, role)
end

function RoundScoreService.RecordSealProgress(player, objectiveId, deltaProgress)
	if not roundActive then return end
	local entry = ensureEntry(player)
	local amount = math.max(0, tonumber(deltaProgress) or 0) * WEIGHTS.sealProgress
	entry.stats.sealProgressPoints += amount
	addScore(entry, amount)
end

function RoundScoreService.RecordSealCompleted(player, objectiveId)
	if not roundActive then return end
	if type(objectiveId) ~= "string" or objectiveId == "" then return end
	local uid = player and player.UserId
	if not uid then return end
	sealCompletionAwards[objectiveId] = sealCompletionAwards[objectiveId] or {}
	if sealCompletionAwards[objectiveId][uid] then
		warnOnce("duplicate_seal_award_" .. objectiveId .. "_" .. tostring(uid),
			"[RoundScoreService] Duplicate seal completion scoring ignored:", objectiveId, player.Name)
		return
	end
	sealCompletionAwards[objectiveId][uid] = true
	local entry = ensureEntry(player)
	entry.stats.sealsCompleted += 1
	addScore(entry, WEIGHTS.sealCompleted)
end

function RoundScoreService.RecordIdolPickedUp(player)
	if not roundActive then return end
	local entry = ensureEntry(player)
	entry.stats.idolPickups += 1
	addScore(entry, WEIGHTS.idolPickup)
end

function RoundScoreService.RecordIdolExtracted(player)
	if not roundActive then return end
	local entry = ensureEntry(player)
	entry.stats.idolExtracted += 1
	addScore(entry, WEIGHTS.idolExtracted)
end

function RoundScoreService.RecordCaged(player)
	if not roundActive then return end
	local entry = ensureEntry(player)
	entry.stats.timesCaged += 1
end

function RoundScoreService.RecordCaughtByGuardian(guardianPlayer, thiefPlayer, wasIdolCarrier)
	if not roundActive then return end
	local g = ensureEntry(guardianPlayer)
	g.stats.catches += 1
	g.stats.cages += 1
	addScore(g, WEIGHTS.catch + WEIGHTS.cage)
	if wasIdolCarrier then
		g.stats.idolCarrierCatches += 1
		addScore(g, WEIGHTS.idolCarrierCatchBonus)
	end
end

function RoundScoreService.RecordRescueProgress(player, deltaProgress)
	if not roundActive then return end
	local entry = ensureEntry(player)
	local amount = math.max(0, tonumber(deltaProgress) or 0) * WEIGHTS.rescueProgress
	entry.stats.rescueProgressPoints += amount
	addScore(entry, amount)
end

function RoundScoreService.RecordRescueCompleted(rescuerPlayer, rescuedPlayer)
	if not roundActive then return end
	local entry = ensureEntry(rescuerPlayer)
	entry.stats.rescuesCompleted += 1
	addScore(entry, WEIGHTS.rescueCompleted)
	local _ = rescuedPlayer
end

function RoundScoreService.RecordGuardianRush(player)
	if not roundActive then return end
	local entry = ensureEntry(player)
	entry.stats.rushesUsed += 1
	addScore(entry, WEIGHTS.rushUse)
end

function RoundScoreService.RecordGuardianReveal(player, revealedCount)
	if not roundActive then return end
	local count = math.max(0, tonumber(revealedCount) or 0)
	if count <= 0 then
		return
	end
	local entry = ensureEntry(player)
	entry.stats.revealsUsed += 1
	addScore(entry, WEIGHTS.revealUse)
end

function RoundScoreService.RecordGuardianRoar(player, affectedCount)
	if not roundActive then return end
	local entry = ensureEntry(player)
	local hits = math.max(0, tonumber(affectedCount) or 0)
	entry.stats.roarHits += hits
	addScore(entry, WEIGHTS.roarHit * hits)
end

function RoundScoreService.RecordSkillCheckHit(player)
	if not roundActive then return end
	local entry = ensureEntry(player)
	entry.stats.skillChecksHit = (entry.stats.skillChecksHit or 0) + 1
	addScore(entry, WEIGHTS.skillCheckHit)
end

local function computeHeroMoments(scoreMap)
	local moments = {}
	local topSeal = { score = -1 }
	local topRescue = { score = -1 }
	local topHunter = { score = -1 }
	local extractor = nil

	for _, entry in pairs(scoreMap) do
		local s = entry.stats
		if (s.idolExtracted or 0) > 0 and not extractor then
			extractor = { name = entry.name, role = entry.role }
		end
		if (s.sealsCompleted or 0) > topSeal.score then
			topSeal = { name = entry.name, role = entry.role, score = s.sealsCompleted }
		end
		if (s.rescuesCompleted or 0) > topRescue.score then
			topRescue = { name = entry.name, role = entry.role, score = s.rescuesCompleted }
		end
		if (s.catches or 0) > topHunter.score then
			topHunter = { name = entry.name, role = entry.role, score = s.catches }
		end
	end

	if extractor then
		table.insert(moments, { title = "Idol Extractor", playerName = extractor.name })
	end
	if topSeal.score and topSeal.score > 0 then
		table.insert(moments, { title = "Seal Breaker", playerName = topSeal.name, value = topSeal.score })
	end
	if topRescue.score and topRescue.score > 0 then
		table.insert(moments, { title = "Clutch Save", playerName = topRescue.name, value = topRescue.score })
	end
	if topHunter.score and topHunter.score > 0 then
		table.insert(moments, { title = "Hunter", playerName = topHunter.name, value = topHunter.score })
	end
	return moments
end

function RoundScoreService.BuildResultsPayload(winner, reason)
	local players = {}
	local thiefTotalScore = 0
	local guardianTotalScore = 0
	local sealsCompleted = 0
	local rescuesCompleted = 0
	local idolExtracted = false
	local mvp = nil

	for _, entry in pairs(scoresByUserId) do
		local row = {
			userId = entry.userId,
			name = entry.name,
			role = entry.role,
			totalScore = math.floor(entry.totalScore + 0.5),
			stats = entry.stats,
		}
		table.insert(players, row)
		if row.role == "Thief" then
			thiefTotalScore += row.totalScore
			sealsCompleted += entry.stats.sealsCompleted
			rescuesCompleted += entry.stats.rescuesCompleted
			if entry.stats.idolExtracted > 0 then
				idolExtracted = true
			end
		elseif row.role == "Guardian" then
			guardianTotalScore += row.totalScore
		end
		if (not mvp) or row.totalScore > mvp.totalScore then
			mvp = { userId = row.userId, name = row.name, role = row.role, totalScore = row.totalScore }
		end
	end
	if #players == 0 then
		warnOnce("results_no_players", "[RoundScoreService] BuildResultsPayload has no players.")
	end

	table.sort(players, function(a, b)
		if a.totalScore == b.totalScore then
			return a.name < b.name
		end
		return a.totalScore > b.totalScore
	end)

	return {
		winner = winner,
		reason = reason,
		mvp = mvp,
		players = players,
		heroMoments = computeHeroMoments(scoresByUserId),
		teamSummary = {
			thiefTotalScore    = thiefTotalScore,
			guardianTotalScore = guardianTotalScore,
			sealsCompleted     = sealsCompleted,
			rescuesCompleted   = rescuesCompleted,
			idolExtracted      = idolExtracted,
		},
	}
end

function RoundScoreService.FireResults(winner, reason)
	local payload = RoundScoreService.BuildResultsPayload(winner, reason)
	local remote = ReplicatedStorage:FindFirstChild("RoundResults")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireAllClients(payload)
	end
end

function RoundScoreService.GetSnapshot()
	return RoundScoreService.BuildResultsPayload(nil, nil)
end

return RoundScoreService
