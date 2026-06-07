-- CageController: PlayerCaged/Rescue remotes → kill feed + directive updates.

local CageController = {}

local sharedHud = nil
local killFeed = nil
local coreHud = nil  -- injected after CoreHud.Init via SetCoreHud()

-- Private state
local lastCageRescueFeedAt = 0
local lastCageRescuePercent = -1

function CageController.Init(sh, kf)
	sharedHud = sh
	killFeed = kf

	local co = sh.connectOptional
	local Remotes = sh.Remotes

	co(Remotes.Names.PlayerCaged, function(userId, playerName)
		local name = type(playerName) == "string" and playerName or "A thief"
		killFeed.Add(name .. " was caged")
		if coreHud then
			if sharedHud.localPlayer.UserId == userId then
				coreHud.SetDirective("You are caged. Wait for rescue.")
			elseif sh.isThiefRole() and sharedHud.localPlayer:GetAttribute("HasIdol") ~= true then
				coreHud.SetDirective("Rescue your teammate")
			end
		end
	end)

	co(Remotes.Names.CageRescueProgress, function(userId, progress, rescuerCount)
		progress = math.clamp(tonumber(progress) or 0, 0, 1)
		local now = os.clock()
		local percent = math.floor(progress * 100)
		local percentStep = math.floor(percent / 10)
		local lastStep = math.floor(math.max(lastCageRescuePercent, 0) / 10)
		if (now - lastCageRescueFeedAt) >= 1.5 and percentStep > lastStep then
			lastCageRescueFeedAt = now
			lastCageRescuePercent = percent
			killFeed.Add("Rescue in progress: " .. percent .. "%")
		end
	end)

	co(Remotes.Names.CageRescueCompleted, function(userId, playerName)
		local name = type(playerName) == "string" and playerName or "A thief"
		lastCageRescueFeedAt = 0
		lastCageRescuePercent = -1
		killFeed.Add(name .. " rescued!")
		if coreHud then
			if sharedHud.localPlayer.UserId == userId then
				local role = sharedHud.localPlayer:GetAttribute("Role")
				if role == "Thief" then
					coreHud.SetDirective("You were rescued. Back in the heist.")
				end
			elseif sh.isThiefRole() and sharedHud.localPlayer:GetAttribute("HasIdol") ~= true then
				coreHud.SetDirective(sharedHud.getVaultOpen() and "Steal the idol" or "Break the seals")
			end
		end
	end)

	co(Remotes.Names.CageRescueCanceled, function(targetUserId, reason)
		lastCageRescueFeedAt = 0
		lastCageRescuePercent = -1
		local reasonText = "Rescue canceled"
		if reason == "rescuer_left" then
			reasonText = "Rescuer moved away"
		elseif reason == "target_left" then
			reasonText = "Target left"
		elseif reason == "roar" then
			reasonText = "Interrupted by Roar"
		elseif reason == "canceled" then
			reasonText = "Rescue canceled"
		end
		killFeed.Add(reasonText)
	end)

	co(Remotes.Names.CageRescueFailed, function(reason)
		sharedHud.showFailure(reason)
	end)
end

function CageController.SetCoreHud(ch)
	coreHud = ch
end

function CageController.Reset()
	lastCageRescueFeedAt = 0
	lastCageRescuePercent = -1
end

return CageController
