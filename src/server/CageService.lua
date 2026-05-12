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
local RESCUE_TIME = Constants.CAGE_RESCUE_SECONDS or Constants.CAGE_RESCUE_TIME or 4
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
			local prevCount = #rec.activeRescuers  -- capture before reassigning
			rec.activeRescuers = valid
			local count = #valid

			-- If we had rescuers but now have none, the rescue was canceled
			if prevCount > 0 and count == 0 then
				if rec.progress > 0 then
					rec.progress = 0
					fireAll("CageRescueCanceled", cageUserId, "rescuer_left")
				end
				continue
			end

			if count == 0 then continue end

			rec.progress = math.clamp(rec.progress + BASE_RATE * getMultiplier(count) * dt, 0, 1)
			fireAll("CageRescueProgress", cageUserId, rec.progress, count)

			if rec.progress >= 1 then
				local rescuedPlayer = caged
				cagedPlayers[cageUserId] = nil
				rescueRecords[cageUserId] = nil

				CageService.ReleasePlayer(rescuedPlayer, "rescued")
				-- Fire CageRescueCompleted to all (UI uses this)
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
	getOrCreateRemote("CageStateChanged")
	getOrCreateRemote("CageRescueStarted")
	getOrCreateRemote("CageRescueProgress")
	getOrCreateRemote("CageRescueCompleted")
	getOrCreateRemote("CageRescueCanceled")
	getOrCreateRemote("CageRescueFailed")

	local startRemote = ReplicatedStorage:WaitForChild("RequestCageRescueStart")
	local stopRemote = ReplicatedStorage:WaitForChild("RequestCageRescueStop")

	startRemote.OnServerEvent:Connect(function(player, targetUserId)
		CageService.StartRescue(player, targetUserId)
	end)

	stopRemote.OnServerEvent:Connect(function(player, targetUserId)
		CageService.StopRescue(player, targetUserId)
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
	local snapshot = {}
	for uid, p in pairs(cagedPlayers) do snapshot[uid] = p end
	cagedPlayers = {}
	rescueRecords = {}
	for _, p in pairs(snapshot) do
		if p and p.Parent then
			pcall(function()
				local char = p.Character
				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.WalkSpeed = Constants.DEFAULT_WALK_SPEED or 16
						if hum.UseJumpPower then hum.JumpPower = 50
						else hum.JumpHeight = 7.2 end
					end
				end
				p:SetAttribute("IsCaught", false)
				p:SetAttribute("IsCaged", false)
			end)
		end
	end
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
	pcall(function() player:SetAttribute("IsCaged", true) end)
	fireAll("CageStateChanged", player.UserId, player.Name, "Caged", "caught")
	print("[CageService] Caged:", player.Name)
end

function CageService.StartRescue(rescuer, targetUserId)
	if not rescuer or not rescuer.Parent then return end
	if not roundIsActive then return end

	if not PlayerStateService.IsAliveThief(rescuer) then
		fireOne(rescuer, "CageRescueFailed", "not_eligible")
		return
	end

	if targetUserId == nil then
		fireOne(rescuer, "CageRescueFailed", "missing_target")
		return
	end
	if targetUserId == rescuer.UserId then
		fireOne(rescuer, "CageRescueFailed", "cannot_rescue_self")
		return
	end
	local targetRec = rescueRecords[targetUserId]
	if cagedPlayers[targetUserId] == nil or targetRec == nil then
		fireOne(rescuer, "CageRescueFailed", "target_not_caged")
		return
	end

	-- Single rescuer per target: reject if someone else is already rescuing
	if #targetRec.activeRescuers > 0 then
		if targetRec.activeRescuers[1] ~= rescuer then
			fireOne(rescuer, "CageRescueFailed", "already_being_rescued")
			return
		end
		-- Same rescuer calling start again: no-op
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

	table.insert(targetRec.activeRescuers, rescuer)

	local caged = cagedPlayers[targetUserId]
	local targetName = caged and caged.Name or "teammate"
	fireOne(rescuer, "CageRescueStarted", rescuer.UserId, targetUserId, targetName, RESCUE_TIME)
end

function CageService.StopRescue(rescuer, targetUserId)
	if not rescuer then return end
	if targetUserId and rescueRecords[targetUserId] then
		local rec = rescueRecords[targetUserId]
		for i, r in ipairs(rec.activeRescuers) do
			if r == rescuer then
				table.remove(rec.activeRescuers, i)
				break
			end
		end
		return
	end
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

function CageService.ReleasePlayer(player, reason)
	if not player or not player.Parent then return end
	cagedPlayers[player.UserId] = nil
	rescueRecords[player.UserId] = nil
	local ok = PlayerStateService.MarkRescued(player)
	if not ok then
		local currentState = PlayerStateService.GetState(player)
		warn("[CageService] ReleasePlayer MarkRescued failed for", player.Name, "state:", tostring(currentState))
	end
	-- Unfreeze
	if player.Parent then
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = Constants.DEFAULT_WALK_SPEED or 16
				if hum.UseJumpPower then
					hum.JumpPower = 50
				else
					hum.JumpHeight = 7.2
				end
			end
		end
		-- Teleport near cage exit
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local exitPos
			if rescuePoint then
				exitPos = rescuePoint.Position + Vector3.new(0, 4, 0)
			elseif cageSpawn then
				exitPos = cageSpawn.Position + Vector3.new(8, 4, 0)
			end
			if exitPos then
				pcall(function() root.CFrame = CFrame.new(exitPos) end)
			end
		end
	end
	pcall(function()
		player:SetAttribute("IsCaged", false)
		player:SetAttribute("IsCaught", false)
	end)
	fireAll("CageStateChanged", player.UserId, player.Name, "Alive", reason or "rescued")
	print("[CageService] Released:", player.Name, "reason:", reason or "rescued")
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
