-- SessionAnalyticsService
-- Session-only round analytics. No DataStore.
-- Prints readable summaries after each round.
-- Exposed via /debug roundlog and /debug analytics.

local SessionAnalyticsService = {}

local rounds = {}
local currentRound = nil

local function formatDuration(seconds)
	if not seconds then return "?" end
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%d:%02d", m, s)
end

local function newRecord(roundId, playerCount, guardianName)
	return {
		roundId        = roundId,
		playerCount    = playerCount,
		guardianName   = guardianName or "?",
		startedAt      = os.clock(),
		endedAt        = nil,
		duration       = nil,
		winner         = nil,
		reason         = nil,
		sealsCompleted = 0,
		firstSealAt    = nil,
		vaultOpenAt    = nil,
		idolPickupAt   = nil,
		extractStartAt = nil,
		extractDoneAt  = nil,
		catches        = 0,
		cages          = 0,
		rescues        = 0,
		roarUses       = 0,
		revealUses     = 0,
		rushUses       = 0,
		extractCancels = 0,
		skillChecksHit = 0,
		pings          = 0,
	}
end

function SessionAnalyticsService.StartRound(roundId, playerCount, guardianName)
	currentRound = newRecord(roundId, playerCount, guardianName)
	table.insert(rounds, currentRound)
	if #rounds > 50 then
		table.remove(rounds, 1)
	end
end

function SessionAnalyticsService.RecordSealCompleted()
	if not currentRound then return end
	currentRound.sealsCompleted += 1
	if not currentRound.firstSealAt then
		currentRound.firstSealAt = os.clock() - currentRound.startedAt
	end
end

function SessionAnalyticsService.RecordVaultOpened()
	if not currentRound then return end
	if not currentRound.vaultOpenAt then
		currentRound.vaultOpenAt = os.clock() - currentRound.startedAt
	end
end

function SessionAnalyticsService.RecordIdolPickup()
	if not currentRound then return end
	if not currentRound.idolPickupAt then
		currentRound.idolPickupAt = os.clock() - currentRound.startedAt
	end
end

function SessionAnalyticsService.RecordExtractionStart()
	if not currentRound then return end
	if not currentRound.extractStartAt then
		currentRound.extractStartAt = os.clock() - currentRound.startedAt
	end
end

function SessionAnalyticsService.RecordExtractionCancel()
	if not currentRound then return end
	currentRound.extractCancels += 1
end

function SessionAnalyticsService.RecordExtractionComplete()
	if not currentRound then return end
	if not currentRound.extractDoneAt then
		currentRound.extractDoneAt = os.clock() - currentRound.startedAt
	end
end

function SessionAnalyticsService.RecordCatch()
	if not currentRound then return end
	currentRound.catches += 1
end

function SessionAnalyticsService.RecordCage()
	if not currentRound then return end
	currentRound.cages += 1
end

function SessionAnalyticsService.RecordRescue()
	if not currentRound then return end
	currentRound.rescues += 1
end

function SessionAnalyticsService.RecordRoar()
	if not currentRound then return end
	currentRound.roarUses += 1
end

function SessionAnalyticsService.RecordReveal()
	if not currentRound then return end
	currentRound.revealUses += 1
end

function SessionAnalyticsService.RecordRush()
	if not currentRound then return end
	currentRound.rushUses += 1
end

function SessionAnalyticsService.RecordSkillCheckHit()
	if not currentRound then return end
	currentRound.skillChecksHit += 1
end

function SessionAnalyticsService.RecordPing()
	if not currentRound then return end
	currentRound.pings += 1
end

function SessionAnalyticsService.EndRound(winner, reason)
	if not currentRound then return end
	currentRound.endedAt = os.clock()
	currentRound.duration = currentRound.endedAt - currentRound.startedAt
	currentRound.winner = winner
	currentRound.reason = reason
	SessionAnalyticsService.PrintRoundSummary(currentRound)
end

function SessionAnalyticsService.PrintRoundSummary(record)
	record = record or currentRound
	if not record then
		print("[Analytics] No round data.")
		return
	end
	local dur = formatDuration(record.duration)
	print(string.format(
		"[Analytics] Round %d: %s won (%s) in %s | Players: %d | Guardian: %s",
		record.roundId,
		record.winner or "?",
		record.reason or "?",
		dur,
		record.playerCount,
		record.guardianName
	))
	print(string.format(
		"[Analytics]   Seals %d/3 | Catches %d | Cages %d | Rescues %d | Extract cancels %d",
		record.sealsCompleted, record.catches, record.cages, record.rescues, record.extractCancels
	))
	print(string.format(
		"[Analytics]   Rush %d | Reveal %d | Roar %d | SkillChecksHit %d | Pings %d",
		record.rushUses, record.revealUses, record.roarUses, record.skillChecksHit, record.pings
	))
	local timeline = {}
	if record.firstSealAt then table.insert(timeline, "Seal@" .. formatDuration(record.firstSealAt)) end
	if record.vaultOpenAt then table.insert(timeline, "Vault@" .. formatDuration(record.vaultOpenAt)) end
	if record.idolPickupAt then table.insert(timeline, "Idol@" .. formatDuration(record.idolPickupAt)) end
	if record.extractDoneAt then table.insert(timeline, "Extract@" .. formatDuration(record.extractDoneAt)) end
	if #timeline > 0 then
		print("[Analytics]   Timeline: " .. table.concat(timeline, " → "))
	end
end

function SessionAnalyticsService.PrintAll()
	if #rounds == 0 then
		print("[Analytics] No rounds recorded this session.")
		return
	end
	local thiefWins, guardianWins = 0, 0
	for _, r in ipairs(rounds) do
		if r.winner == "Thieves" then thiefWins += 1
		elseif r.winner == "Guardian" then guardianWins += 1 end
	end
	print(string.format(
		"[Analytics] Session: %d rounds | Thief wins %d | Guardian wins %d",
		#rounds, thiefWins, guardianWins
	))
	for _, r in ipairs(rounds) do
		SessionAnalyticsService.PrintRoundSummary(r)
	end
end

function SessionAnalyticsService.GetLastRound()
	return rounds[#rounds]
end

function SessionAnalyticsService.GetAllRounds()
	return rounds
end

function SessionAnalyticsService.Init()
	print("[SessionAnalyticsService] Initialized.")
end

return SessionAnalyticsService
