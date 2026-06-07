-- PingService
-- Simple team ping/callout system. Rate-limited. Auto-expiring.
-- Thief pings visible to all alive thieves.
-- Guardian pings visible only to guardian.

local PingService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local RemoteGuardService = require(script.Parent:WaitForChild("RemoteGuardService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local COOLDOWN = Constants.PING_COOLDOWN_SECONDS or 3
local LIFETIME = Constants.PING_LIFETIME_SECONDS or 5
local MAX_DIST = Constants.PING_MAX_DISTANCE or 120

local VALID_TYPES = {
	Objective = true, Idol = true, Extract = true,
	Cage = true, Danger = true, Generic = true,
}

local roundIsActive = false
local nextPingId = 0
local analyticsCallback = nil

local function fireOne(player, name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then r:FireClient(player, ...) end
end

function PingService.RequestPing(player, pingType, position)
	if not roundIsActive then
		fireOne(player, "PingFailed", "round_inactive")
		return
	end
	if not RemoteGuardService.Allow(player, "RequestPing", COOLDOWN) then
		fireOne(player, "PingFailed", "on_cooldown")
		return
	end

	local state = PlayerStateService.GetState(player)
	if state ~= PlayerStateService.State.Alive then
		fireOne(player, "PingFailed", "not_eligible")
		return
	end

	local safeType = (type(pingType) == "string" and VALID_TYPES[pingType]) and pingType or "Generic"

	-- Use player root if no valid position provided
	if typeof(position) ~= "Vector3" then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then
			fireOne(player, "PingFailed", "no_character")
			return
		end
		position = root.Position
	else
		-- Clamp to max distance from player
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local d = (position - root.Position).Magnitude
			if d > MAX_DIST then
				position = root.Position + (position - root.Position).Unit * MAX_DIST
			end
		end
	end

	nextPingId += 1
	local pingData = {
		pingId      = nextPingId,
		pingType    = safeType,
		position    = position,
		playerName  = player.Name,
		playerUserId = player.UserId,
		role        = PlayerStateService.GetRole(player),
	}

	local role = PlayerStateService.GetRole(player)
	if role == PlayerStateService.Role.Thief then
		for _, p in ipairs(Players:GetPlayers()) do
			if PlayerStateService.GetRole(p) == PlayerStateService.Role.Thief
				and PlayerStateService.IsAlive(p) then
				fireOne(p, "PingCreated", pingData, LIFETIME)
			end
		end
	else
		-- Guardian pings to self only
		fireOne(player, "PingCreated", pingData, LIFETIME)
	end

	if analyticsCallback then
		pcall(analyticsCallback)
	end
end

function PingService.SetAnalyticsCallback(cb)
	analyticsCallback = cb
end

function PingService.Init()
	local requestRemote = Remotes.Server(Remotes.Names.RequestPing)
	Remotes.Server(Remotes.Names.PingCreated)
	Remotes.Server(Remotes.Names.PingFailed)

	requestRemote.OnServerEvent:Connect(function(player, pingType, position)
		PingService.RequestPing(player, pingType, position)
	end)

	print("[PingService] Initialized.")
end

function PingService.ResetForRound()
	roundIsActive = true
end

function PingService.StopRound()
	roundIsActive = false
end

return PingService
