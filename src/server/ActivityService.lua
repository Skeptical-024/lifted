-- ActivityService
-- Tracks coarse player activity for lobby eligibility and active-round AFK handling.
-- Activity pulses never authorize gameplay; they only prevent false AFK positives.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local RemoteGuardService = require(script.Parent:WaitForChild("RemoteGuardService"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local ActivityService = {}

local records = {}
local trackedRemotes = {}

local function ensureRecord(player)
	local record = records[player.UserId]
	if not record then
		record = {
			lastActiveAt = os.clock(),
			warned = false,
			actioned = false,
			lastSource = "joined",
		}
		records[player.UserId] = record
	end
	return record
end

function ActivityService.MarkActive(player, source)
	if not player or not player.Parent then
		return
	end
	local record = ensureRecord(player)
	record.lastActiveAt = os.clock()
	record.warned = false
	record.actioned = false
	record.lastSource = source or "gameplay"
	player:SetAttribute("IsAFK", false)
end

function ActivityService.GetIdleSeconds(player)
	local record = player and records[player.UserId]
	if not record then
		return 0
	end
	return math.max(0, os.clock() - record.lastActiveAt)
end

function ActivityService.IsLobbyEligible(player)
	if Constants.AFK_ENABLED ~= true then
		return true
	end
	return ActivityService.GetIdleSeconds(player) < (Constants.AFK_LOBBY_SECONDS or 60)
end

function ActivityService.GetEligiblePlayers()
	local eligible = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if ActivityService.IsLobbyEligible(player) then
			table.insert(eligible, player)
		end
	end
	return eligible
end

function ActivityService.ShouldWarn(player)
	if Constants.AFK_ENABLED ~= true then
		return false
	end
	local record = ensureRecord(player)
	return not record.warned
		and ActivityService.GetIdleSeconds(player) >= (Constants.AFK_ACTIVE_WARNING_SECONDS or 90)
end

function ActivityService.MarkWarned(player)
	local record = ensureRecord(player)
	record.warned = true
	local remote = Remotes.Find(Remotes.Names.AFKWarning)
	if remote then
		remote:FireClient(player, "You are marked AFK. Move or act to stay in the round.")
	end
	player:SetAttribute("IsAFK", true)
end

function ActivityService.ShouldAction(player)
	if Constants.AFK_ENABLED ~= true then
		return false
	end
	local record = ensureRecord(player)
	return not record.actioned
		and ActivityService.GetIdleSeconds(player) >= (Constants.AFK_ACTIVE_ACTION_SECONDS or 120)
end

function ActivityService.MarkActioned(player)
	local record = ensureRecord(player)
	record.actioned = true
	player:SetAttribute("IsAFK", true)
end

function ActivityService.GetSnapshot(player)
	local record = player and ensureRecord(player) or nil
	return {
		idleSeconds = player and ActivityService.GetIdleSeconds(player) or 0,
		isAFK = player and player:GetAttribute("IsAFK") == true or false,
		warned = record and record.warned or false,
		actioned = record and record.actioned or false,
		lastSource = record and record.lastSource or nil,
	}
end

function ActivityService.TrackRemote(remoteName)
	if trackedRemotes[remoteName] then
		return
	end
	local remote = ReplicatedStorage:FindFirstChild(remoteName)
	if not (remote and remote:IsA("RemoteEvent")) then
		return
	end
	trackedRemotes[remoteName] = remote.OnServerEvent:Connect(function(player)
		ActivityService.MarkActive(player, remoteName)
	end)
end

function ActivityService.Init()
	local pulse = Remotes.Server(Remotes.Names.ActivityPulse)
	Remotes.Server(Remotes.Names.AFKWarning)
	pulse.OnServerEvent:Connect(function(player)
		if RemoteGuardService.Allow(
			player,
			"ActivityPulse",
			Constants.AFK_ACTIVITY_PULSE_SECONDS or 5
		) then
			ActivityService.MarkActive(player, "input")
		end
	end)

	local function register(player)
		ensureRecord(player)
		player:SetAttribute("IsAFK", false)
	end
	Players.PlayerAdded:Connect(register)
	Players.PlayerRemoving:Connect(function(player)
		records[player.UserId] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		register(player)
	end
end

function ActivityService.ResetForRound(players)
	for _, player in ipairs(players or Players:GetPlayers()) do
		ActivityService.MarkActive(player, "round_start")
	end
end

return ActivityService
