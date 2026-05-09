-- CageService
-- Server-authoritative cage and rescue system.
-- Physical freeze/teleport to cage is handled by GameManager.freezeThiefCharacter.
-- CageService owns state transitions and rescue progression.

local CageService = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local RESCUE_DIST = Constants.CAGE_RESCUE_DISTANCE or 12
local RESCUE_TIME = Constants.CAGE_RESCUE_TIME or 8
local BASE_RATE = 1 / RESCUE_TIME

local MULTIPLIERS = { [1] = 1.0, [2] = 1.5, [3] = 2.0, [4] = 2.25 }

local cagedPlayers = {}
local rescueRecords = {}
local rescuePoint = nil
local cageSpawn = nil
local heartbeatConn = nil
local roundIsActive = false

local function getOrCreateRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then return r end
	if r then r:Destroy() end
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = ReplicatedStorage
	return e
end

local function fireAll(name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then r:FireAllClients(...) end
end

local function fireOne(player, name, ...)
	local r = ReplicatedStorage:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then r:FireClient(player, ...) end
end

local function getRootPart(player)
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getMultiplier(n)
	return MULTIPLIERS[math.clamp(n, 1, 4)] or 1.0
end

local function unfreeze(player)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum.WalkSpeed = Constants.DEFAULT_WALK_SPEED or 16
	if hum.UseJumpPower then
		hum.JumpPower = 50
	else
		hum.JumpHeight = 7.2
	end
	pcall(function() player:SetAttribute("IsCaught", false) end)
end

local function teleportNearCage(player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local targetPos
	if rescuePoint then
		targetPos = rescuePoint.Position + Vector3.new(0, 4, 0)
	elseif cageSpawn then
		targetPos = cageSpawn.Position + Vector3.new(8, 4, 0)
	end
	if targetPos then
		pcall(function() root.CFrame = CFrame.new(targetPos) end)
	end
end

local function stopHeartbeat()
	if heartbeatConn then heartbeatConn:Disconnect() heartbeatConn = nil end
end

local function startHeartbeat()
	stopHeartbeat()
	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		if not roundIsActive then return end

		for cageUserId, rec in pairs(rescueRecords) do
			local caged = cagedPlayers[cageUserId]
			if not caged or not caged.Parent then
				rescueRecords[cageUserId] = nil
				continue
			end

			local valid = {}
			for _, rescuer in ipairs(rec.activeRescuers) do
				if rescuer and rescuer.Parent and PlayerStateService.IsAliveThief(rescuer) then
					local root = getRootPart(rescuer)
					if root and rescuePoint then
						if (root.Position - rescuePoint.Position).Magnitude <= RESCUE_DIST then
							table.insert(valid, rescuer)
						end
					elseif root and cageSpawn then
						if (root.Position - cageSpawn.Position).Magnitude <= RESCUE_DIST then
							table.insert(valid, rescuer)
						end
					end
				end
			end
			rec.activeRescuers = valid

			local count = #valid
			if count == 0 then continue end

			rec.progress = math.clamp(rec.progress + BASE_RATE * getMultiplier(count) * dt, 0, 1)
			fireAll("CageRescueProgress", cageUserId, rec.progress, count)

			if rec.progress >= 1 then
				local rescuedPlayer = caged
				cagedPlayers[cageUserId] = nil
				rescueRecords[cageUserId] = nil

				PlayerStateService.MarkRescued(rescuedPlayer)
				unfreeze(rescuedPlayer)
				teleportNearCage(rescuedPlayer)

				fireAll("CageRescueCompleted", rescuedPlayer.UserId, rescuedPlayer.Name)
				print("[CageService] Rescued:", rescuedPlayer.Name)
			end
		end
	end)
end

function CageService.Init()
	getOrCreateRemote("RequestCageRescueStart")
	getOrCreateRemote("RequestCageRescueStop")
	getOrCreateRemote("PlayerCaged")
	getOrCreateRemote("CageRescueStarted")
	getOrCreateRemote("CageRescueProgress")
	getOrCreateRemote("CageRescueCompleted")
	getOrCreateRemote("CageRescueFailed")

	local startRemote = ReplicatedStorage:WaitForChild("RequestCageRescueStart")
	local stopRemote = ReplicatedStorage:WaitForChild("RequestCageRescueStop")

	startRemote.OnServerEvent:Connect(function(player)
		CageService.StartRescue(player)
	end)

	stopRemote.OnServerEvent:Connect(function(player)
		CageService.StopRescue(player)
	end)

	print("[CageService] Initialized.")
end

function CageService.AutoRegisterParts()
	rescuePoint = nil
	cageSpawn = nil

	for _, part in ipairs(CollectionService:GetTagged("CageRescuePoint")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			rescuePoint = part
			break
		end
	end

	for _, part in ipairs(CollectionService:GetTagged("CageSpawn")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			cageSpawn = part
			break
		end
	end

	if not rescuePoint and cageSpawn then
		rescuePoint = cageSpawn
		warn("[CageService] No CageRescuePoint found, using CageSpawn as fallback.")
	end
	if not cageSpawn then
		warn("[CageService] No CageSpawn found - CagePlayer will fail.")
	end
end

function CageService.ResetForRound(roundId)
	roundIsActive = true
	cagedPlayers = {}
	rescueRecords = {}
	CageService.AutoRegisterParts()
	stopHeartbeat()
	startHeartbeat()
end

function CageService.StopRound()
	roundIsActive = false
	stopHeartbeat()
	for _, player in pairs(cagedPlayers) do
		if player and player.Parent then
			pcall(function() unfreeze(player) end)
		end
	end
	cagedPlayers = {}
	rescueRecords = {}
end

function CageService.CagePlayer(player)
	if not player or not player.Parent then return end
	if not roundIsActive then return end

	local ok = PlayerStateService.MarkCaged(player)
	if not ok then
		warn("[CageService] CagePlayer failed for", player.Name, "- not in Caught state")
		return
	end

	cagedPlayers[player.UserId] = player
	rescueRecords[player.UserId] = {
		player = player,
		progress = 0,
		activeRescuers = {},
	}

	fireAll("PlayerCaged", player.UserId, player.Name)
	print("[CageService] Caged:", player.Name)
end

function CageService.StartRescue(rescuer)
	if not rescuer or not rescuer.Parent then return end
	if not roundIsActive then return end

	if not PlayerStateService.IsAliveThief(rescuer) then
		fireOne(rescuer, "CageRescueFailed", "not_eligible")
		return
	end

	local hasCaged = false
	for _ in pairs(cagedPlayers) do hasCaged = true break end
	if not hasCaged then
		fireOne(rescuer, "CageRescueFailed", "no_caged_players")
		return
	end

	local root = getRootPart(rescuer)
	if not root then
		fireOne(rescuer, "CageRescueFailed", "no_character")
		return
	end
	local refPart = rescuePoint or cageSpawn
	if not refPart then
		fireOne(rescuer, "CageRescueFailed", "no_rescue_point")
		return
	end
	if (root.Position - refPart.Position).Magnitude > RESCUE_DIST then
		fireOne(rescuer, "CageRescueFailed", "too_far")
		return
	end

	for _, rec in pairs(rescueRecords) do
		local alreadyIn = false
		for _, r in ipairs(rec.activeRescuers) do
			if r == rescuer then alreadyIn = true break end
		end
		if not alreadyIn then
			table.insert(rec.activeRescuers, rescuer)
		end
	end

	fireOne(rescuer, "CageRescueStarted", rescuer.UserId)
end

function CageService.StopRescue(rescuer)
	for _, rec in pairs(rescueRecords) do
		for i, r in ipairs(rec.activeRescuers) do
			if r == rescuer then
				table.remove(rec.activeRescuers, i)
				break
			end
		end
	end
end

function CageService.StopAllForPlayer(player)
	if player and cagedPlayers[player.UserId] then
		cagedPlayers[player.UserId] = nil
		rescueRecords[player.UserId] = nil
	end
	CageService.StopRescue(player)
end

function CageService.IsCaged(player)
	return cagedPlayers[player and player.UserId] ~= nil
end

function CageService.GetCagedPlayersSnapshot()
	local snap = {}
	for uid, p in pairs(cagedPlayers) do
		snap[uid] = { userId = uid, name = p.Name }
	end
	return snap
end

return CageService
