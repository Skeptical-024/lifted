-- SnapshotController: requestGameSnapshot, applyGameSnapshot, attribute watchers.
-- Init LAST; calls into every other controller.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local SnapshotController = {}

local sharedHud = nil
local coreHud = nil
local killFeed = nil
local guardianHud = nil
local thiefHud = nil
local skillCheck = nil
local objectiveHud = nil
local idolExtract = nil
local cage = nil

local requestGameSnapshotRemote = nil
local gameSnapshotRemote = nil

local function requestGameSnapshot()
	if requestGameSnapshotRemote then
		requestGameSnapshotRemote:FireServer()
	end
end

local function applyGameSnapshot(snapshot)
	if type(snapshot) ~= "table" then return end
	local COLORS = sharedHud.COLORS
	local localPlayer = sharedHud.localPlayer

	local state       = snapshot.roundState
	local role        = snapshot.playerRole or localPlayer:GetAttribute("Role")
	local playerState = snapshot.playerState or localPlayer:GetAttribute("RoundState")

	if state == "Active" or state == "Starting" then
		sharedHud.setIsRoundActive(true)
		coreHud.Show()
		coreHud.SetRole(role)
		coreHud.SetDirectiveVisible(true)
	elseif state == "Lobby" or state == "Intermission" or state == "Cleanup" then
		sharedHud.setIsRoundActive(false)
		coreHud.Hide()
		coreHud.SetHintVisible(false)
	end

	local timeRemaining = tonumber(snapshot.timeRemaining)
	if timeRemaining and timeRemaining > 0 then
		sharedHud.setRoundEndTime(os.clock() + timeRemaining)
		coreHud.SetTimerText(string.format("%d:%02d",
			math.floor(math.max(timeRemaining, 0) / 60),
			math.floor(math.max(timeRemaining, 0) % 60)
		))
	end

	if type(snapshot.objectives) == "table" then
		local indexByObjectiveId = {
			FlameSeal  = 1,
			MoonLock   = 2,
			StoneSigil = 3,
		}
		local completed = 0
		for objectiveId, obj in pairs(snapshot.objectives) do
			if type(obj) == "table" and obj.completed == true then
				completed += 1
				objectiveHud.SetSealCompleted(objectiveId)
			end
		end
		sharedHud.setSealsBroken(math.clamp(completed, 0, 3))
	end

	if snapshot.vaultOpen == true then
		idolExtract.SetVaultOpenUI()
	else
		coreHud.SetPhase("Break the Seals")
	end

	if type(snapshot.idol) == "table" then
		if snapshot.idol.carrierUserId ~= nil then
			idolExtract.SetCarrierUI(snapshot.idol.carrierUserId, snapshot.idol.carrierName)
			guardianHud.SetCarrier(snapshot.idol.carrierUserId, snapshot.idol.carrierName)
		elseif snapshot.idol.state == "Available" then
			idolExtract.SetAvailableUI()
		elseif snapshot.idol.state == "Dropped" then
			idolExtract.SetDroppedUI()
		elseif snapshot.idol.state == "Extracted" then
			idolExtract.SetExtractedUI()
		else
			guardianHud.ClearCarrier()
		end
		if snapshot.idol.isExtracting then
			idolExtract.SetExtractProgressUI(snapshot.idol.extractProgress or 0)
		end
	end

	if type(snapshot.guardianAbilities) == "table" then
		for abilityName, seconds in pairs(snapshot.guardianAbilities) do
			guardianHud.SetAbilityCooldownEnd(abilityName, os.clock() + math.max(0, tonumber(seconds) or 0))
		end
		guardianHud.UpdateAbilityLine()
	end

	local localIsCaged     = snapshot.isLocalPlayerCaged == true or playerState == "Caged"
	local localIsEliminated = snapshot.isLocalPlayerEliminated == true or playerState == "Eliminated"
	local localIsOut       = snapshot.isLocalPlayerOutOfRound == true or playerState == "OutOfRound"

	if type(snapshot.cage) == "table" then
		local cagedPlayers = snapshot.cage.cagedPlayers or {}
		local rescues = snapshot.cage.rescues or {}
		if cagedPlayers[localPlayer.UserId] then
			localIsCaged = true
			coreHud.SetDirective("You are caged. Wait for rescue.")
			coreHud.SetDirectiveVisible(true)
			coreHud.SetHintVisible(false)
			local rescueRec = rescues[localPlayer.UserId]
			if rescueRec and (tonumber(rescueRec.progress) or 0) > 0 then
				coreHud.SetDirective("Rescue in progress...")
			end
		end
	end

	if localIsEliminated then
		coreHud.SetRoleOverride("ELIMINATED", COLORS.red)
		coreHud.SetDirective("ELIMINATED — spectating until next round")
		coreHud.SetDirectiveVisible(true)
		coreHud.SetHintVisible(false)
	elseif localIsCaged then
		coreHud.SetRoleOverride("CAGED", COLORS.red)
		coreHud.SetDirectiveVisible(true)
		coreHud.SetHintVisible(false)
	elseif localIsOut then
		coreHud.SetRoleOverride("WAITING", COLORS.grey)
		coreHud.SetDirective("Round in progress — waiting for next round")
		coreHud.SetDirectiveVisible(true)
		coreHud.SetHintVisible(false)
	elseif role == "Thief" and sharedHud.getIsRoundActive() then
		if localPlayer:GetAttribute("HasIdol") == true then
			coreHud.SetDirective("Extract with the idol")
		elseif snapshot.idol and snapshot.idol.carrierUserId then
			coreHud.SetDirective("Protect the idol carrier")
		elseif snapshot.vaultOpen == true then
			coreHud.SetDirective("Steal the idol")
		else
			coreHud.SetDirective("Break the seals")
		end
	elseif role == "Guardian" and sharedHud.getIsRoundActive() then
		coreHud.SetDirective(
			snapshot.idol and snapshot.idol.carrierUserId
				and "Catch the idol carrier"
				or "Stop the thieves"
		)
	end
end

function SnapshotController.Init(sh, ch, kf, gh, th, sc, oh, ie, cg)
	sharedHud   = sh
	coreHud     = ch
	killFeed    = kf
	guardianHud = gh
	thiefHud    = th
	skillCheck  = sc
	objectiveHud = oh
	idolExtract = ie
	cage        = cg

	requestGameSnapshotRemote = Remotes.Client(Remotes.Names.RequestGameSnapshot)
	gameSnapshotRemote        = Remotes.Client(Remotes.Names.GameSnapshot)

	-- Snapshot response
	gameSnapshotRemote.OnClientEvent:Connect(function(snapshot)
		applyGameSnapshot(snapshot)
	end)

	-- Role attribute change → re-apply role UI + request snapshot
	sh.localPlayer:GetAttributeChangedSignal("Role"):Connect(function()
		coreHud.SetRole(sh.localPlayer:GetAttribute("Role"))
		requestGameSnapshot()
	end)

	-- RoundState attribute change → status overrides + snapshot
	sh.localPlayer:GetAttributeChangedSignal("RoundState"):Connect(function()
		local state = sh.localPlayer:GetAttribute("RoundState")
		local COLORS = sh.COLORS
		if state == "Eliminated" then
			coreHud.SetRoleOverride("ELIMINATED", COLORS.red)
			coreHud.SetDirective("ELIMINATED — spectating until next round")
			coreHud.SetDirectiveVisible(true)
			coreHud.SetHintVisible(false)
		elseif state == "Caged" then
			coreHud.SetRoleOverride("CAGED", COLORS.red)
			coreHud.SetDirective("YOU ARE CAGED — wait for rescue")
			coreHud.SetDirectiveVisible(true)
			coreHud.SetHintVisible(false)
		elseif state == "OutOfRound" and sharedHud.getIsRoundActive() then
			coreHud.SetRoleOverride("WAITING", COLORS.grey)
			coreHud.SetDirective("Round in progress — waiting for next round")
			coreHud.SetDirectiveVisible(true)
			coreHud.SetHintVisible(false)
		end
		requestGameSnapshot()
	end)

	-- Character respawn → request snapshot
	sh.localPlayer.CharacterAdded:Connect(function()
		task.defer(requestGameSnapshot)
	end)

	-- Initial snapshot
	task.defer(requestGameSnapshot)
end

return SnapshotController
