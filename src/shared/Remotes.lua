--!strict
-- Remotes.lua
-- Single source of truth for all RemoteEvent names and accessors.
-- Server:  Remotes.Server(Remotes.Names.X)  — idempotent create-or-get, any load order.
-- Client:  Remotes.Client(Remotes.Names.X)  — WaitForChild (blocking, up to timeout).
-- Either:  Remotes.Find(Remotes.Names.X)    — FindFirstChild, non-blocking, nil if absent.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Guard: remotes must stay flat under ReplicatedStorage, never inside a subfolder.
if ReplicatedStorage:FindFirstChild("Remotes") then
	warn("[Remotes] FATAL: A child named 'Remotes' exists under ReplicatedStorage. "
		.. "All RemoteEvents must be direct children of ReplicatedStorage (flat layout). Remove it.")
end

local Remotes = {}

-- Canonical remote names grouped by system.
-- Every RemoteEvent in the game is listed here. No string literals elsewhere.
Remotes.Names = {
	-- Round lifecycle
	RoleAssigned                = "RoleAssigned",
	RoundStarted                = "RoundStarted",
	RoundEnded                  = "RoundEnded",
	LobbyUpdate                 = "LobbyUpdate",
	ThiefCaught                 = "ThiefCaught",
	ThiefCountUpdate            = "ThiefCountUpdate",
	PlayerEliminated            = "PlayerEliminated",
	ThiefExtracted              = "ThiefExtracted",    -- legacy stub; intentional no-op on server
	SetMovementState            = "SetMovementState",
	CatchThief                  = "CatchThief",

	-- Objective / Seals
	RequestObjectiveStart       = "RequestObjectiveStart",
	RequestObjectiveStop        = "RequestObjectiveStop",
	ObjectivePromptShown        = "ObjectivePromptShown",
	ObjectivePromptHidden       = "ObjectivePromptHidden",
	ObjectiveInteractionStarted = "ObjectiveInteractionStarted",
	ObjectiveProgress           = "ObjectiveProgress",
	ObjectiveCompleted          = "ObjectiveCompleted",
	ObjectiveFailed             = "ObjectiveFailed",
	VaultOpened                 = "VaultOpened",

	-- Idol / Extract
	RequestIdolPickup           = "RequestIdolPickup",
	RequestIdolDrop             = "RequestIdolDrop",
	RequestExtractWithIdol      = "RequestExtractWithIdol",
	RequestExtractCancel        = "RequestExtractCancel",
	IdolAvailable               = "IdolAvailable",
	IdolPickedUp                = "IdolPickedUp",
	IdolDropped                 = "IdolDropped",
	IdolCarrierChanged          = "IdolCarrierChanged",
	IdolExtracted               = "IdolExtracted",
	IdolFailed                  = "IdolFailed",
	ExtractStarted              = "ExtractStarted",
	ExtractProgress             = "ExtractProgress",
	ExtractCanceled             = "ExtractCanceled",
	ExtractCompleted            = "ExtractCompleted",
	ExtractFailed               = "ExtractFailed",

	-- Cage / Rescue
	RequestCageRescueStart      = "RequestCageRescueStart",
	RequestCageRescueStop       = "RequestCageRescueStop",
	PlayerCaged                 = "PlayerCaged",
	CageStateChanged            = "CageStateChanged",
	CageRescueStarted           = "CageRescueStarted",
	CageRescueProgress          = "CageRescueProgress",
	CageRescueCompleted         = "CageRescueCompleted",
	CageRescueCanceled          = "CageRescueCanceled",
	CageRescueFailed            = "CageRescueFailed",

	-- Guardian abilities
	RequestGuardianRush         = "RequestGuardianRush",
	RequestGuardianReveal       = "RequestGuardianReveal",
	RequestGuardianRoar         = "RequestGuardianRoar",
	GuardianRushStarted         = "GuardianRushStarted",
	GuardianRushFailed          = "GuardianRushFailed",
	GuardianRevealStarted       = "GuardianRevealStarted",
	GuardianRevealFailed        = "GuardianRevealFailed",
	GuardianRoarActivated       = "GuardianRoarActivated",
	GuardianRoarFailed          = "GuardianRoarFailed",
	GuardianAbilityCooldown     = "GuardianAbilityCooldown",
	GuardianCarrierPing         = "GuardianCarrierPing",
	GuardianCatchFailed         = "GuardianCatchFailed",

	-- Skill check
	RequestSkillCheckHit        = "RequestSkillCheckHit",
	SkillCheckStarted           = "SkillCheckStarted",
	SkillCheckResult            = "SkillCheckResult",
	SkillCheckExpired           = "SkillCheckExpired",

	-- Ping / callout
	RequestPing                 = "RequestPing",
	PingCreated                 = "PingCreated",
	PingFailed                  = "PingFailed",

	-- Snapshot / recovery
	RequestGameSnapshot         = "RequestGameSnapshot",
	GameSnapshot                = "GameSnapshot",

	-- Results
	RoundResults                = "RoundResults",

	-- Activity / AFK
	ActivityPulse               = "ActivityPulse",
	AFKWarning                  = "AFKWarning",
}

-- Server: idempotent create-or-get. Safe at any load order.
-- Replaces the per-file getOrCreateRemote pattern; semantics are identical.
function Remotes.Server(name: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing :: RemoteEvent
	end
	if existing then
		existing:Destroy()
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

-- Client: WaitForChild (blocking up to `timeout` seconds, default 30).
-- Mirrors the WaitForChild pattern used throughout client scripts.
function Remotes.Client(name: string, timeout: number?): RemoteEvent
	return ReplicatedStorage:WaitForChild(name, timeout or 30) :: RemoteEvent
end

-- Non-blocking: FindFirstChild. Returns nil if the remote does not yet exist.
-- Use for optional connections (connectOptional pattern) or deferred lookups.
function Remotes.Find(name: string): RemoteEvent?
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then
		return r :: RemoteEvent
	end
	return nil
end

return Remotes
