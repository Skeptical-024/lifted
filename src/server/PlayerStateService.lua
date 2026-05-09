-- PlayerStateService
-- Server-authoritative per-round player state.
-- Internal records are the source of truth.
-- Player attributes are for UI/debug visibility only.

local PlayerStateService = {}

-- State constants
PlayerStateService.State = {
	Lobby      = "Lobby",
	Alive      = "Alive",
	Caught     = "Caught",
	Caged      = "Caged",
	Escaped    = "Escaped",
	Eliminated = "Eliminated",
	OutOfRound = "OutOfRound",
}

-- Role constants (mirrors Types.PlayerRole but local for safety)
PlayerStateService.Role = {
	Thief    = "Thief",
	Guardian = "Guardian",
	None     = "None",
}

local records = {}       -- [userId] = record
local currentRoundId = 0

local function defaultRecord(player, role, roundId)
	return {
		player           = player,
		userId           = player.UserId,
		role             = role or PlayerStateService.Role.None,
		state            = PlayerStateService.State.Lobby,
		lives            = 2,
		caughtCount      = 0,
		escaped          = false,
		eliminated       = false,
		roundId          = roundId or 0,
		lastStateChangedAt = os.clock(),
	}
end

local function setAttributes(player, record)
	-- Attributes are display-only. Do not use them as state source of truth.
	local ok = pcall(function()
		player:SetAttribute("Role",        record.role)
		player:SetAttribute("RoundState",  record.state)
		player:SetAttribute("Lives",       record.lives)
		player:SetAttribute("CaughtCount", record.caughtCount)
	end)
	if not ok then
		warn("[PlayerStateService] Failed to set attributes for", player.Name)
	end
end

-- Resets all records for a new round.
function PlayerStateService.ResetForNewRound(roundId)
	records = {}
	currentRoundId = roundId or (currentRoundId + 1)
end

-- Creates or refreshes a player record with assigned role.
function PlayerStateService.RegisterPlayer(player, role, roundId)
	if not player or not player.Parent then return end
	local rec = defaultRecord(player, role, roundId or currentRoundId)
	if role == PlayerStateService.Role.Guardian or role == PlayerStateService.Role.Thief then
		rec.state = PlayerStateService.State.Alive
	end
	records[player.UserId] = rec
	setAttributes(player, rec)
end

-- Cleans up a player record when they leave or round ends.
function PlayerStateService.UnregisterPlayer(player)
	if not player then return end
	records[player.UserId] = nil
end

-- Role API
function PlayerStateService.SetRole(player, role)
	local rec = records[player and player.UserId]
	if not rec then return end
	rec.role = role
	setAttributes(player, rec)
end

function PlayerStateService.GetRole(player)
	local rec = records[player and player.UserId]
	return rec and rec.role or PlayerStateService.Role.None
end

-- State API
function PlayerStateService.SetState(player, state)
	local rec = records[player and player.UserId]
	if not rec then return end
	rec.state = state
	rec.lastStateChangedAt = os.clock()
	setAttributes(player, rec)
end

function PlayerStateService.GetState(player)
	local rec = records[player and player.UserId]
	return rec and rec.state or PlayerStateService.State.Lobby
end

function PlayerStateService.GetRecord(player)
	local rec = records[player and player.UserId]
	if not rec then return nil end
	-- Return shallow copy so callers cannot mutate internal state
	local copy = {}
	for k, v in pairs(rec) do
		copy[k] = v
	end
	return copy
end

-- State query helpers
function PlayerStateService.IsInRound(player)
	local s = PlayerStateService.GetState(player)
	return s == PlayerStateService.State.Alive
		or s == PlayerStateService.State.Caught
		or s == PlayerStateService.State.Caged
end

function PlayerStateService.IsAlive(player)
	return PlayerStateService.GetState(player) == PlayerStateService.State.Alive
end

function PlayerStateService.IsAliveThief(player)
	return PlayerStateService.GetRole(player) == PlayerStateService.Role.Thief
		and PlayerStateService.IsAlive(player)
end

function PlayerStateService.IsGuardian(player)
	return PlayerStateService.GetRole(player) == PlayerStateService.Role.Guardian
end

function PlayerStateService.CanBeCaught(player)
	return PlayerStateService.GetRole(player) == PlayerStateService.Role.Thief
		and PlayerStateService.GetState(player) == PlayerStateService.State.Alive
end

function PlayerStateService.CanInteractObjective(player)
	return PlayerStateService.GetRole(player) == PlayerStateService.Role.Thief
		and PlayerStateService.GetState(player) == PlayerStateService.State.Alive
end

function PlayerStateService.CanExtract(player)
	-- Future: will also require idol carrier check
	return PlayerStateService.GetRole(player) == PlayerStateService.Role.Thief
		and PlayerStateService.GetState(player) == PlayerStateService.State.Alive
end

-- State transition helpers
function PlayerStateService.MarkCaught(player)
	if not PlayerStateService.CanBeCaught(player) then
		return false, PlayerStateService.GetState(player)
	end
	local rec = records[player.UserId]
	rec.caughtCount += 1
	rec.lives = math.max(0, rec.lives - 1)
	local newState
	if rec.lives <= 0 then
		newState = PlayerStateService.State.Eliminated
		rec.eliminated = true
	else
		newState = PlayerStateService.State.Caught
	end
	rec.state = newState
	rec.lastStateChangedAt = os.clock()
	setAttributes(player, rec)
	return true, newState
end

function PlayerStateService.MarkCaged(player)
	if PlayerStateService.GetState(player) ~= PlayerStateService.State.Caught then
		return false
	end
	PlayerStateService.SetState(player, PlayerStateService.State.Caged)
	return true
end

function PlayerStateService.MarkRescued(player)
	local s = PlayerStateService.GetState(player)
	if s ~= PlayerStateService.State.Caught and s ~= PlayerStateService.State.Caged then
		return false
	end
	PlayerStateService.SetState(player, PlayerStateService.State.Alive)
	return true
end

function PlayerStateService.MarkEscaped(player)
	if not PlayerStateService.IsAliveThief(player) then
		return false
	end
	local rec = records[player.UserId]
	rec.escaped = true
	rec.state = PlayerStateService.State.Escaped
	rec.lastStateChangedAt = os.clock()
	setAttributes(player, rec)
	return true
end

function PlayerStateService.MarkEliminated(player)
	local rec = records[player and player.UserId]
	if not rec then return false end
	rec.eliminated = true
	rec.state = PlayerStateService.State.Eliminated
	rec.lastStateChangedAt = os.clock()
	setAttributes(player, rec)
	return true
end

-- Thief queries
function PlayerStateService.GetThieves()
	local result = {}
	for _, rec in pairs(records) do
		if rec.role == PlayerStateService.Role.Thief and rec.player and rec.player.Parent then
			table.insert(result, rec.player)
		end
	end
	return result
end

function PlayerStateService.GetAliveThieves()
	local result = {}
	for _, rec in pairs(records) do
		if rec.role == PlayerStateService.Role.Thief
			and rec.state == PlayerStateService.State.Alive
			and rec.player and rec.player.Parent then
			table.insert(result, rec.player)
		end
	end
	return result
end

function PlayerStateService.GetActiveThieves()
	local result = {}
	for _, rec in pairs(records) do
		if rec.role == PlayerStateService.Role.Thief
			and (rec.state == PlayerStateService.State.Alive
				or rec.state == PlayerStateService.State.Caught
				or rec.state == PlayerStateService.State.Caged)
			and rec.player and rec.player.Parent then
			table.insert(result, rec.player)
		end
	end
	return result
end

function PlayerStateService.CountAliveThieves()
	return #PlayerStateService.GetAliveThieves()
end

function PlayerStateService.AreAllThievesOut()
	-- Returns true when every registered thief is Escaped, Eliminated, or OutOfRound.
	-- Returns false if any thief is Alive, Caught, or Caged.
	for _, rec in pairs(records) do
		if rec.role == PlayerStateService.Role.Thief then
			local s = rec.state
			if s == PlayerStateService.State.Alive
				or s == PlayerStateService.State.Caught
				or s == PlayerStateService.State.Caged then
				return false
			end
		end
	end
	return true
end

function PlayerStateService.GetSnapshot()
	local snap = {}
	for userId, rec in pairs(records) do
		snap[userId] = {}
		for k, v in pairs(rec) do
			snap[userId][k] = v
		end
	end
	return snap
end

return PlayerStateService
